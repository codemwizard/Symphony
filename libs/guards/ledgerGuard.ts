/**
 * Symphony Ledger Guard — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Purpose: Structural request-scope validation (defense-in-depth, non-authoritative).
 *
 * This guard validates that requested accounts/wallets are within the participant's
 * declared ledger_scope. It is a pre-flight filter, NOT a decision engine.
 *
 * CRITICAL: This guard does NOT:
 * - Perform balance checks
 * - Grant execution authority
 * - Override .NET Financial Core enforcement
 *
 * Ledger scope validation in Node.js is advisory and preventative only;
 * it does not grant execution authority and cannot override ledger-level
 * enforcement in the .NET Financial Core.
 *
 * This is defense-in-depth, not dual authority.
 */

import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { ResolvedParticipant, LedgerScope } from '../participant/index.js';
import { DbRole } from '../db/roles.js';

export interface LedgerGuardContext {
    /** Request ID for correlation */
    readonly requestId: string;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Resolved participant */
    readonly participant: ResolvedParticipant;
    /** Account IDs in the request */
    readonly requestedAccountIds: readonly string[];
    /** Wallet IDs in the request (optional) */
    readonly requestedWalletIds?: readonly string[];
}

export type LedgerGuardResult =
    | { allowed: true }
    | { allowed: false; reason: LedgerGuardDenyReason; details: string };

export type LedgerGuardDenyReason =
    | 'ACCOUNT_OUT_OF_SCOPE'
    | 'WALLET_OUT_OF_SCOPE';

/**
 * Execute ledger scope guard.
 * Structural validation only — does NOT grant execution authority.
 */
export async function executeLedgerGuard(
    role: DbRole,
    context: LedgerGuardContext
): Promise<LedgerGuardResult> {
    const {
        requestId,
        ingressSequenceId,
        participant,
        requestedAccountIds,
        requestedWalletIds
    } = context;

    const scope = participant.ledgerScope;

    // Check accounts against scope
    for (const accountId of requestedAccountIds) {
        if (!isAccountInScope(accountId, scope)) {
            const details = `Account ${accountId} not in participant ledger scope`;
            await logDenial(role, requestId, ingressSequenceId, participant.participantId, 'ACCOUNT_OUT_OF_SCOPE', details);
            return { allowed: false, reason: 'ACCOUNT_OUT_OF_SCOPE', details };
        }
    }

    // Check wallets against scope (if provided)
    if (requestedWalletIds) {
        for (const walletId of requestedWalletIds) {
            if (!isWalletInScope(walletId, scope)) {
                const details = `Wallet ${walletId} not in participant ledger scope`;
                await logDenial(role, requestId, ingressSequenceId, participant.participantId, 'WALLET_OUT_OF_SCOPE', details);
                return { allowed: false, reason: 'WALLET_OUT_OF_SCOPE', details };
            }
        }
    }

    logger.debug({
        requestId,
        participantId: participant.participantId,
        accountCount: requestedAccountIds.length,
        walletCount: requestedWalletIds?.length ?? 0
    }, 'Ledger scope guard passed');

    return { allowed: true };
}

/**
 * Check if account is in participant's ledger scope.
 * If scope is empty/undefined, all accounts are blocked (fail-closed).
 */
function isAccountInScope(accountId: string, scope: LedgerScope): boolean {
    // Fail-closed: if no allowed accounts defined, deny all
    if (!scope.allowedAccountIds || scope.allowedAccountIds.length === 0) {
        return false;
    }

    return scope.allowedAccountIds.includes(accountId);
}

/**
 * Check if wallet is in participant's ledger scope.
 * If scope is empty/undefined, all wallets are blocked (fail-closed).
 */
function isWalletInScope(walletId: string, scope: LedgerScope): boolean {
    // Fail-closed: if no allowed wallets defined, deny all
    if (!scope.allowedWalletIds || scope.allowedWalletIds.length === 0) {
        return false;
    }

    return scope.allowedWalletIds.includes(walletId);
}

async function logDenial(
    role: DbRole,
    requestId: string,
    ingressSequenceId: string,
    participantId: string,
    reason: LedgerGuardDenyReason,
    details: string
): Promise<void> {
    logger.warn({
        requestId,
        participantId,
        reason,
        details
    }, 'Ledger scope guard denied request');

    await guardAuditLogger.log(role, {
        type: 'GUARD_LEDGER_SCOPE_DENY',
        requestId,
        ingressSequenceId,
        participantId,
        reason,
        details
    });
}
