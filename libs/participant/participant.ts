/**
 * Symphony Participant Identity Model — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Each sandbox participant is treated as a regulated actor, not a SaaS tenant.
 * This aligns with NPS Act supervisory framing and sandbox expectations.
 *
 * System of Record: Platform Orchestration Layer (Node.js)
 */

/**
 * Participant role classification.
 * SUPERVISOR is non-executing: read-only, evidence-access only.
 */
export type ParticipantRole = 'BANK' | 'PSP' | 'OPERATOR' | 'SUPERVISOR';

/**
 * Participant authorization status.
 * Non-ACTIVE participants are fail-closed at ingress.
 */
export type ParticipantStatus = 'ACTIVE' | 'SUSPENDED' | 'REVOKED';

/**
 * Sandbox exposure limits (configurational, not infrastructural).
 * These do not constrain system capability — they apply configurable limits
 * without requiring code changes or redeployment.
 */
export interface SandboxLimits {
    /** Per-transaction limit (decimal string for BigNumber precision) */
    readonly maxTransactionAmount?: string;
    /** Transactions per second rate limit */
    readonly maxTransactionsPerSecond?: number;
    /** Daily aggregate cap (decimal string) */
    readonly dailyAggregateLimit?: string;
    /** Allowed ISO-20022 message types (whitelist) */
    readonly allowedMessageTypes?: readonly string[];
}

/**
 * Ledger scope constraints (defense-in-depth, non-authoritative).
 * Defines what accounts/wallets this participant may REQUEST operations on.
 * Actual enforcement is authoritative in .NET Financial Core.
 */
export interface LedgerScope {
    /** Account IDs this participant may request operations on */
    readonly allowedAccountIds?: readonly string[];
    /** Wallet IDs this participant may request operations on */
    readonly allowedWalletIds?: readonly string[];
}

/**
 * Regulated participant identity.
 * Immutable after resolution.
 */
export interface Participant {
    /** Stable, regulator-visible identifier (ULID) */
    readonly participantId: string;
    /** External legal identity reference (e.g., BoZ registration number) */
    readonly legalEntityRef: string;
    /** SHA-256 fingerprint of bound mTLS certificate */
    readonly mtlsCertFingerprint: string;
    /** Participant classification */
    readonly role: ParticipantRole;
    /** Linked policy configuration */
    readonly policyProfileId: string;
    /** Defense-in-depth ledger scope */
    readonly ledgerScope: LedgerScope;
    /** Override sandbox limits (inherits from policy if not set) */
    readonly sandboxLimits: SandboxLimits;
    /** Runtime-controllable authorization status */
    readonly status: ParticipantStatus;
    /** Timestamp of last status change */
    readonly statusChangedAt: string;
    /** Audit trail for status changes */
    readonly statusReason: string | null;
    /** Creation timestamp (ISO-8601) */
    readonly createdAt: string;
    /** Last update timestamp (ISO-8601) */
    readonly updatedAt: string;
    /** Creator identity */
    readonly createdBy: string;
}

/**
 * Resolved participant context for request processing.
 * Frozen after resolution to prevent mutation.
 */
export type ResolvedParticipant = Readonly<Participant>;

/**
 * Participant resolution result.
 */
export type ParticipantResolutionResult =
    | { success: true; participant: ResolvedParticipant }
    | { success: false; reason: ParticipantResolutionFailure };

/**
 * Reasons for participant resolution failure.
 */
export type ParticipantResolutionFailure =
    | 'FINGERPRINT_NOT_FOUND'
    | 'PARTICIPANT_SUSPENDED'
    | 'PARTICIPANT_REVOKED'
    | 'CERTIFICATE_REVOKED'
    | 'POLICY_PROFILE_NOT_FOUND';
