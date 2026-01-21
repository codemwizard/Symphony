import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { DbRole } from '../../libs/db/roles.js';

const databaseUrl = process.env.DATABASE_URL;

const describeWithDb = databaseUrl ? describe : describe.skip;

function assertSqlStateOneOf(err: unknown, allowed: string[]): boolean {
    const anyErr = err as { sqlState?: string; code?: string; cause?: { sqlState?: string; code?: string } };
    const sqlState = anyErr?.sqlState ?? anyErr?.code ?? anyErr?.cause?.sqlState ?? anyErr?.cause?.code;
    return typeof sqlState === 'string' && allowed.includes(sqlState);
}

function getSqlState(err: unknown): string | undefined {
    const anyErr = err as { sqlState?: string; code?: string; cause?: { sqlState?: string; code?: string } };
    return anyErr?.sqlState ?? anyErr?.code ?? anyErr?.cause?.sqlState ?? anyErr?.cause?.code;
}

describeWithDb('Outbox privilege enforcement', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let queryNoRole: typeof import('symphony/libs/db/testOnly')['queryNoRole'];
    let originalNodeEnv: string | undefined;

    before(async () => {
        if (!databaseUrl) return;
        originalNodeEnv = process.env.NODE_ENV;
        process.env.NODE_ENV = 'test';
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');

        const dbModule = await import('../../libs/db/index.js');
        db = dbModule.db;
        ({ queryNoRole } = await import('symphony/libs/db/testOnly'));
    });

    after(() => {
        if (!databaseUrl) return;
        process.env.NODE_ENV = originalNodeEnv;
    });

    async function queryAsRole<T>(role: DbRole, sql: string, params?: unknown[]): Promise<T> {
        const result = await db.queryAsRole(role, sql, params);
        return result as T;
    }

    async function insertAttemptRow(): Promise<string> {
        const suffix = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
        const result = await queryNoRole<{ attempt_id: string }>(
            `
            INSERT INTO payment_outbox_attempts (
                outbox_id,
                instruction_id,
                participant_id,
                sequence_id,
                idempotency_key,
                rail_type,
                payload,
                attempt_no,
                state
            )
            VALUES (
                uuidv7(),
                $1,
                $2,
                $3,
                $4,
                'PAYMENT',
                '{"hello":"world"}'::jsonb,
                1,
                'DISPATCHING'
            )
            RETURNING attempt_id
            `,
            [
                `inst-${suffix}`,
                `participant-${suffix}`,
                Math.floor(Math.random() * 100000) + 1,
                `idem-${suffix}`
            ]
        );
        const row = result.rows[0];
        assert.ok(row?.attempt_id);
        return row.attempt_id;
    }

    it('blocks ingest from inserting into payment_outbox_pending', async () => {
        await assert.rejects(
            () => queryAsRole(
                'symphony_ingest',
                `
                INSERT INTO payment_outbox_pending (
                    instruction_id,
                    participant_id,
                    sequence_id,
                    idempotency_key,
                    rail_type,
                    payload
                ) VALUES ('inst-test', 'participant-test', 1, 'idem-test', 'PAYMENT', '{}'::jsonb);
                `
            ),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for ingest insert pending:', getSqlState(err));
                }
                return ok;
            }
        );
    });

    it('blocks readonly from inserting into payment_outbox_pending', async () => {
        await assert.rejects(
            () => queryAsRole(
                'symphony_readonly',
                `
                INSERT INTO payment_outbox_pending (
                    instruction_id,
                    participant_id,
                    sequence_id,
                    idempotency_key,
                    rail_type,
                    payload
                ) VALUES ('inst-test', 'participant-test', 1, 'idem-test', 'PAYMENT', '{}'::jsonb);
                `
            ),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for readonly insert pending:', getSqlState(err));
                }
                return ok;
            }
        );
    });

    it('blocks executor from updating or deleting payment_outbox_attempts', async () => {
        const attemptId = await insertAttemptRow();
        await assert.rejects(
            () => queryAsRole(
                'symphony_executor',
                "UPDATE payment_outbox_attempts SET error_message = 'x' WHERE attempt_id = $1;",
                [attemptId]
            ),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for executor update attempts:', getSqlState(err));
                }
                return ok;
            }
        );

        await assert.rejects(
            () => queryAsRole(
                'symphony_executor',
                'DELETE FROM payment_outbox_attempts WHERE attempt_id = $1;',
                [attemptId]
            ),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for executor delete attempts:', getSqlState(err));
                }
                return ok;
            }
        );
    });

    it('rejects TRUNCATE on outbox tables for runtime roles', async () => {
        await assert.rejects(
            () => queryAsRole('symphony_executor', 'TRUNCATE payment_outbox_attempts;'),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for executor truncate attempts:', getSqlState(err));
                }
                return ok;
            }
        );

        await assert.rejects(
            () => queryAsRole('symphony_executor', 'TRUNCATE payment_outbox_pending;'),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for executor truncate pending:', getSqlState(err));
                }
                return ok;
            }
        );
    });

    it('revokes sequence table visibility from readonly and auditor roles', async () => {
        await assert.rejects(
            () => queryAsRole('symphony_readonly', 'SELECT * FROM participant_outbox_sequences LIMIT 1;'),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for readonly sequence select:', getSqlState(err));
                }
                return ok;
            }
        );

        await assert.rejects(
            () => queryAsRole('symphony_auditor', 'SELECT * FROM participant_outbox_sequences LIMIT 1;'),
            (err: unknown) => {
                const ok = assertSqlStateOneOf(err, ['42501']);
                if (!ok) {
                    console.error('unexpected sqlState for auditor sequence select:', getSqlState(err));
                }
                return ok;
            }
        );
    });
});
