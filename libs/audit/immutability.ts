/**
 * Audit Immutability Guard (Phase 2)
 * Enforces append-only audit posture in protected environments.
 */

const PROTECTED_ENVS = new Set(['production', 'staging']);

export function enforceAuditImmutability(): void {
    const env = process.env.NODE_ENV ?? 'development';
    if (!PROTECTED_ENVS.has(env)) {
        return;
    }

    if (process.env.AUDIT_APPEND_ONLY !== 'true') {
        throw new Error('AUDIT_APPEND_ONLY must be enabled in production/staging');
    }
}
