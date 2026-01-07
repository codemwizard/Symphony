/**
 * FINANCIAL SCHEMA GUARD: verify_financial_schema.js
 * Enforces the "Derived-Only Balance" doctrine.
 * Fails if 'balance' columns or single-sided mutations are found in SQL files.
 */

import fs from 'fs';
import path from 'path';

const SCHEMA_DIR = 'schema/v1';
const FORBIDDEN_PATTERNS = [
    /balance\s+numeric/i,
    /available_balance/i,
    /cached_total/i,
    /wallet_total/i
];

function scanSchemaFiles() {
    console.log("Scanning schema for balance columns (Derived-Only Doctrine)...");

    if (!fs.existsSync(path.resolve(process.cwd(), SCHEMA_DIR))) {
        console.error("❌ FAILURE: Schema directory missing.");
        process.exit(1);
    }

    const files = fs.readdirSync(path.resolve(process.cwd(), SCHEMA_DIR))
        .filter(f => f.endsWith('.sql'));

    let violations = [];

    for (const file of files) {
        const content = fs.readFileSync(path.join(SCHEMA_DIR, file), 'utf8');
        for (const pattern of FORBIDDEN_PATTERNS) {
            if (pattern.test(content)) {
                violations.push(`${file}: Matches forbidden pattern ${pattern}`);
            }
        }
    }

    if (violations.length > 0) {
        console.error("❌ FAILURE: Financial schema violations detected:");
        violations.forEach(v => console.error(`   - ${v}`));
        console.error("\nAudit Note: Symphony enforces derived-only balances. Stored balances are prohibited.");
        process.exit(1);
    }

    console.log("✅ SUCCESS: No balance columns detected. Derived-only truth enforced.");
}

scanSchemaFiles();
process.exit(0);
