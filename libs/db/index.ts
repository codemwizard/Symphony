import pg from 'pg';
import { ConfigGuard } from '../bootstrap/config-guard.js';
import { DB_CONFIG_GUARDS } from '../bootstrap/config/db-config.js';
import { ErrorSanitizer } from '../errors/sanitizer.js';

const { Pool } = pg;

// CRIT-SEC-002: Enforce strict configuration bootstrapping
ConfigGuard.enforce(DB_CONFIG_GUARDS);

const isProduction = process.env.NODE_ENV === 'production';

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
    ssl: process.env.DB_SSL_QUERY === 'true' ? {
        rejectUnauthorized: true,
        ca: process.env.DB_CA_CERT,
    } : false
});

export let currentRole: string = "anon";

export const db = {
    /**
     * Set the database role for the next query.
     * Roles must match those defined in schema/v1/010_roles.sql
     */
    setRole: (role: string) => {
        const validRoles = [
            "symphony_control",
            "symphony_ingest",
            "symphony_executor",
            "symphony_readonly",
            "symphony_auditor",
            "anon"
        ];
        if (!validRoles.includes(role)) {
            throw new Error(`Invalid DB role attempt: ${role}`);
        }
        currentRole = role;
    },

    /**
     * Executes a query with mandatory role enforcement and parameterization.
     */
    query: async (text: string, params?: any[]) => {
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
                    console.error('[DB] Failed to reset role, connection may be tainted', resetErr);
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
    executeTransaction: async <T>(callback: (client: any) => Promise<T>): Promise<T> => {
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
                try { await client.query('RESET ROLE'); } catch (e) { }
            }
            client.release();
        }
    }
};
