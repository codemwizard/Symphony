/**
 * PHASE-GATE ENFORCEMENT: verify_no_financial_mutation.js
 * Blocks financial code leakage into Phase 6.
 * Portable Node.js implementation (Windows/Linux/macOS safe).
 */

import fs from 'fs';
import path from 'path';

const PHASE = process.env.PHASE || "6";

const FORBIDDEN_PATHS = [
    'ledger',
    'posting',
    'financial'
];

const FORBIDDEN_TAGS = [
    'INV-FIN-'
];

const IGNORE_DIRS = [
    'node_modules',
    '.git',
    'artifacts',
    '.gemini'
];

function walkDir(dir, callback) {
    fs.readdirSync(dir).forEach(f => {
        let dirPath = path.join(dir, f);
        let isDirectory = fs.statSync(dirPath).isDirectory();
        if (isDirectory) {
            if (!IGNORE_DIRS.includes(f)) {
                walkDir(dirPath, callback);
            }
        } else {
            callback(path.join(dir, f));
        }
    });
}

function checkPhaseGate() {
    if (PHASE === "7") {
        console.log("Phase 7 explicitly enabled. Financial mutation gates open.");
        process.exit(0);
    }

    console.log(`Phase ${PHASE} detected. Enforcing financial mutation block...`);

    let violations = [];

    walkDir(process.cwd(), (filePath) => {
        const relativePath = path.relative(process.cwd(), filePath);

        // 1. Path-based detection
        for (const forbidden of FORBIDDEN_PATHS) {
            if (relativePath.split(path.sep).includes(forbidden)) {
                violations.push(`Forbidden Path Leakage: ${relativePath}`);
            }
        }

        // 2. Tag-based detection
        if (filePath.endsWith('.ts') || filePath.endsWith('.js') || filePath.endsWith('.sql')) {
            const content = fs.readFileSync(filePath, 'utf8');
            for (const tag of FORBIDDEN_TAGS) {
                if (content.includes(tag)) {
                    violations.push(`Forbidden Invariant Leakage (${tag} detected in ${relativePath})`);
                }
            }
        }
    });

    if (violations.length > 0) {
        console.error("❌ FAILURE: Phase 7 feature leak detected in Phase 6 codebase:");
        violations.forEach(v => console.error(`   - ${v}`));
        process.exit(1);
    }

    console.log("✅ SUCCESS: Financial mutation gate is LOCKED.");
}

checkPhaseGate();
process.exit(0);
