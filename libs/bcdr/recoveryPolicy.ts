/**
 * Symphony Recovery Policy (SYM-35)
 * Defines graduated recovery modes post-catastrophe.
 */

export enum RecoveryMode {
    LOCKDOWN = "LOCKDOWN",           // Default Fail-Closed state
    READ_ONLY = "READ_ONLY",         // Regulator visibility only
    CONTROL_ONLY = "CONTROL_ONLY",   // Remediation by Command actors
    FULL_OPERATIONAL = "FULL_OPERATIONAL" // Normal execution
}

export interface RecoveryState {
    mode: RecoveryMode;
    incidentId?: string;           // Reference to Phase 6.6 Incident
    authorizedBy: string[];        // Dual-control enforcement
    timestamp: string;
}

/**
 * Valid state transitions for graduated recovery.
 * Prevents bypass of verification gates.
 */
const ALLOWED_TRANSITIONS: Record<RecoveryMode, RecoveryMode[]> = {
    [RecoveryMode.LOCKDOWN]: [RecoveryMode.READ_ONLY, RecoveryMode.CONTROL_ONLY],
    [RecoveryMode.READ_ONLY]: [RecoveryMode.CONTROL_ONLY, RecoveryMode.LOCKDOWN],
    [RecoveryMode.CONTROL_ONLY]: [RecoveryMode.FULL_OPERATIONAL, RecoveryMode.LOCKDOWN],
    [RecoveryMode.FULL_OPERATIONAL]: [RecoveryMode.LOCKDOWN]
};

export class RecoveryPolicyManager {
    private static currentState: RecoveryState = {
        mode: RecoveryMode.LOCKDOWN,
        authorizedBy: [],
        timestamp: new Date().toISOString()
    };

    static async transition(newMode: RecoveryMode, actorId: string, incidentId: string): Promise<boolean> {
        if (!ALLOWED_TRANSITIONS[this.currentState.mode].includes(newMode)) {
            throw new Error(`Invalid recovery transition: ${this.currentState.mode} -> ${newMode}`);
        }

        // Dual Control Check (Mock logic for Phase 6.7)
        if (newMode === RecoveryMode.FULL_OPERATIONAL && this.currentState.authorizedBy.length < 1) {
            this.currentState.authorizedBy.push(actorId);
            return false; // Waiting for second authorizer
        }

        this.currentState = {
            mode: newMode,
            incidentId,
            authorizedBy: [...this.currentState.authorizedBy, actorId],
            timestamp: new Date().toISOString()
        };

        return true;
    }

    static getState(): RecoveryState {
        return { ...this.currentState };
    }
}
