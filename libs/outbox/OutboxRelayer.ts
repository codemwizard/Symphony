/**
 * Phase-7B: Outbox Relayer Service (Option 2A)
 *
 * This service implements a hybrid wakeup relayer:
 * - LISTEN/NOTIFY for low-latency wakeups
 * - fallback polling to ensure SLA stability
 *
 * It uses DELETE ... RETURNING from payment_outbox_pending and appends
 * DISPATCHING attempts in the same transaction for crash consistency.
 */

import { Pool, PoolClient } from 'pg';
import { pino } from 'pino';

const logger = pino({ name: 'OutboxRelayer' });

// Configuration
const BATCH_SIZE = 50;
const POLL_INTERVAL_MS = 500;
const NOTIFY_DEBOUNCE_MS = 50;
const MAX_CONCURRENCY = 10;
const DISPATCH_TIMEOUT_MS = 30_000;

const TERMINAL_RAIL_CODES = new Set([
    'INVALID_ACCOUNT',
    'INSUFFICIENT_FUNDS',
    'FRAUD_BLOCK',
    'INVALID_AMOUNT',
    'INVALID_DESTINATION',
    'INVALID_CURRENCY'
]);

// External Rail Client Interface
interface RailClient {
    dispatch(params: {
        reference: string;
        amount: number;
        currency: string;
        destination: string;
        participantId: string;
        railType: string;
        payload: Record<string, unknown>;
    }): Promise<{
        success: boolean;
        railReference?: string;
        railCode?: string;
        errorCode?: string;
        errorMessage?: string;
        retryable?: boolean;
    }>;
}

interface OutboxRecord {
    outbox_id: string;
    instruction_id: string;
    participant_id: string;
    sequence_id: number;
    idempotency_key: string;
    rail_type: string;
    payload: {
        amount: number;
        currency: string;
        destination: string;
        [key: string]: unknown;
    };
    attempt_count: number;
    attempt_no: number;
    created_at: Date;
}

class Semaphore {
    private inFlight = 0;
    private readonly queue: Array<() => void> = [];

    constructor(private readonly limit: number) {}

    async acquire(): Promise<() => void> {
        if (this.inFlight < this.limit) {
            this.inFlight += 1;
            return () => this.release();
        }

        return new Promise(resolve => {
            this.queue.push(() => {
                this.inFlight += 1;
                resolve(() => this.release());
            });
        });
    }

    private release(): void {
        this.inFlight -= 1;
        const next = this.queue.shift();
        if (next) {
            next();
        }
    }
}

export class OutboxRelayer {
    private isRunning = false;
    private pollInProgress = false;
    private pendingWakeup = false;
    private debounceTimer: NodeJS.Timeout | null = null;
    private pollTimer: NodeJS.Timeout | null = null;
    private listenClient: PoolClient | null = null;

    constructor(
        private readonly pool: Pool,
        private readonly railClient: RailClient
    ) { }

    /**
     * Start the relayer polling loop
     */
    public async start(): Promise<void> {
        if (this.isRunning) {
            logger.warn('Relayer already running');
            return;
        }
        this.isRunning = true;

        await this.attachListener();

        this.pollTimer = setInterval(() => this.triggerPoll('interval'), POLL_INTERVAL_MS);
        this.triggerPoll('startup');
        logger.info('OutboxRelayer started');
    }

    /**
     * Stop the relayer gracefully
     */
    public async stop(): Promise<void> {
        this.isRunning = false;

        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }

        if (this.debounceTimer) {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = null;
        }

        if (this.listenClient) {
            await this.listenClient.query('UNLISTEN outbox_pending');
            this.listenClient.release();
            this.listenClient = null;
        }

