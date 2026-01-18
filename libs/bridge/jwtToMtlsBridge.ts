import { IdentityEnvelopeV1, ValidatedIdentityContext, UserIdentityEnvelopeV1, ParticipantRole, ParticipantStatus } from "../context/identity.js";
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
     * Terminate External JWT and Re-Issue Internal mTLS Identity (Client).
     * @param rawJwtToken The raw bearer token from the gateway.
     * @param clientCertFingerprint The mTLS certificate fingerprint (if present).
     * @returns A Verified Context with 'external' Trust Tier.
     */
    bridgeExternalIdentity: async (
        rawJwtToken: string,
        _clientCertFingerprint?: string
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
                algorithms: ['ES256'] // SECURITY: Prevent alg confusion
            });
            claims = payload as SymphonyJWTPayload;
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.warn({ error: errorMessage }, 'JWT verification failed');
            throw new Error(`JWT verification failed: ${errorMessage}`);
        }

        const now = new Date().toISOString();
        const requestId = crypto.randomUUID();

        // Correct strict typing: Client envelope has NO certFingerprint. 
        // We drop clientCertFingerprint from the envelope structure itself.
        const strictContext: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: requestId,
            issuedAt: now,
            issuerService: 'ingest-api',
            subjectType: 'client',
            subjectId: claims.sub,
            tenantId: 'tenant_default',
            policyVersion: 'v1.0.0',
            roles: ['authenticated_user'],
            trustTier: 'external',
            signature: '',
        };

        strictContext.signature = await signEnvelope(strictContext);

        logger.info({
            type: 'IDENTITY_BRIDGE',
            requestId,
            action: 'TERMINATE_JWT_AND_BRIDGE_CLIENT',
            subjectId: strictContext.subjectId,
            trustTier: strictContext.trustTier
        }, "Bridged external client identity");

        return Object.freeze(strictContext);
    },

    /**
     * Terminate External JWT and Re-Issue Tenant-Anchored User Identity.
     * @param rawJwtToken The raw bearer token.
     * @param participantResolver Async function to resolve participant details from tenantId.
     */
    bridgeUserIdentity: async (
        rawJwtToken: string,
        participantResolver: (tenantId: string) => Promise<{ role: string, status: string }>
    ): Promise<ValidatedIdentityContext> => {
        if (!rawJwtToken) throw new Error("Missing JWT Token");

        // 1. Verify JWT
        let claims: SymphonyJWTPayload;
        try {
            const { payload } = await jwtVerify(rawJwtToken, getJWKS(), {
                issuer: JWT_ISSUER,
                audience: JWT_AUDIENCE,
                clockTolerance: CLOCK_TOLERANCE_SECONDS,
                requiredClaims: ['sub', 'iss', 'aud', 'exp', 'iat', 'tenant_id'], // tenant_id required for user
            });
            claims = payload as SymphonyJWTPayload;
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.warn({ error: errorMessage }, 'JWT verification failed (User)');
            throw new Error(`JWT verification failed: ${errorMessage}`);
        }

        if (!claims.tenant_id) {
            throw new Error("JWT missing mandatory 'tenant_id' claim for user");
        }

        // 2. Resolve Participant details
        const details = await participantResolver(claims.tenant_id);

        const now = new Date().toISOString();
        const requestId = crypto.randomUUID();

        // 3. Create 'user' Trust Tier Context
        // Note: Casting roles/status strings to Enums is assumed valid here or handled by resolver
        const context: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: requestId,
            issuedAt: now,
            issuerService: 'ingest-api', // Matches allowlist
            subjectType: 'user',
            subjectId: claims.sub,
            tenantId: claims.tenant_id,
            policyVersion: 'v1.0.0',
            roles: claims.scope ? claims.scope.split(' ') : [],
            trustTier: 'user',
            participantId: claims.tenant_id,
            participantRole: details.role as unknown as ParticipantRole,
            participantStatus: details.status as unknown as ParticipantStatus,
            signature: '',
            // certFingerprint FORBIDDEN
        };

        context.signature = await signEnvelope(context);

        logger.info({
            type: 'IDENTITY_BRIDGE',
            requestId,
            action: 'TERMINATE_JWT_AND_BRIDGE_USER',
            subjectId: context.subjectId,
            participantId: context.participantId,
            trustTier: context.trustTier
        }, "Bridged tenant-anchored user identity");

        return Object.freeze(context);
    },

    /**
     * Assert that a context is safe for internal propagation.
     */
    assertInternalSafety: async (context: ValidatedIdentityContext): Promise<void> => {
        const contextFields = context as Record<string, unknown>;
        if (contextFields.jwt || contextFields.rawToken) {
            throw new Error("CRITICAL: Raw JWT leakage detected in internal context.");
        }

        const expectedSig = await signEnvelope(context);

        // SEC-7R-FIX: Timing-safe comparison
        const sigBuffer = Buffer.from(context.signature, 'hex');
        const expectedBuffer = Buffer.from(expectedSig, 'hex');

        if (sigBuffer.length !== expectedBuffer.length ||
            !crypto.timingSafeEqual(sigBuffer, expectedBuffer)) {
            throw new Error("CRITICAL: Internal identity integrity check failed (Invalid Signature).");
        }
    }
};

// --- Helper Functions (Matching verifyIdentity.ts contract) ---

function normalizeStr(v: string): string {
    return v.trim();
}

function normalizeRoles(roles: string[]): string[] {
    return roles
        .map(r => r.trim())
        .filter(Boolean)
        .sort();
}

/**
 * Build deterministic signed payload matching verifyIdentity.ts
 */
async function signEnvelope(envelope: IdentityEnvelopeV1): Promise<string> {
    const certFingerprint = envelope.subjectType === 'service'
        ? envelope.certFingerprint
        : null;

    const base = {
        certFingerprint: certFingerprint,
        issuedAt: normalizeStr(envelope.issuedAt),
        issuerService: normalizeStr(envelope.issuerService),
        policyVersion: normalizeStr(envelope.policyVersion),
        requestId: normalizeStr(envelope.requestId),
        roles: normalizeRoles(envelope.roles),
        subjectId: normalizeStr(envelope.subjectId),
        subjectType: envelope.subjectType,
        tenantId: normalizeStr(envelope.tenantId),
        trustTier: envelope.trustTier,
        version: envelope.version,
    } as Record<string, unknown>;

    if (envelope.subjectType === 'user') {
        const userEnv = envelope as unknown as UserIdentityEnvelopeV1; // Safe cast inside guard
        base.participantId = normalizeStr(userEnv.participantId);
        base.participantRole = userEnv.participantRole;
        base.participantStatus = userEnv.participantStatus;
    }

    const dataToSign = JSON.stringify(base);

    return crypto.createHmac('sha256', await keyManager.deriveKey('identity/hmac'))
        .update(dataToSign)
        .digest('hex');
}
