/**
 * Symphony Repair Types — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Types for operational reconciliation (repair workflow).
 *
 * REGULATORY GUARANTEES:
 * - Repair may only advance an instruction to a terminal state;
 *   it may never regress or reopen a terminal instruction.
 * - Repair never re-creates instruction, mutates past ledger entries,
 *   or deletes history.
 */

/**
 * Repair context for reconciliation.
 */
export interface RepairContext {
    /** Instruction ID requiring repair */
    readonly instructionId: string;
    /** Latest attempt ID (TIMEOUT state) */
    readonly attemptId: string;
    /** Ingress sequence ID */
    readonly ingressSequenceId: string;
    /** Request ID for correlation */
    readonly requestId: string;
    /** External rail identifier */
    readonly railId: string;
    /** Original rail reference from send (if available) */
    readonly originalRailReference?: string;
}

/**
 * Reconciliation result from rail query.
 */
export type ReconciliationResult =
    | { status: 'CONFIRMED_SUCCESS'; railReference: string; details?: string }
    | { status: 'CONFIRMED_FAILURE'; failureReason: string; details?: string }
    | { status: 'NOT_FOUND'; details?: string }
    | { status: 'STILL_PENDING'; details?: string }
    | { status: 'RAIL_UNAVAILABLE'; details?: string };

/**
 * Repair outcome after reconciliation.
 */
export interface RepairOutcome {
    /** Was repair able to determine outcome? */
    readonly resolved: boolean;
    /** Reconciliation result */
    readonly reconciliationResult: ReconciliationResult;
    /** Recommended instruction transition (if resolved) */
    readonly recommendedTransition?: 'COMPLETED' | 'FAILED';
    /** Timestamp (ISO-8601) */
    readonly repairedAt: string;
    /** Audit trail ID */
    readonly repairEventId: string;
}

/**
 * Repair event for append-only audit.
 */
export interface RepairEvent {
    /** Unique repair event ID */
    readonly repairEventId: string;
    /** Instruction ID */
    readonly instructionId: string;
    /** Attempt ID being repaired */
    readonly attemptId: string;
    /** Rail queried */
    readonly railId: string;
    /** Reconciliation result */
    readonly reconciliationResult: ReconciliationResult;
    /** Recommended transition */
    readonly recommendedTransition?: 'COMPLETED' | 'FAILED';
    /** Event timestamp */
    readonly createdAt: string;
    /** Request ID for correlation */
    readonly requestId: string;
}
