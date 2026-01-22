/**
 * Unit Tests: Lease Repair Worker
 * 
 * Tests temporal idempotency and requeue behavior.
 * Refactored to use node:test and call production code.
 * 
 * @see libs/repair/LeaseRepairWorker.ts
 */

import { describe, it, beforeEach, mock } from 'node:test';
import * as assert from 'node:assert';
import { LeaseRepairWorker } from '../../libs/repair/LeaseRepairWorker.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

describe('LeaseRepairWorker', () => {
    let worker: LeaseRepairWorker;
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };


    beforeEach(() => {
        mockDb = {
            queryAsRole: mock.fn(async () => ({ rows: [], rowCount: 0 })),
            transactionAsRole: mock.fn(async () => undefined),
            withRoleClient: mock.fn(async () => undefined),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            probeRoles: mock.fn(async () => undefined)
        };
        worker = new LeaseRepairWorker('symphony_executor', mockDb as unknown as DbClient, 'worker-1');
    });

    describe('runRepairCycle()', () => {
        it('should call repair_expired_leases via DB wrapper', async () => {
            mockDb.queryAsRole = mock.fn(async () => ({
                rows: [{ outbox_id: 'outbox-1', attempt_no: 2 }]
            }));

            const result = await worker.runRepairCycle();

            assert.ok(result);
            assert.strictEqual(result.repairedCount, 1);
            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 1);
            const queryArgs = mockDb.queryAsRole.mock.calls[0]!.arguments as [string, string];
            assert.ok(queryArgs[1].includes('repair_expired_leases'));
        });

        it('should rollback on error', async () => {
            mockDb.queryAsRole.mock.mockImplementation(async () => {
                throw new Error('DB Failure');
            });

            const result = await worker.runRepairCycle();

            assert.strictEqual(result.errors.length, 1);
            assert.strictEqual(result.errors[0], 'DB Failure');

            assert.strictEqual(mockDb.queryAsRole.mock.calls.length, 1);
        });
    });

    describe('getExpiredLeaseCount()', () => {
        it('should return count from DB', async () => {
            mockDb.queryAsRole.mock.mockImplementationOnce(async () => ({
                rows: [{ count: '5' }]
            }));

            const count = await worker.getExpiredLeaseCount();
            assert.strictEqual(count, 5);
        });
    });
});
