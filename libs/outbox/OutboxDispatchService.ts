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
            const result = await dbClient.query(`
                SELECT outbox_id, sequence_id, created_at, state
                FROM enqueue_payment_outbox($1, $2, $3, $4, $5);
            `, [
                request.instructionId,
                request.participantId,
                request.idempotencyKey,
                request.railType,
                JSON.stringify(request.payload)
            ]);

            const row = result.rows[0];

            logger.info({
                event: 'DISPATCH_QUEUED',
                outboxId: row.outbox_id,
                sequenceId: Number(row.sequence_id),
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
                sequenceId: Number(row.sequence_id),
                status: row.state,
                createdAt: row.created_at
            };
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Unknown error';

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
