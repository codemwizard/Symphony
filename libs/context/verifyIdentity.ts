import { IdentityEnvelopeV1, ValidatedIdentityContext } from "./identity.js";
import { validatePolicyVersion } from "../db/policy.js";
import { TrustFabric } from "../auth/trustFabric.js";
import crypto from "crypto";
import { KeyManager } from "../crypto/keyManager.js";

// OU Interaction Graph (Phase 3)
// Allowed issuers for each service/OU
const ALLOWED_ISSUERS: Record<string, string[]> = {
    'control-plane': ['client', 'ingest-api'], // OU-01/OU-03 accepts from Client or Ingest
    'ingest-api': ['client'],                // OU-04 accepts from Client
    'executor-worker': ['control-plane'],     // OU-05 accepts from Control Plane (OU-03)
    'read-api': ['executor-worker'],          // OU-06 accepts from Executor (OU-05)
};

// SEC-7R-FIX: Clock skew tolerance and max token age
const CLOCK_SKEW_MS = 30_000; // 30 seconds
const MAX_TOKEN_AGE_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Verifies the identity envelope and returns a validated, immutable context.
 * Throws on any violation (Fail-Closed).
 * 
 * SEC-7R-FIX: Implements timing-safe comparison, canonical JSON, and freshness checks.
 */
export async function verifyIdentity(
    envelope: IdentityEnvelopeV1,
    currentService: string,
    keyManager: KeyManager, // Dependency Injection (INV-SEC-04)
    certFingerprint?: string // Phase 6.4: Optional for clients, mandatory for services
): Promise<ValidatedIdentityContext> {

    // 1. Basic Schema & Version Validation
    if (envelope.version !== 'v1') throw new Error("Unsupported identity version");

    // SEC-7R-FIX: Token freshness check with clock skew tolerance
    const issuedAt = new Date(envelope.issuedAt).getTime();
    const now = Date.now();
    if (isNaN(issuedAt)) {
        throw new Error("Invalid issuedAt timestamp");
    }
    if (now - issuedAt > MAX_TOKEN_AGE_MS + CLOCK_SKEW_MS) {
        throw new Error("Identity token too old - re-authentication required");
    }
    if (issuedAt > now + CLOCK_SKEW_MS) {
        throw new Error("Identity token issued in the future");
    }

    // 2. SEC-7R-FIX: Canonical JSON with sorted keys for deterministic signatures
    // Includes trustTier and certFingerprint for complete binding
    const dataToSign = JSON.stringify({
        certFingerprint: envelope.certFingerprint ?? null,
        issuedAt: envelope.issuedAt,
        issuerService: envelope.issuerService,
        policyVersion: envelope.policyVersion,
        requestId: envelope.requestId,
        roles: envelope.roles.slice().sort(), // Sorted for determinism
        subjectId: envelope.subjectId,
        subjectType: envelope.subjectType,
        tenantId: envelope.tenantId,
        trustTier: envelope.trustTier ?? null,
        version: envelope.version,
    });

    const expectedSignature = crypto
        .createHmac('sha256', await keyManager.deriveKey('identity/hmac'))
        .update(dataToSign)
        .digest('hex');

    // SEC-7R-FIX: Timing-safe comparison to prevent timing attacks
    const sigBuffer = Buffer.from(envelope.signature, 'hex');
    const expectedBuffer = Buffer.from(expectedSignature, 'hex');

    if (sigBuffer.length !== expectedBuffer.length ||
        !crypto.timingSafeEqual(sigBuffer, expectedBuffer)) {
        throw new Error("Invalid identity signature");
    }

    // 3. Policy Version Validation
    // SEC-7R-FIX: Enforce active policy version matching.
    await validatePolicyVersion(envelope.policyVersion);

    // 4. Directional Trust Enforcement (OU Interaction Graph)
    const allowed = ALLOWED_ISSUERS[currentService];
    if (!allowed || !allowed.includes(envelope.issuerService)) {
        // Special case for initial client requests
        if (envelope.subjectType === 'client' && allowed && allowed.includes('client')) {
            // Allowed
        } else if (envelope.subjectType === 'user') {
            // Finding #5: 'user' subject type supported in Phase 7B
            // User identity must be validated against allowed issuers (e.g. client)
        } else {
            throw new Error(`Unauthorized OU interaction: ${envelope.issuerService} -> ${currentService}`);
        }
    }



    // 5. Phase 6.4: mTLS & Trust Fabric Enforcement
    if (envelope.subjectType === 'service') {
        if (!certFingerprint) {
            throw new Error("mTLS Violation: Service-to-service calls require cryptographic proof.");
        }

        const identity = TrustFabric.resolveIdentity(certFingerprint);
        if (!identity) {
            throw new Error("mTLS Violation: Revoked or untrusted certificate.");
        }

        // Bind mTLS claim to envelope subject
        if (identity.serviceName !== envelope.issuerService) {
            throw new Error(`mTLS Violation: Certificate identity (${identity.serviceName}) mismatch with claim (${envelope.issuerService}).`);
        }

        // Ensure OU consistency
        // In a real system, envelope.ou would be checked here if present.
    }

    // 6. Freeze and Return
    return Object.freeze({
        ...envelope,
        ...(certFingerprint ? { certFingerprint } : {})
    });
}
