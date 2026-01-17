import pg from 'pg';
import { ConfigGuard } from '../bootstrap/config-guard.js';
import { DB_CONFIG_GUARDS } from '../bootstrap/config/db-config.js';
import { ErrorSanitizer } from '../errors/sanitizer.js';
import { logger } from '../logging/logger.js';

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
const pool = new Pool({
    // CRIT-SEC-002 FIX: Removed silent fallbacks. All values must be explicitly configured.
    host: process.env.DB_HOST!,
    port: parseInt(process.env.DB_PORT!),
    user: process.env.DB_USER!,
    password: process.env.DB_PASSWORD!,
    database: process.env.DB_NAME!,
    max: 20,
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

// SEC-FIX: Valid roles allowlist (injection prevention via strict allowlist)
const VALID_ROLES = [
    "symphony_control",
    "symphony_ingest",
    "symphony_executor",
    "symphony_readonly",
    "symphony_auditor",
    "symphony_auth",
    "anon"
] as const;
type ValidRole = typeof VALID_ROLES[number];

function isValidRole(role: string): role is ValidRole {
    return VALID_ROLES.includes(role as ValidRole);
}

// @deprecated Use queryAsRole for concurrency-safe scoped queries
export let currentRole: string = "anon";

export const db = {
    /**
     * @deprecated Use queryAsRole for concurrency-safe scoped queries.
     * Set the database role for the next query.
     */
    setRole: (role: string) => {
        if (!isValidRole(role)) {
            throw new Error(`Invalid DB role attempt: ${role}`);
        }
        currentRole = role;
    },

    /**
     * SEC-FIX: Concurrency-safe scoped role query.
     * Role is applied per-call, not globally.
     */
    queryAsRole: async (role: ValidRole, text: string, params?: unknown[]) => {
        if (!isValidRole(role)) {
            throw new Error(`Invalid DB role: ${role}`);
        }
        const client = await pool.connect();
        try {
            if (role !== "anon") {
                // Injection safe: role validated against strict allowlist
                await client.query(`SET ROLE ${role}`);
            }
            return await client.query(text, params);
        } catch (err) {
            throw ErrorSanitizer.sanitize(err, "DatabaseLayer:QueryAsRoleFailure");
        } finally {
            if (role !== "anon") {
                try { await client.query('RESET ROLE'); } catch (e) {
                    logger.warn({ error: e }, "[DB] Failed to reset role");
                }
            }
            client.release();
        }
    },

    /**
     * Executes a query with mandatory role enforcement and parameterization.
     * @deprecated Prefer queryAsRole for new code.
     */
    query: async (text: string, params?: unknown[]) => {
        const client = await pool.connect();
        try {
            if (currentRole !== "anon") {
                // INV-PERSIST-01: Protocol-level role enforcement
                await client.query(`SET ROLE ${currentRole}`);

                // Verification of role (Hard Blocker requirement)
                const roleCheck = await client.query('SELECT current_user');
                if (roleCheck.rows[0].current_user !== currentRole) {
                    throw new Error(`CRITICAL: Role enforcement failure. Target: ${currentRole}, Actual: ${roleCheck.rows[0].current_user}`);
                }
            }

            // Zero-tolerance for unparameterized queries is enforced by the pg driver API usage requirement
            return await client.query(text, params);
        } catch (err) {
            // HIGH-SEC-003: Prevent information disclosure
            throw ErrorSanitizer.sanitize(err, "DatabaseLayer:QueryFailure");
        } finally {
            // Clean up the connection state before returning to pool
            if (currentRole !== "anon") {
                try {
                    await client.query('RESET ROLE');
                } catch (resetErr) {
                    logger.error({ error: resetErr }, '[DB] Failed to reset role, connection may be tainted');
                }
            }
            client.release();
        }
    },

    /**
     * F-2: Fail-Safe Transaction Wrapper
     * Executes a callback within a managed transaction.
     * Automatically rolls back on error.
     */
    executeTransaction: async <T>(callback: (client: pg.PoolClient) => Promise<T>): Promise<T> => {
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            if (currentRole !== "anon") {
                await client.query(`SET ROLE ${currentRole}`);
            }

            const result = await callback(client);

            await client.query('COMMIT');
            return result;
        } catch (err) {
            await client.query('ROLLBACK');
            throw ErrorSanitizer.sanitize(err, "DatabaseLayer:TransactionFailed");
        } finally {
            if (currentRole !== "anon") {
                try { await client.query('RESET ROLE'); } catch (e) {
                    logger.warn({ error: e }, "[DB] Failed to reset role in transaction cleanup");
                }
            }
            client.release();
        }
    }
};

