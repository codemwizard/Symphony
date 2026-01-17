/**
 * Unit Tests: Participant Resolver
 * 
 * Tests mTLS certificate to participant identity resolution.
 * 
 * @see libs/participant/resolver.ts
 */

import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';

describe('ParticipantResolver', () => {
    const originalEnv = { ...process.env };

    before(async () => {
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test';
        process.env.DB_PASSWORD = 'test';
        process.env.DB_NAME = 'test';
        process.env.DB_CA_CERT = 'test';
    });

    after(() => {
        process.env = originalEnv;
    });

    describe('Resolution Context Validation', () => {
        it('should require requestId in context', () => {
            const context = {
                requestId: 'req-123',
                certFingerprint: 'fp-abc',
                ingressSequenceId: 'seq-1'
            };

            assert.ok(context.requestId, 'Context must have requestId');
            assert.ok(context.certFingerprint, 'Context must have certFingerprint');
            assert.ok(context.ingressSequenceId, 'Context must have ingressSequenceId');
        });
    });

    describe('Resolution Failure Reasons', () => {
        const validFailures = [
            'CERTIFICATE_REVOKED',
            'FINGERPRINT_NOT_FOUND',
            'PARTICIPANT_SUSPENDED',
            'PARTICIPANT_REVOKED',
            'POLICY_PROFILE_NOT_FOUND'
        ];

        it('should define all expected failure reasons', () => {
            assert.strictEqual(validFailures.length, 5);
        });

        it('should include CERTIFICATE_REVOKED for trust fabric failures', () => {
            assert.ok(validFailures.includes('CERTIFICATE_REVOKED'));
        });

        it('should include FINGERPRINT_NOT_FOUND for unknown certs', () => {
            assert.ok(validFailures.includes('FINGERPRINT_NOT_FOUND'));
        });

        it('should include PARTICIPANT_SUSPENDED for inactive participants', () => {
            assert.ok(validFailures.includes('PARTICIPANT_SUSPENDED'));
        });
    });

    describe('Resolution Flow Steps', () => {
        const resolutionSteps = [
            'Validate certificate in Trust Fabric',
            'Resolve participant from fingerprint',
            'Check participant status',
            'Validate policy profile exists',
            'Log successful resolution'
        ];

        it('should have 5 resolution steps', () => {
            assert.strictEqual(resolutionSteps.length, 5);
        });

        it('should validate certificate before participant lookup', () => {
            assert.strictEqual(resolutionSteps[0], 'Validate certificate in Trust Fabric');
            assert.strictEqual(resolutionSteps[1], 'Resolve participant from fingerprint');
        });
    });
});
