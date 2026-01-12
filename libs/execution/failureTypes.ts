/**
 * Symphony Failure Types — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Deterministic failure classification for execution semantics.
 *
 * REGULATORY GUARANTEE:
 * Phase-7.2 never weakens an invariant during failure;
 * failure paths are strictly more restrictive than success paths.
 */

/**
 * Failure class enumeration.
 *
 * Each class has deterministic retry/repair eligibility.
 */
export type FailureClass =
    | 'VALIDATION_FAILURE'  // Internal, deterministic → No retry, no repair
    | 'AUTHZ_FAILURE'       // Identity / policy → No retry, no repair
    | 'RAIL_REJECT'         // External negative response → No retry, no repair
    | 'TIMEOUT'             // Unknown rail outcome → Repair only
    | 'TRANSPORT_ERROR'     // No delivery guarantee → Retry allowed
    | 'SYSTEM_FAILURE';     // Internal crash before send → Retry allowed

/**
 * Retry eligibility determination.
 */
export interface RetryEligibility {
    /** Whether retry is allowed for this failure class */
    readonly retryAllowed: boolean;
    /** Whether repair path should be used instead */
    readonly repairRequired: boolean;
    /** Human-readable reason */
    readonly reason: string;
}

/**
 * Complete failure classification result.
 */
export interface FailureClassification {
    /** The classified failure type */
    readonly failureClass: FailureClass;
    /** Retry/repair eligibility */
    readonly eligibility: RetryEligibility;
    /** Original error code (if available) */
    readonly errorCode?: string;
    /** Original error message (sanitized) */
    readonly errorMessage?: string;
    /** Classification timestamp (ISO-8601) */
    readonly classifiedAt: string;
}

/**
 * Retry decision after evaluation.
 */
export interface RetryDecision {
    /** Whether retry should proceed */
    readonly shouldRetry: boolean;
    /** Whether repair workflow should be invoked */
    readonly shouldRepair: boolean;
    /** Reason for decision */
    readonly reason: string;
    /** Associated instruction ID */
    readonly instructionId: string;
    /** Idempotency key (must be present for retry) */
    readonly idempotencyKey: string;
}

/**
 * TIMEOUT Clarification:
 * TIMEOUT does not imply failure; it represents an unknown external
 * state requiring reconciliation. The rail may have processed the
 * request successfully, failed, or never received it.
 */
export const TIMEOUT_CLARIFICATION =
    'TIMEOUT represents unknown external state requiring reconciliation, not failure.';

/**
 * Failure class metadata with eligibility defaults.
 */
export const FAILURE_CLASS_METADATA: Record<FailureClass, RetryEligibility> = {
    VALIDATION_FAILURE: {
        retryAllowed: false,
        repairRequired: false,
        reason: 'Deterministic internal validation failure; retry would produce same result'
    },
    AUTHZ_FAILURE: {
        retryAllowed: false,
        repairRequired: false,
        reason: 'Identity or policy failure; retry without remediation is futile'
    },
    RAIL_REJECT: {
        retryAllowed: false,
        repairRequired: false,
        reason: 'External system explicitly rejected; retry would be re-rejected'
    },
    TIMEOUT: {
        retryAllowed: false,
        repairRequired: true,
        reason: TIMEOUT_CLARIFICATION
    },
    TRANSPORT_ERROR: {
        retryAllowed: true,
        repairRequired: false,
        reason: 'No delivery guarantee; safe to retry under same idempotency key'
    },
    SYSTEM_FAILURE: {
        retryAllowed: true,
        repairRequired: false,
        reason: 'Crash before external side-effect; safe to retry'
    }
};
