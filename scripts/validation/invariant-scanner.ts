import { db } from "../../libs/db/index.js";
import { ProofOfFunds } from "../../libs/ledger/proof-of-funds.js";

async function scan() {
    console.log("🔍 Starting Global Invariant Scan...");

    try {
        // 1. Get all active currencies
        const currenciesResult = await db.queryAsRole<{ currency: string }>(
            "symphony_control",
            "SELECT DISTINCT currency FROM ledger_balances"
        );
        const currencies = currenciesResult.rows.map((row) => row.currency);

        if (currencies.length === 0) {
            console.log("✅ No active ledger balances found. System is clean.");
            return;
        }

        let allPassed = true;

        for (const currency of currencies) {
            console.log(`Checking [${currency}] balances...`);
            const passed = await ProofOfFunds.validateGlobalInvariant("symphony_control", currency);

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

    } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        console.error("💥 Scanner Crash:", message);
        process.exit(1);
    }
}

scan().catch(err => {
    console.error(err);
    process.exit(1);
});
