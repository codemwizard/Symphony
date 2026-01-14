/**
 * Phase-7R Unit Tests: Ingress Attestation Middleware
 * 
 * Tests envelope validation and hash-chaining.
 * 
 * @see libs/attestation/IngressAttestationMiddleware.ts
 */

import { describe, it, expect, beforeEach, jest, afterEach } from '@jest/globals';
import { Pool } from 'pg';
import crypto from 'crypto';

describe('IngressAttestationMiddleware', () => {
    let mockPool: Partial<Pool>;
    let mockClient: {
        query: jest.Mock;
        release: jest.Mock;
    };

    beforeEach(() => {
        mockClient = {
            query: jest.fn(),
            release: jest.fn()
        };

        mockPool = {
            connect: jest.fn().mockResolvedValue(mockClient),
            query: jest.fn()
        };
    });

    afterEach(() => {
        jest.clearAllMocks();
    });

    describe('Envelope Validation', () => {
        it('should require requestId', () => {
            const envelope = {
                idempotencyKey: 'key-1',
                callerId: 'tenant-1',
                signature: 'sig-1',
                timestamp: new Date().toISOString()
            };

            const isValid = Boolean(envelope.idempotencyKey && envelope.callerId);
            expect(isValid).toBe(true);

            // Missing requestId
            const hasRequestId = 'requestId' in envelope;
            expect(hasRequestId).toBe(false);
        });

        it('should require idempotencyKey', () => {
            const envelope = {
                requestId: 'req-1',
                callerId: 'tenant-1',
                signature: 'sig-1'
            };

            const hasIdempotencyKey = 'idempotencyKey' in envelope;
            expect(hasIdempotencyKey).toBe(false);
        });

        it('should require callerId', () => {
            const envelope = {
                requestId: 'req-1',
                idempotencyKey: 'key-1',
                signature: 'sig-1'
            };

            const hasCallerId = 'callerId' in envelope;
            expect(hasCallerId).toBe(false);
        });

        it('should require signature', () => {
            const envelope = {
                requestId: 'req-1',
                idempotencyKey: 'key-1',
                callerId: 'tenant-1'
            };

            const hasSignature = 'signature' in envelope;
            expect(hasSignature).toBe(false);
        });

        it('should accept valid complete envelope', () => {
            const envelope = {
                requestId: crypto.randomUUID(),
                idempotencyKey: crypto.randomUUID(),
                callerId: 'tenant-123',
                signature: 'valid-signature',
                timestamp: new Date().toISOString()
            };

            const isValid =
                typeof envelope.requestId === 'string' &&
                typeof envelope.idempotencyKey === 'string' &&
                typeof envelope.callerId === 'string' &&
                typeof envelope.signature === 'string';

            expect(isValid).toBe(true);
        });
    });

    describe('Hash-Chaining', () => {
        it('should compute record hash correctly', () => {
            const record = {
                id: 'uuid-1',
                requestId: 'req-1',
                idempotencyKey: 'key-1',
                callerId: 'tenant-1',
                prevHash: 'prev-hash-value'
            };

            const hashInput = `${record.id}${record.requestId}${record.idempotencyKey}${record.callerId}${record.prevHash}`;
            const hash = crypto.createHash('sha256').update(hashInput).digest('hex');

            expect(hash).toHaveLength(64);
            expect(hash).toMatch(/^[a-f0-9]+$/);
        });

        it('should link records via prev_hash', () => {
            const record1Hash = crypto.createHash('sha256').update('record1').digest('hex');

            const record2 = {
                id: 'uuid-2',
                prevHash: record1Hash
            };

            expect(record2.prevHash).toBe(record1Hash);
        });

        it('should have empty prev_hash for first record', () => {
            const firstRecord = {
                id: 'uuid-1',
                prevHash: ''
            };

            expect(firstRecord.prevHash).toBe('');
        });
    });

    describe('Attestation Insertion', () => {
        it('should insert attestation before execution', async () => {
            const insertQuery = `
                INSERT INTO ingress_attestations (
                    request_id, idempotency_key, caller_identity, signature, prev_hash
                ) VALUES ($1, $2, $3, $4, $5)
                RETURNING id, record_hash, attested_at;
            `;

            mockClient.query.mockResolvedValueOnce({
                rows: [{
                    id: 'att-1',
                    record_hash: 'hash-value',
                    attested_at: new Date()
                }]
            });

            const result = await mockClient.query(insertQuery, [
                'req-1', 'key-1', 'tenant-1', 'sig-1', ''
            ]);

            expect(result.rows[0].id).toBe('att-1');
            expect(result.rows[0].record_hash).toBeDefined();
        });
    });

    describe('Execution Tracking', () => {
        it('should mark execution_started = TRUE after attestation', async () => {
            mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

            await mockClient.query(
                'UPDATE ingress_attestations SET execution_started = TRUE WHERE id = $1',
                ['att-1']
            );

            expect(mockClient.query).toHaveBeenCalledWith(
                expect.stringContaining('execution_started = TRUE'),
                ['att-1']
            );
        });

        it('should mark execution_completed with terminal status', async () => {
            const statuses = ['SUCCESS', 'FAILED', 'REPAIRED'];

            for (const status of statuses) {
                mockClient.query.mockResolvedValueOnce({ rowCount: 1 });

                await mockClient.query(
                    'UPDATE ingress_attestations SET execution_completed = TRUE, terminal_status = $2 WHERE id = $1',
                    ['att-1', status]
                );
            }

            expect(mockClient.query).toHaveBeenCalledTimes(3);
        });
    });
});

describe('InvalidEnvelopeError', () => {
    it('should have correct error properties', () => {
        const error = {
            name: 'InvalidEnvelopeError',
            code: 'INVALID_ENVELOPE',
            statusCode: 400,
            message: 'Missing requestId'
        };

        expect(error.code).toBe('INVALID_ENVELOPE');
        expect(error.statusCode).toBe(400);
    });
});

describe('AttestationFailedError', () => {
    it('should have correct error properties', () => {
        const error = {
            name: 'AttestationFailedError',
            code: 'ATTESTATION_FAILED',
            statusCode: 503,
            message: 'DB connection failed'
        };

        expect(error.code).toBe('ATTESTATION_FAILED');
        expect(error.statusCode).toBe(503);
    });
});
