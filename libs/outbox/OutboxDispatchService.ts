/**
 * Phase-7R: Outbox Dispatch Service
 * 
 * This module implements the Transactional Outbox pattern by replacing
 * direct external rail calls with atomic outbox writes.
 * 
 * Pattern: Write to outbox in same transaction as ledger → Relayer executes async
 * 
 * @see PHASE-7R-implementation_plan.md Section "Transactional Outbox"
 */

import { Pool, PoolClient } from 'pg';
import pino from 'pino';

const logger = pino({ name: 'OutboxDispatch' });

/**
 * Dispatch request payload
 */
export interface DispatchRequest {
    instructionId: string;
    participantId: string;
    idempotencyKey: string;
    railType: 'PAYMENT' | 'TRANSFER' | 'REFUND' | 'REVERSAL';
    payload: {
        amount: number;
        currency: string;
        destination: string;
        reference?: string;
        metadata?: Record<string, unknown>;
    };
    attestationId?: string;
}

/**
 * Dispatch result
 */
export interface DispatchResult {
    outboxId: string;
    sequenceId: number;
    status: 'PENDING' | 'DISPATCHING' | 'DISPATCHED' | 'RETRYABLE' | 'FAILED' | 'ZOMBIE_REQUEUE';
    createdAt: Date;
}

/**
 * Error thrown when dispatch fails
 */
export class DispatchError extends Error {
    readonly code: string;
    readonly statusCode: number;

    constructor(code: string, message: string, statusCode = 500) {
        super(message);
        this.name = 'DispatchError';
        this.code = code;
        this.statusCode = statusCode;
    }
}

/**
 * Outbox Dispatch Service
 * 
 * Replaces direct ExternalRequestService calls with atomic outbox writes.
 * The Relayer will pick up and execute these asynchronously.
 */
export class OutboxDispatchService {
    constructor(
        private readonly pool: Pool
    ) {
    }

    /**
     * Dispatch a request to the outbox (atomic with transaction)
     * 
     * This MUST be called within the same transaction as ledger updates.
     */
    public async dispatch(
        request: DispatchRequest,
        client?: PoolClient
    ): Promise<DispatchResult> {
        const shouldReleaseClient = !client;
        const dbClient = client ?? await this.pool.connect();

        try {
            // Check for duplicate idempotency key
            const existing = await dbClient.query(`
                SELECT outbox_id, sequence_id, created_at
                FROM payment_outbox_pending
                WHERE instruction_id = $1
                  AND idempotency_key = $2
                LIMIT 1;
            `, [request.instructionId, request.idempotencyKey]);

            if (existing.rows.length > 0) {
                const existingRecord = existing.rows[0];
                logger.info({
                    event: 'DUPLICATE_DISPATCH',
                    idempotencyKey: request.idempotencyKey,
                    instructionId: request.instructionId,
                    existingOutboxId: existingRecord.outbox_id
                });

                return {
                    outboxId: existingRecord.outbox_id,
                    sequenceId: Number(existingRecord.sequence_id),
                    status: 'PENDING',
                    createdAt: existingRecord.created_at
                };
            }

            const existingAttempt = await dbClient.query(`
                SELECT outbox_id, sequence_id, state, created_at
                FROM payment_outbox_attempts
                WHERE instruction_id = $1
                  AND idempotency_key = $2
                ORDER BY created_at DESC
                LIMIT 1;
            `, [request.instructionId, request.idempotencyKey]);

            if (existingAttempt.rows.length > 0) {
                const attemptRecord = existingAttempt.rows[0];
                logger.info({
                    event: 'DUPLICATE_DISPATCH',
                    idempotencyKey: request.idempotencyKey,
                    instructionId: request.instructionId,
                    existingOutboxId: attemptRecord.outbox_id
                });

                return {
                    outboxId: attemptRecord.outbox_id,
                    sequenceId: Number(attemptRecord.sequence_id),
                    status: attemptRecord.state,
                    createdAt: attemptRecord.created_at
                };
            }

            const sequenceResult = await dbClient.query(`
                SELECT bump_participant_outbox_seq($1) AS sequence_id;
            `, [request.participantId]);
            const sequenceId = Number(sequenceResult.rows[0]?.sequence_id);

            // Insert into outbox (same transaction as ledger)
            const result = await dbClient.query(`
                INSERT INTO payment_outbox_pending (
                    instruction_id,
                    participant_id,
                    sequence_id,
                    idempotency_key,
                    rail_type,
                    payload,
                    attempt_count,
                    next_attempt_at,
                    created_at
                ) VALUES ($1, $2, $3, $4, $5, $6, 0, NOW(), NOW())
                RETURNING outbox_id, created_at;
            `, [
                request.instructionId,
                request.participantId,
                sequenceId,
                request.idempotencyKey,
                request.railType,
                JSON.stringify(request.payload)
            ]);

            const row = result.rows[0];

            logger.info({
                event: 'DISPATCH_QUEUED',
                outboxId: row.outbox_id,
                sequenceId,
                participantId: request.participantId,
                railType: request.railType
            });

            // Update attestation if provided
            if (request.attestationId) {
                await dbClient.query(`
                    UPDATE ingress_attestations
                    SET execution_started = TRUE
                    WHERE id = $1;
                `, [request.attestationId]);
            }

            return {
                outboxId: row.outbox_id,
                sequenceId,
                status: 'PENDING',
                createdAt: row.created_at
            };
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Unknown error';

            // Check for idempotency key collision (concurrent insert)
            if (message.includes('duplicate key') || message.includes('unique constraint')) {
                // Fetch the existing record
                const existing = await dbClient.query(`
                    SELECT outbox_id, sequence_id, created_at
                    FROM payment_outbox_pending
                    WHERE instruction_id = $1
                      AND idempotency_key = $2
                    LIMIT 1;
                `, [request.instructionId, request.idempotencyKey]);

                if (existing.rows.length > 0) {
                    return {
                        outboxId: existing.rows[0].outbox_id,
                        sequenceId: Number(existing.rows[0].sequence_id),
                        status: 'PENDING',
                        createdAt: existing.rows[0].created_at
                    };
                }

                const existingAttempt = await dbClient.query(`
                    SELECT outbox_id, state, created_at, sequence_id
                    FROM payment_outbox_attempts
                    WHERE instruction_id = $1
                      AND idempotency_key = $2
                    ORDER BY created_at DESC
                    LIMIT 1;
                `, [request.instructionId, request.idempotencyKey]);

                if (existingAttempt.rows.length > 0) {
                    return {
                        outboxId: existingAttempt.rows[0].outbox_id,
                        sequenceId: Number(existingAttempt.rows[0].sequence_id),
                        status: existingAttempt.rows[0].state,
                        createdAt: existingAttempt.rows[0].created_at
                    };
                }
            }

            logger.error({ error: message }, 'Dispatch failed');
            throw new DispatchError('DISPATCH_FAILED', message);
        } finally {
            if (shouldReleaseClient) {
                dbClient.release();
            }
        }
    }

