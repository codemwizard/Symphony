/**
 * KeyManager Unit Tests
 * SEC-FIX: Verifies KMS_KEY_REF usage, fail-closed, no fallback.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('SymphonyKeyManager (SEC-FIX)', () => {
    describe('KMS_KEY_REF Enforcement', () => {
        it('should throw if KMS_KEY_REF is missing', async () => {
            // Clear any existing value
            const originalRef = process.env.KMS_KEY_REF;
            delete process.env.KMS_KEY_REF;

            // Also need other env vars for constructor
            process.env.KMS_ACCESS_KEY_ID = 'test-key';
            process.env.KMS_SECRET_ACCESS_KEY = 'test-secret';

            try {
                // Dynamic import to get fresh module state
                const { SymphonyKeyManager } = await import('../../libs/crypto/keyManager.js');
                const km = new SymphonyKeyManager();

                await assert.rejects(
                    async () => km.deriveKey('test/purpose'),
                    (err: Error) => {
                        assert(err.message.includes('KMS_KEY_REF is missing'));
                        return true;
                    }
                );
            } finally {
                if (originalRef) {
                    process.env.KMS_KEY_REF = originalRef;
                }
            }
        });

        it('should throw if KMS_KEY_REF is empty string', async () => {
            const originalRef = process.env.KMS_KEY_REF;
            process.env.KMS_KEY_REF = '   '; // whitespace only
            process.env.KMS_ACCESS_KEY_ID = 'test-key';
            process.env.KMS_SECRET_ACCESS_KEY = 'test-secret';

            try {
                const { SymphonyKeyManager } = await import('../../libs/crypto/keyManager.js');
                const km = new SymphonyKeyManager();

                await assert.rejects(
                    async () => km.deriveKey('test/purpose'),
                    (err: Error) => {
                        assert(err.message.includes('KMS_KEY_REF is missing'));
                        return true;
                    }
                );
            } finally {
                if (originalRef) {
                    process.env.KMS_KEY_REF = originalRef;
                }
            }
        });

        it('should NOT use alias/symphony-root fallback', async () => {
            // Verify the code no longer references the old fallback
            const fs = await import('node:fs');
            const path = await import('node:path');
            const keyManagerPath = path.resolve(process.cwd(), 'libs/crypto/keyManager.ts');
            const content = fs.readFileSync(keyManagerPath, 'utf-8');

            // Should not contain the old fallback
            assert.strictEqual(
                content.includes("alias/symphony-root"),
                false,
                "KeyManager should not contain alias/symphony-root fallback"
            );

            // Should use KMS_KEY_REF
            assert.strictEqual(
                content.includes("KMS_KEY_REF"),
                true,
                "KeyManager should use KMS_KEY_REF"
            );

            // Should not use KMS_KEY_ARN
            assert.strictEqual(
                content.includes("KMS_KEY_ARN"),
                false,
                "KeyManager should not use KMS_KEY_ARN"
            );
        });

        it('should use KMS_KEY_REF when present', async () => {
            const originalRef = process.env.KMS_KEY_REF;
            process.env.KMS_KEY_REF = 'arn:aws:kms:us-east-1:123456789:key/test-key';
            process.env.KMS_ACCESS_KEY_ID = 'test-key';
            process.env.KMS_SECRET_ACCESS_KEY = 'test-secret';
            process.env.KMS_ENDPOINT = 'http://localhost:8080';

            try {
                const { SymphonyKeyManager } = await import('../../libs/crypto/keyManager.js');
                const km = new SymphonyKeyManager();

                // This will fail because we don't have a real KMS, but we can verify
                // it attempts to use the key by checking the error
                await assert.rejects(
                    async () => km.deriveKey('test/purpose'),
                    (err: Error) => {
                        // If it threw about missing KMS_KEY_REF, that would be wrong
                        assert(!err.message.includes('KMS_KEY_REF is missing'));
                        return true;
                    }
                );
            } finally {
                if (originalRef) {
                    process.env.KMS_KEY_REF = originalRef;
                } else {
                    delete process.env.KMS_KEY_REF;
                }
            }
        });
    });

    describe('Logging Correctness', () => {
        it('should log operation as deriveKey (not decrypt)', async () => {
            const fs = await import('node:fs');
            const path = await import('node:path');
            const keyManagerPath = path.resolve(process.cwd(), 'libs/crypto/keyManager.ts');
            const content = fs.readFileSync(keyManagerPath, 'utf-8');

            // Should use correct operation label
            assert.strictEqual(
                content.includes("operation: 'deriveKey'"),
                true,
                "KeyManager should log operation as 'deriveKey'"
            );

            // Should not use old incorrect label
            assert.strictEqual(
                content.includes("operation: 'decrypt'"),
                false,
                "KeyManager should not log operation as 'decrypt'"
            );
        });
    });
});
