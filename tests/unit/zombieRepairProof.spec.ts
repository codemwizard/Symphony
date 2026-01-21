import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Zombie repair proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let worker: InstanceType<Awaited<typeof import('../../libs/repair/ZombieRepairWorker.js')>['ZombieRepairWorker']>;
    let queryNoRole: typeof import('../../libs/db/testOnly.js')['queryNoRole'];
    let outboxId: string;
    let instructionId: string;
    let participantId: string;
    let sequenceId: number;
    let idempotencyKey: string;

    before(async () => {
        if (!databaseUrl) return;
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');
        process.env.ZOMBIE_THRESHOLD_SECONDS = '1';
        const dbModule = await import('../../libs/db/index.js');
        ({ queryNoRole } = await import('../../libs/db/testOnly.js'));
        const workerModule = await import('../../libs/repair/ZombieRepairWorker.js');
        db = dbModule.db;
        worker = new workerModule.ZombieRepairWorker('symphony_executor', db);
    });

    beforeEach(async () => {
        if (!databaseUrl) return;
        await queryNoRole(`
            TRUNCATE
                payment_outbox_pending,
                payment_outbox_attempts,
                participant_outbox_sequences
            RESTART IDENTITY
            CASCADE;
        `);
    });

    after(async () => {
        if (!outboxId) return;
        await db.queryAsRole('symphony_executor', 'DELETE FROM payment_outbox_pending WHERE outbox_id = $1', [outboxId]);
    });

    it('requeues stale dispatching attempt with ZOMBIE_REQUEUE and same outbox_id', async () => {
        outboxId = crypto.randomUUID();
        instructionId = `inst_${crypto.randomUUID()}`;
        participantId = `participant_${crypto.randomUUID()}`;
        sequenceId = Math.floor(Math.random() * 100000) + 1;
        idempotencyKey = `idem_${crypto.randomUUID()}`;

        await db.queryAsRole(
            'symphony_executor',
            `
            INSERT INTO payment_outbox_attempts (
                outbox_id,
                instruction_id,
                participant_id,
                sequence_id,
                idempotency_key,
                rail_type,
                payload,
                state,
                attempt_no,
                claimed_at,
                created_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, 'DISPATCHING', 1, NOW() - INTERVAL '10 seconds', NOW());
        `,
            [
                outboxId,
                instructionId,
                participantId,
                sequenceId,
                idempotencyKey,
                'PAYMENT',
                JSON.stringify({ amount: 10, currency: 'USD', destination: 'test' })
            ]
        );

        const result = await worker.runRepairCycle();
        assert.strictEqual(result.errors.length, 0);
        assert.strictEqual(result.zombiesRequeued, 1);

        const pending = await db.queryAsRole(
            'symphony_executor',
            'SELECT outbox_id, attempt_count FROM payment_outbox_pending WHERE outbox_id = $1',
            [outboxId]
        );
        assert.strictEqual(pending.rows.length, 1);
        assert.strictEqual(pending.rows[0]?.outbox_id, outboxId);
        assert.strictEqual(pending.rows[0]?.attempt_count, 1);

        const attempts = await db.queryAsRole(
            'symphony_executor',
            `
            SELECT attempt_no, state
            FROM payment_outbox_attempts
            WHERE outbox_id = $1
            ORDER BY attempt_no ASC;
        `,
            [outboxId]
        );

        assert.strictEqual(attempts.rows.length >= 2, true);
        assert.strictEqual(attempts.rows[0]?.attempt_no, 1);
        assert.strictEqual(attempts.rows[0]?.state, 'DISPATCHING');
        assert.strictEqual(attempts.rows[1]?.attempt_no, 2);
        assert.strictEqual(attempts.rows[1]?.state, 'ZOMBIE_REQUEUE');
    });
});
