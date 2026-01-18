/**
 * ConfigGuard Tests
 * Tests for CRIT-SEC-002 fix: Environment variable enforcement
 * 
 * Run with: node --test tests/configGuard.test.js
 */

import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import { ConfigGuard } from '../libs/bootstrap/config-guard.js';
import { DB_CONFIG_GUARDS } from '../libs/bootstrap/config/db-config.js';
import { DEV_CRYPTO_GUARDS, PROD_CRYPTO_GUARDS } from '../libs/bootstrap/config/crypto-config.js';

// Store original env
const originalEnv = { ...process.env };

describe('ConfigGuard Module', () => {
    beforeEach(() => {
        process.env = { ...originalEnv };
    });

    afterEach(() => {
        process.env = { ...originalEnv };
    });

    describe('Module Exports', () => {
        it('should have ConfigGuard class', () => {
            assert.ok(ConfigGuard, 'ConfigGuard should be exported');
            assert.strictEqual(typeof ConfigGuard.enforce, 'function', 'ConfigGuard.enforce should be a function');
        });

        it('should have DB_CONFIG_GUARDS', () => {
            assert.ok(Array.isArray(DB_CONFIG_GUARDS), 'DB_CONFIG_GUARDS should be an array');
            assert.ok(DB_CONFIG_GUARDS.length > 0, 'DB_CONFIG_GUARDS should not be empty');
        });

        it('should have CRYPTO_GUARDS', () => {
            assert.ok(Array.isArray(DEV_CRYPTO_GUARDS), 'DEV_CRYPTO_GUARDS should be an array');
            assert.ok(Array.isArray(PROD_CRYPTO_GUARDS), 'PROD_CRYPTO_GUARDS should be an array');
        });
    });

    describe('DB_CONFIG_GUARDS', () => {
        it('should include all required database config keys', () => {
            const requiredKeys = ['DB_HOST', 'DB_PORT', 'DB_USER', 'DB_PASSWORD', 'DB_NAME'];

            for (const key of requiredKeys) {
                const found = DB_CONFIG_GUARDS.find(req => req.name === key);
                assert.ok(found, `DB_CONFIG_GUARDS should include ${key}`);
            }
        });

        it('should mark DB_PASSWORD as sensitive', () => {
            const passwordReq = DB_CONFIG_GUARDS.find(req => req.name === 'DB_PASSWORD');
            assert.ok(passwordReq, 'DB_PASSWORD should be in requirements');
            assert.strictEqual(passwordReq.sensitive, true, 'DB_PASSWORD should be marked as sensitive');
        });
    });

    describe('PROD_CRYPTO_GUARDS', () => {
        it('should include required KMS config keys', () => {
            // SEC-FIX: Standardized on KMS_KEY_REF
            const requiredKeys = ['KMS_ENDPOINT', 'KMS_REGION', 'KMS_KEY_REF'];

            for (const key of requiredKeys) {
                const found = PROD_CRYPTO_GUARDS.find(req => req.name === key);
                assert.ok(found, `PROD_CRYPTO_GUARDS should include ${key}`);
            }
        });
    });
});
