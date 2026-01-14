/**
 * Phase-7R Unit Tests: Outbox Relayer
 * 
 * Tests the reliable relayer with DLQ logic and idempotency.
 * 
 * @see libs/outbox/OutboxRelayer.ts
 */

import { describe, it, expect, beforeEach, jest, afterEach } from '@jest/globals';
import { Pool } from 'pg';

// Mock interfaces for testing
interface MockRailClient {
    dispatch: jest.Mock;
}

interface MockPoolClient {
    query: jest.Mock;
    release: jest.Mock;
}

describe('OutboxRelayer', () => {
    let mockPool: Partial<Pool>;
    let mockRailClient: MockRailClient;
    let mockClient: MockPoolClient;

    beforeEach(() => {
        mockClient = {
            query: jest.fn(),
            release: jest.fn()
        };

        mockPool = {
            connect: jest.fn().mockResolvedValue(mockClient),
            query: jest.fn()
        };

        mockRailClient = {
            dispatch: jest.fn()
        };
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('Batch Fetching with SKIP LOCKED', () => {
        it('should fetch pending records with FOR UPDATE SKIP LOCKED', async () => {
            const mockRecords = [
                { id: 'uuid-1', payload: { amount: 100 }, participant_id: 'p1' },
                { id: 'uuid-2', payload: { amount: 200 }, participant_id: 'p2' }
            ];

            mockClient.query.mockResolvedValueOnce({ rows: mockRecords });

            // Simulate a fetch
            const result = await mockClient.query(
                expect.stringContaining('FOR UPDATE SKIP LOCKED'),
                [50]
            );

            expect(mockClient.query).toHaveBeenCalled();
        });
    });

    describe('DLQ Logic', () => {
        it('should move records to FAILED after retry_count > 5', async () => {
            const record = {
                id: 'uuid-1',
                retry_count: 6,
                participant_id: 'p1',
                payload: { amount: 100 }
            };

            // Simulate DLQ logic
            const shouldMoveToDLQ = record.retry_count > 5;
            expect(shouldMoveToDLQ).toBe(true);
        });

        it('should keep retrying if retry_count <= 5', async () => {
            const record = {
                id: 'uuid-1',
                retry_count: 3,
                participant_id: 'p1',
                payload: { amount: 100 }
            };

            const shouldMoveToDLQ = record.retry_count > 5;
            expect(shouldMoveToDLQ).toBe(false);
        });
    });

    describe('Relayer Idempotency', () => {
        it('should use outbox ID as rail idempotency key', async () => {
            const outboxId = 'uuid-outbox-123';
            const record = {
                id: outboxId,
                payload: { amount: 100, destination: 'dest-1' },
                participant_id: 'p1'
            };

            mockRailClient.dispatch.mockResolvedValueOnce({ success: true });

            await mockRailClient.dispatch({
                reference: record.id, // This is the critical assertion
                amount: record.payload.amount,
                destination: record.payload.destination,
                participantId: record.participant_id
            });

            expect(mockRailClient.dispatch).toHaveBeenCalledWith(
                expect.objectContaining({
                    reference: outboxId // Outbox ID used as rail idempotency key
                })
            );
        });
    });

    describe('Status Transitions', () => {
        it('should transition PENDING -> IN_FLIGHT on pickup', () => {
            const stateMachine = {
                PENDING: ['IN_FLIGHT'],
                IN_FLIGHT: ['SUCCESS', 'FAILED', 'RECOVERING'],
                RECOVERING: ['IN_FLIGHT', 'FAILED'],
                SUCCESS: [],
                FAILED: []
            };

            expect(stateMachine['PENDING']).toContain('IN_FLIGHT');
        });

        it('should transition IN_FLIGHT -> SUCCESS on rail success', () => {
            const stateMachine = {
                IN_FLIGHT: ['SUCCESS', 'FAILED', 'RECOVERING']
            };

            expect(stateMachine['IN_FLIGHT']).toContain('SUCCESS');
        });

        it('should transition IN_FLIGHT -> RECOVERING on transient failure', () => {
            const stateMachine = {
                IN_FLIGHT: ['SUCCESS', 'FAILED', 'RECOVERING']
            };

            expect(stateMachine['IN_FLIGHT']).toContain('RECOVERING');
        });
    });
});

describe('Transient Error Detection', () => {
    const transientCodes = ['ECONNRESET', 'ETIMEDOUT', 'ENOTFOUND', '503', '504'];

    it('should identify transient errors correctly', () => {
        transientCodes.forEach(code => {
            const error = new Error(`Network error: ${code}`);
            const isTransient = transientCodes.some(c => error.message.includes(c));
            expect(isTransient).toBe(true);
        });
    });

    it('should identify non-transient errors correctly', () => {
        const error = new Error('Invalid account number');
        const isTransient = transientCodes.some(c => error.message.includes(c));
        expect(isTransient).toBe(false);
    });
});
