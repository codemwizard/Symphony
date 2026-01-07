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
    { type: 'required', name: 'DB_CA_CERT', sensitive: true },

    {
        type: 'assert',
        check: () => process.env.NODE_ENV !== 'production' || !!process.env.DB_HOST,
        message: 'DB_HOST must be explicitly set in production (no fallbacks)',
    }
];
