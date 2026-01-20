/**
 * Symphony Attempt Repository — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Append-only persistence for execution attempts.
 *
 * REGULATORY GUARANTEE:
 * No execution decision may be derived solely from attempt state.
 * This repository is for diagnostics and audit trail only.
 */

import { db } from '../db/index.js';
import { DbRole } from '../db/roles.js';
import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import {
    ExecutionAttempt,
    AttemptState,
    RailResponse,
    CreateAttemptInput,
    ResolveAttemptInput
} from './attempt.js';

interface AttemptRow {
    attempt_id: string;
    instruction_id: string;
    sequence_number: number;
    state: AttemptState;
    rail_response: RailResponse | null;
    failure_class: string | null;
    created_at: string;
    resolved_at: string | null;
    ingress_sequence_id: string;
    request_id: string;
}

/**
 * Create a new execution attempt.
 * Attempts are append-only; this creates a new record.
 */
export async function createAttempt(role: DbRole, input: CreateAttemptInput): Promise<ExecutionAttempt> {
    const { instructionId, ingressSequenceId, requestId } = input;

    // Get next sequence number for this instruction
    const seqResult = await db.queryAsRole(
        role,
        `SELECT COALESCE(MAX(sequence_number), 0) + 1 as next_seq
         FROM execution_attempts
         WHERE instruction_id = $1`,
        [instructionId]
    );
    const sequenceNumber = (seqResult.rows[0] as { next_seq: number }).next_seq;

    const result = await db.queryAsRole(
        role,
        `INSERT INTO execution_attempts (
            instruction_id,
            sequence_number,
            state,
            ingress_sequence_id,
            request_id
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING
            attempt_id,
            instruction_id,
            sequence_number,
            state,
            rail_response,
            failure_class,
            created_at,
            resolved_at,
            ingress_sequence_id,
            request_id`,
        [instructionId, sequenceNumber, 'CREATED', ingressSequenceId, requestId]
    );

    const attempt = mapRowToAttempt(result.rows[0] as AttemptRow);

    await guardAuditLogger.log(role, {
        type: 'EXECUTION_ATTEMPT_CREATED',
        requestId,
        ingressSequenceId,
        attemptId: attempt.attemptId,
        instructionId,
        sequenceNumber
    });

    logger.info({
        attemptId: attempt.attemptId,
        instructionId,
        sequenceNumber,
        requestId
    }, 'Execution attempt created');

    return attempt;
}

/**
 * Mark attempt as sent to external rail.
 */
export async function markAttemptSent(role: DbRole, attemptId: string, requestId: string): Promise<void> {
    await db.queryAsRole(
        role,
        `UPDATE execution_attempts
         SET state = $1
         WHERE attempt_id = $2 AND state = 'CREATED'`,
        ['SENT', attemptId]
    );

    const result = await db.queryAsRole(
        role,
        `SELECT ingress_sequence_id FROM execution_attempts WHERE attempt_id = $1 LIMIT 1`,
        [attemptId]
    );

    if (result.rows.length > 0) {
        await guardAuditLogger.log(role, {
            type: 'EXECUTION_ATTEMPT_SENT',
            requestId,
            ingressSequenceId: (result.rows[0] as { ingress_sequence_id: string }).ingress_sequence_id,
            attemptId
        });
    }

    logger.debug({ attemptId, requestId }, 'Attempt marked as sent');
}

/**
 * Resolve an attempt with final state.
 * This is append-like: we update state but never delete or regress.
 */
export async function resolveAttempt(role: DbRole, input: ResolveAttemptInput): Promise<ExecutionAttempt> {
    const { attemptId, state, railResponse, failureClass } = input;

    const result = await db.queryAsRole(
        role,
        `UPDATE execution_attempts
         SET state = $1,
             rail_response = $2,
             failure_class = $3,
             resolved_at = NOW()
         WHERE attempt_id = $4
         RETURNING
            attempt_id,
            instruction_id,
            sequence_number,
            state,
            rail_response,
            failure_class,
            created_at,
            resolved_at,
            ingress_sequence_id,
            request_id`,
        [state, railResponse ? JSON.stringify(railResponse) : null, failureClass, attemptId]
    );

    if (result.rows.length === 0) {
        throw new Error(`Attempt not found: ${attemptId}`);
    }

    const attempt = mapRowToAttempt(result.rows[0] as AttemptRow);

    await guardAuditLogger.log(role, {
        type: 'EXECUTION_ATTEMPT_RESOLVED',
        requestId: attempt.requestId,
        ingressSequenceId: attempt.ingressSequenceId,
        attemptId,
        state,
        failureClass
    });

    logger.info({
        attemptId,
        instructionId: attempt.instructionId,
        state,
        failureClass
    }, 'Attempt resolved');

    return attempt;
}

/**
 * Find attempts by instruction ID.
 */
export async function findAttemptsByInstruction(role: DbRole, instructionId: string): Promise<readonly ExecutionAttempt[]> {
    const result = await db.queryAsRole(
        role,
        `SELECT
            attempt_id,
            instruction_id,
            sequence_number,
            state,
            rail_response,
            failure_class,
            created_at,
            resolved_at,
            ingress_sequence_id,
            request_id
         FROM execution_attempts
         WHERE instruction_id = $1
         ORDER BY sequence_number ASC
         LIMIT 100`,
        [instructionId]
    );

    return result.rows.map((row: unknown) => mapRowToAttempt(row as AttemptRow));
}

/**
 * Get latest attempt for instruction.
 */
export async function getLatestAttempt(role: DbRole, instructionId: string): Promise<ExecutionAttempt | null> {
    const result = await db.queryAsRole(
        role,
        `SELECT
            attempt_id,
            instruction_id,
            sequence_number,
            state,
            rail_response,
            failure_class,
            created_at,
            resolved_at,
            ingress_sequence_id,
            request_id
         FROM execution_attempts
         WHERE instruction_id = $1
         ORDER BY sequence_number DESC
         LIMIT 1`,
        [instructionId]
    );

    if (result.rows.length === 0) {
        return null;
    }

    return mapRowToAttempt(result.rows[0] as AttemptRow);
}

function mapRowToAttempt(row: AttemptRow): ExecutionAttempt {
    return Object.freeze({
        attemptId: row.attempt_id,
        instructionId: row.instruction_id,
        sequenceNumber: row.sequence_number,
        state: row.state,
        ...(row.rail_response ? { railResponse: row.rail_response } : {}),
        ...(row.failure_class ? { failureClass: row.failure_class } : {}),
        createdAt: row.created_at,
        ...(row.resolved_at ? { resolvedAt: row.resolved_at } : {}),
        ingressSequenceId: row.ingress_sequence_id,
        requestId: row.request_id
    });
}
