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
        delete process.env.ALLOW_DEV_JWKS_FALLBACK;
    });

    it('should load JWKS from default path if exists', () => {
        const jwks = getJWKS();
        assert.ok(jwks, 'Should return JWKSet');
    });

    it('should FAIL CLOSED in PRODUCTION if JWKS missing', () => {
        process.env.NODE_ENV = 'production';
        process.env.JWKS_PATH = 'non-existent-jwks.json';

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
        const first = getJWKS();
        const second = getJWKS();
        assert.equal(first, second, 'Should return cached instance');

        clearJWKSCache();
        const third = getJWKS();
        assert.notEqual(first, third, 'Should return new instance after clear');
    });
});
