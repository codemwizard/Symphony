import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('payment_outbox_attempts append-only trigger', () => {
    let queryNoRole: typeof import('symphony/libs/db/testOnly')['queryNoRole'];

    before(async () => {
        if (!databaseUrl) return;
        process.env.NODE_ENV = 'test';
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');

        ({ queryNoRole } = await import('symphony/libs/db/testOnly'));
    });

    function getSqlState(err: unknown): string | undefined {
        const anyErr = err as {
            code?: string;
            sqlState?: string;
            internalDetails?: { sqlState?: string };
            cause?: { code?: string; sqlState?: string };
        };
        return anyErr?.code ?? anyErr?.sqlState ?? anyErr?.internalDetails?.sqlState ?? anyErr?.cause?.code ?? anyErr?.cause?.sqlState;
    }

    async function insertAttempt(): Promise<string> {
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
                'inst-test',
                'participant-test',
                1,
                'idem-test',
                'PAYMENT',
                '{"hello":"world"}'::jsonb,
                1,
                'DISPATCHING'
            )
            RETURNING attempt_id
            `
        );
        const row = result.rows[0];
        assert.ok(row?.attempt_id);
        return row.attempt_id;
    }

    it('blocks UPDATE via immutability trigger (P0001)', async () => {
        await queryNoRole('BEGIN');
        try {
            const attemptId = await insertAttempt();
            await assert.rejects(
                () => queryNoRole(
                    'UPDATE payment_outbox_attempts SET rail_reference = $1 WHERE attempt_id = $2',
                    ['ref-test', attemptId]
                ),
                (err: unknown) => getSqlState(err) === 'P0001'
            );
        } finally {
            await queryNoRole('ROLLBACK');
        }
    });

    it('blocks DELETE via immutability trigger (P0001)', async () => {
        await queryNoRole('BEGIN');
        try {
            const attemptId = await insertAttempt();
            await assert.rejects(
                () => queryNoRole('DELETE FROM payment_outbox_attempts WHERE attempt_id = $1', [attemptId]),
                (err: unknown) => getSqlState(err) === 'P0001'
            );
        } finally {
            await queryNoRole('ROLLBACK');
        }
    });
});
