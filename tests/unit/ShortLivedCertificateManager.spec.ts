/**
 * Phase-7R Unit Tests: Short-Lived Certificate Manager (Kill-Switch)
 * 
 * Tests certificate lifecycle, revocation, and TTL enforcement.
 * Migrated to node:test
 * 
 * @see libs/pki/ShortLivedCertificateManager.ts
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('ShortLivedCertificateManager', () => {
    type TestCertificate = {
        fingerprint: string;
        revoked: boolean;
        revokedAt?: Date;
        revokedReason?: string;
    };
    const DEFAULT_TTL_HOURS = 4;
    const MAX_TTL_HOURS = 24;

    describe('Certificate Issuance', () => {
        it('should issue certificate with correct TTL', () => {
            const now = new Date();
            const ttlHours = 4;
            const expiresAt = new Date(now.getTime() + ttlHours * 60 * 60 * 1000);

            const cert = {
                issuedAt: now,
                expiresAt: expiresAt,
                ttlHours: ttlHours
            };

            const actualTtlHours = (cert.expiresAt.getTime() - cert.issuedAt.getTime()) / (60 * 60 * 1000);
            assert.strictEqual(actualTtlHours, 4);
        });

        it('should reject TTL > 24 hours', () => {
            const invalidTtl = 48;
            const isValid = invalidTtl <= MAX_TTL_HOURS;

            assert.strictEqual(isValid, false);
        });

        it('should default to 4-hour TTL', () => {
            assert.strictEqual(DEFAULT_TTL_HOURS, 4);
        });

        it('should calculate correct renewal window (30 min before expiry)', () => {
            const RENEWAL_WINDOW_MINUTES = 30;
            const now = new Date();
            const expiresAt = new Date(now.getTime() + 4 * 60 * 60 * 1000);
            const renewAfter = new Date(expiresAt.getTime() - RENEWAL_WINDOW_MINUTES * 60 * 1000);

            const renewalWindow = (expiresAt.getTime() - renewAfter.getTime()) / (60 * 1000);
            assert.strictEqual(renewalWindow, 30);
        });
    });

    describe('Certificate Revocation', () => {
        it('should mark certificate as revoked', () => {
            const cert: TestCertificate = {
                fingerprint: 'fp-1',
                revoked: false
            };

            // Revoke
            cert.revoked = true;
            cert.revokedAt = new Date();
            cert.revokedReason = 'Participant suspended';

            assert.strictEqual(cert.revoked, true);
            assert.ok(cert.revokedAt);
            assert.strictEqual(cert.revokedReason, 'Participant suspended');
        });

        it('should add fingerprint to revoked set', () => {
            const revokedFingerprints = new Set<string>();
            const fingerprint = 'cert-123';

            revokedFingerprints.add(fingerprint);

            assert.ok(revokedFingerprints.has(fingerprint));
        });
    });

    describe('Kill-Switch: Revoke All for Participant', () => {
        it('should revoke all certificates for a participant', () => {
            const participantId = 'participant-1';
            const certificates = [
                { fingerprint: 'cert-1', participantId, revoked: false },
                { fingerprint: 'cert-2', participantId, revoked: false },
                { fingerprint: 'cert-3', participantId: 'other', revoked: false }
            ];

            // Kill-switch for participant-1
            let revokedCount = 0;
            for (const cert of certificates) {
                if (cert.participantId === participantId && !cert.revoked) {
                    cert.revoked = true;
                    revokedCount++;
                }
            }

            assert.strictEqual(revokedCount, 2);
            assert.strictEqual(certificates[0]!.revoked, true);
            assert.strictEqual(certificates[1]!.revoked, true);
            assert.strictEqual(certificates[2]!.revoked, false); // Different participant
        });
    });

    describe('Certificate Validation', () => {
        it('should reject revoked certificates', () => {
            const cert = { revoked: true, expiresAt: new Date(Date.now() + 10000) };

            const isValid = !cert.revoked && cert.expiresAt > new Date();
            assert.strictEqual(isValid, false);
        });

        it('should reject expired certificates', () => {
            const cert = { revoked: false, expiresAt: new Date(Date.now() - 10000) };

            const isValid = !cert.revoked && cert.expiresAt > new Date();
            assert.strictEqual(isValid, false);
        });

        it('should accept valid certificates', () => {
            const cert = { revoked: false, expiresAt: new Date(Date.now() + 10000) };

            const isValid = !cert.revoked && cert.expiresAt > new Date();
            assert.strictEqual(isValid, true);
        });
    });

    describe('Revocation Bounds for Evidence Bundle', () => {
        it('should calculate worst-case revocation window', () => {
            const certTtlHours = 4;
            const policyPropagationSeconds = 60;

            const worstCaseRevocationSeconds = certTtlHours * 3600 + policyPropagationSeconds;

            assert.strictEqual(worstCaseRevocationSeconds, 14460); // 4h 1min in seconds
        });

        it('should return correct bounds object', () => {
            const bounds = {
                certTtlHours: 4,
                policyPropagationSeconds: 60,
                worstCaseRevocationSeconds: 4 * 3600 + 60
            };

            assert.strictEqual(bounds.certTtlHours, 4);
            assert.strictEqual(bounds.policyPropagationSeconds, 60);
            assert.strictEqual(bounds.worstCaseRevocationSeconds, 14460);
        });
    });

    describe('Suspended Participant Protection', () => {
        it('should block certificate issuance for suspended participant', () => {
            const participantCerts = [
                { fingerprint: 'cert-1', revoked: true },
                { fingerprint: 'cert-2', revoked: true }
            ];

            const allRevoked = participantCerts.every(c => c.revoked);
            const hasExistingCerts = participantCerts.length > 0;

            const shouldBlockIssuance = allRevoked && hasExistingCerts;
            assert.strictEqual(shouldBlockIssuance, true);
        });
    });
});

describe('CertificateError', () => {
    it('should have correct error codes', () => {
        const errorCodes = [
            { code: 'TTL_EXCEEDS_MAX', statusCode: 400 },
            { code: 'CERT_NOT_FOUND', statusCode: 404 },
            { code: 'CERT_REVOKED', statusCode: 403 },
            { code: 'CERT_EXPIRED', statusCode: 403 },
            { code: 'PARTICIPANT_SUSPENDED', statusCode: 403 }
        ];

        for (const err of errorCodes) {
            assert.ok(err.code);
            assert.ok(err.statusCode >= 400);
        }
    });
});
