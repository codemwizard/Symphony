import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import { DbRole } from '../roles.js';

const hasDbConfig = process.env.RUN_DB_TESTS === 'true' && Boolean(
    process.env.DB_HOST &&
    process.env.DB_PORT &&
    process.env.DB_USER &&
    process.env.DB_PASSWORD &&
    process.env.DB_NAME
);

const describeWithDb = hasDbConfig ? describe : describe.skip;

describeWithDb('DB role residue', () => {
    let db: Awaited<typeof import('../index.js')>['db'];
    let testOnly: typeof import('../testOnly.js');

    before(async () => {
        process.env.NODE_ENV = 'test';
        process.env.DB_POOL_MAX = '1';
        const dbModule = await import('../index.js');
        db = dbModule.db;
        testOnly = await import('../testOnly.js');
    });

    it('returns a clean client to the pool after role-scoped query', async () => {
        const role: DbRole = 'symphony_control';
        const res = await db.queryAsRole(role, 'SELECT current_user');
        const roleRow = res.rows[0];
        assert.ok(roleRow);
        assert.equal(roleRow.current_user, role);

        const clean = await testOnly.queryNoRole('SELECT current_user, session_user');
        const row = clean.rows[0];
        assert.ok(row);
        assert.equal(row.current_user, row.session_user);
        assert.notEqual(row.current_user, role);
    });
});
