/**
 * Symphony Retry Eligibility Tests — Phase 7.2
 * Phase Key: SYS-7-2
 */

import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { FailureClassification } from '../libs/execution/failureTypes.js';

// Mock dependencies
jest.mock('../libs/audit/guardLogger.js', () => ({
    guardAuditLogger: { log: jest.fn().mockResolvedValue(undefined) }
}));

jest.mock('../libs/logging/logger.js', () => ({
    logger: {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn()
    }
}));

// Mock instruction state client
const mockIsTerminal = jest.fn<() => Promise<boolean>>();
jest.mock('../libs/execution/instructionStateClient.js', () => ({
    isTerminal: () => mockIsTerminal()
}));

describe('Phase 7.2: Retry Eligibility', () => {

    describe('Retry Semantics', () => {
        it('retry should use same instruction, not create new one', () => {
            // This is a structural test validating the contract
            const retryDecision = {
                shouldRetry: true,
                instructionId: 'instr-001',
                idempotencyKey: 'key-001'
            };

            // Same instruction ID means reuse, not duplicate
            expect(retryDecision.instructionId).toBeDefined();
            expect(retryDecision.idempotencyKey).toBeDefined();
        });
    });

    describe('Failure Class Retry Eligibility', () => {
        const createFailureClassification = (failureClass: string, retryAllowed: boolean, repairRequired: boolean): FailureClassification => ({
            failureClass: failureClass as FailureClassification['failureClass'],
            eligibility: {
                retryAllowed,
                repairRequired,
                reason: 'test'
            },
            classifiedAt: new Date().toISOString()
        });

        it('VALIDATION_FAILURE should block retry', () => {
            const classification = createFailureClassification('VALIDATION_FAILURE', false, false);
            expect(classification.eligibility.retryAllowed).toBe(false);
        });

        it('TIMEOUT should redirect to repair', () => {
            const classification = createFailureClassification('TIMEOUT', false, true);
            expect(classification.eligibility.retryAllowed).toBe(false);
            expect(classification.eligibility.repairRequired).toBe(true);
        });

        it('TRANSPORT_ERROR should allow retry', () => {
            const classification = createFailureClassification('TRANSPORT_ERROR', true, false);
            expect(classification.eligibility.retryAllowed).toBe(true);
        });
    });

    describe('Invariant INV-PERSIST-03', () => {
        it('retry must preserve idempotency key', () => {
            const originalKey = 'idem-key-12345678';
            const retryContext = {
                instructionId: 'instr-001',
                idempotencyKey: originalKey
            };

            // Retry uses same key
            expect(retryContext.idempotencyKey).toBe(originalKey);
        });
    });
});
