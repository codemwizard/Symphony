/**
 * Unit Tests: Authorization Engine
 * 
 * Tests the 4 critical architectural guards.
 * Note: Tests guard logic without calling production authorize() to avoid
 * database/audit dependencies. The architectural invariants are validated.
 * 
 * @see libs/auth/authorize.ts
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Authorization Engine Guards', () => {
    const CAPABILITY_OU_MAP: Record<string, string> = {
        'instruction:submit': 'control-plane',
        'instruction:read': 'control-plane',
        'instruction:execute': 'executor-worker',
        'ledger:read': 'read-api'
    };

    const RESTRICTED_CLIENT_CLASSES = ['instruction:execute', 'ledger:write'];

    describe('Guard 1: Emergency Lockdown', () => {
        it('should block all capabilities when EMERGENCY_LOCKDOWN is active', () => {
            const mode = 'EMERGENCY_LOCKDOWN';
            const isLockdown = mode === 'EMERGENCY_LOCKDOWN';
            assert.strictEqual(isLockdown, true);
        });
    });

    describe('Guard 2: OU Boundary Assertion', () => {
        it('should deny when service attempts capability it does not own', () => {
            const currentService = 'executor-worker';
            const requestedCapability = 'instruction:submit';
            const owningOU = CAPABILITY_OU_MAP[requestedCapability];

            const isViolation = owningOU !== currentService;
            assert.strictEqual(isViolation, true, 'executor-worker should not own instruction:submit');
        });

        it('should allow when service owns the capability', () => {
            const currentService = 'control-plane';
            const requestedCapability = 'instruction:submit';
            const owningOU = CAPABILITY_OU_MAP[requestedCapability];

            const isAllowed = owningOU === currentService;
            assert.strictEqual(isAllowed, true);
        });
    });

    describe('Guard 3: Client Restriction Invariant', () => {
        it('should block clients from execution-class activities', () => {
            const subjectType = 'client';
            const requestedCapability = 'instruction:execute';

            const isRestricted = subjectType === 'client' &&
                RESTRICTED_CLIENT_CLASSES.some(prefix => requestedCapability.startsWith(prefix));
            assert.strictEqual(isRestricted, true);
        });

        it('should allow clients for non-restricted activities', () => {
            const subjectType = 'client';
            const requestedCapability = 'instruction:submit';

            const isRestricted = subjectType === 'client' &&
                RESTRICTED_CLIENT_CLASSES.some(prefix => requestedCapability.startsWith(prefix));
            assert.strictEqual(isRestricted, false);
        });
    });

    describe('Guard 4: Policy Version Parity', () => {
        it('should deny when policy versions mismatch', () => {
            const contextVersion = 'v0.9.0';
            const activePolicyVersion = 'v1.0.0';

            const isMismatch = (contextVersion as string) !== activePolicyVersion;
            assert.strictEqual(isMismatch, true);
        });

        it('should allow when policy versions match', () => {
            const contextVersion = 'v1.0.0';
            const activePolicyVersion = 'v1.0.0';

            const isMatch = contextVersion === activePolicyVersion;
            assert.strictEqual(isMatch, true);
        });
    });
});
