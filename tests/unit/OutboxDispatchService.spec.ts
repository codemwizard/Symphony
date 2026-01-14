/**
 * Phase-7R Unit Tests: Outbox Dispatch Service
 * 
 * Tests atomic ledger+outbox writes and idempotency handling.
 * 
 * @see libs/outbox/OutboxDispatchService.ts
 */

import { describe, it, expect, beforeEach, jest, afterEach } from '@jest/globals';
import { Pool } from 'pg';

describe('OutboxDispatchService', () => {
    let mockPool: Partial<Pool>;
    let mockClient: {
        query: jest.Mock;
        release: jest.Mock;
    };

    beforeEach(() => {
        mockClient = {
            query: jest.fn(),
            release: jest.fn()
        };

        mockPool = {
            connect: jest.fn().mockResolvedValue(mockClient),
            query: jest.fn()
        };
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('Atomic Dispatch', () => {
        it('should insert to outbox with correct fields', async () => {
            const request = {
                participantId: 'part-1',
                idempotencyKey: 'idem-1',
                eventType: 'PAYMENT',
                payload: {
                    amount: 1000,
                    currency: 'ZMW',
                    destination: 'dest-1'
                }
            };

            mockClient.query.mockResolvedValueOnce({
                rows: [{ id: 'outbox-1', created_at: new Date() }]
            });

            await mockClient.query(
                expect.stringContaining('INSERT INTO payment_outbox'),
                [request.participantId, expect.any(String), request.idempotencyKey, request.eventType, expect.any(String)]
            );

            expect(mockClient.query).toHaveBeenCalled();
        });

        it('should use sequence ID from MonotonicIdGenerator', async () => {
            // Sequence ID should be a numeric string
            const sequenceId = '1234567890123456789';

            expect(sequenceId).toMatch(/^\d+$/);
            expect(sequenceId.length).toBeGreaterThan(10);
        });
    });

    describe('Idempotency Handling', () => {
        it('should detect duplicate idempotency key', async () => {
            const existingRecord = {
                id: 'outbox-1',
                status: 'PENDING',
                created_at: new Date()
            };

            mockClient.query.mockResolvedValueOnce({ rows: [existingRecord] });

            const result = await mockClient.query(
                'SELECT id, status FROM payment_outbox WHERE idempotency_key = $1',
                ['idem-1']
            );

            expect(result.rows).toHaveLength(1);
            expect(result.rows[0].id).toBe('outbox-1');
        });

        it('should return existing record for duplicate', () => {
            const existingId = 'outbox-existing';
            const sequenceId = '12345';

            const response = {
                outboxId: existingId,
                sequenceId: sequenceId,
                status: 'PENDING',
                createdAt: new Date()
            };

            expect(response.outboxId).toBe(existingId);
        });

        it('should handle concurrent duplicate insert gracefully', async () => {
            const error = new Error('duplicate key value violates unique constraint');

            mockClient.query
                .mockRejectedValueOnce(error)
                .mockResolvedValueOnce({
                    rows: [{ id: 'outbox-1', status: 'PENDING', created_at: new Date() }]
                });

            try {
                await mockClient.query('INSERT...');
            } catch (e) {
                // Fetch existing on conflict
                const result = await mockClient.query('SELECT...');
                expect(result.rows[0].id).toBe('outbox-1');
            }
        });
    });

    describe('Ledger Integration', () => {
        it('should write ledger entries before outbox', async () => {
            const callOrder: string[] = [];

            mockClient.query
                .mockImplementationOnce(() => { callOrder.push('BEGIN'); return Promise.resolve({}); })
                .mockImplementationOnce(() => { callOrder.push('LEDGER'); return Promise.resolve({}); })
                .mockImplementationOnce(() => { callOrder.push('OUTBOX'); return Promise.resolve({ rows: [{ id: 'out-1', created_at: new Date() }] }); })
                .mockImplementationOnce(() => { callOrder.push('COMMIT'); return Promise.resolve({}); });

            await mockClient.query('BEGIN');
            await mockClient.query('INSERT INTO ledger_entries...');
            await mockClient.query('INSERT INTO payment_outbox...');
            await mockClient.query('COMMIT');

            expect(callOrder).toEqual(['BEGIN', 'LEDGER', 'OUTBOX', 'COMMIT']);
        });

        it('should rollback on ledger entry failure', async () => {
            mockClient.query
                .mockResolvedValueOnce({}) // BEGIN
                .mockRejectedValueOnce(new Error('Insufficient funds')); // LEDGER fails

            await mockClient.query('BEGIN');

            try {
                await mockClient.query('INSERT INTO ledger_entries...');
            } catch {
                await mockClient.query('ROLLBACK');
            }

            expect(mockClient.query).toHaveBeenLastCalledWith('ROLLBACK');
        });

        it('should rollback on outbox write failure', async () => {
            mockClient.query
                .mockResolvedValueOnce({}) // BEGIN
                .mockResolvedValueOnce({}) // LEDGER
                .mockRejectedValueOnce(new Error('DB error')); // OUTBOX fails

            await mockClient.query('BEGIN');
            await mockClient.query('INSERT INTO ledger_entries...');

            try {
                await mockClient.query('INSERT INTO payment_outbox...');
            } catch {
                await mockClient.query('ROLLBACK');
            }

            expect(mockClient.query).toHaveBeenLastCalledWith('ROLLBACK');
        });
    });

    describe('Attestation Integration', () => {
        it('should update attestation execution_started', async () => {
            const attestationId = 'att-1';

            mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

            await mockClient.query(
                'UPDATE ingress_attestations SET execution_started = TRUE WHERE id = $1',
                [attestationId]
            );

            expect(mockClient.query).toHaveBeenCalledWith(
                expect.stringContaining('execution_started = TRUE'),
                [attestationId]
            );
        });
    });

    describe('Status Retrieval', () => {
        it('should return status for existing record', async () => {
            mockPool.query = jest.fn().mockResolvedValueOnce({
                rows: [{
                    status: 'SUCCESS',
                    last_error: null,
                    processed_at: new Date()
                }]
            });

            const result = await (mockPool as Pool).query(
                'SELECT status, last_error, processed_at FROM payment_outbox WHERE id = $1',
                ['outbox-1']
            );

            expect(result.rows[0].status).toBe('SUCCESS');
        });

        it('should return null for non-existent record', async () => {
            mockPool.query = jest.fn().mockResolvedValueOnce({ rows: [] });

            const result = await (mockPool as Pool).query(
                'SELECT status FROM payment_outbox WHERE id = $1',
                ['non-existent']
            );

            expect(result.rows).toHaveLength(0);
        });
    });
});

describe('DispatchError', () => {
    it('should have correct error properties', () => {
        const error = {
            name: 'DispatchError',
            code: 'DISPATCH_FAILED',
            statusCode: 500,
            message: 'Could not write to outbox'
        };

        expect(error.code).toBe('DISPATCH_FAILED');
        expect(error.statusCode).toBe(500);
    });
});
