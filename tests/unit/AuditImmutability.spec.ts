import { describe, it } from 'node:test';
import assert from 'node:assert';
import { enforceAuditImmutability } from '../../libs/audit/immutability.js';

describe('Audit Immutability Guard', () => {
    it('should allow missing AUDIT_APPEND_ONLY outside protected envs', () => {
        process.env.NODE_ENV = 'development';
        delete process.env.AUDIT_APPEND_ONLY;

        assert.doesNotThrow(() => enforceAuditImmutability());
    });

    it('should require AUDIT_APPEND_ONLY in production', () => {
        process.env.NODE_ENV = 'production';
        delete process.env.AUDIT_APPEND_ONLY;

        assert.throws(
            () => enforceAuditImmutability(),
            /AUDIT_APPEND_ONLY must be enabled/
        );
    });

    it('should pass when AUDIT_APPEND_ONLY is enabled in staging', () => {
        process.env.NODE_ENV = 'staging';
        process.env.AUDIT_APPEND_ONLY = 'true';

        assert.doesNotThrow(() => enforceAuditImmutability());
    });
});
