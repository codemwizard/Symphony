/**
 * Phase-7B: Evidence Export Service
 * 
 * Read-only export mechanism that emits Evidence Bundles from Phase-7R artifacts.
 * 
 * Constraints:
 * - No data mutation
 * - No reformatting beyond schema normalization
 * - No derived or inferred data
 * - Each batch includes SHA-256 hash of sorted records + schema version + batch metadata
 */

import { Pool, PoolClient } from 'pg';
import pino from 'pino';
import crypto from 'crypto';
import fs from 'fs/promises';
import path from 'path';

const logger = pino({ name: 'EvidenceExportService' });

// ------------------ Domain Errors ------------------

export class ExportError extends Error {
    readonly code: string;
    readonly statusCode: number;

    constructor(message: string, code: string, statusCode: number = 500) {
        super(message);
        this.name = 'ExportError';
        this.code = code;
        this.statusCode = statusCode;
    }
}

export class BatchBoundaryError extends ExportError {
    constructor(message: string) {
        super(message, 'BATCH_BOUNDARY_ERROR', 400);
        this.name = 'BatchBoundaryError';
    }
}

// ------------------ Types ------------------

export interface HighWaterMarks {
    readonly maxIngressId: string;
    readonly maxOutboxId: string;
    readonly maxLedgerId: string;
}

export interface ExportBatchMetadata {
    readonly batchId: string;
    readonly schemaVersion: string;
    readonly exportedAt: string;
    readonly highWaterMarks: HighWaterMarks;
    readonly previousBatchId: string | null;
    readonly recordCounts: {
        readonly ingress: number;
        readonly outbox: number;
        readonly ledger: number;
    };
    readonly batchHash: string;
    readonly viewVersion: string;
    readonly generatedAt: string;
}

export interface IngressRecord {
    readonly id: string;
    readonly request_id: string;
    readonly caller_id: string;
    readonly created_at: string;
    readonly execution_started: boolean;
    readonly execution_completed: boolean;
    readonly terminal_status: string | null;
    readonly prev_hash: string | null;
}

export interface OutboxRecord {
    readonly id: string;
    readonly idempotency_key: string;
    readonly status: string;
    readonly retry_count: number;
    readonly created_at: string;
    readonly updated_at: string;
}

export interface LedgerRecord {
    readonly id: string;
    readonly account_id: string;
    readonly amount: string;
    readonly currency: string;
    readonly entry_type: string;
    readonly created_at: string;
}

export interface EvidenceBatch {
    readonly metadata: ExportBatchMetadata;
    readonly ingress: readonly IngressRecord[];
    readonly outbox: readonly OutboxRecord[];
    readonly ledger: readonly LedgerRecord[];
}

export interface ExportConfig {
    readonly outputDir: string;
    readonly schemaVersion: string;
    readonly batchSize: number;
}

// ------------------ Service ------------------

export class EvidenceExportService {
    private readonly pool: Pool;
    private readonly config: ExportConfig;
    private readonly VIEW_VERSION = '7B.1.0';
    private readonly fs: typeof fs;

    constructor(pool: Pool, config: ExportConfig, filesystem?: typeof fs) {
        this.pool = pool;
        this.config = config;
        this.fs = filesystem ?? fs;
    }

    /**
     * Get current high-water marks from all source tables.
     * These are used to define batch boundaries.
     */
    async getHighWaterMarks(): Promise<HighWaterMarks> {
        const client = await this.pool.connect();
        try {
            const result = await client.query(`
                SELECT
                    (SELECT COALESCE(MAX(id)::text, '0') FROM ingress_attestations) AS max_ingress_id,
                    (SELECT COALESCE(MAX(id)::text, '0') FROM payment_outbox) AS max_outbox_id,
                    (SELECT COALESCE(MAX(id)::text, '0') FROM ledger_entries) AS max_ledger_id
            `);

            const row = result.rows[0];
            return {
                maxIngressId: row.max_ingress_id,
                maxOutboxId: row.max_outbox_id,
                maxLedgerId: row.max_ledger_id,
            };
        } finally {
            client.release();
        }
    }

    /**
     * Get last exported batch ID and high-water marks.
     * Returns null if no previous export exists.
     */
    async getLastExportState(): Promise<{ batchId: string; highWaterMarks: HighWaterMarks } | null> {
        const client = await this.pool.connect();
        try {
            const result = await client.query(`
                SELECT batch_id, max_ingress_id, max_outbox_id, max_ledger_id
                FROM evidence_export_log
                ORDER BY exported_at DESC
                LIMIT 1
            `);

            if (result.rows.length === 0) {
                return null;
            }

            const row = result.rows[0];
            return {
                batchId: row.batch_id,
                highWaterMarks: {
                    maxIngressId: row.max_ingress_id,
                    maxOutboxId: row.max_outbox_id,
                    maxLedgerId: row.max_ledger_id,
                },
            };
        } finally {
            client.release();
        }
    }

