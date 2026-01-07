/**
 * MIGRATION IMMUTABILITY GUARD: verify_migration_immutability.js
 * Enforces append-only schema evolution (INV-PERSIST-02).
 * Fails if destructive SQL commands (DROP, etc.) are found in schema files.
 */

import fs from 'fs';
import path from 'path';

const SCHEMA_DIR = 'schema/v1';

// We target 'DELETE FROM' explicitly to avoid matching 'REVOKE DELETE ON ...'
const DESTRUCTIVE_PATTERNS = [
    /DROP\s+COLUMN/i,
    /DROP\s+TABLE/i,
    /TRUNCATE/i,
    /\s+DELETE\s+FROM/i, // Needs leading space or start of line to avoid REVOKE matching
    /^DELETE\s+FROM/im
];

function verifyImmutability() {
    console.log("Checking migration immutability (Append-Only Doctrine)...");

    const schemaPath = path.resolve(process.cwd(), SCHEMA_DIR);
    if (!fs.existsSync(schemaPath)) {
        process.exit(0); // No schema yet
    }

    const files = fs.readdirSync(schemaPath).filter(f => f.endsWith('.sql'));

    let violations = [];

    for (const file of files) {
        const content = fs.readFileSync(path.join(schemaPath, file), 'utf8');
        for (const pattern of DESTRUCTIVE_PATTERNS) {
            if (pattern.test(content)) {
                violations.push(`${file}: Matches destructive pattern ${pattern}`);
            }
        }
    }

    if (violations.length > 0) {
        console.error("❌ FAILURE: Destructive migrations detected:");
        violations.forEach(v => console.error(`   - ${v}`));
        console.error("\nAudit Note: Production schema is append-only. Modifying existing state is prohibited.");
        process.exit(1);
    }

    console.log("✅ SUCCESS: All migrations are append-only.");
}

verifyImmutability();
process.exit(0);
