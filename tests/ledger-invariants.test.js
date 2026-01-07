/**
 * Phase 7 Ledger Invariants Tests
 * Verifies controls E-2 (Proof-of-Funds) and E-3 (Idempotency)
 * 
 * Run with: npm test
 */

import { describe, it, mock, afterEach, before } from 'node:test';
import assert from 'node:assert';

// Dynamic imports required to set process.env before ConfigGuard runs
let LedgerInvariants;
let db;
let mockDbQuery;

describe('E. Ledger & Financial Invariants', () => {

    before(async () => {
        // Setup mock environment to satisfy ConfigGuard
        process.env.DB_HOST = 'localhost';
        process.env.DB_PORT = '5432';
        process.env.DB_USER = 'test_user';
        process.env.DB_PASSWORD = 'test_password';
        process.env.DB_NAME = 'test_db';
        process.env.DB_CA_CERT = 'fake_cert';

        // Import modules AFTER env is set
        const ledgerModule = await import('../libs/ledger/invariants.js');
        const dbModule = await import('../libs/db/index.js');

        LedgerInvariants = ledgerModule.LedgerInvariants;
        db = dbModule.db;

        // Mock query function
        mockDbQuery = mock.fn();

        // Monkey-patch the db object
        // Note: 'db' is successfully imported but might be read-only if it were a direct export, 
        // but it is an object exported as `export const db = { ... }`, so we can mutate its properties.
        db.query = mockDbQuery;
    });

    afterEach(() => {
        if (mockDbQuery) mockDbQuery.mock.resetCalls();
    });

    describe('E-2 Proof-of-Funds', () => {
        it('should allow transaction if balance >= amount', async () => {
            // Mock DB response: Balance = 200
            mockDbQuery.mock.mockImplementation(async () => ({ rows: [{ balance: '200.00' }] }));

            await assert.doesNotReject(async () => {
                await LedgerInvariants.ensureSufficientFunds("ACC_123", 150.00);
            });

            assert.strictEqual(mockDbQuery.mock.callCount(), 1);
        });

        it('should reject transaction if balance < amount', async () => {
            // Mock DB response: Balance = 50
            mockDbQuery.mock.mockImplementation(async () => ({ rows: [{ balance: '50.00' }] }));

            await assert.rejects(async () => {
                await LedgerInvariants.ensureSufficientFunds("ACC_123", 100.00);
            }, /LedgerInvariant: Insufficient funds/);
        });

        it('should reject if account not found', async () => {
            mockDbQuery.mock.mockImplementation(async () => ({ rows: [] }));

            await assert.rejects(async () => {
                await LedgerInvariants.ensureSufficientFunds("ACC_XXX", 100.00);
            }, /LedgerInvariant: Account not found/);
        });
    });

    describe('E-3 Idempotency', () => {
        it('should allow new transaction ID', async () => {
            // Mock DB response: No existing tx
            mockDbQuery.mock.mockImplementation(async () => ({ rows: [] }));

            await assert.doesNotReject(async () => {
                await LedgerInvariants.ensureIdempotency("TX_NEW");
            });
        });

        it('should reject duplicate transaction ID', async () => {
            // Mock DB response: Existing tx found
            mockDbQuery.mock.mockImplementation(async () => ({ rows: [{ id: "TX_DUP" }] }));

            await assert.rejects(async () => {
                await LedgerInvariants.ensureIdempotency("TX_DUP");
            }, /LedgerInvariant: Idempotency violation/);
        });
    });
});
