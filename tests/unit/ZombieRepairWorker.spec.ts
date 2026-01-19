/**
 * Unit Tests: Zombie Repair Worker
 * 
 * Tests temporal idempotency and requeue behavior.
 * Refactored to use node:test and call production code.
 * 
 * @see libs/repair/ZombieRepairWorker.ts
 */

import { describe, it, beforeEach, mock } from 'node:test';
import * as assert from 'node:assert';
import { Pool } from 'pg';
import { ZombieRepairWorker } from '../../libs/repair/ZombieRepairWorker.js';

describe('ZombieRepairWorker', () => {
    let worker: ZombieRepairWorker;
    let mockPool: { connect: ReturnType<typeof mock.fn>; query: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };


    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [], rowCount: 0 })),
            release: mock.fn()
        };
        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn(async () => ({ rows: [], rowCount: 0 }))
        };
        worker = new ZombieRepairWorker(mockPool as unknown as Pool);
    });

    describe('runRepairCycle()', () => {
        it('should execute repair queries with correct SQL', async () => {
            // Mock DB response to ensure all branches are taken
            mockClient.query.mock.mockImplementation(async (sql: string) => {
                if (sql === 'BEGIN' || sql === 'COMMIT') return {};
                if (sql.includes('FROM payment_outbox_attempts')) {
                    return {
                        rows: [{
                            outbox_id: 'outbox-1',
                            instruction_id: 'instruction-1',
                            participant_id: 'participant-1',
                            sequence_id: 10,
                            idempotency_key: 'idem-1',
                            rail_type: 'PAYMENT',
                            payload: { amount: 100, currency: 'USD', destination: 'dest' },
                            attempt_no: 2
                        }]
                    };
                }
                return { rows: [], rowCount: 0 };
            });

            const result = await worker.runRepairCycle();

            assert.ok(result);

            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            const queries = mockClient.query.mock.calls.map((c: any) => c.arguments[0] as string);
            // console.log('CAPTURED QUERIES:', JSON.stringify(queries, null, 2));

            // Check stale dispatching lookup
            assert.ok(queries.some((q) => q.includes('FROM payment_outbox_attempts')));

            // Check requeue insert
            assert.ok(queries.some((q) => q.includes('INSERT INTO payment_outbox_pending')));

            // Check audit attempt insert
            assert.ok(queries.some((q) => q.includes('INSERT INTO payment_outbox_attempts')));
        });

        it('should define transaction boundaries', async () => {
            const result = await worker.runRepairCycle();

            assert.ok(result);

            // Verify transaction flow: BEGIN -> ... -> COMMIT
            const queries = mockClient.query.mock.calls.map((c: { arguments: unknown[] }) => c.arguments[0]);
            assert.strictEqual(queries[0], 'BEGIN');
            assert.strictEqual(queries[queries.length - 1], 'COMMIT');
            assert.strictEqual(mockClient.release.mock.calls.length, 1);
        });

        it('should rollback on error', async () => {
            mockClient.query.mock.mockImplementation(async (sql: string) => {
                if (sql === 'BEGIN' || sql === 'ROLLBACK') return {};
                throw new Error('DB Failure');
            });

            const result = await worker.runRepairCycle();

            assert.strictEqual(result.errors.length, 1);
            assert.strictEqual(result.errors[0], 'DB Failure');

            // Verify connect was called
            assert.strictEqual(mockPool.connect.mock.calls.length, 1);
            const connectCall = mockPool.connect.mock.calls[0];
            assert.ok(connectCall, 'Connect should be called');

            // Verify ROLLBACK was called
            const calls = mockClient.query.mock.calls;
            const lastCall = calls[calls.length - 1]!;
            const lastCallArgs = lastCall.arguments as [string];
            assert.strictEqual(lastCallArgs[0], 'ROLLBACK');
        });
    });

    describe('getZombieCount()', () => {
        it('should return count from DB', async () => {
            mockPool.query.mock.mockImplementationOnce(async () => ({
                rows: [{ count: '5' }]
            }));

            const count = await worker.getZombieCount();
            assert.strictEqual(count, 5);
        });
    });
});
