/**
 * KeyManager Tests
 * Tests for CRIT-SEC-003 fix: DevelopmentKeyManager and ProductionKeyManager exports
 * 
 * Run with: node --test tests/keyManager.test.js
 */

import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';

// Mock environment for testing
const originalEnv = { ...process.env };

describe('KeyManager Module', () => {
    beforeEach(() => {
        // Reset environment before each test
        process.env = { ...originalEnv };
        // Set minimal KMS config for testing
        process.env.KMS_REGION = 'us-east-1';
        process.env.KMS_ENDPOINT = 'http://localhost:8080';
        process.env.KMS_ACCESS_KEY_ID = 'test';
        process.env.KMS_SECRET_ACCESS_KEY = 'test';
        process.env.KMS_KEY_ID = 'alias/test-key';
        process.env.DEV_ROOT_KEY = 'test-root-key';
    });

    afterEach(() => {
        process.env = { ...originalEnv };
    });

    describe('Module Exports', () => {
        it('should export KeyManager interface', async () => {
            const keyManagerModule = await import('../libs/crypto/keyManager.js');
            assert.ok(keyManagerModule, 'Module should be importable');
        });

        it('should export SymphonyKeyManager class', async () => {
            const { SymphonyKeyManager } = await import('../libs/crypto/keyManager.js');
            assert.ok(SymphonyKeyManager, 'SymphonyKeyManager should be exported');
            assert.strictEqual(typeof SymphonyKeyManager, 'function', 'SymphonyKeyManager should be a class');
        });

        it('should export ProductionKeyManager as alias for SymphonyKeyManager', async () => {
            const { ProductionKeyManager, SymphonyKeyManager } = await import('../libs/crypto/keyManager.js');
            assert.ok(ProductionKeyManager, 'ProductionKeyManager should be exported');
            assert.strictEqual(ProductionKeyManager, SymphonyKeyManager, 'ProductionKeyManager should be alias for SymphonyKeyManager');
        });

        it('should export DevelopmentKeyManager class', async () => {
            const { DevelopmentKeyManager } = await import('../libs/crypto/dev-key-manager.js');
            assert.ok(DevelopmentKeyManager, 'DevelopmentKeyManager should be exported');
            assert.strictEqual(typeof DevelopmentKeyManager, 'function', 'DevelopmentKeyManager should be a class');
        });

        it('should export cryptoAudit helper', async () => {
            const { cryptoAudit } = await import('../libs/crypto/keyManager.js');
            assert.ok(cryptoAudit, 'cryptoAudit should be exported');
            assert.strictEqual(typeof cryptoAudit.logKeyUsage, 'function', 'cryptoAudit.logKeyUsage should be a function');
        });
    });

    describe('DevelopmentKeyManager', () => {
        it('should extend SymphonyKeyManager', async () => {
            const { SymphonyKeyManager } = await import('../libs/crypto/keyManager.js');
            const { DevelopmentKeyManager } = await import('../libs/crypto/dev-key-manager.js');
            const devManager = new DevelopmentKeyManager();
            assert.ok(devManager instanceof SymphonyKeyManager, 'DevelopmentKeyManager should extend SymphonyKeyManager');
        });

        it('should have deriveKey method', async () => {
            const { DevelopmentKeyManager } = await import('../libs/crypto/dev-key-manager.js');
            const devManager = new DevelopmentKeyManager();
            assert.strictEqual(typeof devManager.deriveKey, 'function', 'deriveKey should be a function');
        });
    });

    describe('SymphonyKeyManager', () => {
        it('should create instance successfully', async () => {
            const { SymphonyKeyManager } = await import('../libs/crypto/keyManager.js');
            const manager = new SymphonyKeyManager();
            assert.ok(manager, 'SymphonyKeyManager instance should be created');
        });

        it('should have deriveKey method', async () => {
            const { SymphonyKeyManager } = await import('../libs/crypto/keyManager.js');
            const manager = new SymphonyKeyManager();
            assert.strictEqual(typeof manager.deriveKey, 'function', 'deriveKey should be a function');
        });
    });
});

console.log('KeyManager tests loaded successfully');
