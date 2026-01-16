import { IdentityEnvelopeV1, ValidatedIdentityContext } from "../context/identity.js";
import { SymphonyKeyManager, KeyManager } from "../crypto/keyManager.js";
import { logger } from "../logging/logger.js";
import crypto from "crypto";
import { jwtVerify, JWTPayload } from 'jose';
import { getJWKS } from '../crypto/jwks.js';

// KeyManager singleton (Unified for Dev/Prod Parity)
const keyManager: KeyManager = new SymphonyKeyManager();

// SEC-7R-FIX: JWT verification configuration
const JWT_ISSUER = 'symphony-idp';
const JWT_AUDIENCE = 'symphony-api';
const CLOCK_TOLERANCE_SECONDS = 30;

/**
 * Extended JWT payload with Symphony-specific claims
 */
interface SymphonyJWTPayload extends JWTPayload {
    sub: string;
    scope?: string;
    tenant_id?: string;
}

/**
 * INV-SEC-03: Trust Tier Isolation & JWT->mTLS Bridge
 * This bridge is the "Singularity Point" where external identities terminate and internal service identities begin.
 * 
 * SEC-7R-FIX: Implements real ES256 JWT verification via jose library.
 */
export const jwtToMtlsBridge = {
    /**
     * Terminate External JWT and Re-Issue Internal mTLS Identity.
     * @param rawJwtToken The raw bearer token from the gateway.
     * @param clientCertFingerprint The mTLS certificate fingerprint (if present).
     * @returns A Verified Context with 'external' Trust Tier.
     */
    bridgeExternalIdentity: async (
        rawJwtToken: string,
        clientCertFingerprint?: string
    ): Promise<ValidatedIdentityContext> => {
        if (!rawJwtToken) {
            throw new Error("Missing JWT Token");
        }

        // SEC-7R-FIX: Real ES256 JWT verification
        let claims: SymphonyJWTPayload;
        try {
            const { payload } = await jwtVerify(rawJwtToken, getJWKS(), {
                issuer: JWT_ISSUER,
                audience: JWT_AUDIENCE,
                clockTolerance: CLOCK_TOLERANCE_SECONDS,
                requiredClaims: ['sub', 'iss', 'aud', 'exp', 'iat'],
            });
            claims = payload as SymphonyJWTPayload;
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.warn({ error: errorMessage }, 'JWT verification failed');
            throw new Error(`JWT verification failed: ${errorMessage}`);
        }

        // 2. Terminate Claims - Do NOT propagate raw JWT.
        const now = new Date().toISOString();
        const requestId = crypto.randomUUID();

        // 3. Create 'external' Trust Tier Context
        const context: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: requestId,
            issuedAt: now,
            issuerService: 'ingress-gateway',
            subjectType: 'client',
            subjectId: claims.sub,
            tenantId: 'tenant_default',
            policyVersion: 'v1.0.0',
            roles: ['authenticated_user'],
            trustTier: 'external',
            signature: '',
            ...(clientCertFingerprint ? { certFingerprint: clientCertFingerprint } : {})
        };

        // 4. SEC-7R-FIX: Sign with canonical JSON (sorted keys) matching verifyIdentity.ts
        const dataToSign = JSON.stringify({
            certFingerprint: context.certFingerprint ?? null,
            issuedAt: context.issuedAt,
            issuerService: context.issuerService,
            policyVersion: context.policyVersion,
            requestId: context.requestId,
            roles: context.roles.slice().sort(),
            subjectId: context.subjectId,
            subjectType: context.subjectType,
            tenantId: context.tenantId,
            trustTier: context.trustTier ?? null,
            version: context.version,
        });

        const signature = crypto.createHmac('sha256', await keyManager.deriveKey('identity/hmac'))
            .update(dataToSign)
            .digest('hex');

        context.signature = signature;

        logger.info({
            type: 'IDENTITY_BRIDGE',
            requestId,
            action: 'TERMINATE_JWT_AND_BRIDGE',
            subjectId: context.subjectId,
            trustTier: context.trustTier
        }, "Bridged external identity to internal verification context");

        return Object.freeze(context);
    },

    /**
     * Assert that a context is safe for internal propagation.
     * Throws if raw JWT claims are detected or signatures are invalid.
     */
    assertInternalSafety: async (context: ValidatedIdentityContext): Promise<void> => {
        const contextFields = context as Record<string, unknown>;
        if (contextFields.jwt || contextFields.rawToken) {
            throw new Error("CRITICAL: Raw JWT leakage detected in internal context.");
        }

        // Verify Signature
        // Verify Signature
        // 4. SEC-7R-FIX: Canonical JSON (sorted keys) matching verifyIdentity.ts
        const dataToSign = JSON.stringify({
            certFingerprint: context.certFingerprint ?? null,
            issuedAt: context.issuedAt,
            issuerService: context.issuerService,
            policyVersion: context.policyVersion,
            requestId: context.requestId,
            roles: context.roles.slice().sort(), // Sorted for determinism
            subjectId: context.subjectId,
            subjectType: context.subjectType,
            tenantId: context.tenantId,
            trustTier: context.trustTier ?? null,
            version: context.version,
        });

        const expectedSig = crypto.createHmac('sha256', await keyManager.deriveKey('identity/hmac'))
            .update(dataToSign)
            .digest('hex');

        // SEC-7R-FIX: Timing-safe comparison
        const sigBuffer = Buffer.from(context.signature, 'hex');
        const expectedBuffer = Buffer.from(expectedSig, 'hex');

        if (sigBuffer.length !== expectedBuffer.length ||
            !crypto.timingSafeEqual(sigBuffer, expectedBuffer)) {
            throw new Error("CRITICAL: Internal identity integrity check failed (Invalid Signature).");
        }
    }
};
