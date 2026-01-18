import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import path from 'path';
import fs from 'fs';
import { clearJWKSCache, getJWKS } from '../../libs/crypto/jwks.js';

const TEST_JWKS_PATH = path.join('tests', 'unit', 'fixtures', 'jwks-loader.json');

describe('JWKS Loader (Security Hardened)', () => {
    beforeEach(() => {
        clearJWKSCache();
        delete process.env.JWKS_PATH;
        delete process.env.ALLOW_DEV_JWKS_FALLBACK;
        delete process.env.NODE_ENV;
        if (fs.existsSync(TEST_JWKS_PATH)) {
            fs.unlinkSync(TEST_JWKS_PATH);
        }
    });

    afterEach(() => {
        clearJWKSCache();
        delete process.env.JWKS_PATH;
        delete process.env.ALLOW_DEV_JWKS_FALLBACK;
        delete process.env.NODE_ENV;
        if (fs.existsSync(TEST_JWKS_PATH)) {
            fs.unlinkSync(TEST_JWKS_PATH);
        }
    });

    it('should FAIL CLOSED in PRODUCTION if JWKS missing', () => {
        process.env.NODE_ENV = 'production';
        process.env.JWKS_PATH = 'non-existent-jwks.json';
        clearJWKSCache();

        assert.throws(
            () => getJWKS(),
            /CRITICAL: JWKS file missing/
        );
    });

    it('should require explicit dev fallback flag when JWKS missing', () => {
        process.env.NODE_ENV = 'development';
        process.env.JWKS_PATH = 'non-existent-jwks.json';
        clearJWKSCache();

        assert.throws(
            () => getJWKS(),
            /CRITICAL: JWKS file missing/
        );
    });

    it('should use fallback in DEVELOPMENT when explicitly allowed', () => {
        process.env.NODE_ENV = 'development';
        process.env.JWKS_PATH = 'non-existent-jwks.json';
        process.env.ALLOW_DEV_JWKS_FALLBACK = 'true';
        clearJWKSCache();

        assert.doesNotThrow(() => getJWKS());
    });

    it('should REJECT path traversal via JWKS_PATH', () => {
        process.env.NODE_ENV = 'development';
        process.env.JWKS_PATH = path.join('..', '..', 'etc', 'passwd');
        clearJWKSCache();

        assert.throws(
            () => getJWKS(),
            /Security Violation: JWKS_PATH/
        );
    });
});
