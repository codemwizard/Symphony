import { IncidentSignal, IncidentClass, IncidentSeverity } from "./taxonomy";
import { logger } from "../logging/logger";
import { auditLogger } from "../audit/logger";
import { IncidentDetector } from "./detector";

/**
 * Symphony Incident Containment
 * Orchestrates automated responses to threats.
 */
export class IncidentContainment {

    /**
     * Executes automated containment based on signal classification.
     */
    static async execute(signal: IncidentSignal) {
        logger.info({ signalId: signal.id }, "Execution of automated containment started");

        const actions: string[] = [];

        // Rule 1: SEC-2 (Integrity Breach) triggers GLOBAL FREEZE
        if (signal.class === IncidentClass.SEC_2 && signal.severity === IncidentSeverity.CRITICAL) {
            actions.push("ACTIVATE_GLOBAL_KILL_SWITCH");
        }

        // Rule 2: SEC-1 (AuthZ Violation) triggers SCOPED RESOURCE LOCK
        if (signal.class === IncidentClass.SEC_1 && signal.severity === IncidentSeverity.CRITICAL) {
            actions.push("FREEZE_ACTOR_CAPABILITIES");
        }

        for (const action of actions) {
            await this.runAction(action, signal);
        }
    }

    private static async runAction(action: string, signal: IncidentSignal) {
        logger.warn({ action, signalId: signal.id }, `CONTAINMENT ACTION TRIGGERED: ${action}`);

        // Audit the containment action (Synchronous)
        await auditLogger.log({
            type: 'CONTAINMENT_ACTIVATE',
            context: {
                version: 'v1',
                issuedAt: new Date().toISOString(),
                issuerService: 'incident-containment',
                requestId: 'containment-' + signal.id,
                subjectId: 'incident-responder',
                subjectType: 'service',
                tenantId: 'symphony',
                policyVersion: 'v1',
                roles: ['system'],
                signature: 'system-signed',
                trustTier: 'internal'
            },

            decision: 'EXECUTED',
            reason: `Automated response to ${signal.class} [${signal.severity}]: ${action}`
        });

        // Implementation Detail: In a real system, this would call the Control Plane 
        // or direct kill-switch APIs. For SYM-34, we signal the state change here.
    }
}
