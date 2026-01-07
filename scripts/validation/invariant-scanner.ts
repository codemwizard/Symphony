import { db } from "../../libs/db/index.js";
import { logger } from "../../libs/logging/logger.js";
import { ProofOfFunds } from "../../libs/ledger/proof-of-funds.js";

/**
 * PHASE-7 VERIFICATION: Invariant Scanner
 * Runs as part of the Ceremony Step 2 and Step 5 to verify ledger integrity.
 */
async function scan() {
    console.log("🔍 Starting Global Invariant Scan...");

    try {
        // 1. Get all active currencies
        const currenciesResult = await db.query("SELECT DISTINCT currency FROM ledger_balances");
        const currencies = currenciesResult.rows.map(r => r.currency);

        if (currencies.length === 0) {
            console.log("✅ No active ledger balances found. System is clean.");
            return;
        }

        let allPassed = true;

        for (const currency of currencies) {
            console.log(`Checking [${currency}] balances...`);
            const passed = await ProofOfFunds.validateGlobalInvariant(currency);

            if (!passed) {
                console.error(`❌ INVARIANT VIOLATION: ${currency} balances are inconsistent!`);
                allPassed = false;
            }
        }

        if (allPassed) {
            console.log("✅ All global invariants passed.");
        } else {
            process.exit(1);
        }

    } catch (err: any) {
        console.error("💥 Scanner Crash:", err.message);
        process.exit(1);
    }
}

scan().catch(err => {
    console.error(err);
    process.exit(1);
});
