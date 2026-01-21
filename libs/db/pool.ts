import pg from 'pg';
import { ConfigGuard } from '../bootstrap/config-guard.js';
import { DB_CONFIG_GUARDS } from '../bootstrap/config/db-config.js';

const { Pool } = pg;

// CRIT-SEC-002: Enforce strict configuration bootstrapping
ConfigGuard.enforce(DB_CONFIG_GUARDS);

// SEC-FIX: Pre-pool CA validation (fail before pool creation)
const isProtectedEnv = process.env.NODE_ENV === 'production' || process.env.NODE_ENV === 'staging';
if (isProtectedEnv && !process.env.DB_CA_CERT) {
    throw new Error("CRITICAL: Missing DB_CA_CERT in protected environment (production/staging). Database connection aborted.");
}

// SEC-FIX: Forbid DB_SSL_QUERY=false in protected environments
if (isProtectedEnv && process.env.DB_SSL_QUERY === 'false') {
    throw new Error("CRITICAL: DB_SSL_QUERY=false is forbidden in production/staging.");
}

/**
 * INV-PERSIST-01: Persistence Reality
 * Hardened PostgreSQL connection with connection pooling and mandatory role enforcement.
 */
const poolMax = process.env.DB_POOL_MAX ? parseInt(process.env.DB_POOL_MAX, 10) : 20;
export const pool = new Pool({
    // CRIT-SEC-002 FIX: Removed silent fallbacks. All values must be explicitly configured.
    host: process.env.DB_HOST!,
    port: parseInt(process.env.DB_PORT!),
    user: process.env.DB_USER!,
    password: process.env.DB_PASSWORD!,
    database: process.env.DB_NAME!,
    max: Number.isFinite(poolMax) ? poolMax : 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
    ssl: isProtectedEnv
        ? {
            rejectUnauthorized: true,
            ca: process.env.DB_CA_CERT,
        }
        : (process.env.DB_SSL_QUERY === 'true' ? {
            rejectUnauthorized: true,
            ca: process.env.DB_CA_CERT,
        } : false)
});
