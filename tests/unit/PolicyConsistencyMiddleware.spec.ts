/**
 * Phase-7R Unit Tests: Policy Consistency Middleware
 * 
 * Tests real policy version validation and scope enforcement logic
 * by mocking the database layer.
 * Migrated to node:test
 * 
 * @see libs/policy/PolicyConsistencyMiddleware.ts
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import { PolicyConsistencyService, PolicyClaims, createPolicyConsistencyMiddleware, signPolicyClaims } from '../../libs/policy/PolicyConsistencyMiddleware.js';
import { SymphonyKeyManager } from '../../libs/crypto/keyManager.js';
import { DbRole } from '../../libs/db/roles.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

// We cannot easily mock 'pino' import in node:test without loaders.
// However, if the service imports pino directly, we just let it run.
// The test silence requirement can be ignored or we can rely on log level env var.
// Since strict output isn't checked for pino, we proceed.

describe('PolicyConsistencyService', () => {
    let service: PolicyConsistencyService;
    let mockQuery: ReturnType<typeof mock.fn>;
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };

    const MOCK_FLAGS = {
        ACTIVE_VERSION: 'v1.2.3',
        GRACE_VERSION: 'v1.2.2', // Older version still in grace period
        RETIRED_VERSION: 'v1.0.0',
        FUTURE_VERSION: 'v2.0.0',
        SCOPE_ID: 'TIER_1'
    };

    beforeEach(() => {
        // Setup PostgreSQL Mock
        mockQuery = mock.fn(async (_role: DbRole, text: string) => {
            if (text.includes('FROM policy_versions')) {
                return {
                    rows: [
                        { version: MOCK_FLAGS.ACTIVE_VERSION, status: 'ACTIVE', activated_at: new Date() },
                        { version: MOCK_FLAGS.GRACE_VERSION, status: 'GRACE', activated_at: new Date() }
                    ]
                };
            }
            if (text.includes('FROM policy_scopes')) {
                return {
                    rows: [{
                        scope_id: MOCK_FLAGS.SCOPE_ID,
                        max_transaction_amount: 1000,
                        allowed_operations: ['PAYMENT', 'TRANSFER'],
                        daily_limit: 10000,
                        hourly_limit: 5000
                    }]
                };
            }
            return { rows: [] };
        });

        mockDb = {
            queryAsRole: mockQuery,
            withRoleClient: mock.fn(async (_role: DbRole, callback: (client: { query: typeof mockQuery }) => Promise<unknown>) =>
                callback({ query: mockQuery })
            ),
            transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: { query: typeof mockQuery }) => Promise<unknown>) =>
                callback({ query: mockQuery })
            ),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            probeRoles: mock.fn(async () => undefined)
        };

        // Instantiate Service
        service = new PolicyConsistencyService('symphony_readonly', mockDb as unknown as DbClient);
    });

    afterEach(() => {
        service.invalidateCache();
    });

    describe('getGlobalPolicyState', () => {
        it('should load and cache policy state from database', async () => {
            const state = await service.getGlobalPolicyState();

            assert.strictEqual(state.activeVersion, MOCK_FLAGS.ACTIVE_VERSION);
            assert.strictEqual(state.graceVersions.has(MOCK_FLAGS.GRACE_VERSION), true);
            assert.strictEqual(state.scopes.has(MOCK_FLAGS.SCOPE_ID), true);

            // Verify DB was called
            // First call (uncached) makes 2 queries (versions + scopes)
            assert.strictEqual(mockQuery.mock.calls.length, 2);

            // Call again to verify cache usage
            await service.getGlobalPolicyState();
            assert.strictEqual(mockQuery.mock.calls.length, 2); // Count should not increase
        });
    });

    describe('validatePolicyClaims', () => {
        it('should validate a valid token with active version', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            const result = await service.validatePolicyClaims(claims);

            assert.strictEqual(result.valid, true);
            assert.strictEqual(result.inGracePeriod, false);
            assert.strictEqual(result.requiresReauth, false);
        });

        it('should allow token in grace period but flag for re-auth', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.GRACE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            const result = await service.validatePolicyClaims(claims);

            assert.strictEqual(result.valid, true); // Still accepted
            assert.strictEqual(result.inGracePeriod, true);
            assert.strictEqual(result.requiresReauth, true); // Client should update
        });

        it('should reject retired or unknown versions', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.RETIRED_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            await assert.rejects(
                async () => service.validatePolicyClaims(claims),
                { name: 'PolicyViolationError' }
            );
        });

        it('should reject tokens with invalid scope', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: 'INVALID_SCOPE',
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            await assert.rejects(
                async () => service.validatePolicyClaims(claims),
                (err: unknown) => err instanceof Error && err.message.includes('not recognized')
            );
        });

        it('should reject expired tokens', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(), // Fresh issuedAt to avoid TOKEN_TOO_OLD
                expiresAt: Date.now() - 70000 // Expired > 60s ago (CLOCK_SKEW_TOLERANCE)
            };

            await assert.rejects(
                async () => service.validatePolicyClaims(claims),
                (err: unknown) => err instanceof Error && err.message.includes('expired')
            );
        });
    });

    describe('isOperationAllowed', () => {
        it('should allow authorized operations within limits', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            const allowed = await service.isOperationAllowed(claims, 'PAYMENT', 500);
            assert.strictEqual(allowed, true);
        });

        it('should deny unauthorized operations', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            // 'REFUND' is not in the mocked allowed_operations list
            const allowed = await service.isOperationAllowed(claims, 'REFUND', 500);
            assert.strictEqual(allowed, false);
        });

        it('should deny transaction amounts exceeding limit', async () => {
            const claims: PolicyClaims = {
                participantId: 'user-123',
                policyVersion: MOCK_FLAGS.ACTIVE_VERSION,
                policyScope: MOCK_FLAGS.SCOPE_ID,
                capabilities: [],
                issuedAt: Date.now(),
                expiresAt: Date.now() + 3600000
            };

            // Limit is 1000
            const allowed = await service.isOperationAllowed(claims, 'PAYMENT', 1500);
            assert.strictEqual(allowed, false);
        });
    });
});

describe('PolicyConsistencyMiddleware', () => {
    const MOCK_SCOPE = 'TIER_1';
    const baseClaims: PolicyClaims = {
        participantId: 'user-123',
        policyVersion: 'v1.2.3',
        policyScope: MOCK_SCOPE,
        capabilities: [],
        issuedAt: Date.now(),
        expiresAt: Date.now() + 3600000
    };

    let restoreMock: () => void;

    beforeEach(() => {
        const mockFn = mock.method(SymphonyKeyManager.prototype, 'deriveKey', async () => {
            return Buffer.from('policy-claims-key').toString('base64');
        });
        restoreMock = () => mockFn.mock.restore();
    });

    afterEach(() => {
        if (restoreMock) restoreMock();
    });

    const buildMockDb = () => ({
        queryAsRole: mock.fn(async (_role: DbRole, text: string) => {
            if (text.includes('FROM policy_versions')) {
                return {
                    rows: [
                        { version: baseClaims.policyVersion, status: 'ACTIVE', activated_at: new Date() }
                    ]
                };
            }
            if (text.includes('FROM policy_scopes')) {
                return {
                    rows: [{
                        scope_id: MOCK_SCOPE,
                        max_transaction_amount: 1000,
                        allowed_operations: ['PAYMENT'],
                        daily_limit: 10000,
                        hourly_limit: 5000
                    }]
                };
            }
            return { rows: [] };
        }),
        withRoleClient: mock.fn(async (_role: DbRole, callback: (client: { query: ReturnType<typeof mock.fn> }) => Promise<unknown>) =>
            callback({ query: mock.fn(async () => ({ rows: [] })) })
        ),
        transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: { query: ReturnType<typeof mock.fn> }) => Promise<unknown>) =>
            callback({ query: mock.fn(async () => ({ rows: [] })) })
        ),
        listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
        probeRoles: mock.fn(async () => undefined)
    });

    it('should accept policy claims with a valid signature header', async () => {
        const mockDb = buildMockDb();
        const middleware = createPolicyConsistencyMiddleware('symphony_readonly', {}, mockDb as unknown as DbClient);
        const signature = await signPolicyClaims(baseClaims);

        const req = {
            policyClaims: baseClaims,
            headers: { 'x-policy-claims-signature': signature }
        } as unknown as { policyClaims: PolicyClaims; headers: Record<string, string> };
        const res = { setHeader: mock.fn() } as unknown as { setHeader: ReturnType<typeof mock.fn> };

        await new Promise<void>((resolve, reject) => {
            middleware(req as unknown as Parameters<typeof middleware>[0], res as unknown as Parameters<typeof middleware>[1], (err?: unknown) => {
                if (err) {
                    reject(err);
                } else {
                    resolve();
                }
            });
        });
    });

    it('should reject policy claims without a signature header', async () => {
        const mockDb = buildMockDb();
        const middleware = createPolicyConsistencyMiddleware('symphony_readonly', {}, mockDb as unknown as DbClient);

        const req = {
            policyClaims: baseClaims,
            headers: {}
        } as unknown as { policyClaims: PolicyClaims; headers: Record<string, string> };
        const res = { setHeader: mock.fn() } as unknown as { setHeader: ReturnType<typeof mock.fn> };

        await new Promise<void>((resolve) => {
            middleware(req as unknown as Parameters<typeof middleware>[0], res as unknown as Parameters<typeof middleware>[1], (err?: unknown) => {
                assert.ok(err instanceof Error);
                assert.ok(err.message.includes('signature is required'));
                resolve();
            });
        });
    });

    it('should reject policy claims with an invalid signature header', async () => {
        const mockDb = buildMockDb();
        const middleware = createPolicyConsistencyMiddleware('symphony_readonly', {}, mockDb as unknown as DbClient);

        const req = {
            policyClaims: baseClaims,
            headers: { 'x-policy-claims-signature': 'deadbeef' }
        } as unknown as { policyClaims: PolicyClaims; headers: Record<string, string> };
        const res = { setHeader: mock.fn() } as unknown as { setHeader: ReturnType<typeof mock.fn> };

        await new Promise<void>((resolve) => {
            middleware(req as unknown as Parameters<typeof middleware>[0], res as unknown as Parameters<typeof middleware>[1], (err?: unknown) => {
                assert.ok(err instanceof Error);
                assert.ok(err.message.includes('signature format is invalid'));
                resolve();
            });
        });
    });
});
