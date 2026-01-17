import { describe, it } from 'node:test';
import assert from 'node:assert';
import { REDACT_CENSOR, REDACT_KEYS } from '../../libs/logging/redactionConfig.js';
import pino from 'pino';
import { Writable } from 'stream';

describe('Log Redaction', () => {
    it('should redact sensitive keys in objects', () => {
        const stream = new Writable({
            write(chunk, encoding, callback) {
                const log = JSON.parse(chunk.toString());
                assert.strictEqual(log.password, REDACT_CENSOR);
                assert.strictEqual(log.authorization, REDACT_CENSOR);
                assert.strictEqual(log.nested.secret, REDACT_CENSOR);
                assert.strictEqual(log.visible, 'ok');
                callback();
            }
        });

        const testLogger = pino({
            redact: {
                paths: REDACT_KEYS,
                censor: REDACT_CENSOR
            }
        }, stream);

        testLogger.info({
            password: 'secret_password',
            authorization: 'Bearer token',
            nested: {
                secret: 'deep_secret',
                other: 'safe'
            },
            visible: 'ok'
        }, 'test message');
    });
});
