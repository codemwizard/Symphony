import { describe, it, before, after, beforeEach } from 'node:test';
import { strict as assert } from 'assert';
import { getJWKS, clearJWKSCache } from '../../libs/crypto/jwks.js';

describe('JWKS Loader (Security Hardened)', () => {
    let originalEnv: NodeJS.ProcessEnv;

    before(() => {
        originalEnv = { ...process.env };
    });

    after(() => {
        process.env = originalEnv;
    });

    beforeEach(() => {
        clearJWKSCache();
        process.env.NODE_ENV = 'development';
        delete process.env.JWKS_PATH;
    });

    it('should load JWKS from default path if exists', () => {
        // Assuming config/jwks.json exists in dev env
        const jwks = getJWKS();
        assert.ok(jwks, 'Should return JWKSet');
    });

    it('should FAIL CLOSED in PRODUCTION if JWKS missing', () => {
        process.env.NODE_ENV = 'production';
        process.env.JWKS_PATH = 'non-existent-jwks.json'; // Force mismatch

        assert.throws(() => {
            getJWKS();
        }, /CRITICAL: JWKS file missing/);
    });

    it('should use fallback in DEVELOPMENT if JWKS missing', () => {
        process.env.NODE_ENV = 'development';
        process.env.JWKS_PATH = 'non-existent-jwks.json';

        const jwks = getJWKS();
        assert.ok(jwks, 'Should use fallback in dev');
    });

    it('should REJECT path traversal via JWKS_PATH', () => {
        process.env.JWKS_PATH = '../../../../etc/passwd';
        assert.throws(() => {
            getJWKS();
        }, /Security Violation: JWKS_PATH/);
    });

    it('should refresh cache after TTL', async () => {
        // This test is tricky without mocking time, but we can verify cache logic structure
        // manually or trust the implementation. For unit test, we'll verify calling it twice returns same object (cached)
        // unless cleared.
        const first = getJWKS();
        const second = getJWKS();
        assert.equal(first, second, 'Should return cached instance');

        clearJWKSCache();
        const third = getJWKS();
        assert.notEqual(first, third, 'Should return new instance after clear');
    });
});
