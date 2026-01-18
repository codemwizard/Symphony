import { IdentityEnvelopeV1, ValidatedIdentityContext } from "./identity.js";
import { validatePolicyVersion } from "../db/policy.js";
import { TrustFabric } from "../auth/trustFabric.js";
import crypto from "crypto";
import { KeyManager } from "../crypto/keyManager.js";

// OU Interaction Graph (Phase 3)
// Allowed issuers for each service/OU (service-to-service directional trust)
const ALLOWED_ISSUERS: Record<string, string[]> = {
    "control-plane": ["client", "ingest-api"],
    "ingest-api": ["client", "ingest-api"],
    "executor-worker": ["control-plane"],
    "read-api": ["executor-worker"],
};

// IDENTITY-7B: user is only valid at ingest boundary and is wrapped by ingest-api.
const USER_ENTRYPOINT_SERVICES = new Set(["ingest-api"]);
const USER_ALLOWED_ISSUERS = new Set(["ingest-api"]); // issuerService on the envelope

// SEC-7R-FIX: Clock skew tolerance and max token age
const CLOCK_SKEW_MS = 30_000; // 30 seconds
const MAX_TOKEN_AGE_MS = 5 * 60 * 1000; // 5 minutes

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
 * Build deterministic signed payload.
 * IDENTITY-7B: user participant fields are cryptographically bound.
 */
function buildDataToSign(envelope: IdentityEnvelopeV1): string {
    // Explicit null canonicalization for stability
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
    };

    if (envelope.subjectType === "user") {
        return JSON.stringify({
            ...base,
            participantId: normalizeStr(envelope.participantId),
            participantRole: envelope.participantRole,
            participantStatus: envelope.participantStatus,
        });
    }

    return JSON.stringify(base);
}

/**
 * Verifies the identity envelope and returns a validated, immutable context.
 * Throws on any violation (Fail-Closed).
 *
 * IDENTITY-7B:
 * - Users only permitted at ingest-api
 * - User issuer allowlist
 * - trustTier='user' required for user
 * - user must not present mTLS proof
 * - user must be tenant-anchored (participantId required)
 * - participant fields are included in signature payload
 *
 * SEC-7R-FIX:
 * - timing-safe HMAC comparison
 * - freshness checks with skew tolerance
 */
export async function verifyIdentity(
    envelope: IdentityEnvelopeV1,
    currentService: string,
    keyManager: KeyManager,
    certFingerprint?: string
): Promise<ValidatedIdentityContext> {
    // 1) Basic Schema & Version Validation
    if (envelope.version !== "v1") throw new Error("Unsupported identity version");

    // 2) Freshness check
    const issuedAtMs = new Date(envelope.issuedAt).getTime();
    const now = Date.now();
    if (Number.isNaN(issuedAtMs)) throw new Error("Invalid issuedAt timestamp");
    if (now - issuedAtMs > MAX_TOKEN_AGE_MS + CLOCK_SKEW_MS) {
        throw new Error("Identity token too old - re-authentication required");
    }
    if (issuedAtMs > now + CLOCK_SKEW_MS) {
        throw new Error("Identity token issued in the future");
    }

    // 3) IDENTITY-7B: User boundary enforcement (pre-HMAC: cheap fail-fast)
    if (envelope.subjectType === "user") {
        // Boundary: users only at ingest-api
        if (!USER_ENTRYPOINT_SERVICES.has(currentService)) {
            throw new Error(`User identity not permitted at ${currentService}`);
        }

        // Issuer allowlist: user envelopes are produced by ingest-api after JWT verification
        if (!USER_ALLOWED_ISSUERS.has(envelope.issuerService)) {
            throw new Error(`Invalid user issuer: ${envelope.issuerService}`);
        }

        // Trust tier: MUST be 'user'
        if ((envelope as Record<string, unknown>).trustTier !== "user") {
            throw new Error(
                `User identity requires trustTier='user', got '${(envelope as Record<string, unknown>).trustTier}'`
            );
        }

        // mTLS rejection: check BOTH param and envelope field
        // envelope check is handled by union type (property doesn't exist)
        // verifyIdentity param check:
        if (certFingerprint) {
            throw new Error("User identity must not present mTLS proof");
        }

        // Runtime check for envelope field leakage (though TS forbids it)
        if ('certFingerprint' in envelope && (envelope as Record<string, unknown>).certFingerprint) {
            throw new Error("User identity must not present mTLS proof (envelope field)");
        }

        // Tenant anchor required
        if (!envelope.participantId?.trim()) {
            throw new Error("User identity missing mandatory participantId anchor");
        }
    }

    // 4) Service mTLS binding (fail-closed, explicit)
    if (envelope.subjectType === "service") {
        // Both must exist
        if (!certFingerprint) {
            throw new Error("mTLS Violation: Service-to-service calls require cryptographic proof.");
        }
        if (!envelope.certFingerprint) {
            throw new Error("mTLS Violation: Service envelope missing certFingerprint binding.");
        }

        // Must match
        if (envelope.certFingerprint !== certFingerprint) {
            throw new Error("mTLS Violation: certFingerprint mismatch between transport and envelope.");
        }
    }

    // 5) HMAC signature verification (now includes participant fields for user)
    const dataToSign = buildDataToSign(envelope);

    const expectedSignature = crypto
        .createHmac("sha256", await keyManager.deriveKey("identity/hmac"))
        .update(dataToSign)
        .digest("hex");

    const sigBuffer = Buffer.from(envelope.signature, "hex");
    const expectedBuffer = Buffer.from(expectedSignature, "hex");

    if (
        sigBuffer.length !== expectedBuffer.length ||
        !crypto.timingSafeEqual(sigBuffer, expectedBuffer)
    ) {
        throw new Error("Invalid identity signature");
    }

    // 6) Policy Version Validation (DB access)
    await validatePolicyVersion(envelope.policyVersion);

    // 7) Directional Trust Enforcement (OU interaction graph)
    // - Users cannot appear here except at ingest-api (already enforced above)
    const allowed = ALLOWED_ISSUERS[currentService];
    if (!allowed || !allowed.includes(envelope.issuerService)) {
        // Special case for initial client requests
        if (envelope.subjectType === "client" && allowed && allowed.includes("client")) {
            // allowed
        } else if (envelope.subjectType === "user") {
            // user already gated above; if we reached here, it's an OU config mismatch
            throw new Error(`User identity OU policy mismatch at ${currentService}`);
        } else {
            throw new Error(
                `Unauthorized OU interaction: ${envelope.issuerService} -> ${currentService}`
            );
        }
    }

    // 8) TrustFabric enforcement for services (certificate trust + serviceName binding)
    // SEC-FIX: TrustFabric.resolveIdentity is now async and throws on failure
    if (envelope.subjectType === "service") {
        const identity = await TrustFabric.resolveIdentity(certFingerprint!);
        // TrustFabric throws TrustViolationError if revoked/expired/inactive/unknown

        if (identity.serviceName !== envelope.issuerService) {
            throw new Error(
                `mTLS Violation: Certificate identity (${identity.serviceName}) mismatch with claim (${envelope.issuerService}).`
            );
        }
    }

    // 9) Freeze and return
    return Object.freeze({
        ...envelope,
        ...(certFingerprint ? { certFingerprint } : {})
    });
}
