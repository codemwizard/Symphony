import { GuardRule } from '../config-guard.js';

/**
 * Crypto Configuration Guards
 * Enforces cryptographic discipline for development environments.
 */
export const DEV_CRYPTO_GUARDS: GuardRule[] = [
    { type: 'required', name: 'DEV_ROOT_KEY', sensitive: true },

    {
        type: 'forbidIf',
        name: 'DevelopmentKeyManager',
        when: () => process.env.NODE_ENV === 'production',
        message: 'DevelopmentKeyManager must never load in production. INV-SEC-04 Violation.',
    },
];

/**
 * Production Crypto Config Guards (KMS)
 */
export const PROD_CRYPTO_GUARDS: GuardRule[] = [
    { type: 'required', name: 'KMS_ENDPOINT' },
    { type: 'required', name: 'KMS_REGION' },
    { type: 'required', name: 'KMS_KEY_ID' },
    // Credentials might be implicit in IAM roles, but if explicit mode is used:
    // We enforce them if they seem to be required by the specific deployment model.
    // For now, mirroring strictness:
    { type: 'assert', check: () => !!process.env.KMS_ACCESS_KEY_ID || !!process.env.AWS_ROLE_ARN || !!process.env.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI, message: "KMS Credentials or Role required" }
];
