import { describe, it } from 'node:test';
import assert from 'node:assert';
import { spawnSync } from 'child_process';

describe('Database Configuration Guards', () => {
    const projectRoot = process.cwd();
    const dbModulePath = './libs/db/index.ts';

    function runTestInSubprocess(envOverrides: Record<string, string>) {
        const env = { ...process.env, ...envOverrides };

        // We run a minimal script that imports the DB module
        const evalSource = [
            `try {`,
            `  await import('${dbModulePath}');`,
            `  process.stdout.write('LOADED\\n');`,
            `  await new Promise(resolve => setImmediate(resolve));`,
            `} catch (e) {`,
            `  console.error(e?.message ?? e);`,
            `  process.exit(1);`,
            `}`
        ].join('\n');
        const result = spawnSync(
            process.execPath,
            [
                '--input-type=module',
                '--loader', 'ts-node/esm',
                '--no-warnings',
                '--eval',
                evalSource
            ],
            {
                cwd: projectRoot,
                env,
                encoding: 'utf-8'
            }
        );

        return result;
    }

    it('should enforce TLS in production environment', { timeout: 60000 }, () => {
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
        assert.match(result.stdout, /Configuration guard passed|LOADED/);
    });

    it('should throw error if DB_CA_CERT is missing in production', { timeout: 60000 }, () => {
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

    it('should throw error if DB_CA_CERT is missing in staging', { timeout: 60000 }, () => {
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

    it('should allow missing DB_CA_CERT in development (default)', { timeout: 60000 }, () => {
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
        assert.match(result.stdout, /Configuration guard passed|LOADED/);
    });
});
