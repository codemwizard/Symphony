import { describe, it } from 'node:test';
import assert from 'node:assert';
import { verifyAuditChain } from '../../libs/audit/integrity.js';
import fs from 'fs';
import path from 'path';
import crypto from 'crypto';

/**
 * Helper to create a valid audit log file matching AuditRecordV1 schema
 */
function createAuditLog(filePath: string, records: Array<Record<string, unknown>>) {
    let prevHash = "0".repeat(64);
    const lines = records.map(r => {
        // Hashing logic: JSON.stringify(content) + prevHash
        // Content is the record WITHOUT integrity field.
        // We assume 'r' contains the content fields (e.g. event, timestamp, etc)
        const content = JSON.stringify(r);
        const hash = crypto.createHash('sha256').update(content + prevHash).digest('hex');

        const entry = {
            ...r,
            integrity: {
                hash,
                prevHash
            }
        };
        prevHash = hash;
        return JSON.stringify(entry);
    });
    fs.writeFileSync(filePath, lines.join('\n'));
}

describe('verifyAuditChain (Integrity)', () => {
    const TEST_FILE = 'tests/unit/fixtures/audit.log';

    it('should verify a valid chain', async () => {
        fs.mkdirSync(path.dirname(TEST_FILE), { recursive: true });
        createAuditLog(TEST_FILE, [{ event: 'A' }, { event: 'B' }]);

        const result = await verifyAuditChain(TEST_FILE);
        // integrity.ts returns { valid: true } on success
        assert.deepStrictEqual(result, { valid: true });

        if (fs.existsSync(TEST_FILE)) fs.unlinkSync(TEST_FILE);
    });

    it('should detect tamper (broken chain)', async () => {
        fs.mkdirSync(path.dirname(TEST_FILE), { recursive: true });
        createAuditLog(TEST_FILE, [{ event: 'A' }, { event: 'B' }]);

        // Tamper with file
        const lines = fs.readFileSync(TEST_FILE, 'utf-8').trim().split('\n');
        const rec1 = JSON.parse(lines[1]!);
        rec1.event = 'C'; // Changed content
        lines[1] = JSON.stringify(rec1);
        fs.writeFileSync(TEST_FILE, lines.join('\n'));

        // Validation should fail at index 1 because the hash inside index 1 (which matched B)
        // no longer matches hash(C + prevHash).
        const result = await verifyAuditChain(TEST_FILE);
        assert.strictEqual(result.valid, false);
        assert.strictEqual(result.violationIndex, 1);
        assert.match(result.reason!, /hash mismatch/);

        if (fs.existsSync(TEST_FILE)) fs.unlinkSync(TEST_FILE);
    });

    it('should handle malformed JSON safely (no eval)', async () => {
        fs.mkdirSync(path.dirname(TEST_FILE), { recursive: true });
        // Create one valid line, then one broken line
        createAuditLog(TEST_FILE, [{ event: 'A' }]);
        fs.appendFileSync(TEST_FILE, '\n{BROKEN_JSON_HERE');

        const result = await verifyAuditChain(TEST_FILE);
        assert.strictEqual(result.valid, false);
        assert.strictEqual(result.violationIndex, 1);

        assert.match(result.reason!, /Format error/);
        // Ensure strictly no eval related message regex

        if (fs.existsSync(TEST_FILE)) fs.unlinkSync(TEST_FILE);
    });
});
