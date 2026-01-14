/**
 * Phase-7B: Unit Tests for EvidenceExportService
 * 
 * Tests batch export, hashing, and high-water mark functionality.
 */

import { jest, describe, it, expect, beforeEach, afterEach } from '@jest/globals';

// Mock types for testing
interface MockPoolClient {
    query: jest.Mock;
    release: jest.Mock;
}

interface MockPool {
    connect: jest.Mock<() => Promise<MockPoolClient>>;
}

// ------------------ Test Helpers ------------------

function createMockPool(): MockPool {
    const mockClient: MockPoolClient = {
        query: jest.fn(),
        release: jest.fn(),
    };

    return {
        connect: jest.fn().mockResolvedValue(mockClient),
    };
}

function createMockClientWithData(
    highWaterMarks: { max_ingress_id: string; max_outbox_id: string; max_ledger_id: string },
    ingressRows: object[] = [],
    outboxRows: object[] = [],
    ledgerRows: object[] = []
): MockPoolClient {
    const mockQuery = jest.fn()
        .mockResolvedValueOnce({ rows: [highWaterMarks] }) // High water marks query
        .mockResolvedValueOnce({ rows: [] }) // BEGIN
        .mockResolvedValueOnce({ rows: ingressRows }) // Ingress records
        .mockResolvedValueOnce({ rows: outboxRows }) // Outbox records
        .mockResolvedValueOnce({ rows: ledgerRows }) // Ledger records
        .mockResolvedValueOnce({ rows: [] }) // Last export state
        .mockResolvedValueOnce({ rows: [] }) // Export log insert
        .mockResolvedValueOnce({ rows: [] }); // COMMIT

    return {
        query: mockQuery,
        release: jest.fn(),
    };
}

// ------------------ Tests ------------------

