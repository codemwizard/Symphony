/**
 * Unit Tests: Zombie Repair Worker
 * 
 * Tests temporal idempotency and ghost reconciliation.
 * Refactored to use node:test and call production code.
 * 
 * @see libs/repair/ZombieRepairWorker.ts
 */

import { describe, it, before, beforeEach, mock } from 'node:test';
import assert from 'node:assert';
import { Pool } from 'pg';

describe('ZombieRepairWorker', () => {
    let ZombieRepairWorker: typeof import('../../libs/repair/ZombieRepairWorker.js').ZombieRepairWorker;
    let worker: InstanceType<typeof import('../../libs/repair/ZombieRepairWorker.js').ZombieRepairWorker>;
    let mockPool: { connect: ReturnType<typeof mock.fn>; query: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };

    before(async () => {
        const module = await import('../../libs/repair/ZombieRepairWorker.js');
        ZombieRepairWorker = module.ZombieRepairWorker;
    });

    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [], rowCount: 0 })),
            release: mock.fn()
        };
        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn()
        };
        worker = new ZombieRepairWorker(mockPool as unknown as Pool);
    });

    describe('runRepairCycle()', () => {
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
