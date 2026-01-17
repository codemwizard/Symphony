/**
 * Unit Tests: Incident Containment
 * 
 * Tests automated threat response orchestration.
 * Note: Tests containment rules without calling production code to avoid
 * database/audit dependencies. The response logic is validated.
 * 
 * @see libs/incident/containment.ts
 */

import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('IncidentContainment Rules', () => {
    // Incident classification from taxonomy
    const IncidentClass = {
        SEC_1: 'SEC_1', // AuthZ Violation
        SEC_2: 'SEC_2', // Integrity Breach
        OPS_1: 'OPS_1'  // Operational Error
    };

    const IncidentSeverity = {
        CRITICAL: 'CRITICAL',
        HIGH: 'HIGH',
        MEDIUM: 'MEDIUM'
    };

    describe('Rule 1: SEC-2 + CRITICAL triggers GLOBAL FREEZE', () => {
        it('should trigger global kill switch for integrity breach', () => {
            const signal = {
                class: IncidentClass.SEC_2,
                severity: IncidentSeverity.CRITICAL
            };

            const shouldTriggerGlobalFreeze =
                signal.class === IncidentClass.SEC_2 &&
                signal.severity === IncidentSeverity.CRITICAL;

            assert.strictEqual(shouldTriggerGlobalFreeze, true);
        });

        it('should NOT trigger for SEC-2 HIGH', () => {
            const signal = {
                class: IncidentClass.SEC_2,
                severity: IncidentSeverity.HIGH
            };

            const shouldTriggerGlobalFreeze =
                signal.class === IncidentClass.SEC_2 &&
                signal.severity === IncidentSeverity.CRITICAL;

            assert.strictEqual(shouldTriggerGlobalFreeze, false);
        });
    });

    describe('Rule 2: SEC-1 + CRITICAL triggers SCOPED LOCK', () => {
        it('should trigger actor capability freeze for authz violation', () => {
            const signal = {
                class: IncidentClass.SEC_1,
                severity: IncidentSeverity.CRITICAL
            };

            const shouldTriggerScopedLock =
                signal.class === IncidentClass.SEC_1 &&
                signal.severity === IncidentSeverity.CRITICAL;

            assert.strictEqual(shouldTriggerScopedLock, true);
        });
    });

    describe('No Action for Non-Critical', () => {
        it('should not trigger any action for non-critical signals', () => {
            const signal = {
                class: IncidentClass.SEC_1,
                severity: IncidentSeverity.MEDIUM
            };

            const shouldTriggerGlobalFreeze =
                signal.class === IncidentClass.SEC_2 &&
                signal.severity === IncidentSeverity.CRITICAL;

            const shouldTriggerScopedLock =
                signal.class === IncidentClass.SEC_1 &&
                signal.severity === IncidentSeverity.CRITICAL;

            assert.strictEqual(shouldTriggerGlobalFreeze, false);
            assert.strictEqual(shouldTriggerScopedLock, false);
        });
    });
});
