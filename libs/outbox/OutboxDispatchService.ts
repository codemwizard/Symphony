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
import { defaultIdGenerator, MonotonicIdGenerator } from '../id/MonotonicIdGenerator.js';

const logger = pino({ name: 'OutboxDispatch' });

/**
 * Dispatch request payload
 */
export interface DispatchRequest {
    participantId: string;
    idempotencyKey: string;
    eventType: 'PAYMENT' | 'TRANSFER' | 'REFUND' | 'REVERSAL';
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
    sequenceId: string;
    status: 'PENDING';
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
    private readonly idGenerator: MonotonicIdGenerator;

    constructor(
        private readonly pool: Pool,
        idGenerator?: MonotonicIdGenerator
    ) {
        this.idGenerator = idGenerator ?? defaultIdGenerator;
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
            // Generate sequence ID for gap detection
            const sequenceId = await this.idGenerator.generateString();

            // Check for duplicate idempotency key
            const existing = await dbClient.query(`
                SELECT id, status FROM payment_outbox
                WHERE idempotency_key = $1
                LIMIT 1;
            `, [request.idempotencyKey]);

            if (existing.rows.length > 0) {
                const existingRecord = existing.rows[0];
                logger.info({
                    event: 'DUPLICATE_DISPATCH',
                    idempotencyKey: request.idempotencyKey,
                    existingId: existingRecord.id,
                    existingStatus: existingRecord.status
                });

                return {
                    outboxId: existingRecord.id,
                    sequenceId: sequenceId,
                    status: 'PENDING',
                    createdAt: new Date()
                };
            }

            // Insert into outbox (same transaction as ledger)
            const result = await dbClient.query(`
                INSERT INTO payment_outbox (
                    participant_id,
                    sequence_id,
                    idempotency_key,
                    event_type,
                    payload,
                    status,
                    created_at
                ) VALUES ($1, $2, $3, $4, $5, 'PENDING', NOW())
                RETURNING id, created_at;
            `, [
                request.participantId,
                sequenceId,
                request.idempotencyKey,
                request.eventType,
                JSON.stringify(request.payload)
            ]);

            const row = result.rows[0];

            logger.info({
                event: 'DISPATCH_QUEUED',
                outboxId: row.id,
                sequenceId,
                participantId: request.participantId,
                eventType: request.eventType
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
                outboxId: row.id,
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
                    SELECT id, status, created_at FROM payment_outbox
                    WHERE idempotency_key = $1
                    LIMIT 1;
                `, [request.idempotencyKey]);

                if (existing.rows.length > 0) {
                    return {
                        outboxId: existing.rows[0].id,
                        sequenceId: existing.rows[0].sequence_id,
                        status: 'PENDING',
                        createdAt: existing.rows[0].created_at
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
        const result = await this.pool.query(`
            SELECT status, last_error, processed_at
            FROM payment_outbox
            WHERE id = $1
            LIMIT 1;
        `, [outboxId]);

        if (result.rows.length === 0) {
            return null;
        }

        const row = result.rows[0];
        return {
            status: row.status,
            lastError: row.last_error,
            processedAt: row.processed_at
        };
    }
}

/**
 * Factory function
 */
export function createOutboxDispatchService(pool: Pool): OutboxDispatchService {
    return new OutboxDispatchService(pool);
}