        logger.info('OutboxRelayer stopped');
    }

    private async attachListener(): Promise<void> {
        const client = await this.pool.connect();
        await client.query('LISTEN outbox_pending');
        client.on('notification', () => this.scheduleDebouncedPoll());
        this.listenClient = client;
    }

    private scheduleDebouncedPoll(): void {
        if (!this.isRunning) return;
        if (this.debounceTimer) return;

        this.debounceTimer = setTimeout(() => {
            this.debounceTimer = null;
            this.triggerPoll('notify');
        }, NOTIFY_DEBOUNCE_MS);
    }

    private triggerPoll(reason: 'notify' | 'interval' | 'startup' | 'queued'): void {
        if (!this.isRunning) return;

        if (this.pollInProgress) {
            this.pendingWakeup = true;
            return;
        }

        this.pollInProgress = true;
        void this.runPoll(reason);
    }

    private async runPoll(reason: string): Promise<void> {
        try {
            await this.processDue(reason);
        } catch (error) {
            logger.error({ error }, 'Relayer poll failure');
        } finally {
            this.pollInProgress = false;
            if (this.pendingWakeup) {
                this.pendingWakeup = false;
                this.triggerPoll('queued');
            }
        }
    }

    private async processDue(reason: string): Promise<void> {
        if (!this.isRunning) return;

        let batchCount = 0;
        while (this.isRunning) {
            const records = await this.claimNextBatch();
            if (records.length === 0) break;

            batchCount += 1;
            logger.info({ count: records.length, reason }, 'Processing outbox batch');
            await this.processRecords(records);

            if (records.length < BATCH_SIZE) break;
        }

        if (batchCount > 0) {
            logger.info({ batchCount, reason }, 'Completed outbox batches');
        }
    }

    private async claimNextBatch(): Promise<OutboxRecord[]> {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');

            const deleteQuery = `
                WITH due AS (
                    SELECT outbox_id
                    FROM payment_outbox_pending
                    WHERE next_attempt_at <= NOW()
                    ORDER BY next_attempt_at ASC, created_at ASC
                    LIMIT $1
                    FOR UPDATE SKIP LOCKED
                )
                DELETE FROM payment_outbox_pending
                USING due
                WHERE payment_outbox_pending.outbox_id = due.outbox_id
                RETURNING
                    payment_outbox_pending.outbox_id,
                    payment_outbox_pending.instruction_id,
                    payment_outbox_pending.participant_id,
                    payment_outbox_pending.sequence_id,
                    payment_outbox_pending.idempotency_key,
                    payment_outbox_pending.rail_type,
                    payment_outbox_pending.payload,
                    payment_outbox_pending.attempt_count,
                    payment_outbox_pending.created_at;
            `;

            const result = await client.query(deleteQuery, [BATCH_SIZE]);
            if (result.rows.length === 0) {
                await client.query('COMMIT');
                return [];
            }

            const records = result.rows.map(row => ({
                ...row,
                sequence_id: Number(row.sequence_id),
                attempt_no: Number(row.attempt_count) + 1
            })) as OutboxRecord[];

            const attemptValues: Array<unknown> = [];
            const placeholders: string[] = [];
            records.forEach((row, index) => {
                const offset = index * 10;
                placeholders.push(`($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5}, $${offset + 6}, $${offset + 7}, 'DISPATCHING', $${offset + 8}, NOW(), NOW())`);
                attemptValues.push(
                    row.outbox_id,
                    row.instruction_id,
                    row.participant_id,
                    row.sequence_id,
                    row.idempotency_key,
                    row.rail_type,
                    JSON.stringify(row.payload),
                    row.attempt_no
                );
            });

            const insertAttempts = `
                INSERT INTO payment_outbox_attempts (
                    outbox_id,
                    instruction_id,
                    participant_id,
                    sequence_id,
                    idempotency_key,
                    rail_type,
                    payload,
                    state,
                    attempt_no,
                    claimed_at,
                    created_at
                ) VALUES ${placeholders.join(', ')};
            `;

            await client.query(insertAttempts, attemptValues);
            await client.query('COMMIT');

            return records;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    private async processRecords(records: OutboxRecord[]): Promise<void> {
        const semaphore = new Semaphore(MAX_CONCURRENCY);
        await Promise.all(records.map(async record => {
            const release = await semaphore.acquire();
            try {
                await this.processRecord(record);
            } finally {
                release();
            }
        }));
    }

    private async processRecord(record: OutboxRecord): Promise<void> {
        const correlationId = record.outbox_id;
        const validationError = this.validatePayload(record.payload);

        if (validationError) {
            await this.insertOutcome(record, 'FAILED', {
                errorCode: validationError.code,
                errorMessage: validationError.message
            });
            logger.warn({ correlationId, errorCode: validationError.code }, 'Validation failed');
            return;
        }

        const start = Date.now();
        try {
            const result = await this.dispatchWithTimeout(record);
            const latencyMs = Date.now() - start;

            if (result.success) {
                const details: {
                    railReference?: string;
                    railCode?: string;
                    latencyMs?: number;
                } = { latencyMs };
                if (result.railReference !== undefined) {
                    details.railReference = result.railReference;
                }
                if (result.railCode !== undefined) {
                    details.railCode = result.railCode;
                }
                await this.insertOutcome(record, 'DISPATCHED', details);
                logger.info({ correlationId, railReference: result.railReference }, 'Dispatch successful');
                return;
            }

            const classification = this.classifyError(result);
            const details: {
                railReference?: string;
                railCode?: string;
                errorCode?: string;
                errorMessage?: string;
                latencyMs?: number;
            } = {
                errorMessage: result.errorMessage ?? 'Dispatch failed',
                latencyMs
            };
            if (result.railReference !== undefined) {
                details.railReference = result.railReference;
            }
            if (result.railCode !== undefined) {
                details.railCode = result.railCode;
            }
            if (result.errorCode !== undefined) {
                details.errorCode = result.errorCode;
            }
            await this.insertOutcome(record, classification.state, details);

            if (classification.state === 'RETRYABLE') {
                await this.requeue(record);
            }
        } catch (error: unknown) {
            const latencyMs = Date.now() - start;
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            const errorCode = errorMessage === 'DISPATCH_TIMEOUT' ? 'DISPATCH_TIMEOUT' : 'DISPATCH_ERROR';
            await this.insertOutcome(record, 'RETRYABLE', {
                errorCode,
                errorMessage,
                latencyMs
            });
            await this.requeue(record);
            logger.error({ correlationId, error: errorMessage }, 'Dispatch failure');
        }
    }

    private validatePayload(payload: OutboxRecord['payload']): { code: string; message: string } | null {
        if (!payload || typeof payload !== 'object') {
            return { code: 'INVALID_PAYLOAD', message: 'Payload is required.' };
        }
        if (typeof payload.amount !== 'number' || payload.amount <= 0) {
            return { code: 'INVALID_AMOUNT', message: 'Amount must be greater than zero.' };
        }
        if (typeof payload.currency !== 'string' || !/^[A-Z]{3}$/.test(payload.currency)) {
            return { code: 'INVALID_CURRENCY', message: 'Currency must be a 3-letter code.' };
        }
        if (typeof payload.destination !== 'string' || payload.destination.trim().length === 0) {
            return { code: 'INVALID_DESTINATION', message: 'Destination is required.' };
        }
        return null;
    }

    private async dispatchWithTimeout(record: OutboxRecord): Promise<Awaited<ReturnType<RailClient['dispatch']>>> {
        const timeoutPromise = new Promise<never>((_, reject) => {
            setTimeout(() => reject(new Error('DISPATCH_TIMEOUT')), DISPATCH_TIMEOUT_MS);
        });

        return Promise.race([
            this.railClient.dispatch({
                reference: record.outbox_id,
                amount: record.payload.amount,
                currency: record.payload.currency,
                destination: record.payload.destination,
                participantId: record.participant_id,
                railType: record.rail_type,
                payload: record.payload
            }),
            timeoutPromise
        ]);
    }

    private classifyError(result: Awaited<ReturnType<RailClient['dispatch']>>): { state: 'RETRYABLE' | 'FAILED' } {
        if (result.retryable === true) return { state: 'RETRYABLE' };
        if (result.retryable === false) return { state: 'FAILED' };
        if (result.railCode && TERMINAL_RAIL_CODES.has(result.railCode)) return { state: 'FAILED' };
        if (result.errorCode && TERMINAL_RAIL_CODES.has(result.errorCode)) return { state: 'FAILED' };
        return { state: 'RETRYABLE' };
    }

    private async insertOutcome(
        record: OutboxRecord,
        state: 'DISPATCHED' | 'RETRYABLE' | 'FAILED',
        details: {
            railReference?: string;
            railCode?: string;
            errorCode?: string;
            errorMessage?: string;
            latencyMs?: number;
        }
    ): Promise<void> {
        await this.pool.query(
            `
            INSERT INTO payment_outbox_attempts (
                outbox_id,
                instruction_id,
                participant_id,
                sequence_id,
                idempotency_key,
                rail_type,
                payload,
                state,
                attempt_no,
                claimed_at,
                completed_at,
                rail_reference,
                rail_code,
                error_code,
                error_message,
                latency_ms,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW(), $10, $11, $12, $13, $14, NOW());
        `,
            [
                record.outbox_id,
                record.instruction_id,
                record.participant_id,
                record.sequence_id,
                record.idempotency_key,
                record.rail_type,
                JSON.stringify(record.payload),
                state,
                record.attempt_no,
                details.railReference ?? null,
                details.railCode ?? null,
                details.errorCode ?? null,
                details.errorMessage ?? null,
                details.latencyMs ?? null
            ]
        );
    }

    private async requeue(record: OutboxRecord): Promise<void> {
        const backoffMs = this.calculateBackoffMs(record.attempt_no);
        await this.pool.query(
            `
            INSERT INTO payment_outbox_pending (
                outbox_id,
                instruction_id,
                participant_id,
                sequence_id,
                idempotency_key,
                rail_type,
                payload,
                attempt_count,
                next_attempt_at,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW() + ($9 * INTERVAL '1 millisecond'), NOW())
            ON CONFLICT (instruction_id, idempotency_key)
            DO UPDATE SET
                attempt_count = EXCLUDED.attempt_count,
                next_attempt_at = EXCLUDED.next_attempt_at;
        `,
            [
                record.outbox_id,
                record.instruction_id,
                record.participant_id,
                record.sequence_id,
                record.idempotency_key,
                record.rail_type,
                JSON.stringify(record.payload),
                record.attempt_no,
                backoffMs
            ]
        );
    }

    private calculateBackoffMs(attemptNo: number): number {
        const base = 1000;
        const backoff = base * Math.pow(2, Math.max(0, attemptNo - 1));
        return Math.min(backoff, 60_000);
    }
}

// Export for testing
export type { RailClient, OutboxRecord };
