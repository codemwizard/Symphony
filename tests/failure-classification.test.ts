/**
 * Symphony Failure Classification Tests — Phase 7.2
 * Phase Key: SYS-7-2
 */

import { describe, it, expect } from '@jest/globals';
import {
    FAILURE_CLASS_METADATA,
    TIMEOUT_CLARIFICATION
} from '../libs/execution/failureTypes.js';
import {
    classifyFailure,
    isRetryable,
    requiresRepair
} from '../libs/execution/failureClassifier.js';

describe('Phase 7.2: Failure Classification', () => {

    describe('Failure Class Metadata', () => {
        it('VALIDATION_FAILURE should not allow retry', () => {
            expect(FAILURE_CLASS_METADATA.VALIDATION_FAILURE.retryAllowed).toBe(false);
            expect(FAILURE_CLASS_METADATA.VALIDATION_FAILURE.repairRequired).toBe(false);
        });

        it('AUTHZ_FAILURE should not allow retry', () => {
            expect(FAILURE_CLASS_METADATA.AUTHZ_FAILURE.retryAllowed).toBe(false);
            expect(FAILURE_CLASS_METADATA.AUTHZ_FAILURE.repairRequired).toBe(false);
        });

        it('RAIL_REJECT should not allow retry', () => {
            expect(FAILURE_CLASS_METADATA.RAIL_REJECT.retryAllowed).toBe(false);
            expect(FAILURE_CLASS_METADATA.RAIL_REJECT.repairRequired).toBe(false);
        });

        it('TIMEOUT should require repair, not retry', () => {
            expect(FAILURE_CLASS_METADATA.TIMEOUT.retryAllowed).toBe(false);
            expect(FAILURE_CLASS_METADATA.TIMEOUT.repairRequired).toBe(true);
        });

        it('TRANSPORT_ERROR should allow retry', () => {
            expect(FAILURE_CLASS_METADATA.TRANSPORT_ERROR.retryAllowed).toBe(true);
            expect(FAILURE_CLASS_METADATA.TRANSPORT_ERROR.repairRequired).toBe(false);
        });

        it('SYSTEM_FAILURE should allow retry', () => {
            expect(FAILURE_CLASS_METADATA.SYSTEM_FAILURE.retryAllowed).toBe(true);
            expect(FAILURE_CLASS_METADATA.SYSTEM_FAILURE.repairRequired).toBe(false);
        });
    });

    describe('TIMEOUT Clarification', () => {
        it('should state that TIMEOUT is unknown state, not failure', () => {
            expect(TIMEOUT_CLARIFICATION).toContain('unknown');
            expect(TIMEOUT_CLARIFICATION).toContain('reconciliation');
        });
    });

    describe('classifyFailure', () => {
        it('should classify validation error as VALIDATION_FAILURE', () => {
            const result = classifyFailure({
                errorCode: 'VALIDATION_ERROR',
                beforeExternalSend: true,
                requestId: 'req-001'
            });

            expect(result.failureClass).toBe('VALIDATION_FAILURE');
            expect(result.eligibility.retryAllowed).toBe(false);
        });

        it('should classify timeout as TIMEOUT', () => {
            const result = classifyFailure({
                errorCode: 'TIMEOUT',
                beforeExternalSend: false,
                requestId: 'req-001'
            });

            expect(result.failureClass).toBe('TIMEOUT');
            expect(result.eligibility.repairRequired).toBe(true);
        });

        it('should classify connection refused as TRANSPORT_ERROR', () => {
            const result = classifyFailure({
                errorCode: 'ECONNREFUSED',
                beforeExternalSend: false,
                requestId: 'req-001'
            });

            expect(result.failureClass).toBe('TRANSPORT_ERROR');
            expect(result.eligibility.retryAllowed).toBe(true);
        });

        it('should classify HTTP 401 as AUTHZ_FAILURE', () => {
            const result = classifyFailure({
                httpStatus: 401,
                beforeExternalSend: false,
                requestId: 'req-001'
            });

            expect(result.failureClass).toBe('AUTHZ_FAILURE');
        });

        it('should sanitize error messages', () => {
            const result = classifyFailure({
                errorMessage: 'Failed with password=secret123',
                beforeExternalSend: true,
                requestId: 'req-001'
            });

            expect(result.errorMessage).not.toContain('secret123');
            expect(result.errorMessage).toContain('[REDACTED]');
        });
    });

    describe('isRetryable', () => {
        it('should return true for TRANSPORT_ERROR', () => {
            expect(isRetryable('TRANSPORT_ERROR')).toBe(true);
        });

        it('should return true for SYSTEM_FAILURE', () => {
            expect(isRetryable('SYSTEM_FAILURE')).toBe(true);
        });

        it('should return false for TIMEOUT', () => {
            expect(isRetryable('TIMEOUT')).toBe(false);
        });

        it('should return false for RAIL_REJECT', () => {
            expect(isRetryable('RAIL_REJECT')).toBe(false);
        });
    });

    describe('requiresRepair', () => {
        it('should return true for TIMEOUT', () => {
            expect(requiresRepair('TIMEOUT')).toBe(true);
        });

        it('should return false for TRANSPORT_ERROR', () => {
            expect(requiresRepair('TRANSPORT_ERROR')).toBe(false);
        });
    });
});
