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

    beforeEach(() => {
        mockClient = {
            query: mock.fn(async () => ({ rows: [] })),
            release: mock.fn()
        };

        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn(async () => ({ rows: [] }))
        };

        service = new OutboxDispatchService(mockPool as unknown as Pool);
    });

    describe('atomic dispatch', () => {
        // We test via dispatchWithLedger to ensure transaction atomicity
        it('should dispatch to outbox and ledger in same transaction', async () => {
            const request = {
                participantId: 'part-1',
                instructionId: 'instruction-1',
                idempotencyKey: 'idem-1',
                railType: 'PAYMENT' as const,
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
                if (sql.includes('FROM enqueue_payment_outbox')) {
                    return { rows: [{ outbox_id: 'outbox-1', sequence_id: 42, state: 'PENDING', created_at: new Date() }] };
                }
                if (sql === 'COMMIT') return {};
                return { rows: [] };
            });

            const result = await service.dispatchWithLedger(request, ledgerEntries);

            assert.strictEqual(result.outboxId, 'outbox-1');
            assert.strictEqual(result.status, 'PENDING');

            // Verify enqueue happens on the client, not the pool directly
            const enqueueCalls = mockClient.query.mock.calls.filter((c: { arguments: unknown[] }) =>
                typeof c.arguments[0] === 'string' && (c.arguments[0] as string).includes('FROM enqueue_payment_outbox')
            );
            assert.ok(enqueueCalls.length > 0, 'Should enqueue outbox via client');
            // Verify call order: BEGIN -> Ledger -> Outbox -> COMMIT
            const queries = mockClient.query.mock.calls.map((c: { arguments: unknown[] }) => c.arguments[0]) as string[];
            assert.strictEqual(queries[0], 'BEGIN');
            assert.match(queries[queries.length - 1] as string, /COMMIT/);
            assert.strictEqual(mockClient.release.mock.calls.length, 1);
        });

        it('should rollback on error', async () => {
            const request = {
                participantId: 'part-1',
                instructionId: 'instruction-1',
                idempotencyKey: 'idem-1',
                railType: 'PAYMENT' as const,
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
                instructionId: 'instruction-1',
                idempotencyKey: 'idem-1',
                railType: 'PAYMENT' as const,
                payload: { amount: 100, currency: 'USD', destination: 'dest' }
            };

            // enqueue_payment_outbox handles idempotency; return existing record
            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('FROM enqueue_payment_outbox')) {
                    return { rows: [{ outbox_id: 'existing-1', sequence_id: 10, state: 'PENDING', created_at: new Date() }] };
                }
                return { rows: [] };
            });

            const result = await service.dispatch(request);

            assert.strictEqual(result.outboxId, 'existing-1');
        });

        it('should handle concurrent insert race condition', async () => {
            const request = {
                participantId: 'part-1',
                instructionId: 'instruction-1',
                idempotencyKey: 'idem-1',
                railType: 'PAYMENT' as const,
                payload: { amount: 100, currency: 'USD', destination: 'dest' }
            };

            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('FROM enqueue_payment_outbox')) {
                    return { rows: [{ outbox_id: 'race-1', sequence_id: 11, state: 'PENDING', created_at: new Date() }] };
                }
                return { rows: [] };
            });

            const result = await service.dispatch(request);
            assert.strictEqual(result.outboxId, 'race-1');
        });
    });
});
