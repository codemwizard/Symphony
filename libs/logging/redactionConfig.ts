/**
 * Centralized Redaction Configuration
 * Defines keys that must be redacted from logs to prevent credential leakage.
 */
export const REDACT_KEYS = [
    // Authentication (Root and Nested)
    'authorization', '*.authorization',
    'token', '*.token',
    'access_token', '*.access_token',
    'refresh_token', '*.refresh_token',
    'id_token', '*.id_token',
    'password', '*.password',
    'secret', '*.secret',
    'client_secret', '*.client_secret',
    'key', '*.key',
    'apiKey', '*.apiKey',
    'api_key', '*.api_key',

    // Financial / PII (Root and Nested)
    'pan', '*.pan',
    'cvv', '*.cvv',
    'credit_card', '*.credit_card',
    'account_number', '*.account_number',
    'ssn', '*.ssn',
    'national_id', '*.national_id',

    // Internal (Root and Nested)
    'jwt', '*.jwt',
    'rawToken', '*.rawToken',
    'signature', '*.signature'
];

export const REDACT_CENSOR = '[REDACTED]';
