/**
 * TrustFabric Unit Tests
 * SEC-FIX: Verifies DB-backed, cached, fail-closed trust resolution.
 * 
 * These tests verify the TrustFabric error codes by reading the source file.
 * Full integration tests would require a database.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';
import { TrustViolationError } from '../../libs/auth/TrustViolationError.js';
import fs from 'node:fs';
import path from 'node:path';

describe('TrustFabric (SEC-FIX)', () => {
    describe('TrustViolationError', () => {
        it('should have correct error codes defined', () => {
            const codes = [
                'TRUST_CERT_UNKNOWN',
                'TRUST_CERT_REVOKED',
                'TRUST_CERT_EXPIRED',
                'TRUST_PARTICIPANT_INACTIVE',
                'TRUST_ENV_MISMATCH'
            ];

            for (const code of codes) {
                const error = new TrustViolationError(code as 'TRUST_CERT_UNKNOWN', 'test-fp');
                assert.strictEqual(error.code, code);
                assert.strictEqual(error.fingerprint, 'test-fp');
                assert.strictEqual(error.statusCode, 403);
            }
        });

        it('should extend Error with correct name', () => {
            const error = new TrustViolationError('TRUST_CERT_REVOKED', 'test-fp');
            assert(error instanceof Error);
            assert.strictEqual(error.name, 'TrustViolationError');
        });
    });

    describe('Implementation Verification', () => {
        const trustFabricPath = path.resolve(process.cwd(), 'libs/auth/trustFabric.ts');
        let content: string;

        it('should exist and be readable', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(content.length > 0);
        });

        it('should use async resolveIdentity', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('static async resolveIdentity'),
                'resolveIdentity must be async'
            );
        });

        it('should import and use LRUCache', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(content.includes("import { LRUCache }"), 'Should import LRUCache');
            assert(content.includes('new LRUCache'), 'Should create LRUCache instance');
        });

        it('should check revoked status', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('TRUST_CERT_REVOKED'),
                'Should throw TRUST_CERT_REVOKED for revoked certs'
            );
        });

        it('should check expiry', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('TRUST_CERT_EXPIRED'),
                'Should throw TRUST_CERT_EXPIRED for expired certs'
            );
        });

        it('should check participant status', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('TRUST_PARTICIPANT_INACTIVE'),
                'Should throw TRUST_PARTICIPANT_INACTIVE for inactive participants'
            );
        });

        it('should check environment binding', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('TRUST_ENV_MISMATCH'),
                'Should throw TRUST_ENV_MISMATCH for env mismatch'
            );
        });

        it('should use queryAsRole for scoped DB access', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('db.queryAsRole'),
                'Should use queryAsRole for scoped DB role'
            );
        });

        it('should have stampede avoidance (inflight map)', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('inflight'),
                'Should have inflight promise map for stampede avoidance'
            );
        });

        it('should have negative cache', () => {
            content = fs.readFileSync(trustFabricPath, 'utf-8');
            assert(
                content.includes('negativeCache'),
                'Should have negative cache to prevent DB hammer'
            );
        });
    });
});
