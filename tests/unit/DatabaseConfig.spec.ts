import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';

describe('Database Configuration Guards', () => {
    const projectRoot = process.cwd();
    const dbModulePath = './libs/db/index.ts';

    function runTestInSubprocess(envOverrides: Record<string, string>) {
        const env = { ...process.env, ...envOverrides };

        // We run a minimal script that imports the DB module
        const result = spawnSync(
            process.execPath,
            [
                '--loader', 'ts-node/esm',
                '--no-warnings',
                '--eval',
                `import('${dbModulePath}').then(() => console.log('LOADED')).catch(e => { console.error(e.message); process.exit(1); })`
            ],
            {
                cwd: projectRoot,
                env,
                encoding: 'utf-8'
            }
        );

        return result;
    }

    it('should enforce TLS in production environment', () => {
        const result = runTestInSubprocess({
            NODE_ENV: 'production',
            DB_HOST: 'localhost',
            DB_PORT: '5432',
            DB_USER: 'symphony',
            DB_PASSWORD: 'password',
            DB_NAME: 'symphony',
            DB_CA_CERT: 'valid-cert'
        });

        assert.strictEqual(result.status, 0, `Process failed: ${result.stderr}`);
        assert.match(result.stdout, /LOADED/);
    });

    it('should throw error if DB_CA_CERT is missing in production', () => {
        const result = runTestInSubprocess({
            NODE_ENV: 'production',
            DB_HOST: 'localhost',
            DB_PORT: '5432',
            DB_USER: 'symphony',
            DB_PASSWORD: 'password',
            DB_NAME: 'symphony',
            DB_CA_CERT: '' // Missing
        });

        assert.strictEqual(result.status, 1, 'Should have failed');
        const output = result.stdout + result.stderr;
        assert.match(output, /FATAL CONFIG: DB_CA_CERT is required in production\/staging|CRITICAL: Missing DB_CA_CERT in protected environment/, `Expected error in output. Got stdout: "${result.stdout}", stderr: "${result.stderr}"`);
    });

    it('should throw error if DB_CA_CERT is missing in staging', () => {
        const result = runTestInSubprocess({
            NODE_ENV: 'staging',
            DB_HOST: 'localhost',
            DB_PORT: '5432',
            DB_USER: 'symphony',
            DB_PASSWORD: 'password',
            DB_NAME: 'symphony',
            DB_CA_CERT: '' // Missing
        });

        assert.strictEqual(result.status, 1, 'Should have failed');
        const output = result.stdout + result.stderr;
        assert.match(output, /FATAL CONFIG: DB_CA_CERT is required in production\/staging|CRITICAL: Missing DB_CA_CERT in protected environment/, `Expected error in output. Got stdout: "${result.stdout}", stderr: "${result.stderr}"`);
    });

    it('should allow missing DB_CA_CERT in development (default)', () => {
        const result = runTestInSubprocess({
            NODE_ENV: 'development',
            DB_HOST: 'localhost',
            DB_PORT: '5432',
            DB_USER: 'symphony',
            DB_PASSWORD: 'password',
            DB_NAME: 'symphony',
            DB_CA_CERT: '' // Missing
        });

        assert.strictEqual(result.status, 0, `Process failed: ${result.stderr}`);
        assert.match(result.stdout, /LOADED/);
    });
});
