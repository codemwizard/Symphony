/**
 * Symphony Execution Library — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Exports for execution semantics module.
 */

// Failure Classification
export type {
    FailureClass,
    FailureClassification,
    RetryEligibility,
    RetryDecision
} from './failureTypes.js';
export { FAILURE_CLASS_METADATA, TIMEOUT_CLARIFICATION } from './failureTypes.js';
export { classifyFailure, isRetryable, requiresRepair } from './failureClassifier.js';

// Attempt Tracking
export type {
    ExecutionAttempt,
    AttemptState,
    RailResponse,
    CreateAttemptInput,
    ResolveAttemptInput
} from './attempt.js';
export {
    createAttempt,
    markAttemptSent,
    resolveAttempt,
    findAttemptsByInstruction,
    getLatestAttempt
} from './attemptRepository.js';

// Retry Evaluation
export type { RetryEvaluationContext } from './retryEvaluator.js';
export { evaluateRetry } from './retryEvaluator.js';

// Repair Workflow
export type {
    RepairContext,
    RepairOutcome,
    ReconciliationResult,
    RepairEvent
} from './repairTypes.js';
export type { RailQueryService } from './repairWorkflow.js';
export { executeRepairWorkflow } from './repairWorkflow.js';

// Instruction State Client
export type {
    InstructionState,
    InstructionStateResponse,
    TransitionRequest,
    TransitionResponse
} from './instructionStateClient.js';
export {
    getInstructionState,
    isTerminal,
    requestTransition
} from './instructionStateClient.js';
