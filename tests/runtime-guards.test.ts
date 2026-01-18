/**
 * Symphony Runtime Guards Tests — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Tests for all four guards:
 * - Identity guard rejection scenarios
 * - Authorization guard scope enforcement (SUPERVISOR blocking)
 * - Policy guard limit enforcement
 * - Ledger scope guard validation
 */

import { describe, it, expect, jest, beforeAll, afterAll } from '@jest/globals';
import {
    executeIdentityGuard,
    IdentityGuardContext
} from '../libs/guards/identityGuard.js';
import {
    executeAuthorizationGuard,
    AuthorizationGuardContext
} from '../libs/guards/authorizationGuard.js';
import {
    executePolicyGuard,
    PolicyGuardContext
} from '../libs/guards/policyGuard.js';
import {
    executeLedgerGuard,
    LedgerGuardContext
} from '../libs/guards/ledgerGuard.js';
import { ResolvedParticipant } from '../libs/participant/index.js';
import { PolicyProfile } from '../libs/policy/index.js';
import { guardAuditLogger } from '../libs/audit/guardLogger.js';
import { logger } from '../libs/logging/logger.js';

describe('Phase 7.1: Runtime Guards', () => {

    beforeAll(() => {
        // Spy on the singleton instances directly
        jest.spyOn(guardAuditLogger, 'log').mockResolvedValue(undefined);

        jest.spyOn(logger, 'debug').mockImplementation(() => { });
        jest.spyOn(logger, 'warn').mockImplementation(() => { });
        jest.spyOn(logger, 'info').mockImplementation(() => { });
        jest.spyOn(logger, 'error').mockImplementation(() => { });
    });

    afterAll(() => {
        jest.restoreAllMocks();
    });

    const createParticipant = (overrides: Partial<ResolvedParticipant> = {}): ResolvedParticipant => ({
        participantId: 'test-participant-001',
        legalEntityRef: 'BOZ-REG-12345',
        mtlsCertFingerprint: 'abc123def456',
        role: 'BANK',
        policyProfileId: 'policy-001',
        ledgerScope: { allowedAccountIds: ['acct-001', 'acct-002'] },
        sandboxLimits: {},
        status: 'ACTIVE',
        statusChangedAt: new Date().toISOString(),
        statusReason: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        createdBy: 'system',
        ...overrides
    });

    const createPolicyProfile = (overrides: Partial<PolicyProfile> = {}): PolicyProfile => ({
        policyProfileId: 'policy-001',
        name: 'Sandbox Default',
        maxTransactionAmount: '10000.00',
        maxTransactionsPerSecond: 10,
        dailyAggregateLimit: '100000.00',
        allowedMessageTypes: ['pacs.008', 'pacs.002'],
        constraints: {},
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        createdBy: 'system',
        ...overrides
    });

    describe('Identity Guard', () => {
        it('should deny when mTLS context is missing', async () => {
            const context: IdentityGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                certFingerprint: undefined,
                participant: undefined
            };

            const result = await executeIdentityGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('NO_MTLS_CONTEXT');
            }
        });

        it('should deny when participant is not resolved', async () => {
            const context: IdentityGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                certFingerprint: 'valid-fingerprint',
                participant: undefined
            };

            const result = await executeIdentityGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('NO_PARTICIPANT_RESOLVED');
            }
        });

        it('should deny SUSPENDED participant with PARTICIPANT_STATUS_DENY', async () => {
            const context: IdentityGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                certFingerprint: 'valid-fingerprint',
                participant: createParticipant({ status: 'SUSPENDED' })
            };

            const result = await executeIdentityGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('PARTICIPANT_STATUS_DENY');
            }
        });

        it('should deny REVOKED participant with PARTICIPANT_STATUS_DENY', async () => {
            const context: IdentityGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                certFingerprint: 'valid-fingerprint',
                participant: createParticipant({ status: 'REVOKED' })
            };

            const result = await executeIdentityGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('PARTICIPANT_STATUS_DENY');
            }
        });

        it('should allow ACTIVE participant', async () => {
            const context: IdentityGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                certFingerprint: 'valid-fingerprint',
                participant: createParticipant({ status: 'ACTIVE' })
            };

            const result = await executeIdentityGuard(context);
            expect(result.allowed).toBe(true);
        });
    });

    describe('Authorization Guard — SUPERVISOR Blocking', () => {
        it('should block SUPERVISOR from execution:attempt capability', async () => {
            const context: AuthorizationGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({ role: 'SUPERVISOR' }),
                requestedCapability: 'execution:attempt'
            };

            const result = await executeAuthorizationGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('SUPERVISOR_CANNOT_EXECUTE');
            }
        });

        it('should block SUPERVISOR from instruction:submit capability', async () => {
            const context: AuthorizationGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({ role: 'SUPERVISOR' }),
                requestedCapability: 'instruction:submit'
            };

            const result = await executeAuthorizationGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('SUPERVISOR_CANNOT_EXECUTE');
            }
        });

        it('should allow SUPERVISOR for audit:read capability', async () => {
            const context: AuthorizationGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({ role: 'SUPERVISOR' }),
                requestedCapability: 'audit:read'
            };

            const result = await executeAuthorizationGuard(context);
            expect(result.allowed).toBe(true);
        });

        it('should allow BANK for execution:attempt capability', async () => {
            const context: AuthorizationGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({ role: 'BANK' }),
                requestedCapability: 'execution:attempt'
            };

            const result = await executeAuthorizationGuard(context);
            expect(result.allowed).toBe(true);
        });
    });

    describe('Policy Guard — Sandbox Exposure Limits', () => {
        it('should deny amount exceeding limit', async () => {
            const context: PolicyGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant(),
                policyProfile: createPolicyProfile({ maxTransactionAmount: '1000.00' }),
                transactionAmount: '5000.00',
                messageType: 'pacs.008'
            };

            const result = await executePolicyGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('AMOUNT_EXCEEDS_LIMIT');
            }
        });

        it('should deny message type not in whitelist', async () => {
            const context: PolicyGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant(),
                policyProfile: createPolicyProfile({ allowedMessageTypes: ['pacs.008'] }),
                transactionAmount: '100.00',
                messageType: 'pain.001'  // Not in whitelist
            };

            const result = await executePolicyGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('MESSAGE_TYPE_NOT_ALLOWED');
            }
        });

        it('should allow amount within limit', async () => {
            const context: PolicyGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant(),
                policyProfile: createPolicyProfile({ maxTransactionAmount: '10000.00' }),
                transactionAmount: '500.00',
                messageType: 'pacs.008'
            };

            const result = await executePolicyGuard(context);
            expect(result.allowed).toBe(true);
        });
    });

    describe('Ledger Guard — Structural Scope Validation', () => {
        it('should deny account not in scope (fail-closed)', async () => {
            const context: LedgerGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({
                    ledgerScope: { allowedAccountIds: ['acct-001'] }
                }),
                requestedAccountIds: ['acct-999'] // Not in scope
            };

            const result = await executeLedgerGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('ACCOUNT_OUT_OF_SCOPE');
            }
        });

        it('should deny when ledger_scope is empty (fail-closed)', async () => {
            const context: LedgerGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({
                    ledgerScope: { allowedAccountIds: [] }
                }),
                requestedAccountIds: ['acct-001']
            };

            const result = await executeLedgerGuard(context);
            expect(result.allowed).toBe(false);
            if (result.allowed === false) {
                expect(result.reason).toBe('ACCOUNT_OUT_OF_SCOPE');
            }
        });

        it('should allow account in scope', async () => {
            const context: LedgerGuardContext = {
                requestId: 'req-001',
                ingressSequenceId: 'seq-001',
                participant: createParticipant({
                    ledgerScope: { allowedAccountIds: ['acct-001', 'acct-002'] }
                }),
                requestedAccountIds: ['acct-001']
            };

            const result = await executeLedgerGuard(context);
            expect(result.allowed).toBe(true);
        });
    });
});
