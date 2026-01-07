/**
 * INVARIANT SCANNER: verify_invariants.js
 * Scans for references to authoritative invariants (e.g., INV-SEC-01).
 * Fails if the authoritative invariants.md is missing or unreadable.
 */

import fs from 'fs';
import path from 'path';

const INVARIANTS_FILE = 'docs/architecture/invariants.md';

function scanInvariants() {
    console.log("Scanning system invariants...");

    if (!fs.existsSync(path.resolve(process.cwd(), INVARIANTS_FILE))) {
        console.error("❌ FAILURE: Master invariants.md is missing. Architectural lock broken.");
        process.exit(1);
    }

    const content = fs.readFileSync(INVARIANTS_FILE, 'utf8');
    const matches = content.match(/INV-[A-Z]+-[0-9]+/g);

    if (!matches || matches.length === 0) {
        console.error("❌ FAILURE: No invariants found in invariants.md.");
        process.exit(1);
    }

    console.log(`✅ SUCCESS: Found ${matches.length} authoritative invariants locked.`);
}

scanInvariants();
process.exit(0);
