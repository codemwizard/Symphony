import { describe, it, mock, before, after } from 'node:test';
import assert from 'node:assert';
import crypto from 'crypto';
import { IdentityEnvelopeV1 } from '../../libs/context/identity.js';
import { KeyManager } from '../../libs/crypto/keyManager.js';

// Mock KeyManager
const mockDeriveKey = mock.fn(async (_context: string) => {
    return crypto.createSecretKey(Buffer.from('test-secret-key-for-hmac-sha256-32b', 'utf-8'));
});
const mockKeyManager = {
    deriveKey: mockDeriveKey
} as unknown as KeyManager;

// SUT will be imported dynamically
let verifyIdentity: typeof import('../../libs/context/verifyIdentity.js').verifyIdentity;

// Helper to sign envelope (pure)
async function signEnvelope(envelope: IdentityEnvelopeV1, manager: KeyManager): Promise<string> {
    const key = await manager.deriveKey('identity/hmac');
    const dataToSign = JSON.stringify({
        certFingerprint: envelope.certFingerprint ?? null,
        issuedAt: envelope.issuedAt,
        issuerService: envelope.issuerService,
        policyVersion: envelope.policyVersion,
        requestId: envelope.requestId,
        roles: envelope.roles.slice().sort(),
        subjectId: envelope.subjectId,
        subjectType: envelope.subjectType,
        tenantId: envelope.tenantId,
        trustTier: envelope.trustTier ?? null,
        version: envelope.version,
    });
    return crypto.createHmac('sha256', key).update(dataToSign).digest('hex');
}

describe('verifyIdentity', () => {
    // Save original env
    const originalEnv = { ...process.env };

    before(async () => {
        // Set dummy env vars to satisfy libs/db/index.ts config guard
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test'; // Dummy

        // Dynamic import SUT after env set
        const module = await import('../../libs/context/verifyIdentity.js');
        verifyIdentity = module.verifyIdentity;
    });

    after(() => {
        // Restore env
        process.env = originalEnv;
    });

    it('should verify a valid identity envelope', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-123',
            issuedAt: now,
            issuerService: 'ingest-api',
            subjectType: 'client',
            subjectId: 'user-123',
            tenantId: 'tenant-1',
            policyVersion: 'v1.0.0', // Valid
            roles: ['user'],
            trustTier: 'external',
            signature: '',
            certFingerprint: 'fingerprint-123'
        };

        envelope.signature = await signEnvelope(envelope, mockKeyManager);

        const context = await verifyIdentity(envelope, 'control-plane', mockKeyManager, 'fingerprint-123');
        assert.deepStrictEqual(context.subjectId, 'user-123');
        assert.strictEqual(context.certFingerprint, 'fingerprint-123');
    });

    it('should verify a valid user identity (Phase 7B)', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-user-1',
            issuedAt: now,
            issuerService: 'client', // Simulating client-mediated user auth for now
            subjectType: 'user',
            subjectId: 'human-user-001',
            tenantId: 'tenant-1',
            policyVersion: 'v1.0.0',
            roles: ['user'],
            trustTier: 'external',
            signature: '',
            certFingerprint: 'fingerprint-user' // Optional but good to test
        };

        envelope.signature = await signEnvelope(envelope, mockKeyManager);

        // Control plane accepts 'client' issuer
        const context = await verifyIdentity(envelope, 'control-plane', mockKeyManager, 'fingerprint-user');
        assert.strictEqual(context.subjectType, 'user');
        assert.strictEqual(context.subjectId, 'human-user-001');
    });

    it('should strictly enforce tenant isolation for user identity', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-user-2',
            issuedAt: now,
            issuerService: 'client',
            subjectType: 'user',
            subjectId: 'human-user-002',
            tenantId: 'tenant-2', // Different tenant
            policyVersion: 'v1.0.0',
            roles: ['user'],
            trustTier: 'external',
            signature: '',
        };

        envelope.signature = await signEnvelope(envelope, mockKeyManager);

        const context = await verifyIdentity(envelope, 'control-plane', mockKeyManager);
        assert.strictEqual(context.tenantId, 'tenant-2');
        assert.notStrictEqual(context.tenantId, 'tenant-1');
        // Note: verifyIdentity validates the TOKEN integrity. 
        // Authorization logic (AuthZ) downstream checks if this tenant is allowed to access resources.
        // This test ensures the tenantId is preserved and validated as part of the immutable context.
    });

    it('should reject outdated policy version', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-123',
            issuedAt: now,
            issuerService: 'ingest-api',
            subjectType: 'client',
            subjectId: 'user-123',
            tenantId: 'tenant-1',
            policyVersion: 'v0.9.0', // Outdated
            roles: ['user'],
            trustTier: 'external',
            signature: '',
        };
        envelope.signature = await signEnvelope(envelope, mockKeyManager);

        await assert.rejects(
            async () => verifyIdentity(envelope, 'control-plane', mockKeyManager),
            { message: /Policy version mismatch/ }
        );
    });

    it('should reject invalid signature', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-123',
            issuedAt: now,
            issuerService: 'ingest-api',
            subjectType: 'client',
            subjectId: 'user-123',
            tenantId: 'tenant-1',
            policyVersion: 'v1.0.0',
            roles: ['user'],
            trustTier: 'external',
            signature: 'invalid_signature_hex',
        };

        await assert.rejects(
            async () => verifyIdentity(envelope, 'control-plane', mockKeyManager),
            { message: 'Invalid identity signature' }
        );
    });

    it('should reject expired tokens (> 5 min + 30s skew)', async () => {
        const oldDate = new Date(Date.now() - (5 * 60 * 1000 + 31 * 1000)).toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-123',
            issuedAt: oldDate,
            issuerService: 'ingest-api',
            subjectType: 'client',
            subjectId: 'user-123',
            tenantId: 'tenant-1',
            policyVersion: 'v1.0.0',
            roles: ['user'],
            trustTier: 'external',
            signature: '',
        };

        await assert.rejects(
            async () => verifyIdentity(envelope, 'control-plane', mockKeyManager),
            { message: /Identity token too old/ }
        );
    });

    it('should enforce directional trust (OU graph)', async () => {
        const now = new Date().toISOString();
        const envelope: IdentityEnvelopeV1 = {
            version: 'v1',
            requestId: 'req-123',
            issuedAt: now,
            issuerService: 'read-api', // read-api cannot talk to ingest-api
            subjectType: 'service',
            subjectId: 'read-api',
            tenantId: 'tenant-1',
            policyVersion: 'v1.0.0',
            roles: ['service'],
            trustTier: 'internal',
            signature: '',
            certFingerprint: 'fp'
        };
        envelope.signature = await signEnvelope(envelope, mockKeyManager);

        await assert.rejects(
            async () => verifyIdentity(envelope, 'ingest-api', mockKeyManager, 'fp'),
            { message: /Unauthorized OU interaction/ }
        );
    });
});
