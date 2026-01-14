/**
 * Phase-7R: Short-Lived Certificate Manager (Kill-Switch)
 * 
 * This module implements the "Kill-Switch" mechanism for participant revocation.
 * Certificates have a maximum TTL of 4 hours and must be renewed through the
 * policy engine, enabling near-instant revocation.
 * 
 * Invariant: Worst-case revocation window = TTL + Policy Propagation Delay
 * Target: TTL ≤ 4h, Policy Propagation ≤ 60s → Max 4h 1min
 * 
 * @see PHASE-7R-implementation_plan.md Section "Kill-Switch"
 */

import pino from 'pino';
import crypto from 'crypto';

const logger = pino({ name: 'CertificateManager' });

// Configuration
const DEFAULT_TTL_HOURS = 4;
const MAX_TTL_HOURS = 24;
const POLICY_PROPAGATION_SECONDS = 60;
const RENEWAL_WINDOW_MINUTES = 30; // Start renewal 30 min before expiry

/**
 * Certificate metadata stored in the identity system
 */
export interface CertificateMetadata {
    fingerprint: string;
    participantId: string;
    issuedAt: Date;
    expiresAt: Date;
    policyVersion: string;
    policyScope: string;
    revoked: boolean;
    revokedAt?: Date;
    revokedReason?: string;
}

/**
 * Certificate issuance request
 */
export interface CertificateRequest {
    participantId: string;
    policyVersion: string;
    policyScope: string;
    ttlHours?: number;
}

/**
 * Certificate issuance result
 */
export interface CertificateResult {
    fingerprint: string;
    certificate: string; // Base64-encoded certificate
    expiresAt: Date;
    renewAfter: Date;
}

/**
 * Error thrown when certificate operations fail
 */
export class CertificateError extends Error {
    readonly code: string;
    readonly statusCode: number;

    constructor(code: string, message: string, statusCode = 500) {
        super(message);
        this.name = 'CertificateError';
        this.code = code;
        this.statusCode = statusCode;
    }
}

/**
 * In-memory certificate store (for development/testing)
 * Production should use a proper certificate authority or vault
 */
const certificateStore = new Map<string, CertificateMetadata>();
const revokedFingerprints = new Set<string>();

/**
 * Short-Lived Certificate Manager
 * 
 * Handles certificate lifecycle with automatic expiry enforcement.
 */
export class ShortLivedCertificateManager {
    private readonly ttlHours: number;

    constructor(ttlHours: number = DEFAULT_TTL_HOURS) {
        if (ttlHours > MAX_TTL_HOURS) {
            throw new CertificateError(
                'TTL_EXCEEDS_MAX',
                `TTL ${ttlHours}h exceeds maximum ${MAX_TTL_HOURS}h`,
                400
            );
        }
        this.ttlHours = ttlHours;
    }

    /**
     * Issue a new short-lived certificate
     */
    public async issueCertificate(request: CertificateRequest): Promise<CertificateResult> {
        // Validate participant is not suspended
        const existingCerts = this.findCertificatesForParticipant(request.participantId);
        const hasRevoked = existingCerts.some(c => c.revoked);

        if (hasRevoked) {
            // Check if ALL certs are revoked (participant suspended)
            const allRevoked = existingCerts.every(c => c.revoked || c.expiresAt < new Date());
            if (allRevoked && existingCerts.length > 0) {
                logger.warn({
                    event: 'CERT_ISSUE_BLOCKED',
                    participantId: request.participantId,
                    reason: 'PARTICIPANT_SUSPENDED'
                });
                throw new CertificateError(
                    'PARTICIPANT_SUSPENDED',
                    'Cannot issue certificate: participant has been suspended',
                    403
                );
            }
        }

        const now = new Date();
        const ttl = request.ttlHours ?? this.ttlHours;
        const expiresAt = new Date(now.getTime() + ttl * 60 * 60 * 1000);
        const renewAfter = new Date(expiresAt.getTime() - RENEWAL_WINDOW_MINUTES * 60 * 1000);

        // Generate certificate (mock implementation)
        const fingerprint = this.generateFingerprint();
        const certificate = this.generateCertificate(request, fingerprint, expiresAt);

        // Store metadata
        const metadata: CertificateMetadata = {
            fingerprint,
            participantId: request.participantId,
            issuedAt: now,
            expiresAt,
            policyVersion: request.policyVersion,
            policyScope: request.policyScope,
            revoked: false
        };

        certificateStore.set(fingerprint, metadata);

        logger.info({
            event: 'CERT_ISSUED',
            fingerprint: fingerprint.substring(0, 16) + '...',
            participantId: request.participantId,
            ttlHours: ttl,
            expiresAt: expiresAt.toISOString()
        });

        return {
            fingerprint,
            certificate,
            expiresAt,
            renewAfter
        };
    }