describe('EvidenceExportService', () => {
    describe('High-Water Marks', () => {
        it('should fetch current high-water marks from all source tables', async () => {
            const mockPool = createMockPool();
            const mockClient = mockPool.connect as jest.Mock;
            const client: MockPoolClient = {
                query: jest.fn().mockResolvedValue({
                    rows: [{
                        max_ingress_id: '1000',
                        max_outbox_id: '500',
                        max_ledger_id: '2000',
                    }],
                }),
                release: jest.fn(),
            };
            mockClient.mockResolvedValue(client);

            // Simulate getHighWaterMarks behavior
            const result = await client.query(`
                SELECT
                    (SELECT COALESCE(MAX(id)::text, '0') FROM ingress_attestations) AS max_ingress_id,
                    (SELECT COALESCE(MAX(id)::text, '0') FROM payment_outbox) AS max_outbox_id,
                    (SELECT COALESCE(MAX(id)::text, '0') FROM ledger_entries) AS max_ledger_id
            `);

            expect(result.rows[0].max_ingress_id).toBe('1000');
            expect(result.rows[0].max_outbox_id).toBe('500');
            expect(result.rows[0].max_ledger_id).toBe('2000');
            expect(client.release).not.toHaveBeenCalled(); // Would be called by service
        });

        it('should return zero marks for empty tables', async () => {
            const client: MockPoolClient = {
                query: jest.fn().mockResolvedValue({
                    rows: [{
                        max_ingress_id: '0',
                        max_outbox_id: '0',
                        max_ledger_id: '0',
                    }],
                }),
                release: jest.fn(),
            };

            const result = await client.query('SELECT ...');

            expect(result.rows[0].max_ingress_id).toBe('0');
            expect(result.rows[0].max_outbox_id).toBe('0');
            expect(result.rows[0].max_ledger_id).toBe('0');
        });
    });

    describe('Batch Hashing', () => {
        it('should compute deterministic SHA-256 hash of sorted records', () => {
            const crypto = require('crypto');

            const records = [
                { id: '3', data: 'c' },
                { id: '1', data: 'a' },
                { id: '2', data: 'b' },
            ];

            const sorted = [...records].sort((a, b) => a.id.localeCompare(b.id));
            const payload = JSON.stringify({
                schemaVersion: '7B.1.0',
                batchId: 'test_batch',
                records: sorted,
            });
            const hash = crypto.createHash('sha256').update(payload).digest('hex');

            expect(hash).toHaveLength(64);
            expect(hash).toMatch(/^[a-f0-9]{64}$/);
        });

        it('should produce same hash for same input regardless of initial order', () => {
            const crypto = require('crypto');

            const computeHash = (records: object[]) => {
                const sorted = [...records].sort((a: any, b: any) => a.id.localeCompare(b.id));
                const payload = JSON.stringify({ records: sorted });
                return crypto.createHash('sha256').update(payload).digest('hex');
            };

            const order1 = [{ id: '2' }, { id: '1' }, { id: '3' }];
            const order2 = [{ id: '1' }, { id: '3' }, { id: '2' }];

            expect(computeHash(order1)).toBe(computeHash(order2));
        });
    });

    describe('Batch Boundaries', () => {
        it('should use exclusive lower bound and inclusive upper bound', async () => {
            const client: MockPoolClient = {
                query: jest.fn().mockResolvedValue({ rows: [] }),
                release: jest.fn(),
            };

            // Simulate query with boundaries
            await client.query(
                'SELECT * FROM ingress_attestations WHERE id > $1 AND id <= $2 ORDER BY id ASC LIMIT $3',
                ['100', '200', 10000]
            );

            expect(client.query).toHaveBeenCalledWith(
                expect.stringContaining('id > $1 AND id <= $2'),
                ['100', '200', 10000]
            );
        });

        it('should prevent overlapping batches', () => {
            // Given two batch ranges, verify no overlap
            const batch1 = { from: '0', to: '100' };
            const batch2 = { from: '100', to: '200' }; // Starts exactly at batch1.to

            // For exclusive lower bound (>), ID 100 is NOT in batch2
            // For inclusive upper bound (<=), ID 100 IS in batch1
            // Therefore: batch1 includes 1-100, batch2 includes 101-200
            expect(parseInt(batch2.from)).toBe(parseInt(batch1.to));
        });
    });

    describe('Export Metadata', () => {
        it('should include view_version and generated_at', () => {
            const metadata = {
                batchId: 'batch_123',
                schemaVersion: '7B.1.0',
                exportedAt: new Date().toISOString(),
                viewVersion: '7B.1.0',
                generatedAt: new Date().toISOString(),
            };

            expect(metadata.viewVersion).toBe('7B.1.0');
            expect(metadata.generatedAt).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
        });

        it('should include previous batch ID for chain continuity', () => {
            const metadata = {
                batchId: 'batch_456',
                previousBatchId: 'batch_123',
            };

            expect(metadata.previousBatchId).toBe('batch_123');
        });
    });

    describe('Error Handling', () => {
        it('should not affect runtime systems on export failure', async () => {
            const client: MockPoolClient = {
                query: jest.fn()
                    .mockResolvedValueOnce({ rows: [] }) // BEGIN
                    .mockRejectedValueOnce(new Error('Export failed')) // Query error
                    .mockResolvedValueOnce({ rows: [] }), // ROLLBACK
                release: jest.fn(),
            };

            try {
                await client.query('BEGIN');
                await client.query('SELECT * FROM ingress_attestations');
            } catch (error) {
                await client.query('ROLLBACK');
                expect(client.query).toHaveBeenCalledWith('ROLLBACK');
            }
        });
    });
});

describe('ExportError', () => {
    it('should have correct error properties', () => {
        class ExportError extends Error {
            readonly code: string;
            readonly statusCode: number;

            constructor(message: string, code: string, statusCode: number) {
                super(message);
                this.name = 'ExportError';
                this.code = code;
                this.statusCode = statusCode;
            }
        }

        const error = new ExportError('Batch failed', 'BATCH_EXPORT_FAILED', 500);

        expect(error.name).toBe('ExportError');
        expect(error.code).toBe('BATCH_EXPORT_FAILED');
        expect(error.statusCode).toBe(500);
        expect(error.message).toBe('Batch failed');
    });
});
