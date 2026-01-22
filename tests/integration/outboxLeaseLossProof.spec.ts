import { describe, it, before, beforeEach, after } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';
import { claimOutboxBatch, completeOutboxAttempt } from '../../libs/outbox/db.js';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Outbox lease loss proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let queryNoRole: typeof import('../../libs/db/testOnly.js')['queryNoRole'];
    let originalNodeEnv: string | undefined;
    let outboxId: string;

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

    after(() => {
        if (!databaseUrl) return;
        process.env.NODE_ENV = originalNodeEnv;
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

    it('rejects stale completion with P7002 and allows current lease completion', async () => {
        const instructionId = `inst_${crypto.randomUUID()}`;
        const participantId = `participant_${crypto.randomUUID()}`;
        const idempotencyKey = `idem_${crypto.randomUUID()}`;

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

        const [leaseA] = await claimOutboxBatch('symphony_executor', 1, 'worker-a', 60, db);
        assert.ok(leaseA);
        outboxId = leaseA.outbox_id;

        await queryNoRole(
            `
            UPDATE payment_outbox_pending
            SET lease_expires_at = NOW() - INTERVAL '1 second'
            WHERE outbox_id = $1;
        `,
            [outboxId]
        );

        const [leaseB] = await claimOutboxBatch('symphony_executor', 1, 'worker-b', 60, db);
        assert.ok(leaseB);

        await assert.rejects(
            () =>
                completeOutboxAttempt('symphony_executor', {
                    outbox_id: outboxId,
                    lease_token: leaseA.lease_token,
                    worker_id: 'worker-a',
                    state: 'DISPATCHED'
                }, db),
            (err: unknown) => getSqlState(err) === 'P7002'
        );

        const completed = await completeOutboxAttempt('symphony_executor', {
            outbox_id: outboxId,
            lease_token: leaseB.lease_token,
            worker_id: 'worker-b',
            state: 'DISPATCHED'
        }, db);
        assert.strictEqual(completed.state, 'DISPATCHED');
    });
});
