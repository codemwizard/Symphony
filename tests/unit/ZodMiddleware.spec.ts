/**
 * Unit Tests: Zod Middleware
 * 
 * Tests input validation middleware.
 * 
 * @see libs/validation/zod-middleware.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { z } from 'zod';

// Dynamic import after env setup
let validate: typeof import('../../libs/validation/zod-middleware.js').validate;
let createValidator: typeof import('../../libs/validation/zod-middleware.js').createValidator;

describe('Zod Middleware', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        // Set dummy env vars for db guards
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test';

        const module = await import('../../libs/validation/zod-middleware.js');
        validate = module.validate;
        createValidator = module.createValidator;
    });

    after(() => {
        process.env = originalEnv;
    });

    const TestSchema = z.object({
        id: z.string().uuid(),
        amount: z.number().positive(),
        currency: z.enum(['USD', 'EUR', 'GBP'])
    });

    it('should validate correct input', () => {
        const input = {
            id: '550e8400-e29b-41d4-a716-446655440000',
            amount: 100.50,
            currency: 'USD'
        };

        const result = validate(TestSchema, input, 'test-context');
        assert.deepStrictEqual(result, input);
    });

    it('should reject invalid input with detailed error', () => {
        const invalidInput = {
            id: 'not-a-uuid',
            amount: -50,
            currency: 'INVALID'
        };

        assert.throws(
            () => validate(TestSchema, invalidInput, 'test-context'),
            (err: Error) => {
                assert.ok(err.message.includes('Validation Violation'), 'Should mention validation');
                assert.ok(err.message.includes('test-context'), 'Should include context');
                return true;
            }
        );
    });

    it('should reject missing required fields', () => {
        const partialInput = { id: '550e8400-e29b-41d4-a716-446655440000' };

        assert.throws(
            () => validate(TestSchema, partialInput, 'partial-test'),
            /Validation Violation/
        );
    });

    it('should create reusable validator factory', () => {
        const validateTest = createValidator(TestSchema);

        const valid = validateTest({
            id: '550e8400-e29b-41d4-a716-446655440000',
            amount: 200,
            currency: 'EUR'
        }, 'factory-test');

        assert.strictEqual(valid.currency, 'EUR');
    });
});
