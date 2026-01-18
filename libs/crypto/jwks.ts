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

// Cached JWKS for performance
let cachedJWKS: ReturnType<typeof createLocalJWKSet> | null = null;

/**
 * Load public keys from static JWKS file.
 * Keys are cached for the lifetime of the process.
 * 
 * @throws Error if JWKS file is missing or malformed
 */
export function getJWKS(): ReturnType<typeof createLocalJWKSet> {
    if (cachedJWKS) {
        return cachedJWKS;
    }

    const jwksPath = process.env.JWKS_PATH
        ? path.resolve(process.cwd(), process.env.JWKS_PATH)
        : path.resolve(process.cwd(), 'config', 'jwks.json');

    const isProtectedEnv = ['production', 'staging'].includes(process.env.NODE_ENV ?? '');
    const allowDevFallback = process.env.ALLOW_DEV_JWKS_FALLBACK === 'true';

    if (!fs.existsSync(jwksPath)) {
        if (isProtectedEnv || !allowDevFallback) {
            throw new Error(`JWKS file not found at ${jwksPath}. Fallback disabled.`);
        }

        logger.warn({ path: jwksPath }, 'JWKS file not found - using explicit development fallback');
        // Development fallback: create a minimal JWKS with the stored dev key
        const devJwks: JSONWebKeySet = {
            keys: [{
                kty: 'EC',
                crv: 'P-256',
                // These are placeholder values for development
                // In production, this file MUST exist with real keys
                x: 'placeholder',
                y: 'placeholder',
                kid: 'dev-key-1',
                use: 'sig',
                alg: 'ES256'
            }]
        };
        cachedJWKS = createLocalJWKSet(devJwks);
        return cachedJWKS;
    }

    try {
        const raw = JSON.parse(fs.readFileSync(jwksPath, 'utf-8')) as JSONWebKeySet;

        // Validate structure
        if (!raw.keys || !Array.isArray(raw.keys) || raw.keys.length === 0) {
            throw new Error('JWKS must contain at least one key');
        }

        cachedJWKS = createLocalJWKSet(raw);
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
