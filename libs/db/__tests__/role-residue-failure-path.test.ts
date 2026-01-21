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

describeWithDb('DB role residue failure path', () => {
    let db: Awaited<typeof import('../index.js')>['db'];
    let testOnly: Awaited<typeof import('../index.js')>['__testOnly'];

    before(async () => {
        process.env.NODE_ENV = 'test';
        process.env.DB_POOL_MAX = '1';
        const dbModule = await import('../index.js');
        db = dbModule.db;
        testOnly = dbModule.__testOnly;
    });

    it('cleans up role state after query errors', async () => {
        assert.ok(testOnly?.queryNoRole, '__testOnly.queryNoRole must exist in NODE_ENV=test');

        const role: DbRole = 'symphony_control';
        await assert.rejects(
            () => db.queryAsRole(role, 'SELECT 1/0'),
            /division by zero|22012|DatabaseLayer:QueryAsRoleFailure/i
        );

        const clean = await testOnly.queryNoRole('SELECT current_user, session_user');
        const row = clean.rows[0];
        assert.ok(row);
        assert.equal(row.current_user, row.session_user);
        assert.notEqual(row.current_user, role);
    });
});
