import { describe, it, before } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';
import { OutboxRelayer } from '../../libs/outbox/OutboxRelayer.js';

const hasDbConfig = process.env.RUN_DB_TESTS === 'true' && Boolean(
    process.env.DB_HOST &&
    process.env.DB_PORT &&
    process.env.DB_USER &&
    process.env.DB_PASSWORD &&
    process.env.DB_NAME
);

const describeWithDb = hasDbConfig ? describe : describe.skip;

describeWithDb('Outbox concurrency/idempotency proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let relayer: OutboxRelayer;

    before(async () => {
        const dbModule = await import('../../libs/db/index.js');
        db = dbModule.db;

        const railClient = {
            dispatch: async () => ({ success: true, railReference: 'ref-ok' })
        };
        relayer = new OutboxRelayer(railClient, 'symphony_executor', db);
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
                attempt_no: number;
                created_at: Date;
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
