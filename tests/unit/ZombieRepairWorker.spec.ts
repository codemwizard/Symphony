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
import { ZombieRepairWorker } from '../../libs/repair/ZombieRepairWorker.js';
import { DbRole } from '../../libs/db/roles.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

describe('ZombieRepairWorker', () => {
    let worker: ZombieRepairWorker;
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };
    let mockClient: { query: ReturnType<typeof mock.fn> };


    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [], rowCount: 0 }))
        };
        mockDb = {
            queryAsRole: mock.fn(async () => ({ rows: [], rowCount: 0 })),
            transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            withRoleClient: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            probeRoles: mock.fn(async () => undefined)
        };
        worker = new ZombieRepairWorker('symphony_executor', mockDb as unknown as DbClient);
    });

    describe('runRepairCycle()', () => {
        it('should execute repair queries with correct SQL', async () => {
            // Mock DB response to ensure all branches are taken
            mockClient.query.mock.mockImplementation(async (sql: string) => {
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

        it('should execute through transaction wrapper', async () => {
            const result = await worker.runRepairCycle();

            assert.ok(result);
            assert.strictEqual(mockDb.transactionAsRole.mock.calls.length, 1);
        });

        it('should rollback on error', async () => {
            mockClient.query.mock.mockImplementation(async () => {
                throw new Error('DB Failure');
            });

            const result = await worker.runRepairCycle();

            assert.strictEqual(result.errors.length, 1);
            assert.strictEqual(result.errors[0], 'DB Failure');

            assert.strictEqual(mockDb.transactionAsRole.mock.calls.length, 1);
        });
    });

    describe('getZombieCount()', () => {
        it('should return count from DB', async () => {
            mockDb.queryAsRole.mock.mockImplementationOnce(async () => ({
                rows: [{ count: '5' }]
            }));

            const count = await worker.getZombieCount();
            assert.strictEqual(count, 5);
        });
    });
});
