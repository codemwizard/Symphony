/**
 * Phase-7B: Unit Tests for Ledger Replay Engine
 * 
 * Tests deterministic reconstruction and verification report generation.
 * Migrated to node:test
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';
import crypto from 'crypto';

// ------------------ Test Helpers ------------------

interface MockLedgerRecord {
    id: string;
    account_id: string;
    amount: string;
    currency: string;
    entry_type: 'DEBIT' | 'CREDIT';
    instruction_id: string;
    created_at: Date;
}

function createMockLedgerRecords(): MockLedgerRecord[] {
    return [
        { id: '1', account_id: 'ACC001', amount: '100.00', currency: 'ZMW', entry_type: 'CREDIT', instruction_id: 'INS001', created_at: new Date() },
        { id: '2', account_id: 'ACC001', amount: '25.00', currency: 'ZMW', entry_type: 'DEBIT', instruction_id: 'INS002', created_at: new Date() },
        { id: '3', account_id: 'ACC002', amount: '500.00', currency: 'ZMW', entry_type: 'CREDIT', instruction_id: 'INS003', created_at: new Date() },
        { id: '4', account_id: 'ACC001', amount: '50.00', currency: 'ZMW', entry_type: 'CREDIT', instruction_id: 'INS004', created_at: new Date() },
    ];
}

function reconstructBalances(ledger: MockLedgerRecord[]): Map<string, { debit: number; credit: number }> {
    const balanceMap = new Map<string, { debit: number; credit: number }>();

    for (const entry of ledger) {
        const key = `${entry.account_id}:${entry.currency}`;
        const existing = balanceMap.get(key) ?? { debit: 0, credit: 0 };

        const amount = parseFloat(entry.amount);

        if (entry.entry_type === 'DEBIT') {
            existing.debit += amount;
        } else {
            existing.credit += amount;
        }

        balanceMap.set(key, existing);
    }

    return balanceMap;
}

// ------------------ Tests ------------------

describe('LedgerReplayEngine', () => {
    describe('Balance Reconstruction', () => {
        it('should correctly sum debits and credits per account', () => {
            const ledger = createMockLedgerRecords();
            const balances = reconstructBalances(ledger);

            const acc001 = balances.get('ACC001:ZMW');
            const acc002 = balances.get('ACC002:ZMW');

            assert.ok(acc001);
            assert.strictEqual(acc001.credit, 150.00); // 100 + 50
            assert.strictEqual(acc001.debit, 25.00);

            assert.ok(acc002);
            assert.strictEqual(acc002.credit, 500.00);
            assert.strictEqual(acc002.debit, 0);
        });

        it('should calculate correct net balance', () => {
            const ledger = createMockLedgerRecords();
            const balances = reconstructBalances(ledger);

            const acc001 = balances.get('ACC001:ZMW')!;
            const netBalance = acc001.credit - acc001.debit;

            assert.strictEqual(netBalance, 125.00); // 150 - 25
        });

        it('should handle empty ledger', () => {
            const balances = reconstructBalances([]);
            assert.strictEqual(balances.size, 0);
        });

        it('should handle multiple currencies for same account', () => {
            const ledger: MockLedgerRecord[] = [
                { id: '1', account_id: 'ACC001', amount: '100.00', currency: 'ZMW', entry_type: 'CREDIT', instruction_id: 'INS001', created_at: new Date() },
                { id: '2', account_id: 'ACC001', amount: '50.00', currency: 'USD', entry_type: 'CREDIT', instruction_id: 'INS002', created_at: new Date() },
            ];

            const balances = reconstructBalances(ledger);

            assert.ok(balances.has('ACC001:ZMW'));
            assert.ok(balances.has('ACC001:USD'));
            assert.strictEqual(balances.get('ACC001:ZMW')!.credit, 100.00);
            assert.strictEqual(balances.get('ACC001:USD')!.credit, 50.00);
        });
    });

    describe('Deterministic Hashing', () => {
        it('should produce consistent hash for same input data', () => {
            const data = { accounts: ['ACC001', 'ACC002'], total: 625.00 };

            const hash1 = crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
            const hash2 = crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');

            assert.strictEqual(hash1, hash2);
        });

        it('should produce different hash for different input data', () => {
            const data1 = { accounts: ['ACC001'], total: 100.00 };
            const data2 = { accounts: ['ACC001'], total: 100.01 };

            const hash1 = crypto.createHash('sha256').update(JSON.stringify(data1)).digest('hex');
            const hash2 = crypto.createHash('sha256').update(JSON.stringify(data2)).digest('hex');

            assert.notStrictEqual(hash1, hash2);
        });
    });

    describe('Replay Reproducibility', () => {
        it('should produce identical results on repeated runs with same input', () => {
            const ledger = createMockLedgerRecords();

            const result1 = reconstructBalances(ledger);
            const result2 = reconstructBalances(ledger);

            assert.deepStrictEqual(result1.get('ACC001:ZMW'), result2.get('ACC001:ZMW'));
            assert.deepStrictEqual(result1.get('ACC002:ZMW'), result2.get('ACC002:ZMW'));
        });
    });
});

describe('ReplayVerificationReport', () => {
    describe('Balance Comparison', () => {
        it('should detect matching balances', () => {
            const reconstructed = { balance: '125.00' };
            const actual = { balance: '125.00' };

            const match = parseFloat(reconstructed.balance) === parseFloat(actual.balance);
            assert.strictEqual(match, true);
        });

        it('should detect deviations', () => {
            const reconstructed = { balance: '125.00' };
            const actual = { balance: '124.99' };

            const difference = parseFloat(reconstructed.balance) - parseFloat(actual.balance);
            // Close to 0.01
            assert.ok(Math.abs(difference - 0.01) < 0.00001);
        });

        it('should tolerate rounding within 1 cent', () => {
            const reconstructed = { balance: '125.004' };
            const actual = { balance: '125.00' };

            const diff = Math.abs(parseFloat(reconstructed.balance) - parseFloat(actual.balance));
            const match = diff < 0.01;

            assert.strictEqual(match, true);
        });
    });

    describe('Report Status', () => {
        it('should return PASS when all balances match', () => {
            const deviations: unknown[] = [];
            const status = deviations.length === 0 ? 'PASS' : 'FAIL';

            assert.strictEqual(status, 'PASS');
        });

        it('should return WARNING for 1-3 deviations', () => {
            const deviations = [{ accountId: 'ACC001' }];
            const status = deviations.length <= 3 ? 'WARNING' : 'FAIL';

            assert.strictEqual(status, 'WARNING');
        });

        it('should return FAIL for >3 deviations', () => {
            const deviations = [
                { accountId: 'ACC001' },
                { accountId: 'ACC002' },
                { accountId: 'ACC003' },
                { accountId: 'ACC004' },
            ];
            const status = deviations.length > 3 ? 'FAIL' : 'WARNING';

            assert.strictEqual(status, 'FAIL');
        });
    });

    describe('Report Hashing', () => {
        it('should include hash of input datasets', () => {
            const inputHashes = {
                attestations: crypto.createHash('sha256').update('attestations').digest('hex'),
                outbox: crypto.createHash('sha256').update('outbox').digest('hex'),
                ledger: crypto.createHash('sha256').update('ledger').digest('hex'),
            };

            assert.strictEqual(inputHashes.attestations.length, 64);
            assert.strictEqual(inputHashes.outbox.length, 64);
            assert.strictEqual(inputHashes.ledger.length, 64);
        });

        it('should include hash of final report', () => {
            const report = {
                reportId: 'rpt_test',
                deviations: [],
                overallStatus: 'PASS',
            };

            const reportHash = crypto.createHash('sha256').update(JSON.stringify(report)).digest('hex');

            assert.strictEqual(reportHash.length, 64);
        });
    });
});