    /**
     * Dispatch with ledger update in single transaction
     * 
     * This is the primary method for financial operations.
     */
    public async dispatchWithLedger(
        request: DispatchRequest,
        ledgerEntries: Array<{
            accountId: string;
            entryType: 'DEBIT' | 'CREDIT';
            amount: number;
            currency: string;
        }>
    ): Promise<DispatchResult> {
        const client = await this.pool.connect();

        try {
            await client.query('BEGIN');

            // 1. Write ledger entries
            for (const entry of ledgerEntries) {
                await client.query(`
                    INSERT INTO ledger_entries (
                        account_id,
                        entry_type,
                        amount,
                        currency,
                        status,
                        created_at
                    ) VALUES ($1, $2, $3, $4, 'PENDING', NOW());
                `, [
                    entry.accountId,
                    entry.entryType,
                    entry.amount,
                    entry.currency
                ]);
            }

            // 2. Write to outbox (same transaction)
            const result = await this.dispatch(request, client);

            await client.query('COMMIT');

            logger.info({
                event: 'LEDGER_AND_DISPATCH_COMMITTED',
                outboxId: result.outboxId,
                ledgerEntries: ledgerEntries.length
            });

            return result;
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    }

    /**
     * Get dispatch status
     */
    public async getStatus(outboxId: string): Promise<{
        status: string;
        lastError?: string;
        processedAt?: Date;
    } | null> {
        const pending = await this.pool.query(`
            SELECT created_at
            FROM payment_outbox_pending
            WHERE outbox_id = $1
            LIMIT 1;
        `, [outboxId]);

        if (pending.rows.length > 0) {
            return {
                status: 'PENDING',
                processedAt: pending.rows[0].created_at
            };
        }

        const result = await this.pool.query(`
            SELECT state, error_message, completed_at
            FROM payment_outbox_attempts
            WHERE outbox_id = $1
            ORDER BY created_at DESC
            LIMIT 1;
        `, [outboxId]);

        if (result.rows.length === 0) {
            return null;
        }

        const row = result.rows[0];
        return {
            status: row.state,
            lastError: row.error_message,
            processedAt: row.completed_at
        };
    }
}

/**
 * Factory function
 */
export function createOutboxDispatchService(pool: Pool): OutboxDispatchService {
    return new OutboxDispatchService(pool);
}
