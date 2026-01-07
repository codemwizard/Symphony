import { IdentityEnvelopeV1, ValidatedIdentityContext } from "./identity.js";
import { checkPolicyVersion } from "../db/policy.js";
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

/**
 * Verifies the identity envelope and returns a validated, immutable context.
 * Throws on any violation (Fail-Closed).
 */
export async function verifyIdentity(
    envelope: IdentityEnvelopeV1,
    currentService: string,
    keyManager: KeyManager, // Dependency Injection (INV-SEC-04)
    certFingerprint?: string // Phase 6.4: Optional for clients, mandatory for services
): Promise<ValidatedIdentityContext> {

    // 1. Basic Schema & Version Validation
    if (envelope.version !== 'v1') throw new Error("Unsupported identity version");

    // 2. signature Validation (HMAC-sha256)
    const dataToSign = JSON.stringify({
        version: envelope.version,
        requestId: envelope.requestId,
        issuedAt: envelope.issuedAt,
        issuerService: envelope.issuerService,
        subjectType: envelope.subjectType,
        subjectId: envelope.subjectId,
        tenantId: envelope.tenantId,
        policyVersion: envelope.policyVersion,
        roles: envelope.roles,
    });

    const expectedSignature = crypto
        .createHmac('sha256', await keyManager.deriveKey('identity/hmac'))
        .update(dataToSign)
        .digest('hex');

    if (envelope.signature !== expectedSignature) {
        throw new Error("Invalid identity signature");
    }

    // 3. Policy Version Validation
    // Implementation note: In a real system, we'd pass the DB client here.
    // For Phase 6.2, we assume the shared lib's checkPolicyVersion logic.
    // We'll simulate the check against the envelope's policyVersion.
    // (In Step 3 integration, we'll call the real checkPolicyVersion)

    // 4. Directional Trust Enforcement (OU Interaction Graph)
    const allowed = ALLOWED_ISSUERS[currentService];
    if (!allowed || !allowed.includes(envelope.issuerService)) {
        // Special case for initial client requests
        if (envelope.subjectType === 'client' && allowed.includes('client')) {
            // Allowed
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
    return Object.freeze({ ...envelope, certFingerprint });
}
