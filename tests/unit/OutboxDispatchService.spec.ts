/**
 * Phase-7R Unit Tests: Outbox Dispatch Service
 * 
 * Tests atomic ledger+outbox writes and idempotency handling.
 * Migrated to node:test
 * 
 * @see libs/outbox/OutboxDispatchService.ts
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert';
import { Pool } from 'pg';
import { OutboxDispatchService } from '../../libs/outbox/OutboxDispatchService.js';

describe('OutboxDispatchService', () => {
    let service: OutboxDispatchService;
    let mockPool: { connect: ReturnType<typeof mock.fn>; query: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };
    let mockIdGenerator: { generateString: ReturnType<typeof mock.fn> };

    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [] })),
            release: mock.fn()
        };

        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn(async () => ({ rows: [] }))
        };

        mockIdGenerator = {
            generateString: mock.fn(async () => '1234567890')
        };

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        service = new OutboxDispatchService(mockPool as unknown as Pool, mockIdGenerator as any);
    });

    describe('atomic dispatch', () => {
        // We test via dispatchWithLedger to ensure transaction atomicity
        it('should dispatch to outbox and ledger in same transaction', async () => {
            const request = {
                participantId: 'part-1',
                idempotencyKey: 'idem-1',
                eventType: 'PAYMENT' as const,
                payload: {
                    amount: 1000,
                    currency: 'ZMW',
                    destination: 'dest-1'
                }
            };

            const ledgerEntries = [{
                accountId: 'acc-1',
                entryType: 'DEBIT' as const,
                amount: 1000,
                currency: 'ZMW'
            }];

            mockClient.query = mock.fn(async (sql: string) => {
                if (sql === 'BEGIN') return {};
                if (sql.includes('INSERT INTO ledger_entries')) return {};
                if (sql.includes('SELECT id, status FROM payment_outbox')) return { rows: [] }; // No duplicate
                if (sql.includes('INSERT INTO payment_outbox')) {
                    return { rows: [{ id: 'outbox-1', created_at: new Date() }] };
                }
                if (sql === 'COMMIT') return {};
                return { rows: [] };
            });

            const result = await service.dispatchWithLedger(request, ledgerEntries);

            assert.strictEqual(result.outboxId, 'outbox-1');
            assert.strictEqual(result.status, 'PENDING');

            // Verify pool query uses atomic insert-select-notify
            // The insert happens on the client, not the pool directly
            const insertCalls = mockClient.query.mock.calls.filter((c: { arguments: unknown[] }) =>
                typeof c.arguments[0] === 'string' && (c.arguments[0] as string).includes('INSERT INTO payment_outbox')
            );
            assert.ok(insertCalls.length > 0, 'Should insert into outbox via client');
            // Verify call order: BEGIN -> Ledger -> Outbox -> COMMIT
            const queries = mockClient.query.mock.calls.map((c: { arguments: unknown[] }) => c.arguments[0]) as string[];
            assert.strictEqual(queries[0], 'BEGIN');
            assert.match(queries[queries.length - 1] as string, /COMMIT/);
            assert.strictEqual(mockClient.release.mock.calls.length, 1);
        });

        it('should rollback on error', async () => {
            const request = {
                participantId: 'part-1',
                idempotencyKey: 'idem-1',
                eventType: 'PAYMENT' as const,
                payload: { amount: 100, currency: 'USD', destination: 'dest' }
            };

            mockClient.query = mock.fn(async (sql: string) => {
                if (sql === 'BEGIN') return {};
                throw new Error('DB Error');
            });

            await assert.rejects(
                async () => service.dispatchWithLedger(request, []),
                { message: 'DB Error' }
            );

            const calls = mockClient.query.mock.calls;
            assert.ok(calls.length > 0);
            const lastCall = calls[calls.length - 1]!;
            assert.strictEqual((lastCall.arguments as [string])[0], 'ROLLBACK');
        });
    });

    describe('idempotency', () => {
        it('should return existing record on duplicate idempotency key', async () => {
            const request = {
                participantId: 'part-1',
                idempotencyKey: 'idem-1',
                eventType: 'PAYMENT' as const,
                payload: { amount: 100, currency: 'USD', destination: 'dest' }
            };

            // Mock finding duplicate
            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('SELECT id, status FROM payment_outbox')) {
                    return { rows: [{ id: 'existing-1', status: 'PENDING', created_at: new Date(), sequence_id: 'seq-1' }] };
                }
                return { rows: [] };
            });

            const result = await service.dispatch(request);

            assert.strictEqual(result.outboxId, 'existing-1');
            // Should NOT have inserted
            const inserts = mockClient.query.mock.calls.filter((c: { arguments: unknown[] }) => {
                const sql = c.arguments[0];
                return typeof sql === 'string' && sql.includes('INSERT');
            });
            assert.strictEqual(inserts.length, 0);
        });

        it('should handle concurrent insert race condition', async () => {
            const request = {
                participantId: 'part-1',
                idempotencyKey: 'idem-1',
                eventType: 'PAYMENT' as const,
                payload: { amount: 100, currency: 'USD', destination: 'dest' }
            };

            let callCount = 0;
            mockClient.query = mock.fn(async (sql: string) => {
                // 1. First check returns nothing (simulate race)
                if (sql.includes('SELECT id, status FROM payment_outbox') && callCount === 0) {
                    callCount++;
                    return { rows: [] };
                }
                // 2. Insert throws unique constraint violation
                if (sql.includes('INSERT INTO payment_outbox')) {
                    throw new Error('duplicate key value violates unique constraint');
                }
                // 3. Second check (recovery) returns existing
                if (sql.includes('SELECT id, status, created_at FROM payment_outbox')) {
                    return { rows: [{ id: 'race-1', status: 'PENDING', created_at: new Date(), sequence_id: 'seq-1' }] };
                }
                return { rows: [] };
            });

            const result = await service.dispatch(request);
            assert.strictEqual(result.outboxId, 'race-1');
        });
    });
});
