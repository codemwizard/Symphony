import { describe, it, before } from 'node:test';
import assert from 'node:assert/strict';
import { DbRole } from '../roles.js';

const databaseUrl = process.env.DATABASE_URL;
const describeWithDb = databaseUrl ? describe : describe.skip;

describeWithDb('DB role residue', () => {
    let db: Awaited<typeof import('../index.js')>['db'];
    let testOnly: typeof import('../testOnly.js');

    before(async () => {
        if (!databaseUrl) return;
        process.env.NODE_ENV = 'test';
        process.env.DB_POOL_MAX = '1';
        const url = new URL(databaseUrl);
        process.env.DB_HOST = url.hostname;
        process.env.DB_PORT = url.port || '5432';
        process.env.DB_USER = decodeURIComponent(url.username);
        process.env.DB_PASSWORD = decodeURIComponent(url.password);
        process.env.DB_NAME = url.pathname.replace(/^\//, '');
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
