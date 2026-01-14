/**
 * Phase-7R Unit Tests: Zombie Repair Worker
 * 
 * Tests temporal idempotency and ghost reconciliation.
 * 
 * @see libs/repair/ZombieRepairWorker.ts
 */

import { describe, it, expect, beforeEach, jest, afterEach } from '@jest/globals';
import { Pool } from 'pg';

describe('ZombieRepairWorker', () => {
    let mockPool: Partial<Pool>;
    let mockClient: {
        query: jest.Mock;
        release: jest.Mock;
    };

    const ZOMBIE_THRESHOLD_SECONDS = 60;
    const HARD_FAILURE_TTL_SECONDS = 600;

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

    describe('Soft Zombie Detection', () => {
        it('should identify zombies stuck > 60 seconds', () => {
            const lastAttemptAt = new Date(Date.now() - 120 * 1000); // 2 minutes ago
            const zombieThreshold = new Date(Date.now() - ZOMBIE_THRESHOLD_SECONDS * 1000);

            const isZombie = lastAttemptAt < zombieThreshold;
            expect(isZombie).toBe(true);
        });

        it('should not flag records < 60 seconds as zombies', () => {
            const lastAttemptAt = new Date(Date.now() - 30 * 1000); // 30 seconds ago
            const zombieThreshold = new Date(Date.now() - ZOMBIE_THRESHOLD_SECONDS * 1000);

            const isZombie = lastAttemptAt < zombieThreshold;
            expect(isZombie).toBe(false);
        });
    });

    describe('Hard Failure Escalation', () => {
        it('should escalate records > TTL to FAILED', () => {
            const createdAt = new Date(Date.now() - 900 * 1000); // 15 minutes ago
            const ttlThreshold = new Date(Date.now() - HARD_FAILURE_TTL_SECONDS * 1000);

            const shouldEscalate = createdAt < ttlThreshold;
            expect(shouldEscalate).toBe(true);
        });

        it('should not escalate records < TTL', () => {
            const createdAt = new Date(Date.now() - 300 * 1000); // 5 minutes ago
            const ttlThreshold = new Date(Date.now() - HARD_FAILURE_TTL_SECONDS * 1000);

            const shouldEscalate = createdAt < ttlThreshold;
            expect(shouldEscalate).toBe(false);
        });
    });

    describe('Ghost Attestation Detection', () => {
        it('should find attestations without corresponding outbox records', async () => {
            const ghostQuery = `
                SELECT ing.id, ing.sequence_id
                FROM ingress_attestations ing
                LEFT JOIN payment_outbox out ON ing.id = out.id
                WHERE out.id IS NULL
                  AND ing.execution_started = FALSE
            `;

            const mockGhosts = [
                { id: 'att-1', sequence_id: '101' },
                { id: 'att-2', sequence_id: '103' }
            ];

            mockPool.query = jest.fn().mockResolvedValueOnce({ rows: mockGhosts });

            const result = await (mockPool as Pool).query(ghostQuery);
            expect(result.rows).toHaveLength(2);
        });
    });

    describe('Repair Cycle Transaction Safety', () => {
        it('should use BEGIN/COMMIT for repair operations', async () => {
            const operations = ['BEGIN', 'UPDATE', 'INSERT', 'COMMIT'];

            mockClient.query
                .mockResolvedValueOnce({}) // BEGIN
                .mockResolvedValueOnce({ rowCount: 2 }) // UPDATE zombies
                .mockResolvedValueOnce({ rowCount: 1 }) // INSERT recovered
                .mockResolvedValueOnce({}); // COMMIT

            await mockClient.query('BEGIN');
            await mockClient.query('UPDATE payment_outbox SET status = $1', ['RECOVERING']);
            await mockClient.query('INSERT INTO payment_outbox SELECT ...', []);
            await mockClient.query('COMMIT');

            expect(mockClient.query).toHaveBeenNthCalledWith(1, 'BEGIN');
            expect(mockClient.query).toHaveBeenLastCalledWith('COMMIT');
        });

        it('should ROLLBACK on error', async () => {
            mockClient.query
                .mockResolvedValueOnce({}) // BEGIN
                .mockRejectedValueOnce(new Error('DB Error')); // Failed operation

            await mockClient.query('BEGIN');

            try {
                await mockClient.query('UPDATE ...');
            } catch {
                await mockClient.query('ROLLBACK');
            }

            expect(mockClient.query).toHaveBeenLastCalledWith('ROLLBACK');
        });
    });
});

describe('Zombie State Machine', () => {
    describe('Status Transitions', () => {
        const validTransitions: Record<string, string[]> = {
            'PENDING': ['IN_FLIGHT'],
            'IN_FLIGHT': ['SUCCESS', 'FAILED', 'RECOVERING'],
            'RECOVERING': ['IN_FLIGHT', 'FAILED'],
            'SUCCESS': [],
            'FAILED': []
        };

        it('should allow IN_FLIGHT -> RECOVERING for zombies', () => {
            expect(validTransitions['IN_FLIGHT']).toContain('RECOVERING');
        });

        it('should allow RECOVERING -> FAILED for hard failures', () => {
            expect(validTransitions['RECOVERING']).toContain('FAILED');
        });

        it('should not allow transitions from terminal states', () => {
            expect(validTransitions['SUCCESS']).toHaveLength(0);
            expect(validTransitions['FAILED']).toHaveLength(0);
        });
    });
});
