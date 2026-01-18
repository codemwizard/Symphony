import { describe, it } from 'node:test';
import assert from 'node:assert';
import { enforceMtlsConfig } from '../../libs/bootstrap/mtls-guard.js';

describe('mTLS Guard', () => {
    it('should allow missing variables outside protected envs', () => {
        process.env.NODE_ENV = 'development';
        delete process.env.MTLS_SERVICE_KEY;
        delete process.env.MTLS_SERVICE_CERT;
        delete process.env.MTLS_CA_CERT;

        assert.doesNotThrow(() => enforceMtlsConfig());
    });

    it('should require mTLS variables in production', () => {
        process.env.NODE_ENV = 'production';
        delete process.env.MTLS_SERVICE_KEY;
        delete process.env.MTLS_SERVICE_CERT;
        delete process.env.MTLS_CA_CERT;

        assert.throws(
            () => enforceMtlsConfig(),
            /Missing required mTLS environment variables/
        );
    });

    it('should pass when mTLS variables are set in staging', () => {
        process.env.NODE_ENV = 'staging';
        process.env.MTLS_SERVICE_KEY = 'key';
        process.env.MTLS_SERVICE_CERT = 'cert';
        process.env.MTLS_CA_CERT = 'ca';

        assert.doesNotThrow(() => enforceMtlsConfig());
    });
});
