/**
 * Unit Tests: Policy Validation
 * 
 * Tests policy version validation logic.
 * 
 * @see libs/db/policy.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';

// Dynamic import after env setup
let validatePolicyVersion: typeof import('../../libs/db/policy.js').validatePolicyVersion;

describe('validatePolicyVersion', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        // Set dummy env vars for db guards
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test';

        const module = await import('../../libs/db/policy.js');
        validatePolicyVersion = module.validatePolicyVersion;
    });

    after(() => {
        process.env = originalEnv;
    });

    it('should accept matching policy version', async () => {
        // Assumes active-policy.json has policy_version: "v1.0.0"
        await assert.doesNotReject(
            async () => validatePolicyVersion('v1.0.0'),
            'Should accept valid policy version'
        );
    });

    it('should reject mismatched policy version', async () => {
        await assert.rejects(
            async () => validatePolicyVersion('v0.9.0'),
            { message: /Policy version mismatch/ },
            'Should reject outdated version'
        );
    });

    it('should reject invalid policy version format', async () => {
        await assert.rejects(
            async () => validatePolicyVersion('invalid'),
            { message: /Policy version mismatch/ },
            'Should reject invalid version'
        );
    });
});
