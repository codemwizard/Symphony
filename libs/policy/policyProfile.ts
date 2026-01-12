/**
 * Symphony Policy Profile Model — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Policy profiles do not constrain system capability.
 * They apply configurable, externally adjustable limits to existing
 * execution capability without requiring code changes or redeployment.
 *
 * System of Record: Platform Orchestration Layer (Node.js)
 */

/**
 * Policy profile for sandbox exposure limits.
 * All limits are configurational, not infrastructural.
 */
export interface PolicyProfile {
    /** Unique identifier (ULID) */
    readonly policyProfileId: string;
    /** Human-readable name */
    readonly name: string;
    /** Per-transaction limit (decimal string, null = no limit) */
    readonly maxTransactionAmount: string | null;
    /** Transactions per second rate limit (null = no limit) */
    readonly maxTransactionsPerSecond: number | null;
    /** Daily aggregate cap (decimal string, null = no limit) */
    readonly dailyAggregateLimit: string | null;
    /** Allowed ISO-20022 message types (whitelist) */
    readonly allowedMessageTypes: readonly string[];
    /** Additional policy constraints (extensible) */
    readonly constraints: Readonly<Record<string, unknown>>;
    /** Whether this profile is active */
    readonly isActive: boolean;
    /** Creation timestamp (ISO-8601) */
    readonly createdAt: string;
    /** Last update timestamp (ISO-8601) */
    readonly updatedAt: string;
    /** Creator identity */
    readonly createdBy: string;
}

/**
 * Frozen policy profile for runtime use.
 */
export type ResolvedPolicyProfile = Readonly<PolicyProfile>;
