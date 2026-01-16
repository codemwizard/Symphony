/**
 * Phase-7R: Ingress Attestation Middleware
 * 
 * This middleware implements the "No Ingress → No Execution" principle.
 * Every request MUST be attested before execution logic runs.
 * 
 * @see PHASE-7R-implementation_plan.md Section "Ingress Attestation"
 */

import type { Request, Response, NextFunction } from 'express';
import { Pool } from 'pg';
import { pino } from 'pino';
import * as crypto from 'crypto';

const logger = pino({ name: 'IngressAttestation' });

/**
 * Ingress Envelope - Required fields for every request
 */
export interface IngressEnvelope {
    requestId: string;
    idempotencyKey: string;
    callerId: string;
    signature: string;
    timestamp: string;
}

/**
 * Attestation record returned after insertion
 */
export interface AttestationRecord {
    id: string;
    requestId: string;
    idempotencyKey: string;
    recordHash: string;
    attestedAt: Date;
}

/**
 * Error thrown when attestation fails
 */
export class AttestationFailedError extends Error {
    readonly code = 'ATTESTATION_FAILED';
    readonly statusCode = 503;

    constructor(message: string) {
        super(message);
        this.name = 'AttestationFailedError';
    }
}

/**
 * Error thrown when envelope validation fails
 */
export class InvalidEnvelopeError extends Error {
    readonly code = 'INVALID_ENVELOPE';
    readonly statusCode = 400;

    constructor(message: string) {
        super(message);
        this.name = 'InvalidEnvelopeError';
    }
}

/**
 * Ingress Attestation Service
 * 
 * Handles the synchronous insertion of attestation records
 * before any execution logic runs.
 */
export class IngressAttestationService {
    private lastHash: string = '';

    constructor(
        private readonly pool: Pool
    ) { }

    /**
     * Attest an ingress request
     * 
     * This MUST complete before execution proceeds.
     * If this fails, the request is rejected (Fail-Closed).
     */
    public async attest(envelope: IngressEnvelope): Promise<AttestationRecord> {
        this.validateEnvelope(envelope);

        const client = await this.pool.connect();
        try {
            // Get the previous hash for hash-chaining
            const prevHashResult = await client.query(`
                SELECT record_hash FROM ingress_attestations
                ORDER BY attested_at DESC, id DESC
                LIMIT 1;
            `);
            const prevHash = prevHashResult.rows[0]?.record_hash ?? '';

            // Insert attestation with hash-chaining
            const result = await client.query(`
                INSERT INTO ingress_attestations (
                    request_id,
                    idempotency_key,
                    caller_identity,
                    signature,
                    prev_hash,
                    execution_started,
                    execution_completed
                ) VALUES ($1, $2, $3, $4, $5, FALSE, FALSE)
                RETURNING id, request_id, idempotency_key, record_hash, attested_at;
            `, [
                envelope.requestId,
                envelope.idempotencyKey,
                envelope.callerId,
                envelope.signature,
                prevHash
            ]);

            const row = result.rows[0];
            this.lastHash = row.record_hash;

            logger.info({
                event: 'INGRESS_ATTESTED',
                attestationId: row.id,
                requestId: envelope.requestId,
                recordHash: row.record_hash.substring(0, 16) + '...'
            });

            return {
                id: row.id,
                requestId: row.request_id,
                idempotencyKey: row.idempotency_key,
                recordHash: row.record_hash,
                attestedAt: row.attested_at
            };
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Unknown error';
            logger.error({ error: message }, 'Attestation failed');
            throw new AttestationFailedError(`Could not create attestation: ${message}`);
        } finally {
            client.release();
        }
    }

    /**
     * Mark attestation as execution started
     */
    public async markExecutionStarted(attestationId: string, attestedAt: Date): Promise<void> {
        await this.pool.query(
            `UPDATE ingress_attestations SET execution_started = TRUE WHERE id = $1 AND attested_at = $2`,
            [attestationId, attestedAt]
        );
    }

    /**
     * Mark attestation as execution completed
     */
    public async markExecutionCompleted(
        attestationId: string,
        attestedAt: Date,
        status: 'SUCCESS' | 'FAILED' | 'REPAIRED'
    ): Promise<void> {
        await this.pool.query(
            `UPDATE ingress_attestations 
             SET execution_completed = TRUE, terminal_status = $3 
             WHERE id = $1 AND attested_at = $2`,
            [attestationId, attestedAt, status]
        );
    }

    /**
     * Validate the ingress envelope
     */
    private validateEnvelope(envelope: IngressEnvelope): void {
        if (!envelope.requestId || typeof envelope.requestId !== 'string') {
            throw new InvalidEnvelopeError('Missing or invalid requestId');
        }
        if (!envelope.idempotencyKey || typeof envelope.idempotencyKey !== 'string') {
            throw new InvalidEnvelopeError('Missing or invalid idempotencyKey');
        }
        if (!envelope.callerId || typeof envelope.callerId !== 'string') {
            throw new InvalidEnvelopeError('Missing or invalid callerId');
        }
        if (!envelope.signature || typeof envelope.signature !== 'string') {
            throw new InvalidEnvelopeError('Missing or invalid signature');
        }
    }
}

/**
 * Express Middleware Factory
 * 
 * Creates middleware that attests every request before passing to handlers.
 */
export function createIngressAttestationMiddleware(pool: Pool) {
    const service = new IngressAttestationService(pool);

    return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
        try {
            // Extract envelope from request
            const envelope: IngressEnvelope = {
                requestId: req.headers['x-request-id'] as string ?? crypto.randomUUID(),
                idempotencyKey: req.headers['x-idempotency-key'] as string ?? crypto.randomUUID(),
                callerId: (req as { tenantId?: string }).tenantId ?? 'UNKNOWN',
                signature: req.headers['x-signature'] as string ?? 'UNSIGNED',
                timestamp: new Date().toISOString()
            };

            // Attest before execution
            const attestation = await service.attest(envelope);

            // Attach to request for downstream use
            (req as { attestation?: AttestationRecord }).attestation = attestation;

            // Mark execution started
            await service.markExecutionStarted(attestation.id, attestation.attestedAt);

            // Capture completion on response finish
            res.on('finish', async () => {
                const status = res.statusCode < 400 ? 'SUCCESS' : 'FAILED';
                await service.markExecutionCompleted(attestation.id, attestation.attestedAt, status);
            });

            next();
        } catch (error) {
            next(error);
        }
    };
}


