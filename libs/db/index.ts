import pg from 'pg';
import { AsyncLocalStorage } from 'node:async_hooks';
import { ConfigGuard } from '../bootstrap/config-guard.js';
import { DB_CONFIG_GUARDS } from '../bootstrap/config/db-config.js';
import { ErrorSanitizer } from '../errors/sanitizer.js';
import { logger } from '../logging/logger.js';
import { assertDbRole, DB_ROLES, DbRole } from './roles.js';

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

export type Queryable = {
    query<T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]): Promise<pg.QueryResult<T>>;
};

export type TxClient = Queryable;

export type RoleBoundClient = Queryable & {
    transaction<T>(callback: (client: TxClient) => Promise<T>): Promise<T>;
};

const transactionContext = new AsyncLocalStorage<{ inTx: boolean }>();

function quoteIdentifier(identifier: string): string {
    const escaped = identifier.replace(/"/g, '""');
    return `"${escaped}"`;
}

async function verifyRole(client: pg.PoolClient, role: DbRole): Promise<void> {
    const roleCheck = await client.query('SELECT current_user');
    const currentUser = roleCheck.rows[0]?.current_user;
    if (currentUser !== role) {
        throw new Error(`CRITICAL: Role enforcement failure. Target: ${role}, Actual: ${currentUser}`);
    }
}

async function resetRole(client: pg.PoolClient, context: string): Promise<void> {
    try {
        await client.query('RESET ROLE');
    } catch (error) {
        logger.warn({ error }, `[DB] Failed to reset role during ${context}`);
    }
}

async function runTransaction<T>(
    client: pg.PoolClient,
    role: DbRole,
    callback: (tx: TxClient) => Promise<T>
): Promise<T> {
    const store = transactionContext.getStore();
    if (store?.inTx) {
        throw new Error('Nested transaction detected: transactionAsRole cannot be invoked within an active transaction.');
    }

    return transactionContext.run({ inTx: true }, async () => {
        try {
            await client.query('BEGIN');
            await client.query(`SET LOCAL ROLE ${quoteIdentifier(role)}`);
            await verifyRole(client, role);

            const txClient: TxClient = {
                query: <T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]) =>
                    client.query<T>(text, params)
            };

            const result = await callback(txClient);
            await client.query('COMMIT');
            return result;
        } catch (error) {
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                logger.error({ error: rollbackError }, '[DB] Failed to rollback transaction');
            }
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:TransactionFailed');
        }
    });
}

export const db = {
    /**
     * SEC-FIX: Concurrency-safe scoped role query.
     * Role is applied per-call, not globally.
     */
    queryAsRole: async <T extends pg.QueryResultRow = pg.QueryResultRow>(
        role: DbRole,
        text: string,
        params?: unknown[]
    ): Promise<pg.QueryResult<T>> => {
        const validatedRole = assertDbRole(role);
        const client = await pool.connect();
        try {
            await client.query(`SET ROLE ${quoteIdentifier(validatedRole)}`);
            await verifyRole(client, validatedRole);
            return await client.query<T>(text, params);
        } catch (error) {
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:QueryAsRoleFailure');
        } finally {
            await resetRole(client, 'queryAsRole');
            client.release();
        }
    },

    /**
     * Scoped client wrapper for multi-step work without forcing a transaction.
     */
    withClientAsRole: async <T>(role: DbRole, callback: (client: RoleBoundClient) => Promise<T>): Promise<T> => {
        const validatedRole = assertDbRole(role);
        const client = await pool.connect();
        try {
            await client.query(`SET ROLE ${quoteIdentifier(validatedRole)}`);
            await verifyRole(client, validatedRole);

            const roleBoundClient: RoleBoundClient = {
                query: <T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]) =>
                    client.query<T>(text, params),
                transaction: async (txCallback) => runTransaction(client, validatedRole, txCallback)
            };

            return await callback(roleBoundClient);
        } catch (error) {
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:WithClientAsRoleFailure');
        } finally {
            await resetRole(client, 'withClientAsRole');
            client.release();
        }
    },

    /**
     * F-2: Fail-Safe Transaction Wrapper
     * Executes a callback within a managed transaction.
     * Automatically rolls back on error.
     */
    transactionAsRole: async <T>(role: DbRole, callback: (client: TxClient) => Promise<T>): Promise<T> => {
        const validatedRole = assertDbRole(role);
        const client = await pool.connect();
        try {
            return await runTransaction(client, validatedRole, callback);
        } finally {
            await resetRole(client, 'transactionAsRole');
            client.release();
        }
    },

    /**
     * Boot-time probe to ensure DB_USER can SET ROLE into each required role.
     */
    probeRoles: async (): Promise<void> => {
        const client = await pool.connect();
        try {
            for (const role of DB_ROLES) {
                await client.query('BEGIN');
                try {
                    await client.query(`SET LOCAL ROLE ${quoteIdentifier(role)}`);
                    await verifyRole(client, role);
                    await client.query('ROLLBACK');
                } catch (error) {
                    try {
                        await client.query('ROLLBACK');
                    } catch (rollbackError) {
                        logger.error({ error: rollbackError }, '[DB] Failed to rollback role probe');
                    }
                    throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:ProbeRolesFailure');
                }
            }
        } finally {
            client.release();
        }
    }
};

export { DbRole };
