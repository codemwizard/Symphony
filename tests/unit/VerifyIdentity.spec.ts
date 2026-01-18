import { describe, it, before } from 'node:test';
import { strict as assert } from 'assert';
import crypto from 'crypto';

// Type-only imports
import type { verifyIdentity as VerifyIdentityFn } from '../../libs/context/verifyIdentity.js';
import type { SymphonyKeyManager as KeyManagerClass } from '../../libs/crypto/keyManager.js';
import type { IdentityEnvelopeV1, ServiceIdentityEnvelopeV1, UserIdentityEnvelopeV1 } from '../../libs/context/identity.js';

let verifyIdentity: typeof VerifyIdentityFn;


describe('VerifyIdentity (Phase 7B Hardening)', () => {

    before(async () => {
        // PRE-IMPORT SETUP (Still needed for ConfigGuard on imports)
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test_db';
        process.env.KMS_KEY_REF = 'alias/test-key';

        const verifyModule = await import('../../libs/context/verifyIdentity.js');
        verifyIdentity = verifyModule.verifyIdentity;


    });

    const createMockKeyManager = () => {
        const keys = new Map<string, string>();
        return {
            deriveKey: async (purpose: string): Promise<string> => {
                if (!keys.has(purpose)) {
                    keys.set(purpose, crypto.randomBytes(32).toString('hex'));
                }
                return keys.get(purpose)!;
            }
        } as unknown as KeyManagerClass;
    };

    async function signEnvelope<T extends IdentityEnvelopeV1>(envelope: T, mockKM: KeyManagerClass): Promise<T> {
        const certFingerprint = envelope.subjectType === 'service'
            ? (envelope as ServiceIdentityEnvelopeV1).certFingerprint
            : null;

        const normalizeStr = (v: string) => v.trim();
        const normalizeRoles = (roles: string[]) => roles.map(r => r.trim()).filter(Boolean).sort();

        const base = {
            certFingerprint: certFingerprint,
            issuedAt: normalizeStr(envelope.issuedAt),
            issuerService: normalizeStr(envelope.issuerService),
            policyVersion: normalizeStr(envelope.policyVersion),
            requestId: normalizeStr(envelope.requestId),
            roles: normalizeRoles(envelope.roles),
            subjectId: normalizeStr(envelope.subjectId),
            subjectType: envelope.subjectType,
            tenantId: normalizeStr(envelope.tenantId),
            trustTier: envelope.trustTier,
            version: envelope.version,
        } as Record<string, unknown>;

        if (envelope.subjectType === 'user') {
            const userEnv = envelope as unknown as UserIdentityEnvelopeV1;
            base.participantId = normalizeStr(userEnv.participantId);
            base.participantRole = userEnv.participantRole;
            base.participantStatus = userEnv.participantStatus;
        }

        const dataToSign = JSON.stringify(base);
        const key = await mockKM.deriveKey('identity/hmac');
        const signature = crypto.createHmac('sha256', key)
            .update(dataToSign)
            .digest('hex');

        return { ...envelope, signature };
    }

    // SKIPPED: Requires DB (Step 6)
    it.skip('should verify a valid CLIENT identity', async () => { });
    it.skip('should verify a valid SERVICE identity', async () => { });
    it.skip('should verify a valid USER identity at Ingest boundary', async () => { });

    // ACTIVE: Security Checks (Steps 3 & 4 - PRE-DB)

    it('should REJECT service identity if mTLS fingerprint mismatches', async () => {
        const mockKM = createMockKeyManager();
        const fingerprint = 'sha256:real-fingerprint';
        const envelope: ServiceIdentityEnvelopeV1 = await signEnvelope({
            version: 'v1',
            requestId: 'req-3',
            issuedAt: new Date().toISOString(),
            issuerService: 'control-plane',
            subjectType: 'service',
            subjectId: 'service-core',
            tenantId: 'system',
            policyVersion: 'v1.0.0',
            roles: ['service_role'],
            trustTier: 'internal',
            signature: '',
            certFingerprint: fingerprint
        }, mockKM);

        await assert.rejects(
            verifyIdentity(envelope, 'executor-worker', mockKM, 'sha256:fake-fingerprint'),
            /mTLS Violation: certFingerprint mismatch/
        );
    });

    it('should REJECT service identity if mTLS fingerprint missing from envelope', async () => {
        const mockKM = createMockKeyManager();
        const envelope = await signEnvelope({
            version: 'v1',
            requestId: 'req-4',
            issuedAt: new Date().toISOString(),
            issuerService: 'control-plane',
            subjectType: 'service',
            subjectId: 'service-core',
            tenantId: 'system',
            policyVersion: 'v1.0.0',
            roles: ['service_role'],
            trustTier: 'internal',
            signature: '',
            certFingerprint: ''
        } as unknown as ServiceIdentityEnvelopeV1, mockKM);

        await assert.rejects(
            verifyIdentity(envelope, 'executor-worker', mockKM, 'sha256:fp'),
            /Identity Schema Violation|mTLS Violation/
        );
    });

    it('should PREVENT USER LAUNDERING: reject user envelope at internal service boundary', async () => {
        const mockKM = createMockKeyManager();
        const envelope: UserIdentityEnvelopeV1 = await signEnvelope({
            version: 'v1',
            requestId: 'req-laundry-1',
            issuedAt: new Date().toISOString(),
            issuerService: 'ingest-api',
            subjectType: 'user',
            subjectId: 'user-alice',
            tenantId: 'tenant-A',
            policyVersion: 'v1.0.0',
            roles: ['user_generic'],
            trustTier: 'user',
            participantId: 'tenant-A',
            participantRole: 'OPERATOR',
            participantStatus: 'ACTIVE',
            signature: ''
        }, mockKM);

        await assert.rejects(
            verifyIdentity(envelope, 'control-plane', mockKM),
            /User identity not permitted|Identity Schema Violation/
        );
    });

    it('should REJECT user identity if issuer is not ingest-api', async () => {
        const mockKM = createMockKeyManager();
        const envelope: UserIdentityEnvelopeV1 = await signEnvelope({
            version: 'v1',
            requestId: 'req-bad-issuer',
            issuedAt: new Date().toISOString(),
            issuerService: 'client',
            subjectType: 'user',
            subjectId: 'user-alice',
            tenantId: 'tenant-A',
            policyVersion: 'v1.0.0',
            roles: [],
            trustTier: 'user',
            participantId: 'tenant-A',
            participantRole: 'OPERATOR',
            participantStatus: 'ACTIVE',
            signature: ''
        }, mockKM);

        await assert.rejects(
            verifyIdentity(envelope, 'ingest-api', mockKM),
            /Invalid user issuer/
        );
    });

    it('should REJECT user identity if trustTier is not user', async () => {
        const mockKM = createMockKeyManager();
        const envelope = await signEnvelope({
            version: 'v1',
            requestId: 'req-bad-tier',
            issuedAt: new Date().toISOString(),
            issuerService: 'ingest-api',
            subjectType: 'user',
            subjectId: 'user-alice',
            tenantId: 'tenant-A',
            policyVersion: 'v1.0.0',
            roles: [],
            trustTier: 'external',
            participantId: 'tenant-A',
            participantRole: 'OPERATOR',
            participantStatus: 'ACTIVE',
            signature: ''
        } as unknown as UserIdentityEnvelopeV1, mockKM);

        await assert.rejects(
            verifyIdentity(envelope, 'ingest-api', mockKM),
            /Identity Schema Violation|trustTier/
        );
    });
});
