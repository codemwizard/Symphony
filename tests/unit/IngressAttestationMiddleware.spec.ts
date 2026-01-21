import { describe, it, beforeEach, mock } from 'node:test';
import * as assert from 'node:assert';
import { IngressAttestationService, IngressEnvelope, InvalidEnvelopeError, createIngressAttestationMiddleware } from '../../libs/attestation/IngressAttestationMiddleware.js';
import { DbRole } from '../../libs/db/roles.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

console.log('DEBUG: IngressAttestationMiddleware.spec.ts loaded');
const VALID_SIGNATURE = 'a'.repeat(64);
describe('IngressAttestationService', () => {
    let service: IngressAttestationService;
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };
    let mockClient: { query: ReturnType<typeof mock.fn> };

    beforeEach(() => {
        console.log('DEBUG: beforeEach started');
        mockClient = {
            query: mock.fn(async () => ({ rows: [], rowCount: 0 }))
        };
        mockDb = {
            queryAsRole: mock.fn(async () => ({ rows: [], rowCount: 0 })),
            withRoleClient: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            probeRoles: mock.fn(async () => undefined)
        };
        try {
            service = new IngressAttestationService('symphony_ingest', mockDb as unknown as DbClient);
            console.log('DEBUG: service instantiated');
        } catch (error) {
            console.error('DEBUG: Error instantiating service', error);
            throw error;
        }
    });

    describe('attest()', () => {
        it('should validate and insert attestation record', async () => {
            console.log('DEBUG: test1 started');
            mockClient.query = mock.fn(async (sql: string) => {
                if (typeof sql === 'string' && sql.includes('SELECT record_hash')) {
                    return { rows: [{ record_hash: 'prev-hash-123' }] };
                }
                if (typeof sql === 'string' && sql.includes('INSERT INTO')) {
                    return {
                        rows: [{
                            id: 'att-1',
                            request_id: 'req-1',
                            idempotency_key: 'idempotency-key-1',
                            record_hash: 'new-hash-456',
                            attested_at: new Date()
                        }]
                    };
                }
                return { rows: [] };
            });

            const envelope = {
                requestId: 'req-1',
                idempotencyKey: 'idempotency-key-1',
                callerId: 'tenant-1',
                signature: VALID_SIGNATURE,
                timestamp: new Date().toISOString()
            };

            const result = await service.attest(envelope);
            console.log('DEBUG: attest called');

            assert.strictEqual(result.id, 'att-1');
            assert.strictEqual(result.recordHash, 'new-hash-456');

            // Verify calls
            assert.strictEqual(mockDb.withRoleClient.mock.calls.length, 1);
            assert.strictEqual(mockClient.query.mock.calls.length, 2); // Select prev + Insert
            console.log('DEBUG: test1 finished');
        });

        it('should throw InvalidEnvelopeError for missing fields', async () => {
            console.log('DEBUG: test2 started');
            const envelope: Partial<IngressEnvelope> = {
                requestId: 'req-1',
                // Missing idempotencyKey
                callerId: 'tenant-1',
                signature: VALID_SIGNATURE,
                timestamp: new Date().toISOString()
            };

            await assert.rejects(
                async () => service.attest(envelope as IngressEnvelope),
                { name: 'InvalidEnvelopeError' }
            );
            console.log('DEBUG: test2 finished');
        });

        it('should release client on error', async () => {
            console.log('DEBUG: test3 started');
            mockClient.query = mock.fn(async () => {
                throw new Error('DB Error');
            });

            const envelope: IngressEnvelope = {
                requestId: 'req-1',
                idempotencyKey: 'key-1',
                callerId: 'tenant-1',
                signature: VALID_SIGNATURE,
                timestamp: new Date().toISOString()
            };

            await assert.rejects(
                async () => service.attest(envelope),
                { message: /Could not create attestation/ }
            );

            console.log('DEBUG: test3 finished');
        });
    });

    describe('markExecutionStarted()', () => {
        it('should update execution_started with attestedAt pruning', async () => {
            console.log('DEBUG: test4 started');
            const attestedAt = new Date();

            await service.markExecutionStarted('att-1', attestedAt);

            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 1, 'DB query should be called exactly once');
            const call = mockDb.queryAsRole.mock.calls[0];
            assert.ok(call, 'Call should exist');

            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const [, sql, params] = call.arguments as [string, string, any[]];

            assert.ok(sql.includes('WHERE id = $1 AND attested_at = $2'));
            assert.strictEqual(params[0], 'att-1');
            assert.strictEqual(params[1], attestedAt);
            console.log('DEBUG: test4 finished');
        });
    });

    describe('markExecutionCompleted()', () => {
        it('should update execution_completed with attestedAt pruning', async () => {
            console.log('DEBUG: test5 started');
            const attestedAt = new Date();

            await service.markExecutionCompleted('att-1', attestedAt, 'SUCCESS');

            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 1, 'DB query should be called exactly once');
            const call = mockDb.queryAsRole.mock.calls[0];
            assert.ok(call, 'Call should exist');

            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const [, sql, params] = call.arguments as [string, string, any[]];

            assert.ok(sql.includes('terminal_status = $3'));
            assert.ok(sql.includes('WHERE id = $1 AND attested_at = $2'));
            assert.strictEqual(params[2], 'SUCCESS');
            console.log('DEBUG: test5 finished');
        });
    });

    describe('createIngressAttestationMiddleware()', () => {
        it('should require x-timestamp header', async () => {
            const middleware = createIngressAttestationMiddleware('symphony_ingest', mockDb as unknown as DbClient);
            const req = {
                headers: {
                    'x-signature': VALID_SIGNATURE,
                    'x-request-id': 'req-1',
                    'x-idempotency-key': 'idem-1'
                },
                body: {}
            } as unknown as import('express').Request;
            const res = {
                on: () => undefined,
                statusCode: 200
            } as unknown as import('express').Response;
            let capturedError: unknown;
            const next = (err?: unknown) => {
                capturedError = err;
            };

            await middleware(req, res, next);

            assert.ok(capturedError instanceof InvalidEnvelopeError);
            assert.strictEqual((capturedError as InvalidEnvelopeError).message, 'Missing x-timestamp header');
        });
    });
});
