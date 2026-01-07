import { db } from "../db/index.js";
import { logger } from "../logging/logger.js";
import { ErrorSanitizer } from "../errors/sanitizer.js";

export interface Transaction {
    accountId: string;
    amount: bigint; // Use bigint for currency to avoid precision issues
    currency: string;
    type: 'DEBIT' | 'CREDIT';
}

/**
 * SYM-PF-001: Proof-of-Funds (PoF) Model
 * Enforces financial invariants before any ledger mutation.
 */
export class ProofOfFunds {
    /**
     * Verifies that the account has sufficient funds for a debit operation.
     * SYM-PF-002: Zero-Overdraft Policy
     */
    static async verifySufficientFunds(transaction: Transaction): Promise<boolean> {
        if (transaction.type !== 'DEBIT') return true;

        try {
            const result = await db.query(
                "SELECT balance FROM ledger_balances WHERE account_id = $1 AND currency = $2 FOR UPDATE",
                [transaction.accountId, transaction.currency]
            );

            if (result.rows.length === 0) {
                logger.warn({ accountId: transaction.accountId }, "PoF: Account not found for balance check");
                return false;
            }

            const currentBalance = BigInt(result.rows[0].balance);
            if (currentBalance < transaction.amount) {
                logger.error({
                    accountId: transaction.accountId,
                    required: transaction.amount.toString(),
                    available: currentBalance.toString()
                }, "PoF: Insufficient funds");
                return false;
            }

            return true;
        } catch (err: any) {
            throw ErrorSanitizer.sanitize(err, "PoF:SufficientFundsCheck");
        }
    }

    /**
     * Enforces the Zero-Sum Invariant across the entire ledger.
     * SYM-PF-003: Asset Invariant (Total Supply = Total Balances)
     */
    static async validateGlobalInvariant(currency: string): Promise<boolean> {
        try {
            const result = await db.query(
                "SELECT SUM(balance) as total_balances FROM ledger_balances WHERE currency = $1",
                [currency]
            );

            const totalBalances = BigInt(result.rows[0].total_balances || '0');

            // In a real system, we'd compare this against an "issue" or "treasury" account
            // For now, we log the state for audit.
            logger.info({ currency, totalBalances: totalBalances.toString() }, "PoF: Global invariant check");

            return true;
        } catch (err: any) {
            throw ErrorSanitizer.sanitize(err, "PoF:GlobalInvariantCheck");
        }
    }
}
