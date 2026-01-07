import { db } from "../db/index.js";
import { logger } from "../logging/logger.js";
import { ErrorSanitizer } from "../errors/sanitizer.js";

/**
 * Phase 7 Ledger Invariants
 * Enforces E-2 (Proof-of-Funds) and E-3 (Idempotency)
 */
export class LedgerInvariants {
    /**
     * E-2: Proof-of-Funds Validation
     * Ensures an account has sufficient balance before debiting.
     * Prevents overdraft creation unless explicitly authorized (not in scope for Phase 7).
     */
    static async ensureSufficientFunds(accountId: string, amount: number): Promise<void> {
        if (amount <= 0) {
            throw new Error("LedgerInvariant: Amount must be positive");
        }

        try {
            // Check current verified balance
            // Note: This presumes a 'balances' table exists from previous phases or we query ledger sum.
            // For Phase 7 stub, we assume a `get_balance` function or direct query.
            const res = await db.query(
                "SELECT balance FROM accounts WHERE id = $1 FOR UPDATE",
                [accountId]
            );

            if (res.rows.length === 0) {
                throw new Error("LedgerInvariant: Account not found");
            }

            const currentBalance = parseFloat(res.rows[0].balance);
            if (currentBalance < amount) {
                logger.warn({ accountId, currentBalance, required: amount }, "LedgerInvariant: Insufficient funds");
                throw new Error("LedgerInvariant: Insufficient funds");
            }

        } catch (err: any) {
            // Re-throw known invariant errors, sanitize DB errors
            if (err.message.startsWith("LedgerInvariant")) throw err;
            throw ErrorSanitizer.sanitize(err, "LedgerInvariant:ProofOfFunds");
        }
    }

    /**
     * E-3: Idempotency Protection
     * Ensures a transaction ID has not already been processed.
     */
    static async ensureIdempotency(txId: string): Promise<void> {
        try {
            const res = await db.query(
                "SELECT id FROM transactions WHERE id = $1",
                [txId]
            );

            if (res.rows.length > 0) {
                logger.warn({ txId }, "LedgerInvariant: Duplicate transaction detected");
                throw new Error("LedgerInvariant: Idempotency violation - Duplicate Transaction");
            }
        } catch (err: any) {
            if (err.message.startsWith("LedgerInvariant")) throw err;
            throw ErrorSanitizer.sanitize(err, "LedgerInvariant:Idempotency");
        }
    }
}
