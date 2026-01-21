import { describe, it, before } from 'node:test';
import assert from 'node:assert';
import { DbRole } from '../../libs/db/roles.js';

const databaseUrl = process.env.DATABASE_URL;

const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Outbox privilege enforcement', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];

    before(async () => {
        if (!databaseUrl) return;
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');

        const dbModule = await import('../../libs/db/index.js');
        db = dbModule.db;
    });

    async function queryAsRole<T>(role: DbRole, sql: string, params?: unknown[]): Promise<T> {
        const result = await db.queryAsRole(role, sql, params);
        return result as T;
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
            /permission denied/i
        );
    });

    it('blocks executor from updating or deleting payment_outbox_attempts', async () => {
        await assert.rejects(
            () => queryAsRole('symphony_executor', "UPDATE payment_outbox_attempts SET error_message = 'x' WHERE 1=0;"),
            /permission denied|append-only/i
        );

        await assert.rejects(
            () => queryAsRole('symphony_executor', 'DELETE FROM payment_outbox_attempts WHERE 1=0;'),
            /permission denied|append-only/i
        );
    });

    it('rejects TRUNCATE on outbox tables for runtime roles', async () => {
        await assert.rejects(
            () => queryAsRole('symphony_executor', 'TRUNCATE payment_outbox_attempts;'),
            /permission denied/i
        );

        await assert.rejects(
            () => queryAsRole('symphony_executor', 'TRUNCATE payment_outbox_pending;'),
            /permission denied/i
        );
    });

    it('revokes sequence table visibility from readonly and auditor roles', async () => {
        await assert.rejects(
            () => queryAsRole('symphony_readonly', 'SELECT * FROM participant_outbox_sequences LIMIT 1;'),
            /permission denied/i
        );

        await assert.rejects(
            () => queryAsRole('symphony_auditor', 'SELECT * FROM participant_outbox_sequences LIMIT 1;'),
            /permission denied/i
        );
    });
});
