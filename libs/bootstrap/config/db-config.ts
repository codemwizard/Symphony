import { GuardRule } from '../config-guard.js';

/**
 * DB Configuration Guards
 * Enforces strict presence of database connection parameters.
 * No assertions or defaults allowed inline.
 */
export const DB_CONFIG_GUARDS: GuardRule[] = [
    { type: 'required', name: 'DB_HOST' },
    { type: 'required', name: 'DB_PORT' },
    { type: 'required', name: 'DB_USER' },
    { type: 'required', name: 'DB_PASSWORD', sensitive: true },
    { type: 'required', name: 'DB_NAME' },

    {
        type: 'assert',
        check: () => process.env.NODE_ENV !== 'production' || !!process.env.DB_HOST,
        message: 'DB_HOST must be explicitly set in production (no fallbacks)',
    },

    // SEC-FIX: Guard-level TLS enforcement (fail-closed)
    {
        type: 'assert',
        check: () =>
            !['production', 'staging'].includes(process.env.NODE_ENV ?? '') ||
            !!process.env.DB_CA_CERT,
        message: 'DB_CA_CERT is required in production/staging',
    }
];
