/**
 * mTLS Guard (Phase 2)
 * Ensures transport credentials are present in protected environments.
 */

const PROTECTED_ENVS = new Set(['production', 'staging']);

export function enforceMtlsConfig(): void {
    const env = process.env.NODE_ENV ?? 'development';
    if (!PROTECTED_ENVS.has(env)) {
        return;
    }

    const required = ['MTLS_SERVICE_KEY', 'MTLS_SERVICE_CERT', 'MTLS_CA_CERT'];
    const missing = required.filter(key => !process.env[key] || process.env[key]?.trim() === '');

    if (missing.length > 0) {
        throw new Error(`Missing required mTLS environment variables: ${missing.join(', ')}`);
    }
}
