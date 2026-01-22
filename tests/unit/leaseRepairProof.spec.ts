import { describe, it, before, after, beforeEach } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';
import { claimOutboxBatch, repairExpiredLeases } from '../../libs/outbox/db.js';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Lease repair proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let queryNoRole: typeof import('../../libs/db/testOnly.js')['queryNoRole'];
    let outboxId: string;
    let instructionId: string;
    let participantId: string;
    let idempotencyKey: string;

    before(async () => {
        if (!databaseUrl) return;
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');
        const dbModule = await import('../../libs/db/index.js');
        ({ queryNoRole } = await import('../../libs/db/testOnly.js'));
        db = dbModule.db;
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

    it('repairs expired lease with ZOMBIE_REQUEUE and clears lease fields', async () => {
        outboxId = crypto.randomUUID();
        instructionId = `inst_${crypto.randomUUID()}`;
        participantId = `participant_${crypto.randomUUID()}`;
        idempotencyKey = `idem_${crypto.randomUUID()}`;

        await db.queryAsRole(
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
                JSON.stringify({ amount: 10, currency: 'USD', destination: 'test' })
            ]
        );

        const claimed = await claimOutboxBatch('symphony_executor', 1, 'worker-lease-proof', 60, db);
        assert.strictEqual(claimed.length, 1);
        outboxId = claimed[0]!.outbox_id;

        await queryNoRole(
            `
            UPDATE payment_outbox_pending
            SET lease_expires_at = NOW() - INTERVAL '1 second'
            WHERE outbox_id = $1;
        `,
            [outboxId]
        );

        const repaired = await repairExpiredLeases('symphony_executor', 10, 'worker-lease-proof', db);
        assert.strictEqual(repaired.length, 1);

        const pending = await db.queryAsRole(
            'symphony_executor',
            `
            SELECT outbox_id, attempt_count, claimed_by, lease_token, lease_expires_at, next_attempt_at
            FROM payment_outbox_pending
            WHERE outbox_id = $1
        `,
            [outboxId]
        );
        assert.strictEqual(pending.rows.length, 1);
        assert.strictEqual(pending.rows[0]?.outbox_id, outboxId);
        assert.ok(Number(pending.rows[0]?.attempt_count) >= 1);
        assert.strictEqual(pending.rows[0]?.claimed_by, null);
        assert.strictEqual(pending.rows[0]?.lease_token, null);
        assert.strictEqual(pending.rows[0]?.lease_expires_at, null);
        assert.ok(pending.rows[0]?.next_attempt_at);

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

        assert.strictEqual(attempts.rows.length, 1);
        assert.strictEqual(attempts.rows[0]?.attempt_no, 1);
        assert.strictEqual(attempts.rows[0]?.state, 'ZOMBIE_REQUEUE');
    });
});
