import { describe, it } from 'node:test';
import assert from 'node:assert';
import { IdentityEnvelopeV1Schema } from '../../libs/validation/identitySchema.js';
import { UserIdentityEnvelopeV1 } from '../../libs/context/identity.js';

describe('Identity Schema Validation (Strict)', () => {

    it('should ACCEPT a valid user envelope with trustTier: "user"', () => {
        const envelope: UserIdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-1',
            issuedAt: new Date().toISOString(),
            issuerService: 'ingest-api',
            subjectType: 'user',
            subjectId: 'user-123',
            tenantId: 'tenant-A',
            policyVersion: 'v1.0.0',
            roles: ['user'],
            signature: 'a'.repeat(64),
            trustTier: 'user', // This is what failed before
            participantId: 'tenant-A',
            participantRole: 'OPERATOR',
            participantStatus: 'ACTIVE'
        };

        const result = IdentityEnvelopeV1Schema.safeParse(envelope);
        assert.ok(result.success, `Schema validation failed: ${!result.success && result.error}`);
    });

    it('should REJECT a user envelope with trustTier: "external"', () => {
        const envelope = {
            version: 'v1',
            requestId: 'req-2',
            issuedAt: new Date().toISOString(),
            issuerService: 'ingest-api',
            subjectType: 'user',
            subjectId: 'user-123',
            tenantId: 'tenant-A',
            policyVersion: 'v1.0.0',
            roles: ['user'],
            signature: 'a'.repeat(64),
            trustTier: 'external', // INVALID for user
            participantId: 'tenant-A',
            participantRole: 'OPERATOR',
            participantStatus: 'ACTIVE'
        };

        const result = IdentityEnvelopeV1Schema.safeParse(envelope);
        assert.strictEqual(result.success, false);
        // Zod discriminated union error might be generic or specific depending on implementation
        assert.ok(result.success === false);
    });

    it('should REJECT a service envelope without certFingerprint', () => {
        const envelope = {
            version: 'v1',
            requestId: 'req-3',
            issuedAt: new Date().toISOString(),
            issuerService: 'control-plane',
            subjectType: 'service',
            subjectId: 'svc-1',
            tenantId: 'system',
            policyVersion: 'v1.0.0',
            roles: ['service'],
            signature: 'a'.repeat(64),
            trustTier: 'internal',
            // Missing certFingerprint
        };

        const result = IdentityEnvelopeV1Schema.safeParse(envelope);
        assert.strictEqual(result.success, false);
    });
});
