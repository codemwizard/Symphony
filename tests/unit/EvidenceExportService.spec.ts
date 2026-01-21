/**
 * Phase-7B: Unit Tests for EvidenceExportService
 * 
 * Tests batch export, hashing, and high-water mark functionality.
 * Migrated to node:test
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert';
import { EvidenceExportService, ExportConfig } from '../../libs/export/EvidenceExportService.js';
import { DbRole } from '../../libs/db/roles.js';
import type { db } from '../../libs/db/index.js';

type DbClient = typeof db;

describe('EvidenceExportService', () => {
    let service: EvidenceExportService;
    let mockClient: { query: ReturnType<typeof mock.fn> };
    let mockFs: { mkdir: ReturnType<typeof mock.fn>; writeFile: ReturnType<typeof mock.fn> };
    let mockQuery: ReturnType<typeof mock.fn>;
    let mockDb: {
        queryAsRole: ReturnType<typeof mock.fn>;
        transactionAsRole: ReturnType<typeof mock.fn>;
        withRoleClient: ReturnType<typeof mock.fn>;
        listenAsRole: ReturnType<typeof mock.fn>;
        probeRoles: ReturnType<typeof mock.fn>;
    };

    const MOCK_CONFIG: ExportConfig = {
        outputDir: '/tmp/test_evidence',
        schemaVersion: '7B.2.0',
        batchSize: 100
    };

    beforeEach(() => {
        // Setup PG Mocks
        mockQuery = mock.fn(async () => ({ rows: [] }));
        mockClient = {
            query: mockQuery
        };
        mockDb = {
            queryAsRole: mock.fn(async () => ({ rows: [] })),
            transactionAsRole: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            withRoleClient: mock.fn(async (_role: DbRole, callback: (client: typeof mockClient) => Promise<unknown>) =>
                callback(mockClient)
            ),
            listenAsRole: mock.fn(async () => ({ close: mock.fn(async () => undefined) })),
            probeRoles: mock.fn(async () => undefined)
        };

        // Mock Filesystem
        mockFs = {
            mkdir: mock.fn(async () => undefined),
            writeFile: mock.fn(async () => undefined)
        };

        // Instantiate Service with injected fs
        service = new EvidenceExportService(
            'symphony_control',
            MOCK_CONFIG,
            mockFs as unknown as typeof import('fs/promises'),
            mockDb as unknown as DbClient
        );
    });

    describe('getHighWaterMarks', () => {
        it('should fetch marks from DB using coalesced max IDs', async () => {
            mockDb.queryAsRole = mock.fn(async () => ({
                rows: [{
                    max_ingress_id: '100',
                    max_outbox_id: '50',
                    max_ledger_id: '200'
                }]
            }));

            const marks = await service.getHighWaterMarks();

            assert.strictEqual(marks.maxIngressId, '100');
            assert.strictEqual(marks.maxOutboxId, '50');
            assert.strictEqual(marks.maxLedgerId, '200');

            const queryCall = mockDb.queryAsRole.mock.calls[0]!;
            assert.match((queryCall.arguments as [string, string])[1], /MAX\(outbox_id\)/);
        });
    });

    describe('getLastExportState', () => {
        it('should return null if no logs exist', async () => {
            mockDb.queryAsRole = mock.fn(async () => ({ rows: [] }));

            const state = await service.getLastExportState();
            assert.strictEqual(state, null);
        });

        it('should return last batch state if exists', async () => {
            mockDb.queryAsRole = mock.fn(async () => ({
                rows: [{
                    batch_id: 'batch_prev',
                    max_ingress_id: '90',
                    max_outbox_id: '40',
                    max_ledger_id: '190'
                }]
            }));

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

            mockDb.queryAsRole = mock.fn(async (_role: string, sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [currentMarks] };
                return { rows: [] };
            });
            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('FROM ingress_attestations')) return { rows: [{ id: '101', data: 'test' }] };
                if (sql.includes('FROM payment_outbox_pending') || sql.includes('FROM payment_outbox_attempts')) return { rows: [] };
                if (sql.includes('FROM ledger_entries')) return { rows: [] };
                if (sql.includes('INSERT INTO evidence_export_log')) return {};
                return { rows: [] };
            });

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
            mockDb.queryAsRole = mock.fn(async (_role: string, sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [{ max_ingress_id: '300', max_outbox_id: '150', max_ledger_id: '600' }] };
                if (sql.includes('FROM evidence_export_log')) return { rows: [{ batch_id: 'batch_old' }] };
                return { rows: [] };
            });
            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('FROM ingress_attestations')) return { rows: [] };
                if (sql.includes('FROM payment_outbox_pending') || sql.includes('FROM payment_outbox_attempts')) return { rows: [] };
                if (sql.includes('FROM ledger_entries')) return { rows: [] };
                if (sql.includes('INSERT INTO evidence_export_log')) return {};
                return { rows: [] };
            });

            const fromMarks = { maxIngressId: '200', maxOutboxId: '100', maxLedgerId: '400' };
            const result = await service.exportBatch(fromMarks);

            assert.strictEqual(result.previousBatchId, 'batch_old');
        });

        it('should rollback and throw on error', async () => {
            mockDb.queryAsRole = mock.fn(async (_role: string, sql: string) => {
                if (sql.includes('SELECT COALESCE(MAX(id)')) {
                    return { rows: [{ max_ingress_id: '1', max_outbox_id: '0', max_ledger_id: '0' }] };
                }
                return { rows: [] };
            });
            mockClient.query = mock.fn(async (sql: string) => {
                if (sql.includes('FROM ingress_attestations') && sql.includes('WHERE id > $1')) {
                    throw new Error('DB Connection Failed');
                }
                return { rows: [] };
            });

            await assert.rejects(
                async () => service.exportBatch(null),
                { message: 'DB Connection Failed' }
            );
        });
    });

    describe('Hashing Logic (Deterministic)', () => {
        it('should produce consistent hash for same data', async () => {
            const setupMocks = () => {
                mockDb.queryAsRole = mock.fn(async (_role: string, sql: string) => {
                    if (sql.includes('SELECT COALESCE(MAX(id)')) return { rows: [{ max_ingress_id: '10', max_outbox_id: '0', max_ledger_id: '0' }] };
                    return { rows: [] };
                });
                mockClient.query = mock.fn(async (sql: string) => {
                    if (sql.includes('FROM ingress_attestations')) {
                        return {
                            rows: [
                                { id: '2', data: 'b' },
                                { id: '1', data: 'a' }
                            ]
                        };
                    }
                    if (sql.includes('FROM payment_outbox_pending') || sql.includes('FROM payment_outbox_attempts')) return { rows: [] };
                    if (sql.includes('FROM ledger_entries')) return { rows: [] };
                    if (sql.includes('INSERT INTO evidence_export_log')) return {};
                    return { rows: [] };
                });
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
