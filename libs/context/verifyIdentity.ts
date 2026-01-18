import { IdentityEnvelopeV1, ValidatedIdentityContext } from "./identity.js";
import { IdentityEnvelopeV1Schema } from "../validation/identitySchema.js";
import { validatePolicyVersion } from "../db/policy.js";
import { TrustFabric } from "../auth/trustFabric.js";
import crypto from "crypto";
import { KeyManager } from "../crypto/keyManager.js";
import { LRUCache } from "lru-cache";

// OU Interaction Graph (Phase 3)
// Allowed issuers for each service/OU (service-to-service directional trust)
// DEFAULT DENY: Any service not listed here accepts NO issuers by default.
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

// SEC-FIX: Replay Protection (In-Memory LRU)
// Stores requestId for the duration of its validity window
const replayCache = new LRUCache<string, boolean>({
    max: 10000,
    ttl: MAX_TOKEN_AGE_MS + CLOCK_SKEW_MS
});

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
 * VALIDATION ORDER (SECURITY CRITICAL):
 * 1. Schema & Type Safety (Fail-Fast)
 * 2. Freshness & Replay (Fail-Fast)
 * 3. OU & Policy Authorization (Pre-Computation)
 * 4. mTLS Binding (Transport check)
 * 5. HMAC Signature (Computationally Expensive - LAST)
 * 6. Business Logic (Policy Version, TrustFabric) (Post-Auth)
 */
export async function verifyIdentity(
    envelope: IdentityEnvelopeV1,
    currentService: string,
    keyManager: KeyManager,
    certFingerprint?: string
): Promise<ValidatedIdentityContext> {
    // 1) Schema Validation (Strict Entry Gate)
    // Ensures trustTier checks and discriminated unions are respected before any logic runs.
    try {
        IdentityEnvelopeV1Schema.parse(envelope);
    } catch (error) {
        throw new Error(`Identity Schema Violation: ${error instanceof Error ? error.message : String(error)}`);
    }

    if (envelope.version !== "v1") throw new Error("Unsupported identity version");

    // 2) Freshness check & Replay Protection
    const issuedAtMs = new Date(envelope.issuedAt).getTime();
    const now = Date.now();
    if (Number.isNaN(issuedAtMs)) throw new Error("Invalid issuedAt timestamp");

    // Check age
    if (now - issuedAtMs > MAX_TOKEN_AGE_MS + CLOCK_SKEW_MS) {
        throw new Error("Identity token too old - re-authentication required");
    }
    if (issuedAtMs > now + CLOCK_SKEW_MS) {
        throw new Error("Identity token issued in the future");
    }

    // Check Replay
    if (replayCache.has(envelope.requestId)) {
        throw new Error(`Replay detected: requestId ${envelope.requestId} already processed`);
    }
    replayCache.set(envelope.requestId, true);

    // 3) OU Interaction & Boundary Check (BEFORE Signature)
    // Prevents Oracle attacks by validating expected topology first.

    // A) User Boundary Enforcement
    if (envelope.subjectType === "user") {
        // Boundary: users only at ingest-api
        if (!USER_ENTRYPOINT_SERVICES.has(currentService)) {
            throw new Error(`User identity not permitted at ${currentService}`);
        }

        // Issuer allowlist: user envelopes are produced by ingest-api
        if (!USER_ALLOWED_ISSUERS.has(envelope.issuerService)) {
            throw new Error(`Invalid user issuer: ${envelope.issuerService}`);
        }

        // Trust tier: MUST be 'user' (Redundant with Schema, but defensive depth)
        if (envelope.trustTier !== "user") {
            // Should never happen if schema passes
            throw new Error(`Invariant Violation: User identity has non-user trustTier`);
        }

        // mTLS rejection (Param check)
        if (certFingerprint) {
            throw new Error("User identity must not present mTLS proof");
        }

        // Tenant anchor required
        if (!envelope.participantId?.trim()) {
            throw new Error("User identity missing mandatory participantId anchor");
        }
    }

    // B) Service/OU Allowlist (Default Deny)
    const allowed = ALLOWED_ISSUERS[currentService];
    if (!allowed) {
        throw new Error(`Configuration Error: ${currentService} has no allowed issuers defined (Default Deny).`);
    }

    if (!allowed.includes(envelope.issuerService)) {
        // Special case for initial client requests
        const isClientAllowed = envelope.subjectType === "client" && allowed.includes("client");

        if (!isClientAllowed) {
            // Generic error message for external callers, log detail for audit
            throw new Error(`Unauthorized OU interaction: Issuer not allowed at ${currentService}`);
        }
    }

    // 4) Service mTLS binding (Fail-Closed)
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

    // 5) HMAC Signature Verification (The Heavy Lift)
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

    // 6) Post-Auth Policy & TrustFabric Check
    await validatePolicyVersion(envelope.policyVersion);

    if (envelope.subjectType === "service") {
        const identity = await TrustFabric.resolveIdentity(certFingerprint!);

        if (identity.serviceName !== envelope.issuerService) {
            throw new Error(
                `mTLS Violation: Certificate identity (${identity.serviceName}) mismatch with claim (${envelope.issuerService}).`
            );
        }
    }

    // 7) Freeze and return
    return Object.freeze({
        ...envelope,
        ...(certFingerprint ? { certFingerprint } : {})
    });
}