    /**
     * Export a batch of evidence records.
     * Read-only operation - only writes to filesystem and export log.
     */
    async exportBatch(fromMarks: HighWaterMarks | null): Promise<ExportBatchMetadata> {
        const batchId = this.generateBatchId();
        const exportedAt = new Date().toISOString();
        const currentMarks = await this.getHighWaterMarks();

        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');

            // Fetch records since last export (read-only queries)
            const ingress = await this.fetchIngressRecords(client, fromMarks?.maxIngressId ?? '0', currentMarks.maxIngressId);
            const outbox = await this.fetchOutboxRecords(client, fromMarks?.maxOutboxId ?? '0', currentMarks.maxOutboxId);
            const ledger = await this.fetchLedgerRecords(client, fromMarks?.maxLedgerId ?? '0', currentMarks.maxLedgerId);

            // Compute batch hash (sorted records + schema version + metadata)
            const batchHash = this.computeBatchHash(ingress, outbox, ledger, this.config.schemaVersion, batchId);

            const metadata: ExportBatchMetadata = {
                batchId,
                schemaVersion: this.config.schemaVersion,
                exportedAt,
                highWaterMarks: currentMarks,
                previousBatchId: fromMarks ? (await this.getLastExportState())?.batchId ?? null : null,
                recordCounts: {
                    ingress: ingress.length,
                    outbox: outbox.length,
                    ledger: ledger.length,
                },
                batchHash,
                viewVersion: this.VIEW_VERSION,
                generatedAt: exportedAt,
            };

            const batch: EvidenceBatch = {
                metadata,
                ingress,
                outbox,
                ledger,
            };

            // Write to filesystem (mock regulator bucket)
            await this.writeBatchToFilesystem(batch);

            // Log the export (audit trail)
            await this.logExport(client, metadata);

            await client.query('COMMIT');

            logger.info({
                batchId,
                recordCounts: metadata.recordCounts,
                batchHash,
            }, 'Evidence batch exported successfully');

            return metadata;
        } catch (error) {
            await client.query('ROLLBACK');
            logger.error({ error, batchId }, 'Evidence batch export failed');
            throw error;
        } finally {
            client.release();
        }
    }

    // ------------------ Private Methods ------------------

    private generateBatchId(): string {
        const timestamp = Date.now().toString(36);
        const random = crypto.randomBytes(4).toString('hex');
        return `batch_${timestamp}_${random}`;
    }

    private async fetchIngressRecords(
        client: PoolClient,
        fromId: string,
        toId: string
    ): Promise<IngressRecord[]> {
        const result = await client.query(
            `SELECT id, request_id, caller_id, created_at, execution_started, 
                    execution_completed, terminal_status, prev_hash
             FROM ingress_attestations
             WHERE id > $1 AND id <= $2
             ORDER BY id ASC
             LIMIT $3`,
            [fromId, toId, this.config.batchSize]
        );
        return result.rows as IngressRecord[];
    }

    private async fetchOutboxRecords(
        client: PoolClient,
        fromId: string,
        toId: string
    ): Promise<OutboxRecord[]> {
        const result = await client.query(
            `SELECT id, idempotency_key, status, retry_count, created_at, updated_at
             FROM payment_outbox
             WHERE id > $1 AND id <= $2
             ORDER BY id ASC
             LIMIT $3`,
            [fromId, toId, this.config.batchSize]
        );
        return result.rows as OutboxRecord[];
    }

    private async fetchLedgerRecords(
        client: PoolClient,
        fromId: string,
        toId: string
    ): Promise<LedgerRecord[]> {
        const result = await client.query(
            `SELECT id, account_id, amount, currency, entry_type, created_at
             FROM ledger_entries
             WHERE id > $1 AND id <= $2
             ORDER BY id ASC
             LIMIT $3`,
            [fromId, toId, this.config.batchSize]
        );
        return result.rows as LedgerRecord[];
    }

    private computeBatchHash(
        ingress: readonly IngressRecord[],
        outbox: readonly OutboxRecord[],
        ledger: readonly LedgerRecord[],
        schemaVersion: string,
        batchId: string
    ): string {
        // Sort records by ID for deterministic hashing
        const sortedIngress = [...ingress].sort((a, b) => a.id.localeCompare(b.id));
        const sortedOutbox = [...outbox].sort((a, b) => a.id.localeCompare(b.id));
        const sortedLedger = [...ledger].sort((a, b) => a.id.localeCompare(b.id));

        const payload = JSON.stringify({
            schemaVersion,
            batchId,
            ingress: sortedIngress,
            outbox: sortedOutbox,
            ledger: sortedLedger,
        });

        return crypto.createHash('sha256').update(payload).digest('hex');
    }

    private async writeBatchToFilesystem(batch: EvidenceBatch): Promise<void> {
        const filename = `${batch.metadata.batchId}.json`;
        const filepath = path.join(this.config.outputDir, filename);

        await this.fs.mkdir(this.config.outputDir, { recursive: true });
        await this.fs.writeFile(filepath, JSON.stringify(batch, null, 2), 'utf-8');

        // Write hash file for integrity verification
        const hashFilepath = `${filepath}.sha256`;
        await this.fs.writeFile(hashFilepath, batch.metadata.batchHash, 'utf-8');

        logger.info({ filepath, hashFilepath }, 'Batch written to filesystem');
    }

    private async logExport(client: PoolClient, metadata: ExportBatchMetadata): Promise<void> {
        await client.query(
            `INSERT INTO evidence_export_log 
             (batch_id, schema_version, exported_at, max_ingress_id, max_outbox_id, max_ledger_id, 
              ingress_count, outbox_count, ledger_count, batch_hash, previous_batch_id)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
            [
                metadata.batchId,
                metadata.schemaVersion,
                metadata.exportedAt,
                metadata.highWaterMarks.maxIngressId,
                metadata.highWaterMarks.maxOutboxId,
                metadata.highWaterMarks.maxLedgerId,
                metadata.recordCounts.ingress,
                metadata.recordCounts.outbox,
                metadata.recordCounts.ledger,
                metadata.batchHash,
                metadata.previousBatchId,
            ]
        );
    }
}

// ------------------ Factory ------------------

export function createEvidenceExportService(pool: Pool, outputDir: string): EvidenceExportService {
    return new EvidenceExportService(pool, {
        outputDir,
        schemaVersion: '7B.1.0',
        batchSize: 10000,
    });
}
