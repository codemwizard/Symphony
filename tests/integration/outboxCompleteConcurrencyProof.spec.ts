import { describe, it, before, beforeEach, after } from 'node:test';
import assert from 'node:assert';
import crypto from 'node:crypto';
import { claimOutboxBatch, completeOutboxAttempt } from '../../libs/outbox/db.js';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('Outbox completion concurrency proof', () => {
    let db: Awaited<typeof import('../../libs/db/index.js')>['db'];
    let queryNoRole: typeof import('../../libs/db/testOnly.js')['queryNoRole'];
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

    it('allows exactly one completion and rejects others with P7002', async () => {
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

        const [lease] = await claimOutboxBatch('symphony_executor', 1, 'worker-a', 60, db);
        assert.ok(lease);

        const attempts = Array.from({ length: 5 }, () =>
            completeOutboxAttempt('symphony_executor', {
                outbox_id: lease.outbox_id,
                lease_token: lease.lease_token,
                worker_id: 'worker-a',
                state: 'DISPATCHED'
            }, db)
        );

        const results = await Promise.allSettled(attempts);
        const successes = results.filter(result => result.status === 'fulfilled');
        const failures = results.filter(result => result.status === 'rejected');

        assert.strictEqual(successes.length, 1);
        assert.strictEqual(failures.length, 4);
        failures.forEach(result => {
            const error = (result as PromiseRejectedResult).reason;
            assert.strictEqual(getSqlState(error), 'P7002');
        });
    });
});
