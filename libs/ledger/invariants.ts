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
    private static async getBalance(accountId: string, client?: unknown): Promise<number> {
        const dbClient = client as
            | { query: (sql: string, params: unknown[]) => Promise<{ rows: { balance: string }[] }> }
            | undefined;
        const queryClient = dbClient ?? {
            query: (sql: string, params: unknown[]) =>
                db.queryAsRole<{ balance: string }>('symphony_control', sql, params)
        };

        const res = await queryClient.query(
            "SELECT balance FROM accounts WHERE id = $1 FOR UPDATE",
            [accountId]
        );

        if (res.rows.length === 0) {
            throw new Error("LedgerInvariant: Account not found");
        }
        const row = res.rows[0];
        if (!row) {
            throw new Error("LedgerInvariant: Account not found");
        }
        return parseFloat(row.balance);
    }

    static async ensureSufficientFunds(accountId: string, amount: number, client?: unknown): Promise<void> {
        if (amount <= 0) {
            throw new Error("LedgerInvariant: Amount must be positive");
        }

        try {
            // Check current verified balance
            // Note: This presumes a 'balances' table exists from previous phases or we query ledger sum.
            // For Phase 7 stub, we assume a `get_balance` function or direct query.
            const currentBalance = await LedgerInvariants.getBalance(accountId, client);

            if (currentBalance < amount) {
                logger.warn({ accountId, currentBalance, required: amount }, "LedgerInvariant: Insufficient funds");
                throw new Error("LedgerInvariant: Insufficient funds");
            }

        } catch (err: unknown) {
            // Re-throw known invariant errors, sanitize DB errors
            if (err instanceof Error && err.message.startsWith("LedgerInvariant")) throw err;
            throw ErrorSanitizer.sanitize(err, "LedgerInvariant:ProofOfFunds");
        }
    }

    /**
     * E-3: Idempotency Protection
     * Ensures a transaction ID has not already been processed.
     */
    static async ensureIdempotency(txId: string, client?: unknown): Promise<void> {
        const dbClient = client as
            | { query: (sql: string, params: unknown[]) => Promise<{ rows: unknown[] }> }
            | undefined;
        const queryClient = dbClient ?? {
            query: (sql: string, params: unknown[]) =>
                db.queryAsRole<{ id: string }>('symphony_control', sql, params)
        };
        try {
            const res = await queryClient.query(
                "SELECT id FROM transactions WHERE id = $1",
                [txId]
            );

            if (res.rows.length > 0) {
                throw new Error("LedgerInvariant: Idempotency violation: Duplicate transaction detected");
            }
        } catch (err: unknown) {
            if (err instanceof Error && err.message.startsWith("LedgerInvariant")) throw err;
            throw ErrorSanitizer.sanitize(err, "LedgerInvariant:Idempotency");
        }
    }
}
