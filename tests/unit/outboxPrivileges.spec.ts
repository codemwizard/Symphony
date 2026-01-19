import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { Pool, PoolClient } from 'pg';

const databaseUrl = process.env.DATABASE_URL;

const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Outbox privilege enforcement', () => {
    let pool: Pool;

    before(() => {
        pool = new Pool({ connectionString: databaseUrl });
    });

    after(async () => {
        await pool.end();
    });

    async function withRole<T>(role: string, fn: (client: PoolClient) => Promise<T>): Promise<T> {
        const client = await pool.connect();
        try {
            await client.query(`SET ROLE ${role}`);
            return await fn(client);
        } finally {
            await client.query('RESET ROLE');
            client.release();
        }
    }

    it('blocks ingest from inserting into payment_outbox_pending', async () => {
        await assert.rejects(
            () => withRole('symphony_ingest', client => client.query(
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
            )),
            /permission denied/i
        );
    });

    it('blocks executor from updating or deleting payment_outbox_attempts', async () => {
        await assert.rejects(
            () => withRole('symphony_executor', client => client.query(
                "UPDATE payment_outbox_attempts SET error_message = 'x' WHERE 1=0;"
            )),
            /permission denied|append-only/i
        );

        await assert.rejects(
            () => withRole('symphony_executor', client => client.query(
                'DELETE FROM payment_outbox_attempts WHERE 1=0;'
            )),
            /permission denied|append-only/i
        );
    });

    it('rejects TRUNCATE on outbox tables for runtime roles', async () => {
        await assert.rejects(
            () => withRole('symphony_executor', client => client.query(
                'TRUNCATE payment_outbox_attempts;'
            )),
            /permission denied/i
        );

        await assert.rejects(
            () => withRole('symphony_executor', client => client.query(
                'TRUNCATE payment_outbox_pending;'
            )),
            /permission denied/i
        );
    });

    it('revokes sequence table visibility from readonly and auditor roles', async () => {
        await assert.rejects(
            () => withRole('symphony_readonly', client => client.query(
                'SELECT * FROM participant_outbox_sequences LIMIT 1;'
            )),
            /permission denied/i
        );

        await assert.rejects(
            () => withRole('symphony_auditor', client => client.query(
                'SELECT * FROM participant_outbox_sequences LIMIT 1;'
            )),
            /permission denied/i
        );
    });
});
