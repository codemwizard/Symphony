import { describe, it, before, after, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';
import { generateKeyPair, exportJWK, SignJWT } from 'jose';
// KeyLike is not exported by newer jose versions, using any/object
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type KeyLike = any;
import { jwtToMtlsBridge } from '../../libs/bridge/jwtToMtlsBridge.js';
import { clearJWKSCache } from '../../libs/crypto/jwks.js';
import { SymphonyKeyManager } from '../../libs/crypto/keyManager.js';

const TEST_JWKS_PATH = 'tests/unit/fixtures/test-jwks.json';
let privateKey: KeyLike;
let restoreMock: () => void;

// Mock key for HMAC: return base64 string or hex string as per KeyManager contract
const MOCK_HMAC_KEY = crypto.randomBytes(32).toString('hex');

describe('jwtToMtlsBridge', () => {
    before(async () => {
        // Mock KeyManager to avoid KMS
        // We mock the prototype to affect the singleton instance used by imported modules
        const mockFn = mock.method(SymphonyKeyManager.prototype, 'deriveKey', async () => {
            return MOCK_HMAC_KEY;
        });
        restoreMock = () => mockFn.mock.restore();

        // Generate key
        const { privateKey: priv, publicKey } = await generateKeyPair('ES256');
        privateKey = priv;
        const jwk = await exportJWK(publicKey);
        jwk.use = 'sig';
        jwk.kid = 'test-key';

        const jwks = { keys: [jwk] };
        fs.mkdirSync(path.dirname(TEST_JWKS_PATH), { recursive: true });
        fs.writeFileSync(TEST_JWKS_PATH, JSON.stringify(jwks));

        process.env.JWKS_PATH = TEST_JWKS_PATH;
        clearJWKSCache();
    });

    after(() => {
        if (restoreMock) restoreMock();
        if (fs.existsSync(TEST_JWKS_PATH)) fs.unlinkSync(TEST_JWKS_PATH);
        delete process.env.JWKS_PATH;
        clearJWKSCache();
    });

    it('should bridge valid CLIENT JWT', async () => {
        const jwt = await new SignJWT({ sub: 'user-1', scope: 'foo' })
            .setProtectedHeader({ alg: 'ES256', kid: 'test-key' })
            .setIssuer('symphony-idp')
            .setAudience('symphony-api')
            .setIssuedAt()
            .setExpirationTime('1h')
            .sign(privateKey);

        const context = await jwtToMtlsBridge.bridgeExternalIdentity(jwt);
        assert.strictEqual(context.subjectId, 'user-1');
        assert.strictEqual(context.trustTier, 'external');
        assert.strictEqual(context.issuerService, 'ingress-gateway');
    });

    it('should bridge valid TENANT-ANCHORED USER JWT', async () => {
        const jwt = await new SignJWT({
            sub: 'user-alice',
            scope: 'user_generic',
            tenant_id: 'tenant-A'
        })
            .setProtectedHeader({ alg: 'ES256', kid: 'test-key' })
            .setIssuer('symphony-idp')
            .setAudience('symphony-api')
            .setIssuedAt()
            .setExpirationTime('1h')
            .sign(privateKey);

        const participantResolver = async (_tid: string) => ({ role: 'OPERATOR', status: 'ACTIVE' });

        const context = await jwtToMtlsBridge.bridgeUserIdentity(jwt, participantResolver);
        assert.strictEqual(context.subjectType, 'user');
        assert.strictEqual(context.trustTier, 'user');
        assert.strictEqual(context.tenantId, 'tenant-A');
        assert.strictEqual(context.issuerService, 'ingest-api');

        if (context.subjectType === 'user') { // Checking discrimination
            assert.strictEqual(context.participantId, 'tenant-A');
            assert.strictEqual(context.participantRole, 'OPERATOR');
        }
    });

    it('should reject invalid signature', async () => {
        // Sign with different key
        const { privateKey: badKey } = await generateKeyPair('ES256');
        const jwt = await new SignJWT({ sub: 'user-1' })
            .setProtectedHeader({ alg: 'ES256', kid: 'test-key' })
            .setIssuer('symphony-idp')
            .setAudience('symphony-api') // Correct audience
            .setIssuedAt()
            .setExpirationTime('1h')
            .sign(badKey);

        await assert.rejects(async () => jwtToMtlsBridge.bridgeExternalIdentity(jwt), {
            message: /verification failed/
        });
    });

    it('should reject expired token', async () => {
        const jwt = await new SignJWT({ sub: 'user-1' })
            .setProtectedHeader({ alg: 'ES256', kid: 'test-key' })
            .setIssuer('symphony-idp')
            .setAudience('symphony-api')
            .setIssuedAt()
            .setExpirationTime('-1h') // Expired
            .sign(privateKey);

        await assert.rejects(async () => jwtToMtlsBridge.bridgeExternalIdentity(jwt), {
            message: /verification failed/
        });
    });

    it('should reject wrong audience', async () => {
        const jwt = await new SignJWT({ sub: 'user-1' })
            .setProtectedHeader({ alg: 'ES256', kid: 'test-key' })
            .setIssuer('symphony-idp')
            .setAudience('wrong-api')
            .setIssuedAt()
            .setExpirationTime('1h')
            .sign(privateKey);

        await assert.rejects(async () => jwtToMtlsBridge.bridgeExternalIdentity(jwt), {
            message: /verification failed/
        });
    });
});
