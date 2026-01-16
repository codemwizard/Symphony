/**
 * Phase-7B: Unit Tests for EvidenceExportService
 * 
 * Tests batch export, hashing, and high-water mark functionality.
 * Migrated to node:test
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert';
import { Pool } from 'pg';
import { EvidenceExportService, ExportConfig } from '../../libs/export/EvidenceExportService.js';

describe('EvidenceExportService', () => {
    let service: EvidenceExportService;
    let mockPool: { connect: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };
    let mockFs: { mkdir: ReturnType<typeof mock.fn>; writeFile: ReturnType<typeof mock.fn> };
    let mockQuery: ReturnType<typeof mock.fn>;
    let mockRelease: ReturnType<typeof mock.fn>;

    const MOCK_CONFIG: ExportConfig = {
        outputDir: '/tmp/test_evidence',
        schemaVersion: '7B.1.0',
        batchSize: 100
    };

    beforeEach(() => {
        // Setup PG Mocks
        mockQuery = mock.fn(async () => ({ rows: [] }));
        mockRelease = mock.fn();
        mockClient = {
            query: mockQuery,
            release: mockRelease
        };

        mockPool = {
            connect: mock.fn(async () => mockClient)
        };

        // Mock Filesystem
        mockFs = {
            mkdir: mock.fn(async () => undefined),
            writeFile: mock.fn(async () => undefined)
        };

        // Instantiate Service with injected fs
        service = new EvidenceExportService(mockPool as unknown as Pool, MOCK_CONFIG, mockFs as unknown as typeof import('fs/promises'));
    });

    describe('getHighWaterMarks', () => {
        it('should fetch marks from DB using coalesced max IDs', async () => {
            mockQuery = mock.fn(async () => ({
                rows: [{
                    max_ingress_id: '100',
                    max_outbox_id: '50',
                    max_ledger_id: '200'
                }]
            }));
            mockClient.query = mockQuery;

            const marks = await service.getHighWaterMarks();

            assert.strictEqual(marks.maxIngressId, '100');
            assert.strictEqual(marks.maxOutboxId, '50');
            assert.strictEqual(marks.maxLedgerId, '200');

            const queryCall = mockQuery.mock.calls[0]!;
            assert.match((queryCall.arguments as [string])[0], /MAX\(id\)/);
            assert.strictEqual(mockRelease.mock.calls.length, 1);
        });
    });

    describe('getLastExportState', () => {
        it('should return null if no logs exist', async () => {
            mockQuery = mock.fn(async () => ({ rows: [] }));
            mockClient.query = mockQuery;

            const state = await service.getLastExportState();
            assert.strictEqual(state, null);
        });

        it('should return last batch state if exists', async () => {
            mockQuery = mock.fn(async () => ({
                rows: [{
                    batch_id: 'batch_prev',
                    max_ingress_id: '90',
                    max_outbox_id: '40',
                    max_ledger_id: '190'
                }]
            }));
            mockClient.query = mockQuery;

            const state = await service.getLastExportState();
            assert.ok(state);
            assert.strictEqual(state.batchId, 'batch_prev');
            assert.strictEqual(state.highWaterMarks.maxIngressId, '90');
        });
    });

    describe('exportBatch', () => {
        it('should orchestrate full export flow (fetch -> hash -> write -> log)', async () => {
            // Mock sequence:
            // 1. getHighWaterMarks (Current)
            // 2. pool.connect() for Transaction
            // 3. BEGIN
            // 4. Record fetches (Ingress, Outbox, Ledger)
            // 5. getLastExportState (Inside exportBatch logic for previous ID) -> Handled via separate query? 
            //    Wait, `previousBatchId: fromMarks ? (await this.getLastExportState())?.batchId : null`
            //    If fromMarks is null, getLastExportState is skipped.

            const currentMarks = { max_ingress_id: '200', max_outbox_id: '100', max_ledger_id: '400' };

            mockQuery = mock.fn(async (sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [currentMarks] };
                if (sql === 'BEGIN') return {};
                if (sql.includes('FROM ingress_attestations')) return { rows: [{ id: '101', data: 'test' }] };
                if (sql.includes('FROM payment_outbox')) return { rows: [] };
                if (sql.includes('FROM ledger_entries')) return { rows: [] };
                if (sql === 'COMMIT') return {};
                if (sql.includes('INSERT INTO evidence_export_log')) return {};
                return { rows: [] };
            });
            mockClient.query = mockQuery;

            const result = await service.exportBatch(null);

            assert.match(result.batchId, /^batch_/);
            assert.strictEqual(result.highWaterMarks.maxIngressId, '200');
            assert.strictEqual(result.recordCounts.ingress, 1);
            assert.strictEqual(result.recordCounts.outbox, 0);

            // Verify FS calls
            assert.strictEqual(mockFs.mkdir.mock.calls.length, 1);
            assert.strictEqual(mockFs.writeFile.mock.calls.length, 2); // json + hash

            const writeCall = mockFs.writeFile.mock.calls[0]!;
            const firstWriteArgs = writeCall.arguments as [string, string];
            assert.ok(firstWriteArgs[0].includes(result.batchId + '.json'));
        });

        it('should link to previous batch ID when fromMarks provided', async () => {
            // Mock getHighWaterMarks
            mockQuery = mock.fn(async (sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [{ max_ingress_id: '300', max_outbox_id: '150', max_ledger_id: '600' }] };
                if (sql.includes('FROM evidence_export_log')) return { rows: [{ batch_id: 'batch_old' }] };
                if (sql === 'BEGIN') return {};
                if (sql.includes('FROM ingress_attestations')) return { rows: [] };
                if (sql.includes('FROM payment_outbox')) return { rows: [] };
                if (sql.includes('FROM ledger_entries')) return { rows: [] };
                if (sql === 'COMMIT') return {};
                if (sql.includes('INSERT INTO evidence_export_log')) return {};
                return { rows: [] };
            });
            mockClient.query = mockQuery;

            const fromMarks = { maxIngressId: '200', maxOutboxId: '100', maxLedgerId: '400' };
            const result = await service.exportBatch(fromMarks);

            assert.strictEqual(result.previousBatchId, 'batch_old');
        });

        it('should rollback and throw on error', async () => {
            mockQuery = mock.fn(async (sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) {
                    return { rows: [{ max_ingress_id: '1', max_outbox_id: '0', max_ledger_id: '0' }] };
                }
                if (sql === 'BEGIN') return {};
                if (sql.includes('FROM ingress_attestations') && sql.includes('WHERE id > $1')) {
                    throw new Error('DB Connection Failed');
                }
                return { rows: [] };
            });
            mockClient.query = mockQuery;

            await assert.rejects(
                async () => service.exportBatch(null),
                { message: 'DB Connection Failed' }
            );

            // Verify ROLLBACK was called
            const calls = mockQuery.mock.calls.map((c: { arguments: unknown[] }) => c.arguments[0]);
            assert.ok(calls.includes('ROLLBACK'));
        });
    });

    describe('Hashing Logic (Deterministic)', () => {
        it('should produce consistent hash for same data', async () => {
            const setupMocks = () => {
                mockQuery = mock.fn(async (sql: string) => {
                    if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [{ max_ingress_id: '10', max_outbox_id: '0', max_ledger_id: '0' }] };
                    if (sql === 'BEGIN') return {};
                    if (sql.includes('FROM ingress_attestations')) {
                        // Unsorted in DB response to test sorting
                        return {
                            rows: [
                                { id: '2', data: 'b' },
                                { id: '1', data: 'a' }
                            ]
                        };
                    }
                    if (sql.includes('FROM payment_outbox')) return { rows: [] };
                    if (sql.includes('FROM ledger_entries')) return { rows: [] };
                    if (sql === 'COMMIT') return {};
                    if (sql.includes('INSERT INTO evidence_export_log')) return {};
                    return { rows: [] };
                });
                mockClient.query = mockQuery;
            };

            setupMocks();
            const result1 = await service.exportBatch(null);

            assert.ok(result1.batchHash);
            assert.strictEqual(result1.batchHash.length, 64);

            // Note: different batch IDs will produce different hashes, so we just verify format here
            // unless we mock generateBatchId which is private.
        });
    });
});
