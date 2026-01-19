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
import { Pool } from 'pg';
import { OutboxRelayer, OutboxRecord } from '../../libs/outbox/OutboxRelayer.js';

describe('OutboxRelayer', () => {
    let relayer: OutboxRelayer;
    let mockPool: { connect: ReturnType<typeof mock.fn>; query: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };
    let mockRailClient: { dispatch: ReturnType<typeof mock.fn> };

    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [] })),
            release: mock.fn()
        };
        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn()
        };
        mockRailClient = {
            dispatch: mock.fn(async () => ({ success: true, railReference: 'ref-123' }))
        };

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        relayer = new OutboxRelayer(mockPool as unknown as Pool, mockRailClient as any);
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
            mockClient.query = mock.fn(async () => ({
                rows: [mockRecord]
            }));

            // Mock markSuccess query
            mockPool.query = mock.fn(async () => ({}));

            // Access private method via casting or testing public side-effect
            // Since poll is private, we can test start() but that loops.
            // Better to test processRecord if accessible or public methods.
            // But poll is recursive, testing it is hard.
            // We can invoke the logic by iterating manually if we export it or test internals.

            const relayerInternal = relayer as unknown as { claimNextBatch: () => Promise<OutboxRecord[]> };
            await relayerInternal.claimNextBatch();

            // Verify SKIP LOCKED usage
            const queryCalls = mockClient.query.mock.calls;
            const hasSkipLocked = queryCalls.some(call => {
                const args = call.arguments as [string];
                return typeof args[0] === 'string' && args[0].includes('FOR UPDATE SKIP LOCKED');
            });
            assert.ok(hasSkipLocked, 'Should use SKIP LOCKED');
            assert.strictEqual(mockClient.release.mock.calls.length, 1, 'Should release client');
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
            assert.strictEqual(mockPool.query.mock.calls.length, 1);
            const poolQueryArgs = mockPool.query.mock.calls[0]!.arguments as [string, unknown[]];
            assert.ok(poolQueryArgs[0].includes('INSERT INTO payment_outbox_attempts'));
            const params = poolQueryArgs[1] as unknown[];
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
            assert.strictEqual(mockPool.query.mock.calls.length, 2);
            const outcomeCall = mockPool.query.mock.calls[0]!;
            const outcomeArgs = outcomeCall.arguments as [string, unknown[]];
            assert.ok(outcomeArgs[0].includes('INSERT INTO payment_outbox_attempts'));
            const outcomeParams = outcomeArgs[1] as unknown[];
            assert.strictEqual(outcomeParams[7], 'RETRYABLE');
            const requeueCall = mockPool.query.mock.calls[1]!;
            const requeueArgs = requeueCall.arguments as [string];
            assert.ok(requeueArgs[0].includes('INSERT INTO payment_outbox_pending'));
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
            const failureCall = mockPool.query.mock.calls[0]!;
            const failureArgs = failureCall.arguments as [string, unknown[]];
            assert.ok(failureArgs[0].includes('INSERT INTO payment_outbox_attempts'));
            const params = failureArgs[1] as unknown[];
            assert.strictEqual(params[7], 'FAILED');
        });
    });
});
