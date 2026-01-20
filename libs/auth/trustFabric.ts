/**
 * Symphony Trust Fabric Registry (SEC-FIX)
 * DB-backed, fail-closed certificate trust resolution.
 * 
 * SEC-FIX: Replaces static REGISTRY with DB + cache.
 * - Throws TrustViolationError (not null)
 * - Positive TTL: 500ms, Negative TTL: 200ms
 * - Stampede avoidance via inflight promise map
 * - Scoped DB role (no global state)
 */

import { LRUCache } from 'lru-cache';
import { db } from '../db/index.js';
import { TrustViolationError, TrustViolationCode } from './TrustViolationError.js';

export interface ServiceCertificateClaims {
    serviceName: string;
    ou: string;
    env: string;
    fingerprint: string;
}

// Positive cache: valid certs (500ms TTL)
const positiveCache = new LRUCache<string, ServiceCertificateClaims>({
    max: 1000,
    ttl: 500,
});

// Negative cache: unknown/revoked/expired (200ms TTL, prevents DB hammer)
const negativeCache = new LRUCache<string, TrustViolationCode>({
    max: 1000,
    ttl: 200,
});

// Inflight promise map (stampede avoidance)
const inflight = new Map<string, Promise<ServiceCertificateClaims>>();

// Current environment (canonical)
const SYMPHONY_ENV = process.env.SYMPHONY_ENV || process.env.NODE_ENV || 'development';

export class TrustFabric {
    /**
     * Resolve service identity from certificate fingerprint.
     * SEC-FIX: Async, throws TrustViolationError, DB-backed, cached.
     */
    static async resolveIdentity(fingerprint: string): Promise<ServiceCertificateClaims> {
        const fp = fingerprint.trim();

        // 1. Check positive cache
        const cached = positiveCache.get(fp);
        if (cached) return cached;

        // 2. Check negative cache
        const negCode = negativeCache.get(fp);
        if (negCode) {
            throw new TrustViolationError(negCode, fp);
        }

        // 3. Check inflight (stampede avoidance)
        const existing = inflight.get(fp);
        if (existing) return existing;

        // 4. Query DB (scoped role)
        const promise = this.fetchFromDB(fp);
        inflight.set(fp, promise);

        try {
            const claims = await promise;
            positiveCache.set(fp, claims);
            return claims;
        } catch (err) {
            if (err instanceof TrustViolationError) {
                negativeCache.set(fp, err.code);
            }
            throw err;
        } finally {
            inflight.delete(fp);
        }
    }

    private static async fetchFromDB(fp: string): Promise<ServiceCertificateClaims> {
        const result = await db.queryAsRole<{
            serviceName: string;
            ou: string;
            env: string;
            fingerprint: string;
            revoked: boolean;
            expires_at: string;
            status: string;
        }>(
            'symphony_auth',
            `SELECT p.name as "serviceName", p.ou, c.env, c.fingerprint, c.revoked, c.expires_at, p.status
             FROM participant_certificates c
             JOIN participants p ON c.participant_id = p.id
             WHERE c.fingerprint = $1
             LIMIT 1`,
            [fp]
        );

        if (result.rows.length === 0) {
            throw new TrustViolationError('TRUST_CERT_UNKNOWN', fp);
        }

        const row = result.rows[0];
        if (!row) {
            throw new TrustViolationError('TRUST_CERT_UNKNOWN', fp);
        }

        // SEC-FIX: Validate revoked
        if (row.revoked === true) {
            throw new TrustViolationError('TRUST_CERT_REVOKED', fp);
        }

        // SEC-FIX: Validate expiry
        if (new Date(row.expires_at) <= new Date()) {
            throw new TrustViolationError('TRUST_CERT_EXPIRED', fp);
        }

        // SEC-FIX: Validate participant status
        if (row.status !== 'ACTIVE') {
            throw new TrustViolationError('TRUST_PARTICIPANT_INACTIVE', fp);
        }

        // SEC-FIX: Validate environment binding
        if (row.env !== SYMPHONY_ENV) {
            throw new TrustViolationError('TRUST_ENV_MISMATCH', fp,
                `Certificate env '${row.env}' does not match system env '${SYMPHONY_ENV}'`);
        }

        return {
            serviceName: row.serviceName,
            ou: row.ou,
            env: row.env,
            fingerprint: row.fingerprint,
        };
    }

    /**
     * @deprecated Static revocation is replaced by DB-backed revocation.
     */
    static revoke(_fingerprint: string): void {
        // No-op: revocation is now handled via DB update
        throw new Error('Static revocation is deprecated. Update participant_certificates.revoked in DB.');
    }
}
