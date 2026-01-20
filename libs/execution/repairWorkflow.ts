/**
 * Symphony Repair Workflow — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Operational reconciliation for ambiguous execution outcomes.
 *
 * REGULATORY GUARANTEES:
 * - Repair may only advance an instruction to a terminal state;
 *   it may never regress or reopen a terminal instruction.
 * - Repair never re-creates instruction, mutates past ledger entries,
 *   or deletes history.
 * - All repair actions are append-only (INV-PERSIST-02).
 */

import crypto from 'crypto';
import { logger } from '../logging/logger.js';
import { guardAuditLogger } from '../audit/guardLogger.js';
import { db } from '../db/index.js';
import { DbRole } from '../db/roles.js';
import {
    RepairContext,
    RepairOutcome,
    ReconciliationResult,
    RepairEvent
} from './repairTypes.js';
import { isTerminal, requestTransition } from './instructionStateClient.js';

/**
 * Rail query interface.
 * Implementations must be provided per rail type.
 */
export interface RailQueryService {
    queryTransactionStatus(railId: string, reference: string): Promise<ReconciliationResult>;
}

/**
 * Execute repair workflow for an instruction with TIMEOUT.
 *
 * Steps:
 * 1. Query external rail for current state
 * 2. Reconcile with known attempt state
 * 3. Append repair event (never mutate)
 * 4. Emit transition command to .NET (if determined)
 */
export async function executeRepairWorkflow(
    role: DbRole,
    context: RepairContext,
    railQuery: RailQueryService
): Promise<RepairOutcome> {
    const { instructionId, attemptId, ingressSequenceId, requestId, railId, originalRailReference } = context;

    // Pre-check: instruction must not already be terminal
    const alreadyTerminal = await isTerminal(instructionId);
    if (alreadyTerminal) {
        logger.warn({
            instructionId,
            requestId
        }, 'Repair attempted on terminal instruction — blocked');

        throw new Error(`Cannot repair terminal instruction: ${instructionId}`);
    }

    // Step 1: Log repair initiation
    await guardAuditLogger.log(role, {
        type: 'REPAIR_INITIATED',
        requestId,
        ingressSequenceId,
        instructionId,
        attemptId,
        railId
    });

    logger.info({
        instructionId,
        attemptId,
        railId,
        requestId
    }, 'Repair workflow initiated');

    // Step 2: Query external rail
    let reconciliationResult: ReconciliationResult;
    try {
        reconciliationResult = await railQuery.queryTransactionStatus(
            railId,
            originalRailReference ?? instructionId
        );
    } catch (error) {
        reconciliationResult = {
            status: 'RAIL_UNAVAILABLE',
            details: error instanceof Error ? error.message : 'Unknown error'
        };
    }

    // Step 3: Record reconciliation result (append-only)
    const repairEventId = crypto.randomUUID();
    const recommendedTransition = determineTransition(reconciliationResult);
    const repairEvent: RepairEvent = {
        repairEventId,
        instructionId,
        attemptId,
        railId,
        reconciliationResult,
        ...(recommendedTransition ? { recommendedTransition } : {}),
        createdAt: new Date().toISOString(),
        requestId
    };

    await persistRepairEvent(role, repairEvent);

    await guardAuditLogger.log(role, {
        type: 'REPAIR_RECONCILIATION_RESULT_RECORDED',
        requestId,
        ingressSequenceId,
        instructionId,
        repairEventId,
        reconciliationStatus: reconciliationResult.status
    });

    // Step 4: Request transition to .NET if outcome is determinable
    const outcome: RepairOutcome = {
        resolved: isResolved(reconciliationResult),
        reconciliationResult,
        ...(repairEvent.recommendedTransition ? { recommendedTransition: repairEvent.recommendedTransition } : {}),
        repairedAt: repairEvent.createdAt,
        repairEventId
    };

    if (outcome.resolved && outcome.recommendedTransition) {
        // Advisory command to .NET — may be rejected if invariant conditions not met
        await requestTransition(instructionId, outcome.recommendedTransition);

        logger.info({
            instructionId,
            transition: outcome.recommendedTransition,
            requestId
        }, 'Transition requested to .NET');
    }

    await guardAuditLogger.log(role, {
        type: 'REPAIR_COMPLETED',
        requestId,
        ingressSequenceId,
        instructionId,
        repairEventId,
        resolved: outcome.resolved,
        recommendedTransition: outcome.recommendedTransition
    });

    logger.info({
        instructionId,
        resolved: outcome.resolved,
        reconciliationStatus: reconciliationResult.status,
        requestId
    }, 'Repair workflow completed');

    return outcome;
}

/**
 * Determine transition based on reconciliation result.
 * Only CONFIRMED_SUCCESS and CONFIRMED_FAILURE yield transitions.
 */
function determineTransition(result: ReconciliationResult): 'COMPLETED' | 'FAILED' | undefined {
    switch (result.status) {
        case 'CONFIRMED_SUCCESS':
            return 'COMPLETED';
        case 'CONFIRMED_FAILURE':
        case 'NOT_FOUND':
            return 'FAILED';
        case 'STILL_PENDING':
        case 'RAIL_UNAVAILABLE':
            return undefined; // Cannot determine yet
    }
}

/**
 * Check if reconciliation result is resolved (determinable).
 */
function isResolved(result: ReconciliationResult): boolean {
    return result.status === 'CONFIRMED_SUCCESS' ||
        result.status === 'CONFIRMED_FAILURE' ||
        result.status === 'NOT_FOUND';
}

/**
 * Persist repair event (append-only).
 */
async function persistRepairEvent(role: DbRole, event: RepairEvent): Promise<void> {
    await db.queryAsRole(
        role,
        `INSERT INTO repair_events (
            repair_event_id,
            instruction_id,
            attempt_id,
            rail_id,
            reconciliation_result,
            recommended_transition,
            created_at,
            request_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
            event.repairEventId,
            event.instructionId,
            event.attemptId,
            event.railId,
            JSON.stringify(event.reconciliationResult),
            event.recommendedTransition,
            event.createdAt,
            event.requestId
        ]
    );
}
