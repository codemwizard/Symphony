import { describe, it, before, beforeEach, after } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';
import { OutboxRelayer } from '../../libs/outbox/OutboxRelayer.js';

const databaseUrl = process.env.DATABASE_URL;
const hasDbConfig = process.env.RUN_DB_TESTS === 'true' && Boolean(
    (databaseUrl || (
        process.env.DB_HOST &&
        process.env.DB_PORT &&
        process.env.DB_USER &&
        process.env.DB_PASSWORD &&
        process.env.DB_NAME
    ))
);

const describeWithDb = hasDbConfig ? describe : describe.skip;

describeWithDb('Outbox concurrency/idempotency proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let relayer: OutboxRelayer;
    let queryNoRole: typeof import('../../libs/db/testOnly.js')['queryNoRole'];
    let originalNodeEnv: string | undefined;

    before(async () => {
        if (databaseUrl) {
            originalNodeEnv = process.env.NODE_ENV;
            process.env.NODE_ENV = 'test';
            const url = new URL(databaseUrl);
            process.env.DB_HOST = url.hostname;
            process.env.DB_PORT = url.port || '5432';
            process.env.DB_USER = decodeURIComponent(url.username);
            process.env.DB_PASSWORD = decodeURIComponent(url.password);
            process.env.DB_NAME = url.pathname.replace(/^\//, '');
        }
        const dbModule = await import('../../libs/db/index.js');
        db = dbModule.db;
        ({ queryNoRole } = await import('../../libs/db/testOnly.js'));

        const railClient = {
            dispatch: async () => ({ success: true, railReference: 'ref-ok' })
        };
        relayer = new OutboxRelayer(railClient, 'symphony_executor', db);
    });

    beforeEach(async () => {
        if (!queryNoRole) return;
        await queryNoRole(`
            TRUNCATE
                payment_outbox_pending,
                payment_outbox_attempts,
                participant_outbox_sequences
            RESTART IDENTITY
            CASCADE;
        `);
    });

    after(() => {
        if (originalNodeEnv !== undefined) {
            process.env.NODE_ENV = originalNodeEnv;
        }
    });

    it('enqueues exactly one logical outbox item and yields one DISPATCHED', async () => {
        const instructionId = `inst_${crypto.randomUUID()}`;
        const idempotencyKey = `idem_${crypto.randomUUID()}`;
        const participantId = `participant_${crypto.randomUUID()}`;

        const tasks = Array.from({ length: 10 }, () =>
            db.queryAsRole(
                'symphony_ingest',
                `
                SELECT outbox_id, sequence_id, created_at, state
                FROM enqueue_payment_outbox($1, $2, $3, $4, $5);
            `,
                [
                    instructionId,
                    participantId,
                    idempotencyKey,
                    'PAYMENT',
                    JSON.stringify({ amount: 10, currency: 'USD', destination: 'dest' })
                ]
            )
        );

        const results = await Promise.all(tasks);
        const outboxIds = results.map(result => result.rows[0]?.outbox_id).filter(Boolean);
        assert.strictEqual(outboxIds.length, 10);
        const uniqueOutboxIds = new Set(outboxIds as string[]);
        assert.strictEqual(uniqueOutboxIds.size, 1);
        const outboxId = outboxIds[0] as string;

        const pending = await db.queryAsRole(
            'symphony_executor',
            `
            SELECT outbox_id
            FROM payment_outbox_pending
            WHERE instruction_id = $1 AND idempotency_key = $2;
        `,
            [instructionId, idempotencyKey]
        );
        assert.strictEqual(pending.rows.length, 1);
        assert.strictEqual(pending.rows[0]?.outbox_id, outboxId);

        const relayerInternal = relayer as unknown as {
            claimNextBatch: () => Promise<Array<{ outbox_id: string }>>;
            processRecord: (record: {
                outbox_id: string;
                instruction_id: string;
                participant_id: string;
                sequence_id: number;
                idempotency_key: string;
                rail_type: string;
                payload: Record<string, unknown>;
                attempt_count: number;
                created_at: Date;
                lease_token: string;
                lease_expires_at: Date;
            }) => Promise<void>;
        };

        const claimed = await relayerInternal.claimNextBatch();
        assert.strictEqual(claimed.length, 1);
        await relayerInternal.processRecord(claimed[0] as never);

        const dispatched = await db.queryAsRole(
            'symphony_executor',
            `
            SELECT COUNT(*)::int AS count
            FROM payment_outbox_attempts
            WHERE outbox_id = $1 AND state = 'DISPATCHED';
        `,
            [outboxId]
        );
        assert.strictEqual(dispatched.rows[0]?.count, 1);
    });
});
