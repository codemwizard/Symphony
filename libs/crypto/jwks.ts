/**
 * SEC-7R-FIX: JWKS Key Management
 * 
 * Provides JWKS-style key distribution for ES256 JWT verification.
 * Phase 1: Static file loading
 * Phase 2+: Upgradeable to /.well-known/jwks.json endpoint
 */

import { createLocalJWKSet, JSONWebKeySet } from 'jose';
import fs from 'fs';
import path from 'path';
import { logger } from '../logging/logger.js';

// Cached JWKS for performance with TTL
let cachedJWKS: ReturnType<typeof createLocalJWKSet> | null = null;
let lastCacheTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Load public keys from static JWKS file.
 * Keys are cached for performance with periodic refresh.
 * 
 * @throws Error if JWKS file is missing or malformed
 */
export function getJWKS(): ReturnType<typeof createLocalJWKSet> {
    const now = Date.now();
    if (cachedJWKS && (now - lastCacheTime < CACHE_TTL_MS)) {
        return cachedJWKS;
    }

    const cwd = process.cwd();
    const jwksPath = process.env.JWKS_PATH
        ? path.resolve(cwd, process.env.JWKS_PATH)
        : path.resolve(cwd, 'config', 'jwks.json');

    if (process.env.JWKS_PATH && !jwksPath.startsWith(`${cwd}${path.sep}`)) {
        throw new Error('Security Violation: JWKS_PATH must resolve within project root.');
    }

    const nodeEnv = process.env.NODE_ENV ?? '';
    const isProtectedEnv = ['production', 'staging'].includes(nodeEnv);
    const allowDevFallback =
        ['development', 'test'].includes(nodeEnv) || process.env.ALLOW_DEV_JWKS_FALLBACK === 'true';

    if (!fs.existsSync(jwksPath)) {
        if (isProtectedEnv) {
            throw new Error(`CRITICAL: JWKS file missing at ${jwksPath}`);
        }
        if (!allowDevFallback) {
            throw new Error(`JWKS file not found at ${jwksPath}. Fallback disabled.`);
        }

        logger.warn({ path: jwksPath }, 'JWKS file not found - using explicit development fallback');
        // Development fallback: create a minimal JWKS with the stored dev key
        const devJwks: JSONWebKeySet = {
            keys: [{
                kty: 'EC',
                crv: 'P-256',
                x: 'placeholder',
                y: 'placeholder',
                kid: 'dev-key-1',
                use: 'sig',
                alg: 'ES256'
            }]
        };
        cachedJWKS = createLocalJWKSet(devJwks);
        lastCacheTime = now;
        return cachedJWKS;
    }

    try {
        const raw = JSON.parse(fs.readFileSync(jwksPath, 'utf-8')) as JSONWebKeySet;

        // Validate structure
        if (!raw.keys || !Array.isArray(raw.keys) || raw.keys.length === 0) {
            throw new Error('JWKS must contain at least one key');
        }

        cachedJWKS = createLocalJWKSet(raw);
        lastCacheTime = now;
        logger.info({ keyCount: raw.keys.length }, 'JWKS loaded successfully');
        return cachedJWKS;
    } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error';
        throw new Error(`Failed to load JWKS: ${message}`);
    }
}

/**
 * Clear the cached JWKS (for testing or key rotation).
 */
export function clearJWKSCache(): void {
    cachedJWKS = null;
}
