/**
 * Symphony Execution Attempt Model — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Attempt tracking is diagnostic and non-authoritative.
 *
 * REGULATORY GUARANTEE:
 * No execution decision may be derived solely from attempt state.
 * Attempts are append-only and never determine instruction finality.
 */

/**
 * Attempt state enumeration.
 */
export type AttemptState = 'CREATED' | 'SENT' | 'ACKED' | 'NACKED' | 'TIMEOUT';

/**
 * Rail response structure (sanitized).
 */
export interface RailResponse {
    /** Response code from external rail */
    readonly responseCode: string;
    /** Response message (sanitized, no secrets) */
    readonly responseMessage?: string;
    /** Rail-specific reference ID */
    readonly railReferenceId?: string;
    /** Response timestamp (ISO-8601) */
    readonly receivedAt: string;
}

/**
 * Execution attempt record.
 *
 * Attempts are:
 * - Append-only (never mutated after creation)
 * - Diagnostic (for observability and debugging)
 * - Non-authoritative (cannot determine instruction success)
 */
export interface ExecutionAttempt {
    /** Unique attempt identifier (ULID) */
    readonly attemptId: string;
    /** Associated instruction ID */
    readonly instructionId: string;
    /** Attempt sequence number (1, 2, 3...) */
    readonly sequenceNumber: number;
    /** Current attempt state */
    readonly state: AttemptState;
    /** External rail response (if received) */
    readonly railResponse?: RailResponse;
    /** Failure classification (if failed) */
    readonly failureClass?: string;
    /** Attempt creation timestamp (ISO-8601) */
    readonly createdAt: string;
    /** State resolution timestamp (ISO-8601) */
    readonly resolvedAt?: string;
    /** Ingress sequence ID (INV SYS-7-1-A) */
    readonly ingressSequenceId: string;
    /** Request ID for correlation */
    readonly requestId: string;
}

/**
 * Attempt creation input.
 */
export interface CreateAttemptInput {
    readonly instructionId: string;
    readonly ingressSequenceId: string;
    readonly requestId: string;
}

/**
 * Attempt resolution input.
 */
export interface ResolveAttemptInput {
    readonly attemptId: string;
    readonly state: 'ACKED' | 'NACKED' | 'TIMEOUT';
    readonly railResponse?: RailResponse;
    readonly failureClass?: string;
}
