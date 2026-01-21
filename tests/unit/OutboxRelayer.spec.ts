/**
 * Unit Tests: Outbox Relayer
 * 
 * Tests the reliable relayer with DLQ logic and idempotency.
 * Refactored to use node:test and call production code.
 * 
 * @see libs/outbox/OutboxRelayer.ts
 */

import { describe, it, beforeEach, mock } from 'node:test';
import * as assert from 'node:assert';
import { OutboxRelayer, OutboxRecord } from '../../libs/outbox/OutboxRelayer.js';
import { DbRole } from '../../libs/db/roles.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

describe('OutboxRelayer', () => {
    let relayer: OutboxRelayer;
    let mockTxClient: { query: ReturnType<typeof mock.fn> };
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };
    let mockRailClient: { dispatch: ReturnType<typeof mock.fn> };

    beforeEach(() => {
        mockTxClient = {
            query: mock.fn(async () => ({ rows: [] }))
        };
        mockDb = {
            queryAsRole: mock.fn(async () => ({ rows: [] })),
            transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: typeof mockTxClient) => Promise<unknown>) =>
                callback(mockTxClient)
            ),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            withRoleClient: mock.fn(async (_role: DbRole, callback: (client: typeof mockTxClient) => Promise<unknown>) =>
                callback(mockTxClient)
            ),
            probeRoles: mock.fn(async () => undefined)
        };
        mockRailClient = {
            dispatch: mock.fn(async () => ({ success: true, railReference: 'ref-123' }))
        };

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        relayer = new OutboxRelayer(mockRailClient as any, 'symphony_executor', mockDb as unknown as DbClient);
    });

    describe('poll() -> claimNextBatch()', () => {
        it('should process available records', async () => {
            const mockRecord: OutboxRecord = {
                outbox_id: 'uuid-1',
                instruction_id: 'instruction-1',
                participant_id: 'p1',
                sequence_id: 1,
                idempotency_key: 'key-1',
                rail_type: 'PAYMENT',
                payload: { amount: 100, currency: 'USD', destination: 'dest-1' },
                attempt_count: 0,
                attempt_no: 1,
                created_at: new Date()
            };

            // Mock fetchNextBatch query result
            mockTxClient.query = mock.fn(async () => ({
                rows: [mockRecord]
            }));

            // Access private method via casting or testing public side-effect
            // Since poll is private, we can test start() but that loops.
            // Better to test processRecord if accessible or public methods.
            // But poll is recursive, testing it is hard.
            // We can invoke the logic by iterating manually if we export it or test internals.

            const relayerInternal = relayer as unknown as { claimNextBatch: () => Promise<OutboxRecord[]> };
            await relayerInternal.claimNextBatch();

            // Verify SKIP LOCKED usage
            const queryCalls = mockTxClient.query.mock.calls;
            const hasSkipLocked = queryCalls.some(call => {
                const args = call.arguments as [string];
                return typeof args[0] === 'string' && args[0].includes('FOR UPDATE SKIP LOCKED');
            });
            assert.ok(hasSkipLocked, 'Should use SKIP LOCKED');
        });
    });

    describe('processRecord()', () => {
        it('should dispatch to rail and mark success', async () => {
            const mockRecord: OutboxRecord = {
                outbox_id: 'uuid-1',
                instruction_id: 'instruction-1',
                participant_id: 'p1',
                sequence_id: 1,
                idempotency_key: 'key-1',
                rail_type: 'PAYMENT',
                payload: { amount: 100, currency: 'USD', destination: 'dest-1' },
                attempt_count: 0,
                attempt_no: 1,
                created_at: new Date()
            };

            const relayerInternal = relayer as unknown as { processRecord: (record: OutboxRecord) => Promise<void> };
            await relayerInternal.processRecord(mockRecord);

            // Verify rail dispatch
            assert.strictEqual(mockRailClient.dispatch.mock.calls.length, 1);
            const dispatchCall = mockRailClient.dispatch.mock.calls[0]!;
            const dispatchArgs = (dispatchCall.arguments as [{ reference: string }])[0];
            assert.strictEqual(dispatchArgs.reference, 'uuid-1');

            // Verify success mark (Pool query)
            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 1);
            const poolQueryArgs = mockDb.queryAsRole.mock.calls[0]!.arguments as [string, string, unknown[]];
            assert.ok(poolQueryArgs[1].includes('INSERT INTO payment_outbox_attempts'));
            const params = poolQueryArgs[2] as unknown[];
            assert.strictEqual(params[7], 'DISPATCHED');
        });

        it('should handle transient errors by marking RECOVERING', async () => {
            mockRailClient.dispatch = mock.fn(async () => {
                throw new Error('ECONNRESET: Connection reset');
            });

            const mockRecord: OutboxRecord = {
                outbox_id: 'uuid-1',
                instruction_id: 'instruction-1',
                participant_id: 'p1',
                sequence_id: 1,
                idempotency_key: 'key-1',
                rail_type: 'PAYMENT',
                payload: { amount: 100, currency: 'USD', destination: 'dest-1' },
                attempt_count: 0,
                attempt_no: 1,
                created_at: new Date()
            };

            const relayerInternal = relayer as unknown as { processRecord: (record: OutboxRecord) => Promise<void> };
            await relayerInternal.processRecord(mockRecord);

            // Verify outcome insert and requeue
            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 2);
            const outcomeCall = mockDb.queryAsRole.mock.calls[0]!;
            const outcomeArgs = outcomeCall.arguments as [string, string, unknown[]];
            assert.ok(outcomeArgs[1].includes('INSERT INTO payment_outbox_attempts'));
            const outcomeParams = outcomeArgs[2] as unknown[];
            assert.strictEqual(outcomeParams[7], 'RETRYABLE');
            const requeueCall = mockDb.queryAsRole.mock.calls[1]!;
            const requeueArgs = requeueCall.arguments as [string, string];
            assert.ok(requeueArgs[1].includes('INSERT INTO payment_outbox_pending'));
        });

        it('should mark failed for terminal errors', async () => {
            mockRailClient.dispatch = mock.fn(async () => ({
                success: false,
                errorCode: 'INVALID_ACCOUNT',
                errorMessage: 'Permanent Error'
            }));

            const mockRecord: OutboxRecord = {
                outbox_id: 'uuid-1',
                instruction_id: 'instruction-1',
                participant_id: 'p1',
                sequence_id: 1,
                idempotency_key: 'key-1',
                rail_type: 'PAYMENT',
                payload: { amount: 100, currency: 'USD', destination: 'dest-1' },
                attempt_count: 5,
                attempt_no: 6,
                created_at: new Date()
            };

            const relayerInternal = relayer as unknown as { processRecord: (record: OutboxRecord) => Promise<void> };
            await relayerInternal.processRecord(mockRecord);

            // Verify outcome insert
            const failureCall = mockDb.queryAsRole.mock.calls[0]!;
            const failureArgs = failureCall.arguments as [string, string, unknown[]];
            assert.ok(failureArgs[1].includes('INSERT INTO payment_outbox_attempts'));
            const params = failureArgs[2] as unknown[];
            assert.strictEqual(params[7], 'FAILED');
        });
    });
});
