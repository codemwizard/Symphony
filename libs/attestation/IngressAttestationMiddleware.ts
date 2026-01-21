/**
 * Phase-7R: Ingress Attestation Middleware
 * 
 * This middleware implements the "No Ingress → No Execution" principle.
 * Every request MUST be attested before execution logic runs.
 * 
 * @see PHASE-7R-implementation_plan.md Section "Ingress Attestation"
 */

import type { Request, Response, NextFunction } from 'express';
import { pino } from 'pino';
import * as crypto from 'crypto';
import { KeyManager, SymphonyKeyManager } from '../crypto/keyManager.js';
import { db, DbRole } from '../db/index.js';

const logger = pino({ name: 'IngressAttestation' });
const keyManager: KeyManager = new SymphonyKeyManager();
let attestationKeyPromise: Promise<Buffer> | null = null;
const MAX_TIMESTAMP_SKEW_MS = 5 * 60 * 1000;

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
        private readonly role: DbRole,
        private readonly dbClient = db
    ) { }

    /**
     * Attest an ingress request
     * 
     * This MUST complete before execution proceeds.
     * If this fails, the request is rejected (Fail-Closed).
     */
    public async attest(envelope: IngressEnvelope): Promise<AttestationRecord> {
        this.validateEnvelope(envelope);

        try {
            return await this.dbClient.withRoleClient(this.role, async (client) => {
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
                if (!row) {
                    throw new Error('Attestation insert returned no rows');
                }
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
            });
        } catch (error: unknown) {
            const message = error instanceof Error ? error.message : 'Unknown error';
            logger.error({ error: message }, 'Attestation failed');
            throw new AttestationFailedError(`Could not create attestation: ${message}`);
        }
    }

    /**
     * Mark attestation as execution started
     */
    public async markExecutionStarted(attestationId: string, attestedAt: Date): Promise<void> {
        await this.dbClient.queryAsRole(
            this.role,
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
        await this.dbClient.queryAsRole(
            this.role,
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
        if (!/^[a-f0-9]{64}$/i.test(envelope.signature)) {
            throw new InvalidEnvelopeError('Invalid signature format');
        }
        if (!envelope.timestamp || Number.isNaN(Date.parse(envelope.timestamp))) {
            throw new InvalidEnvelopeError('Missing or invalid timestamp');
        }
    }
}

/**
 * Express Middleware Factory
 * 
 * Creates middleware that attests every request before passing to handlers.
 */
export function createIngressAttestationMiddleware(role: DbRole, dbClient = db) {
    const service = new IngressAttestationService(role, dbClient);

    return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
        try {
            const signatureHeader = req.headers['x-signature'];
            if (!signatureHeader || typeof signatureHeader !== 'string') {
                throw new InvalidEnvelopeError('Missing x-signature header');
            }
            const timestampHeader = req.headers['x-timestamp'];
            if (!timestampHeader || typeof timestampHeader !== 'string') {
                throw new InvalidEnvelopeError('Missing x-timestamp header');
            }

            // Extract envelope from request
            const envelope: IngressEnvelope = {
                requestId: req.headers['x-request-id'] as string ?? crypto.randomUUID(),
                idempotencyKey: req.headers['x-idempotency-key'] as string ?? crypto.randomUUID(),
                callerId: (req as { tenantId?: string }).tenantId ?? 'UNKNOWN',
                signature: signatureHeader,
                timestamp: timestampHeader
            };

            const bodyHash = computeBodyHash(req.body);
            await verifyIngressSignature(envelope, bodyHash);

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

function stableStringify(value: unknown): string {
    if (value === null || value === undefined) {
        return JSON.stringify(value);
    }

    if (typeof value !== 'object') {
        return JSON.stringify(value);
    }

    if (Array.isArray(value)) {
        return `[${value.map(item => stableStringify(item)).join(',')}]`;
    }

    const record = value as Record<string, unknown>;
    const keys = Object.keys(record).sort();
    const entries = keys.map(key => `"${key}":${stableStringify(record[key])}`);
    return `{${entries.join(',')}}`;
}

function computeBodyHash(body: unknown): string {
    if (body === undefined) {
        return crypto.createHash('sha256').update('').digest('hex');
    }

    if (Buffer.isBuffer(body)) {
        return crypto.createHash('sha256').update(body).digest('hex');
    }

    if (typeof body === 'string') {
        return crypto.createHash('sha256').update(body).digest('hex');
    }

    const serialized = stableStringify(body);
    return crypto.createHash('sha256').update(serialized).digest('hex');
}

async function getAttestationKey(): Promise<Buffer> {
    if (!attestationKeyPromise) {
        attestationKeyPromise = keyManager
            .deriveKey('attestation/hmac')
            .then(key => Buffer.from(key, 'base64'));
    }

    return attestationKeyPromise;
}

function buildSignaturePayload(envelope: IngressEnvelope, bodyHash: string): string {
    return [
        envelope.requestId,
        envelope.idempotencyKey,
        envelope.callerId,
        envelope.timestamp,
        bodyHash
    ].join('|');
}

async function verifyIngressSignature(envelope: IngressEnvelope, bodyHash: string): Promise<void> {
    const now = Date.now();
    const issuedAt = Date.parse(envelope.timestamp);
    if (Number.isNaN(issuedAt)) {
        throw new InvalidEnvelopeError('Invalid timestamp');
    }
    if (Math.abs(now - issuedAt) > MAX_TIMESTAMP_SKEW_MS) {
        throw new InvalidEnvelopeError('Ingress timestamp outside allowable skew');
    }

    const key = await getAttestationKey();
    const payload = buildSignaturePayload(envelope, bodyHash);
    const expected = crypto.createHmac('sha256', key).update(payload).digest('hex');

    const provided = envelope.signature.toLowerCase();
    const expectedBuffer = Buffer.from(expected, 'hex');
    const providedBuffer = Buffer.from(provided, 'hex');

    if (
        expectedBuffer.length !== providedBuffer.length ||
        !crypto.timingSafeEqual(expectedBuffer, providedBuffer)
    ) {
        throw new InvalidEnvelopeError('Invalid ingress signature');
    }
}
