/**
 * TrustViolationError
 * Canonical error for Trust Fabric failures with machine-readable codes.
 * SEC-FIX: Enables consistent audit logging and incident response.
 */

export type TrustViolationCode =
    | 'TRUST_CERT_UNKNOWN'
    | 'TRUST_CERT_REVOKED'
    | 'TRUST_CERT_EXPIRED'
    | 'TRUST_PARTICIPANT_INACTIVE'
    | 'TRUST_ENV_MISMATCH';

export class TrustViolationError extends Error {
    readonly code: TrustViolationCode;
    readonly fingerprint: string;
    readonly statusCode: number = 403;

    constructor(code: TrustViolationCode, fingerprint: string, message?: string) {
        super(message || `Trust violation: ${code} for fingerprint ${fingerprint}`);
        this.name = 'TrustViolationError';
        this.code = code;
        this.fingerprint = fingerprint;
        Object.setPrototypeOf(this, TrustViolationError.prototype);
    }
}
