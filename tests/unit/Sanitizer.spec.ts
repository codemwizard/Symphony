/**
 * Unit Tests: ErrorSanitizer
 * 
 * Tests error wrapping and information disclosure prevention.
 * 
 * @see libs/errors/sanitizer.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';

// Dynamic import after env setup
let SymphonyError: typeof import('../../libs/errors/sanitizer.js').SymphonyError;
let ErrorSanitizer: typeof import('../../libs/errors/sanitizer.js').ErrorSanitizer;

describe('ErrorSanitizer', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        // Set dummy env vars for db guards
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test';

        const module = await import('../../libs/errors/sanitizer.js');
        SymphonyError = module.SymphonyError;
        ErrorSanitizer = module.ErrorSanitizer;
    });

    after(() => {
        process.env = originalEnv;
    });

    it('should create SymphonyError with incidentId', () => {
        const error = new SymphonyError('Test error', { secret: 'hidden' }, 'SEC');

        assert.ok(error.incidentId, 'Should have incidentId');
        assert.ok(error.incidentId.length > 0, 'incidentId should not be empty');
        assert.strictEqual(error.publicMessage, 'Test error');
        assert.strictEqual(error.category, 'SEC');
    });

    it('should sanitize raw errors into SymphonyError', () => {
        const rawError = new Error('Database connection failed: password=secret123');
        const sanitized = ErrorSanitizer.sanitize(rawError, 'db-op');

        assert.ok(sanitized instanceof SymphonyError, 'Should be SymphonyError');
        assert.ok(!sanitized.publicMessage.includes('password'), 'Should not expose raw error');
        assert.ok(!sanitized.publicMessage.includes('secret123'), 'Should not expose credentials');
        assert.ok(sanitized.incidentId, 'Should have incidentId for tracking');
    });

    it('should pass through existing SymphonyError unchanged', () => {
        const original = new SymphonyError('Original', { data: 'test' }, 'OPS');
        const result = ErrorSanitizer.sanitize(original, 'test-context');

        assert.strictEqual(result, original, 'Should return same instance');
        assert.strictEqual(result.incidentId, original.incidentId);
    });
});
