/**
 * Unit Tests: Ingress Attestation Middleware
 * 
 * Tests envelope validation and hash-chaining.
 * Refactored to use node:test and call production code.
 * 
 * @see libs/attestation/IngressAttestationMiddleware.ts
 */

import { describe, it, beforeEach, mock } from 'node:test';
import assert from 'node:assert';
import { Pool } from 'pg';
import { IngressAttestationService, IngressEnvelope } from '../../libs/attestation/IngressAttestationMiddleware.js';

describe('IngressAttestationService', () => {
    let service: IngressAttestationService;
    let mockPool: { connect: ReturnType<typeof mock.fn>; query: ReturnType<typeof mock.fn> };
    let mockClient: { query: ReturnType<typeof mock.fn>; release: ReturnType<typeof mock.fn> };

    beforeEach(() => {
        mockClient = {
            query: mock.fn(),
            release: mock.fn()
        };
        mockPool = {
            connect: mock.fn(async () => mockClient),
            query: mock.fn() // method not used by service directly, but good to have
        };
        service = new IngressAttestationService(mockPool as unknown as Pool);
    });

    describe('attest()', () => {
        it('should validate and insert attestation record', async () => {
            mockClient.query = mock.fn(async (sql: string) => {
                if (typeof sql === 'string' && sql.includes('SELECT record_hash')) {
                    return { rows: [{ record_hash: 'prev-hash-123' }] };
                }
                if (typeof sql === 'string' && sql.includes('INSERT INTO')) {
                    return {
                        rows: [{
                            id: 'att-1',
                            request_id: 'req-1',
                            idempotency_key: 'idempotency-key-1',
                            record_hash: 'new-hash-456',
                            attested_at: new Date()
                        }]
                    };
                }
                return { rows: [] };
            });

            const envelope = {
                requestId: 'req-1',
                idempotencyKey: 'idempotency-key-1',
                callerId: 'tenant-1',
                signature: 'sig-1',
                timestamp: new Date().toISOString()
            };

            const result = await service.attest(envelope);

            assert.strictEqual(result.id, 'att-1');
            assert.strictEqual(result.recordHash, 'new-hash-456');

            // Verify calls
            assert.strictEqual(mockPool.connect.mock.calls.length, 1);
            assert.strictEqual(mockClient.query.mock.calls.length, 2); // Select prev + Insert
            assert.strictEqual(mockClient.release.mock.calls.length, 1);
        });

        it('should throw InvalidEnvelopeError for missing fields', async () => {
            const envelope: Partial<IngressEnvelope> = {
                requestId: 'req-1',
                // Missing idempotencyKey
                callerId: 'tenant-1',
                signature: 'sig-1',
                timestamp: new Date().toISOString()
            };

            await assert.rejects(
                async () => service.attest(envelope as IngressEnvelope),
                { name: 'InvalidEnvelopeError' }
            );
        });

        it('should release client on error', async () => {
            mockClient.query = mock.fn(async () => {
                throw new Error('DB Error');
            });

            const envelope: IngressEnvelope = {
                requestId: 'req-1',
                idempotencyKey: 'key-1',
                callerId: 'tenant-1',
                signature: 'sig-1',
                timestamp: new Date().toISOString()
            };

            await assert.rejects(
                async () => service.attest(envelope),
                { message: /Could not create attestation/ }
            );

            assert.strictEqual(mockClient.release.mock.calls.length, 1, 'Should release client even on error');
        });
    });

    // Polyfill for beforeEach since node:test doesn't have it natively in older versions or strictly typed
    // Actually node:test supports beforeEach/afterEach in recent versions.
    // But since I used 'before' and manual setup in previous tests, I'll stick to manual setup inside tests or use a helper if needed.
    // Wait, node:test DOES have beforeEach. I will use a simple setup function instead to be safe and explicit.
});