    /**
     * Revoke a certificate immediately
     */
    public async revokeCertificate(fingerprint: string, reason: string): Promise<void> {
        const metadata = certificateStore.get(fingerprint);

        if (!metadata) {
            throw new CertificateError('CERT_NOT_FOUND', 'Certificate not found', 404);
        }

        if (metadata.revoked) {
            logger.warn({ fingerprint }, 'Certificate already revoked');
            return;
        }

        metadata.revoked = true;
        metadata.revokedAt = new Date();
        metadata.revokedReason = reason;

        revokedFingerprints.add(fingerprint);

        logger.info({
            event: 'CERT_REVOKED',
            fingerprint: fingerprint.substring(0, 16) + '...',
            participantId: metadata.participantId,
            reason
        });
    }

    /**
     * Revoke all certificates for a participant (Kill-Switch)
     */
    public async revokeAllForParticipant(participantId: string, reason: string): Promise<number> {
        const certs = this.findCertificatesForParticipant(participantId);
        let revokedCount = 0;

        for (const cert of certs) {
            if (!cert.revoked) {
                await this.revokeCertificate(cert.fingerprint, reason);
                revokedCount++;
            }
        }

        logger.info({
            event: 'PARTICIPANT_KILL_SWITCH',
            participantId,
            certificatesRevoked: revokedCount,
            reason
        });

        return revokedCount;
    }

    /**
     * Validate a certificate
     */
    public async validateCertificate(fingerprint: string): Promise<CertificateMetadata> {
        const metadata = certificateStore.get(fingerprint);

        if (!metadata) {
            throw new CertificateError('CERT_NOT_FOUND', 'Certificate not found', 404);
        }

        if (metadata.revoked) {
            throw new CertificateError('CERT_REVOKED', 'Certificate has been revoked', 403);
        }

        if (metadata.expiresAt < new Date()) {
            throw new CertificateError('CERT_EXPIRED', 'Certificate has expired', 403);
        }

        return metadata;
    }

    /**
     * Check if a fingerprint is revoked (for OCSP stapling)
     */
    public isRevoked(fingerprint: string): boolean {
        return revokedFingerprints.has(fingerprint);
    }

    /**
     * Get revocation bounds for evidence bundle
     */
    public getRevocationBounds(): {
        certTtlHours: number;
        policyPropagationSeconds: number;
        worstCaseRevocationSeconds: number;
    } {
        return {
            certTtlHours: this.ttlHours,
            policyPropagationSeconds: POLICY_PROPAGATION_SECONDS,
            worstCaseRevocationSeconds: this.ttlHours * 3600 + POLICY_PROPAGATION_SECONDS
        };
    }

    /**
     * Find all certificates for a participant
     */
    private findCertificatesForParticipant(participantId: string): CertificateMetadata[] {
        return Array.from(certificateStore.values())
            .filter(c => c.participantId === participantId);
    }

    /**
     * Generate a certificate fingerprint
     */
    private generateFingerprint(): string {
        return crypto.createHash('sha256')
            .update(crypto.randomBytes(32))
            .digest('hex');
    }

    /**
     * Generate a mock certificate (production would use real PKI)
     */
    private generateCertificate(
        request: CertificateRequest,
        fingerprint: string,
        expiresAt: Date
    ): string {
        const certData = {
            fingerprint,
            participantId: request.participantId,
            policyVersion: request.policyVersion,
            policyScope: request.policyScope,
            expiresAt: expiresAt.toISOString(),
            issuedBy: 'symphony-pki'
        };

        return Buffer.from(JSON.stringify(certData)).toString('base64');
    }
}

/**
 * Default certificate manager instance
 */
export const certificateManager = new ShortLivedCertificateManager();
