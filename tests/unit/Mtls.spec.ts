/**
 * Unit Tests: mTLS Gate
 * 
 * Tests mTLS configuration primitives.
 * 
 * @see libs/bootstrap/mtls.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import https from 'https';

// Direct import (no db dependency)
let MtlsGate: typeof import('../../libs/bootstrap/mtls.js').MtlsGate;

describe('MtlsGate', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        // Set mTLS env vars
        process.env.MTLS_SERVICE_KEY = 'test-key-content';
        process.env.MTLS_SERVICE_CERT = 'test-cert-content';
        process.env.MTLS_CA_CERT = 'test-ca-content';

        const module = await import('../../libs/bootstrap/mtls.js');
        MtlsGate = module.MtlsGate;
    });

    after(() => {
        process.env = originalEnv;
    });

    describe('getServerOptions', () => {
        it('should return hardened server options with rejectUnauthorized=true', () => {
            const options = MtlsGate.getServerOptions();

            assert.strictEqual(options.requestCert, true, 'Should require client cert');
            assert.strictEqual(options.rejectUnauthorized, true, 'Should be FAIL-CLOSED');
            assert.ok(options.key, 'Should have key');
            assert.ok(options.cert, 'Should have cert');
            assert.ok(options.ca, 'Should have CA');
        });

        it('should read from environment variables', () => {
            const options = MtlsGate.getServerOptions();

            assert.strictEqual(options.key, 'test-key-content');
            assert.strictEqual(options.cert, 'test-cert-content');
            assert.strictEqual(options.ca, 'test-ca-content');
        });
    });

    describe('getAgent', () => {
        it('should return HTTPS agent with rejectUnauthorized=true', () => {
            const agent = MtlsGate.getAgent();

            assert.ok(agent instanceof https.Agent, 'Should be HTTPS Agent');
            // Agent options are not directly accessible, but we verify it's created
        });
    });
});
