/**
 * Phase-7B: Deterministic Ledger Reconstruction Script
 * 
 * Reconstructs ledger state using only recorded ingress and outbox data.
 * 
 * Inputs:
 * - ingress_attestations
 * - payment_outbox
 * - ledger snapshot views (read-only)
 * 
 * Outputs:
 * - Reconstructed balances
 * - Execution timeline
 * 
 * Constraints:
 * - No business logic invocation
 * - No side effects
 * - Offline / read-only execution
 */

import { Pool } from 'pg';
import pino from 'pino';
import crypto from 'crypto';

const logger = pino({ name: 'LedgerReplay' });

// ------------------ Types ------------------

export interface ReplayConfig {
    readonly fromDate?: Date;
    readonly toDate?: Date;
    readonly accountFilter?: string[];
}

export interface AttestationRecord {
    readonly id: string;
    readonly request_id: string;
    readonly caller_id: string;
    readonly created_at: Date;
    readonly execution_completed: boolean;
    readonly terminal_status: string | null;
}

export interface OutboxRecord {
    readonly id: string;
    readonly idempotency_key: string;
    readonly instruction_id: string;
    readonly status: string;
    readonly payload: Record<string, unknown>;
    readonly created_at: Date;
}

export interface LedgerRecord {
    readonly id: string;
    readonly account_id: string;
    readonly amount: string;
    readonly currency: string;
    readonly entry_type: 'DEBIT' | 'CREDIT';
    readonly instruction_id: string;
    readonly created_at: Date;
}

export interface ReconstructedBalance {
    readonly accountId: string;
    readonly currency: string;
    readonly debitTotal: string;
    readonly creditTotal: string;
    readonly netBalance: string;
    readonly entryCount: number;
}

export interface ExecutionTimelineEntry {
    readonly timestamp: Date;
    readonly eventType: 'ATTESTED' | 'DISPATCHED' | 'LEDGER_ENTRY' | 'COMPLETED' | 'FAILED';
    readonly sourceId: string;
    readonly details: string;
}

export interface ReplayResult {
    readonly config: ReplayConfig;
    readonly replayedAt: string;
    readonly inputHashes: {
        readonly attestations: string;
        readonly outbox: string;
        readonly ledger: string;
    };
    readonly attestationCount: number;
    readonly outboxCount: number;
    readonly ledgerEntryCount: number;
    readonly reconstructedBalances: readonly ReconstructedBalance[];
    readonly executionTimeline: readonly ExecutionTimelineEntry[];
    readonly resultHash: string;
}

// ------------------ Core Logic ------------------

export class LedgerReplayEngine {
    private readonly pool: Pool;

    constructor(pool: Pool) {
        this.pool = pool;
    }

    /**
     * Replay the ledger from source data.
     * This is a READ-ONLY operation with NO side effects.
     */
    async replay(config: ReplayConfig = {}): Promise<ReplayResult> {
        const replayedAt = new Date().toISOString();

        logger.info({ config }, 'Starting ledger replay');

        const client = await this.pool.connect();
        try {
            // Fetch all source data (read-only)
            const attestations = await this.fetchAttestations(client, config);
            const outbox = await this.fetchOutbox(client, config);
            const ledger = await this.fetchLedger(client, config);

            // Compute input hashes for integrity verification
            const inputHashes = {
                attestations: this.computeHash(attestations),
                outbox: this.computeHash(outbox),
                ledger: this.computeHash(ledger),
            };

            // Reconstruct balances from ledger entries
            const reconstructedBalances = this.reconstructBalances(ledger);

            // Build execution timeline
            const executionTimeline = this.buildTimeline(attestations, outbox, ledger);

            // Compute result hash
            const result: Omit<ReplayResult, 'resultHash'> = {
                config,
                replayedAt,
                inputHashes,
                attestationCount: attestations.length,
                outboxCount: outbox.length,
                ledgerEntryCount: ledger.length,
                reconstructedBalances,
                executionTimeline,
            };

            const resultHash = this.computeHash(result);

            logger.info({
                attestationCount: attestations.length,
                outboxCount: outbox.length,
                ledgerEntryCount: ledger.length,
                balanceCount: reconstructedBalances.length,
                resultHash,
            }, 'Ledger replay completed');

            return { ...result, resultHash };
        } finally {
            client.release();
        }
    }

    // ------------------ Private Methods ------------------

    private async fetchAttestations(
        client: ReturnType<Pool['connect']> extends Promise<infer T> ? T : never,
        config: ReplayConfig
    ): Promise<AttestationRecord[]> {
        let query = `
            SELECT id, request_id, caller_id, created_at, execution_completed, terminal_status
            FROM ingress_attestations
            WHERE execution_completed = TRUE
        `;
        const params: unknown[] = [];

        if (config.fromDate) {
            params.push(config.fromDate);
            query += ` AND created_at >= $${params.length}`;
        }
        if (config.toDate) {
            params.push(config.toDate);
            query += ` AND created_at <= $${params.length}`;
        }

        query += ' ORDER BY created_at ASC';

        const result = await client.query(query, params);
        return result.rows as AttestationRecord[];
    }

