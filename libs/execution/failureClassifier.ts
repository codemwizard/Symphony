/**
 * Symphony Failure Classifier — Phase 7.2
 * Phase Key: SYS-7-2
 *
 * Deterministic failure classification for execution semantics.
 *
 * REGULATORY GUARANTEE:
 * Every execution failure MUST be classified as one of the defined
 * failure classes. Classification is logged, auditable, and immutable.
 */

import { logger } from '../logging/logger.js';
import {
    FailureClass,
    FailureClassification,
    FAILURE_CLASS_METADATA
} from './failureTypes.js';

/**
 * Error patterns for classification.
 */
interface ErrorPattern {
    readonly patterns: readonly (string | RegExp)[];
    readonly failureClass: FailureClass;
}

/**
 * Known error patterns mapped to failure classes.
 * Order matters: first match wins.
 */
const ERROR_PATTERNS: readonly ErrorPattern[] = [
    // Validation failures
    {
        patterns: ['VALIDATION_ERROR', 'SCHEMA_INVALID', 'MALFORMED_REQUEST', /invalid.*format/i],
        failureClass: 'VALIDATION_FAILURE'
    },
    // Authorization failures
    {
        patterns: ['UNAUTHORIZED', 'FORBIDDEN', 'AUTH_FAILED', 'PERMISSION_DENIED', /authz?.*fail/i],
        failureClass: 'AUTHZ_FAILURE'
    },
    // Rail rejections (explicit negative response)
    {
        patterns: ['RAIL_REJECT', 'REJECTED', 'DECLINED', 'INSUFFICIENT_FUNDS', 'ACCOUNT_CLOSED'],
        failureClass: 'RAIL_REJECT'
    },
    // Timeouts (unknown outcome - requires repair)
    {
        patterns: ['TIMEOUT', 'DEADLINE_EXCEEDED', 'REQUEST_TIMEOUT', /timed?\s*out/i],
        failureClass: 'TIMEOUT'
    },
    // Transport errors (no delivery guarantee)
    {
        patterns: ['ECONNREFUSED', 'ECONNRESET', 'NETWORK_ERROR', 'CONNECTION_FAILED', 'DNS_ERROR'],
        failureClass: 'TRANSPORT_ERROR'
    },
    // System failures (internal crash before send)
    {
        patterns: ['INTERNAL_ERROR', 'SYSTEM_ERROR', 'UNEXPECTED_ERROR', 'CRASH'],
        failureClass: 'SYSTEM_FAILURE'
    }
];

/**
 * Context for failure classification.
 */
export interface ClassificationContext {
    /** Error code from the failure */
    readonly errorCode?: string;
    /** Error message (will be sanitized) */
    readonly errorMessage?: string;
    /** HTTP status code (if applicable) */
    readonly httpStatus?: number;
    /** Whether the failure occurred before external send */
    readonly beforeExternalSend: boolean;
    /** Request ID for correlation */
    readonly requestId: string;
}

/**
 * Classify a failure into one of the defined failure classes.
 *
 * Classification is deterministic and based on:
 * 1. Explicit error codes
 * 2. Error message patterns
 * 3. HTTP status codes
 * 4. Execution phase (before/after external send)
 *
 * @param context Classification context
 * @returns Complete failure classification
 */
export function classifyFailure(context: ClassificationContext): FailureClassification {
    const { errorCode, errorMessage, httpStatus, beforeExternalSend, requestId } = context;

    let failureClass: FailureClass = 'SYSTEM_FAILURE'; // Default: assume system failure

    // Step 1: Check error code patterns
    if (errorCode) {
        const matchedPattern = ERROR_PATTERNS.find(pattern =>
            pattern.patterns.some(p =>
                typeof p === 'string'
                    ? errorCode.toUpperCase().includes(p.toUpperCase())
                    : p.test(errorCode)
            )
        );
        if (matchedPattern) {
            failureClass = matchedPattern.failureClass;
        }
    }

    // Step 2: Check error message patterns (if no code match)
    if (failureClass === 'SYSTEM_FAILURE' && errorMessage) {
        const matchedPattern = ERROR_PATTERNS.find(pattern =>
            pattern.patterns.some(p =>
                typeof p === 'string'
                    ? errorMessage.toUpperCase().includes(p.toUpperCase())
                    : p.test(errorMessage)
            )
        );
        if (matchedPattern) {
            failureClass = matchedPattern.failureClass;
        }
    }

    // Step 3: HTTP status code fallback
    if (failureClass === 'SYSTEM_FAILURE' && httpStatus) {
        if (httpStatus === 400 || httpStatus === 422) {
            failureClass = 'VALIDATION_FAILURE';
        } else if (httpStatus === 401 || httpStatus === 403) {
            failureClass = 'AUTHZ_FAILURE';
        } else if (httpStatus === 408 || httpStatus === 504) {
            failureClass = 'TIMEOUT';
        } else if (httpStatus >= 500 && httpStatus < 600) {
            // 5xx could be transport or system - check if before send
            failureClass = beforeExternalSend ? 'SYSTEM_FAILURE' : 'TRANSPORT_ERROR';
        }
    }

    // Step 4: Phase-based refinement
    if (beforeExternalSend && failureClass === 'TIMEOUT') {
        // Timeout before send is a system failure, not an unknown rail state
        failureClass = 'SYSTEM_FAILURE';
    }

    const eligibility = FAILURE_CLASS_METADATA[failureClass];
    const classification: FailureClassification = {
        failureClass,
        eligibility,
        errorCode,
        errorMessage: sanitizeErrorMessage(errorMessage),
        classifiedAt: new Date().toISOString()
    };

    logger.info({
        requestId,
        failureClass,
        retryAllowed: eligibility.retryAllowed,
        repairRequired: eligibility.repairRequired
    }, 'Failure classified');

    return classification;
}

/**
 * Sanitize error message to remove sensitive data.
 */
function sanitizeErrorMessage(message: string | undefined): string | undefined {
    if (!message) return undefined;

    // Remove potential secrets, tokens, credentials
    return message
        .replace(/password[=:]\s*\S+/gi, 'password=[REDACTED]')
        .replace(/token[=:]\s*\S+/gi, 'token=[REDACTED]')
        .replace(/key[=:]\s*\S+/gi, 'key=[REDACTED]')
        .replace(/secret[=:]\s*\S+/gi, 'secret=[REDACTED]')
        .substring(0, 500); // Limit length
}

/**
 * Check if a failure class allows retry.
 */
export function isRetryable(failureClass: FailureClass): boolean {
    return FAILURE_CLASS_METADATA[failureClass].retryAllowed;
}

/**
 * Check if a failure class requires repair workflow.
 */
export function requiresRepair(failureClass: FailureClass): boolean {
    return FAILURE_CLASS_METADATA[failureClass].repairRequired;
}
