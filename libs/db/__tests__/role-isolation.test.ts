import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import { DbRole } from '../roles.js';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('DB role isolation', () => {
    let db: Awaited<typeof import('../index.js')>['db'];

    before(async () => {
        if (!databaseUrl) return;
        process.env.NODE_ENV = 'test';
        process.env.DB_POOL_MAX ??= '2';
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');
        const dbModule = await import('../index.js');
        db = dbModule.db;
    });

    it('does not leak roles across concurrent queryAsRole calls', async () => {
        const roleA: DbRole = 'symphony_readonly';
        const roleB: DbRole = 'symphony_control';

        const tasks: Promise<{ current_user: string; session_user: string }>[] = [];
        for (let i = 0; i < 20; i += 1) {
            const role = i % 2 === 0 ? roleA : roleB;
            tasks.push(db.queryAsRole<{ current_user: string; session_user: string }>(
                role,
                'SELECT current_user, session_user'
            ).then(res => {
                const row = res.rows[0];
                assert.ok(row);
                return row;
            }));
        }

        const results = await Promise.all(tasks);
        results.forEach((row, index) => {
            const expected = index % 2 === 0 ? roleA : roleB;
            assert.equal(row.current_user, expected);
            assert.ok(row.session_user);
        });
    });
});
