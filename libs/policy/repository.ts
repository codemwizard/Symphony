/**
 * Symphony Policy Profile Repository — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Database access layer for policy profiles.
 * All queries use parameterized statements and explicit column lists.
 */

import { db } from '../db/index.js';
import { PolicyProfile } from './policyProfile.js';

interface PolicyProfileRow {
    policy_profile_id: string;
    name: string;
    max_transaction_amount: string | null;
    max_transactions_per_second: number | null;
    daily_aggregate_limit: string | null;
    allowed_message_types: string[];
    constraints: Record<string, unknown>;
    is_active: boolean;
    created_at: string;
    updated_at: string;
    created_by: string;
}

/**
 * Find policy profile by ID.
 * Returns null if not found — does NOT throw.
 */
export async function findById(policyProfileId: string): Promise<PolicyProfile | null> {
    const result = await db.query(
        `SELECT
            policy_profile_id,
            name,
            max_transaction_amount,
            max_transactions_per_second,
            daily_aggregate_limit,
            allowed_message_types,
            constraints,
            is_active,
            created_at,
            updated_at,
            created_by
        FROM policy_profiles
        WHERE policy_profile_id = $1
        LIMIT 1`,
        [policyProfileId]
    );

    if (result.rows.length === 0) {
        return null;
    }

    return mapRowToPolicyProfile(result.rows[0] as PolicyProfileRow);
}

/**
 * Find active policy profile by name.
 * Returns null if not found — does NOT throw.
 */
export async function findActiveByName(name: string): Promise<PolicyProfile | null> {
    const result = await db.query(
        `SELECT
            policy_profile_id,
            name,
            max_transaction_amount,
            max_transactions_per_second,
            daily_aggregate_limit,
            allowed_message_types,
            constraints,
            is_active,
            created_at,
            updated_at,
            created_by
        FROM policy_profiles
        WHERE name = $1 AND is_active = true
        LIMIT 1`,
        [name]
    );

    if (result.rows.length === 0) {
        return null;
    }

    return mapRowToPolicyProfile(result.rows[0] as PolicyProfileRow);
}

/**
 * Map database row to PolicyProfile object.
 */
function mapRowToPolicyProfile(row: PolicyProfileRow): PolicyProfile {
    return Object.freeze({
        policyProfileId: row.policy_profile_id,
        name: row.name,
        maxTransactionAmount: row.max_transaction_amount,
        maxTransactionsPerSecond: row.max_transactions_per_second,
        dailyAggregateLimit: row.daily_aggregate_limit,
        allowedMessageTypes: Object.freeze(row.allowed_message_types),
        constraints: Object.freeze(row.constraints),
        isActive: row.is_active,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
        createdBy: row.created_by
    });
}
