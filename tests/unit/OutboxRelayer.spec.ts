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

    describe('poll() -> fetchNextBatch()', () => {
        it('should process available records', async () => {
            const mockRecord: OutboxRecord = {
                id: 'uuid-1',
                participant_id: 'p1',
                sequence_id: 'seq-1',
                idempotency_key: 'key-1',
                event_type: 'PAYMENT',
                payload: { amount: 100, destination: 'dest-1' },
                retry_count: 0
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

            const relayerInternal = relayer as unknown as { fetchNextBatch: () => Promise<OutboxRecord[]> };
            await relayerInternal.fetchNextBatch();

            // Verify SKIP LOCKED usage
            const queryCall = mockClient.query.mock.calls[0]!;
            const queryArgs = queryCall.arguments as [string];
            assert.ok(queryArgs[0].includes('FOR UPDATE SKIP LOCKED'), 'Should use SKIP LOCKED');
            assert.strictEqual(mockClient.release.mock.calls.length, 1, 'Should release client');
        });
    });

    describe('processRecord()', () => {
        it('should dispatch to rail and mark success', async () => {
            const mockRecord: OutboxRecord = {
                id: 'uuid-1',
                participant_id: 'p1',
                sequence_id: 'seq-1',
                idempotency_key: 'key-1',
                event_type: 'PAYMENT',
                payload: { amount: 100, destination: 'dest-1' },
                retry_count: 0
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
            const poolQueryArgs = mockPool.query.mock.calls[0]!.arguments as [string];
            assert.ok(poolQueryArgs[0].includes("status = 'SUCCESS'"));
        });

        it('should handle transient errors by marking RECOVERING', async () => {
            mockRailClient.dispatch = mock.fn(async () => {
                throw new Error('ECONNRESET: Connection reset');
            });

            const mockRecord: OutboxRecord = {
                id: 'uuid-1',
                participant_id: 'p1',
                sequence_id: 'seq-1',
                idempotency_key: 'key-1',
                event_type: 'PAYMENT',
                payload: { amount: 100, destination: 'dest-1' },
                retry_count: 0
            };

            const relayerInternal = relayer as unknown as { processRecord: (record: OutboxRecord) => Promise<void> };
            await relayerInternal.processRecord(mockRecord);

            // Verify update to RECOVERING
            assert.strictEqual(mockPool.query.mock.calls.length, 1);
            const recoveringCall = mockPool.query.mock.calls[0]!;
            const queryArgs = recoveringCall.arguments as [string, string[]];
            const query = queryArgs[0];
            const params = queryArgs[1];

            assert.ok(query.includes("status = $1")); // Parameterized update
            assert.strictEqual(params[0], 'RECOVERING');
        });

        it('should dlq after max retries', async () => {
            mockRailClient.dispatch = mock.fn(async () => ({
                success: false,
                error: 'Permanent Error'
            }));

            const mockRecord: OutboxRecord = {
                id: 'uuid-1',
                participant_id: 'p1',
                sequence_id: 'seq-1',
                idempotency_key: 'key-1',
                event_type: 'PAYMENT',
                payload: { amount: 100, destination: 'dest-1' },
                retry_count: 5 // MAX_RETRIES reached
            };

            const relayerInternal = relayer as unknown as { processRecord: (record: OutboxRecord) => Promise<void> };
            await relayerInternal.processRecord(mockRecord);

            // Verify update to FAILED (DLQ)
            const dlqCall = mockPool.query.mock.calls[0]!;
            const dlqQueryArgs = dlqCall.arguments as [string, string[]];
            const params = dlqQueryArgs[1];
            // The query for DLQ is specific: SET status = 'FAILED'
            const query = dlqQueryArgs[0];
            assert.ok(query.includes("status = 'FAILED'"));
            assert.ok(params[1]?.includes('DLQ:'));
        });
    });
});
