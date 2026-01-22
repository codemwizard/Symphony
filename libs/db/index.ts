import pg from 'pg';
import { AsyncLocalStorage } from 'node:async_hooks';
import { ErrorSanitizer } from '../errors/sanitizer.js';
import { logger } from '../logging/logger.js';
import { assertDbRole, DB_ROLES, DbRole } from './roles.js';
import { pool } from './pool.js';

export type Queryable = {
    query<T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]): Promise<pg.QueryResult<T>>;
};

export type TxClient = Queryable;

export type RoleBoundClient = Queryable;

export type ListenHandle = {
    close: () => Promise<void>;
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

async function resetRole(client: pg.PoolClient, context: string): Promise<boolean> {
    try {
        await client.query('RESET ROLE');
        return true;
    } catch (error) {
        logger.warn({ error }, `[DB] Failed to reset role during ${context}`);
        return false;
    }
}

function releaseClient(client: pg.PoolClient, forceDestroy: boolean, context: string): void {
    try {
        if (forceDestroy) {
            client.release(new Error(`[DB] Forcing client destroy after ${context}`));
        } else {
            client.release();
        }
    } catch (error) {
        logger.error({ error }, `[DB] Failed to release client during ${context}`);
    }
}

const TAINTED_CLIENT = Symbol('tainted_client');

function markTainted(error: unknown): Error {
    const wrapped = error instanceof Error ? error : new Error(String(error));
    (wrapped as Error & { [TAINTED_CLIENT]?: boolean })[TAINTED_CLIENT] = true;
    return wrapped;
}

function isTainted(error: unknown): boolean {
    return Boolean((error as { [TAINTED_CLIENT]?: boolean } | undefined)?.[TAINTED_CLIENT]);
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
        let commitAttempted = false;
        try {
            await client.query('BEGIN');
            await client.query(`SET LOCAL ROLE ${quoteIdentifier(role)}`);
            await verifyRole(client, role);

            const txClient: TxClient = {
                query: <T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]) =>
                    client.query<T>(text, params)
            };

            const result = await callback(txClient);
            commitAttempted = true;
            await client.query('COMMIT');
            return result;
        } catch (error) {
            let rollbackFailed = false;
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                rollbackFailed = true;
                logger.error({ error: rollbackError }, '[DB] Failed to rollback transaction');
            }
            const sanitized = ErrorSanitizer.sanitize(error, 'DatabaseLayer:TransactionFailed');
            if (commitAttempted || rollbackFailed) {
                throw markTainted(sanitized);
            }
            throw sanitized;
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
        let forceDestroy = false;
        try {
            await client.query(`SET ROLE ${quoteIdentifier(validatedRole)}`);
            await verifyRole(client, validatedRole);
            return await client.query<T>(text, params);
        } catch (error) {
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:QueryAsRoleFailure');
        } finally {
            const resetOk = await resetRole(client, 'queryAsRole');
            forceDestroy = !resetOk;
            releaseClient(client, forceDestroy, 'queryAsRole');
        }
    },

    /**
     * Scoped client wrapper for multi-step work without forcing a transaction.
     */
    withRoleClient: async <T>(role: DbRole, callback: (client: RoleBoundClient) => Promise<T>): Promise<T> => {
        const validatedRole = assertDbRole(role);
        const client = await pool.connect();
        let forceDestroy = false;
        try {
            await client.query(`SET ROLE ${quoteIdentifier(validatedRole)}`);
            await verifyRole(client, validatedRole);

            const roleBoundClient: RoleBoundClient = {
                query: <T extends pg.QueryResultRow = pg.QueryResultRow>(text: string, params?: unknown[]) =>
                    client.query<T>(text, params)
            };

            return await callback(roleBoundClient);
        } catch (error) {
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:WithRoleClientFailure');
        } finally {
            const resetOk = await resetRole(client, 'withRoleClient');
            forceDestroy = !resetOk;
            releaseClient(client, forceDestroy, 'withRoleClient');
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
        let forceDestroy = false;
        try {
            return await runTransaction(client, validatedRole, callback);
        } catch (error) {
            if (isTainted(error)) {
                forceDestroy = true;
            }
            throw error;
        } finally {
            const resetOk = await resetRole(client, 'transactionAsRole');
            forceDestroy = forceDestroy || !resetOk;
            releaseClient(client, forceDestroy, 'transactionAsRole');
        }
    },

    listenAsRole: async (
        role: DbRole,
        channel: string,
        onNotify: (notification: pg.Notification) => void
    ): Promise<ListenHandle> => {
        const validatedRole = assertDbRole(role);
        const client = await pool.connect();
        let listenerAttached = false;
        const handler = (notification: pg.Notification) => {
            if (notification.channel === channel) {
                onNotify(notification);
            }
        };

        try {
            await client.query(`SET ROLE ${quoteIdentifier(validatedRole)}`);
            await verifyRole(client, validatedRole);
            await client.query(`LISTEN ${quoteIdentifier(channel)}`);
            client.on('notification', handler);
            listenerAttached = true;
        } catch (error) {
            const resetOk = await resetRole(client, 'listenAsRole');
            releaseClient(client, !resetOk, 'listenAsRole');
            throw ErrorSanitizer.sanitize(error, 'DatabaseLayer:ListenAsRoleFailure');
        }

        return {
            close: async (): Promise<void> => {
                if (!listenerAttached) return;
                listenerAttached = false;
                client.removeListener('notification', handler);
                try {
                    await client.query(`UNLISTEN ${quoteIdentifier(channel)}`);
                } catch (error) {
                    logger.warn({ error }, '[DB] Failed to unlisten channel');
                } finally {
                    const resetOk = await resetRole(client, 'listenAsRole');
                    releaseClient(client, !resetOk, 'listenAsRole');
                }
            }
        };
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
            releaseClient(client, false, 'probeRoles');
        }
    }
};

export { DbRole };
export { isLeaseLostError } from './errors.js';