    private async fetchOutbox(
        client: ReturnType<Pool['connect']> extends Promise<infer T> ? T : never,
        config: ReplayConfig
    ): Promise<OutboxRecord[]> {
        let query = `
            SELECT id, idempotency_key, instruction_id, status, payload, created_at
            FROM payment_outbox
            WHERE status IN ('SUCCESS', 'FAILED')
        `;
        const params: unknown[] = [];

        if (config.fromDate) {
            params.push(config.fromDate);
            query += ` AND created_at >= $${params.length}`;
        }
        if (config.toDate) {
            params.push(config.toDate);
            query += ` AND created_at <= $${params.length}`;
        }

        query += ' ORDER BY created_at ASC';

        const result = await client.query(query, params);
        return result.rows as OutboxRecord[];
    }

    private async fetchLedger(
        client: ReturnType<Pool['connect']> extends Promise<infer T> ? T : never,
        config: ReplayConfig
    ): Promise<LedgerRecord[]> {
        let query = `
            SELECT id, account_id, amount, currency, entry_type, instruction_id, created_at
            FROM ledger_entries
            WHERE 1=1
        `;
        const params: unknown[] = [];

        if (config.fromDate) {
            params.push(config.fromDate);
            query += ` AND created_at >= $${params.length}`;
        }
        if (config.toDate) {
            params.push(config.toDate);
            query += ` AND created_at <= $${params.length}`;
        }
        if (config.accountFilter && config.accountFilter.length > 0) {
            params.push(config.accountFilter);
            query += ` AND account_id = ANY($${params.length})`;
        }

        query += ' ORDER BY created_at ASC';

        const result = await client.query(query, params);
        return result.rows as LedgerRecord[];
    }

    private reconstructBalances(ledger: LedgerRecord[]): ReconstructedBalance[] {
        const balanceMap = new Map<string, {
            debitTotal: bigint;
            creditTotal: bigint;
            entryCount: number;
            currency: string;
        }>();

        for (const entry of ledger) {
            const key = `${entry.account_id}:${entry.currency}`;
            const existing = balanceMap.get(key) ?? {
                debitTotal: 0n,
                creditTotal: 0n,
                entryCount: 0,
                currency: entry.currency,
            };

            const amount = BigInt(Math.round(parseFloat(entry.amount) * 100)); // Convert to cents

            if (entry.entry_type === 'DEBIT') {
                existing.debitTotal += amount;
            } else {
                existing.creditTotal += amount;
            }
            existing.entryCount += 1;

            balanceMap.set(key, existing);
        }

        const results: ReconstructedBalance[] = [];
        for (const [key, value] of balanceMap) {
            const [accountId] = key.split(':');
            const netBalance = value.creditTotal - value.debitTotal;

            results.push({
                accountId,
                currency: value.currency,
                debitTotal: (Number(value.debitTotal) / 100).toFixed(2),
                creditTotal: (Number(value.creditTotal) / 100).toFixed(2),
                netBalance: (Number(netBalance) / 100).toFixed(2),
                entryCount: value.entryCount,
            });
        }

        return results.sort((a, b) => a.accountId.localeCompare(b.accountId));
    }

    private buildTimeline(
        attestations: AttestationRecord[],
        outbox: OutboxRecord[],
        ledger: LedgerRecord[]
    ): ExecutionTimelineEntry[] {
        const timeline: ExecutionTimelineEntry[] = [];

        for (const att of attestations) {
            timeline.push({
                timestamp: att.created_at,
                eventType: 'ATTESTED',
                sourceId: att.id,
                details: `Request ${att.request_id} from ${att.caller_id}`,
            });
        }

        for (const out of outbox) {
            const eventType = out.status === 'SUCCESS' ? 'COMPLETED' : 'FAILED';
            timeline.push({
                timestamp: out.created_at,
                eventType: 'DISPATCHED',
                sourceId: out.id,
                details: `Instruction ${out.instruction_id} (${out.idempotency_key})`,
            });
            timeline.push({
                timestamp: out.created_at,
                eventType,
                sourceId: out.id,
                details: `Status: ${out.status}`,
            });
        }

        for (const entry of ledger) {
            timeline.push({
                timestamp: entry.created_at,
                eventType: 'LEDGER_ENTRY',
                sourceId: entry.id,
                details: `${entry.entry_type} ${entry.amount} ${entry.currency} on ${entry.account_id}`,
            });
        }

        return timeline.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());
    }

    private computeHash(data: unknown): string {
        const json = JSON.stringify(data, (_, value) =>
            value instanceof Date ? value.toISOString() : value
        );
        return crypto.createHash('sha256').update(json).digest('hex');
    }
}

// ------------------ CLI Entry Point ------------------

export async function runReplay(pool: Pool, config: ReplayConfig): Promise<ReplayResult> {
    const engine = new LedgerReplayEngine(pool);
    return engine.replay(config);
}
