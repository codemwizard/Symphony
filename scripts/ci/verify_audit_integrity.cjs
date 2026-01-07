/**
 * Symphony Audit Integrity Verification Suite
 * Standalone JS for environment independence.
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

function computeHash(record, prevHash) {
    const { integrity, ...contentsOnly } = record;
    return crypto.createHash("sha256")
        .update(JSON.stringify(contentsOnly) + prevHash)
        .digest("hex");
}

function verifyChain(lines) {
    let lastHash = "0".repeat(64);
    for (let i = 0; i < lines.length; i++) {
        const record = JSON.parse(lines[i]);
        if (record.integrity.prevHash !== lastHash) {
            return { valid: false, index: i, reason: "prevHash mismatch" };
        }
        const computed = computeHash(record, lastHash);
        if (computed !== record.integrity.hash) {
            return { valid: false, index: i, reason: "hash mismatch" };
        }
        lastHash = record.integrity.hash;
    }
    return { valid: true };
}

async function runTests() {
    console.log("--- Starting Phase 6.5 Audit Integrity Verification ---");

    const testLogPath = path.join(__dirname, 'test_audit.jsonl');
    if (fs.existsSync(testLogPath)) fs.unlinkSync(testLogPath);

    // 1. Generate valid chain
    console.log("Step 1: Generating valid audit chain...");
    let chain = [];
    let lastHash = "0".repeat(64);
    for (let i = 0; i < 3; i++) {
        const record = {
            eventId: `uuid-${i}`,
            eventType: "TEST_EVENT",
            timestamp: new Date().toISOString(),
            decision: "ALLOW"
        };
        const hash = crypto.createHash("sha256").update(JSON.stringify(record) + lastHash).digest("hex");
        const signed = { ...record, integrity: { prevHash: lastHash, hash } };
        chain.push(JSON.stringify(signed));
        lastHash = hash;
    }
    fs.writeFileSync(testLogPath, chain.join('\n') + '\n');

    const initialVerify = verifyChain(chain);
    console.log(`Initial Verification: ${initialVerify.valid ? "PASS" : "FAIL"}`);

    // 2. Tamper Test (Mutation)
    console.log("Step 2: Tampering with record 1 (Decision change)...");
    let tamperedChain = [...chain];
    let r1 = JSON.parse(tamperedChain[1]);
    r1.decision = "DENY"; // Malicious change
    tamperedChain[1] = JSON.stringify(r1);

    const tamperVerify = verifyChain(tamperedChain);
    console.log(`Tamper Detection (Mutation): ${tamperVerify.valid === false ? "PASS (Detected)" : "FAIL (Not Detected)"}`);
    if (tamperVerify.reason) console.log(`  Reason: ${tamperVerify.reason} at index ${tamperVerify.index}`);

    // 3. Deletion Test
    console.log("Step 3: Tampering by record deletion...");
    let deletedChain = [chain[0], chain[2]]; // Deleted record 1
    const deleteVerify = verifyChain(deletedChain);
    console.log(`Tamper Detection (Deletion): ${deleteVerify.valid === false ? "PASS (Detected)" : "FAIL (Not Detected)"}`);
    if (deleteVerify.reason) console.log(`  Reason: ${deleteVerify.reason} at index ${deleteVerify.index}`);

    // Cleanup
    fs.unlinkSync(testLogPath);

    if (!initialVerify.valid || tamperVerify.valid || deleteVerify.valid) {
        process.exit(1);
    }
}

runTests().catch(err => {
    console.error(err);
    process.exit(1);
});
