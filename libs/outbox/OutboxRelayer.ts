/**
 * Phase-7R: Outbox Relayer Service
 * 
 * This service implements the "Reliable Relayer" pattern for crash-consistent
 * external rail dispatch. It polls the payment_outbox table and executes
 * pending dispatches with idempotency guarantees.
 * 
 * Key Features:
 * - FOR UPDATE SKIP LOCKED for zero-contention parallel workers
 * - Dead Letter Queue (DLQ) after 5 retries
 * - Outbox ID used as external rail idempotency key
 */

import { Pool, PoolClient } from 'pg';
import pino from 'pino';

const logger = pino({ name: 'OutboxRelayer' });

// Configuration
const BATCH_SIZE = 50;
const POLL_INTERVAL_MS = 100;
const MAX_RETRIES = 5;
const RECOVERY_TIMEOUT_SECONDS = 30;

// External Rail Client Interface
interface RailClient {
    dispatch(params: {
        reference: string;
        amount: number;
        destination: string;
        participantId: string;
    }): Promise<{ success: boolean; railReference?: string; error?: string }>;
}

interface OutboxRecord {
    id: string;
    participant_id: string;
    sequence_id: string;
    idempotency_key: string;
    event_type: string;
    payload: {
        amount: number;
        destination: string;
        [key: string]: unknown;
    };
    retry_count: number;
}

export class OutboxRelayer {
    private isRunning = false;

    constructor(
        private readonly pool: Pool,
        private readonly railClient: RailClient
    ) { }

    /**
     * Start the relayer polling loop
     */
    public start(): void {
        if (this.isRunning) {
            logger.warn('Relayer already running');
            return;
        }
        this.isRunning = true;
        logger.info('OutboxRelayer started');
        this.poll();
    }

    /**
     * Stop the relayer gracefully
     */
    public stop(): void {
        this.isRunning = false;
        logger.info('OutboxRelayer stopped');
    }

    /**
     * Main polling loop using recursive setTimeout (avoids convoy effects)
     */
    private async poll(): Promise<void> {
        if (!this.isRunning) return;

        try {
            const records = await this.fetchNextBatch();

            if (records.length > 0) {
                logger.info({ count: records.length }, 'Processing batch');

                // Process batch in parallel - DB handles row-level locking
                await Promise.all(records.map(record => this.processRecord(record)));
            }
        } catch (error) {
            logger.error({ error }, 'Relayer poll failure');
        }

        // Recursive timeout avoids "convoy" effects if processing takes longer than interval
        setTimeout(() => this.poll(), POLL_INTERVAL_MS);
    }

    /**
     * Fetch next batch using SKIP LOCKED for zero-contention parallel workers
     */
    private async fetchNextBatch(): Promise<OutboxRecord[]> {
        const client = await this.pool.connect();
        try {
            // Atomic pick-up with SKIP LOCKED
            const query = `
                WITH target_records AS (
                    SELECT id FROM payment_outbox
                    WHERE status IN ('PENDING', 'RECOVERING')
                      AND (last_attempt_at IS NULL OR last_attempt_at < NOW() - INTERVAL '${RECOVERY_TIMEOUT_SECONDS} seconds')
                    ORDER BY created_at ASC
                    LIMIT $1
                    FOR UPDATE SKIP LOCKED
                )
                UPDATE payment_outbox
                SET status = 'IN_FLIGHT',
                    last_attempt_at = NOW(),
                    retry_count = retry_count + 1
                FROM target_records
                WHERE payment_outbox.id = target_records.id
                RETURNING 
                    payment_outbox.id,
                    payment_outbox.participant_id,
                    payment_outbox.sequence_id,
                    payment_outbox.idempotency_key,
                    payment_outbox.event_type,
                    payment_outbox.payload,
                    payment_outbox.retry_count;
            `;

            const res = await client.query(query, [BATCH_SIZE]);
            return res.rows;
        } finally {
            client.release();
        }
    }

    /**
     * Process a single outbox record
     */
    private async processRecord(record: OutboxRecord): Promise<void> {
        const correlationId = record.id;

        try {
            // CRITICAL: Use Outbox ID as external rail idempotency key
            // If relayer crashes and restarts, rail will return cached result
            const result = await this.railClient.dispatch({
                reference: record.id, // UUIDv7 as rail idempotency key
                amount: record.payload.amount,
                destination: record.payload.destination,
                participantId: record.participant_id
            });

            if (result.success) {
                await this.markSuccess(record.id, result.railReference);
                logger.info({ correlationId, railReference: result.railReference }, 'Dispatch successful');
            } else {
                await this.handleFailure(record, result.error ?? 'Unknown error', false);
            }
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            const isTransient = this.isTransientError(error);
            await this.handleFailure(record, errorMessage, isTransient);
            logger.error({ correlationId, error: errorMessage }, 'Dispatch failure');
        }
    }

    /**
     * Mark record as successfully processed
     */
    private async markSuccess(id: string, railReference?: string): Promise<void> {
        await this.pool.query(
            `UPDATE payment_outbox 
             SET status = 'SUCCESS', 
                 processed_at = NOW(),
                 last_error = $2
             WHERE id = $1`,
            [id, railReference ?? null]
        );
    }

    /**
     * Handle failure with DLQ logic
     * If retry_count > MAX_RETRIES, move to FAILED (Dead Letter Queue)
     */
    private async handleFailure(record: OutboxRecord, error: string, retryable: boolean): Promise<void> {
        // DLQ Logic: If exceeded retries, mark as FAILED (terminal)
        if (record.retry_count >= MAX_RETRIES) {
            await this.pool.query(
                `UPDATE payment_outbox 
                 SET status = 'FAILED', 
                     last_error = $2,
                     processed_at = NOW()
                 WHERE id = $1`,
                [record.id, `DLQ: ${error} (after ${record.retry_count} attempts)`]
            );
            logger.warn({ correlationId: record.id, retryCount: record.retry_count }, 'Moved to DLQ');
            return;
        }

        // Transient errors go to RECOVERING, permanent errors go to FAILED
        const nextStatus = retryable ? 'RECOVERING' : 'FAILED';
        await this.pool.query(
            `UPDATE payment_outbox 
             SET status = $1, 
                 last_error = $2
             WHERE id = $3`,
            [nextStatus, error, record.id]
        );
    }

    /**
     * Determine if an error is transient (retryable)
     */
    private isTransientError(error: unknown): boolean {
        if (error instanceof Error) {
            const transientCodes = ['ECONNRESET', 'ETIMEDOUT', 'ENOTFOUND', '503', '504'];
            return transientCodes.some(code => error.message.includes(code));
        }
        return false;
    }
}

// Export for testing
export { RailClient, OutboxRecord };
