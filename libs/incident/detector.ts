import { IncidentSignal, IncidentClass, IncidentSeverity, isMaterial } from "./taxonomy.js";
import { logger } from "../logging/logger.js";
import { auditLogger } from "../audit/logger.js";
import { IncidentContainment } from "./containment.js";
import crypto from "crypto";

/**
 * Symphony Incident Detector
 * Monitors critical paths for anomalies.
 */
export class IncidentDetector {

    /**
     * Detects and emits an incident signal.
     */
    static async emitSignal(params: {
        class: IncidentClass;
        severity: IncidentSeverity;
        source: string;
        details: string;
        materiality?: {
            financialImpactZMW?: number;
            customerCount?: number;
            dataExposure: boolean;
            systemicRisk: boolean;
        }
    }): Promise<IncidentSignal> {

        const signal: IncidentSignal = {
            id: crypto.randomUUID(),
            timestamp: new Date().toISOString(),
            ...params
        };

        // Log to operational logger
        logger.error({ signal }, `INCIDENT SIGNAL EMITTED: ${signal.class} [${signal.severity}]`);

        // Synchronous Audit Log (Preserve evidence)
        await auditLogger.log({
            type: 'INCIDENT_SIGNAL',
            context: {
                version: 'v1',
                issuedAt: new Date().toISOString(),
                issuerService: signal.source,
                requestId: 'incident-' + signal.id,
                subjectId: signal.source,
                subjectType: 'service',
                tenantId: 'symphony',
                policyVersion: 'v1',
                roles: ['system'],
                signature: 'system-signed',
                trustTier: 'internal'
            },

            decision: 'ALLOW', // Signal emission itself is an allowed act
            reason: `Incident ${signal.class} detected from ${signal.source}`
        });

        // Escalation logic placeholder (Next step)
        if (signal.severity === IncidentSeverity.CRITICAL || signal.severity === IncidentSeverity.HIGH) {
            await this.triggerEscalation(signal);
        }

        return signal;
    }

    /**
     * Specifically handles mTLS violations (Phase 6.4)
     */
    static async detectMtlsFailure(source: string, details: string) {
        return await this.emitSignal({
            class: IncidentClass.SEC_1,
            severity: IncidentSeverity.HIGH,
            source,
            details,
            materiality: {
                dataExposure: false,
                systemicRisk: true // Transport failure is systemic
            }
        });
    }

    private static async triggerEscalation(signal: IncidentSignal) {
        // Determine if regulator notification is mandatory
        const mandatoryDisclosure = signal.class === IncidentClass.REG_1 ||
            (signal.materiality && isMaterial(signal.materiality));

        logger.warn({ signalId: signal.id, mandatoryDisclosure },
            `Incident Escalation triggered. Mandatory Disclosure: ${mandatoryDisclosure}`);

        // Trigger Automated Containment
        if (signal.severity === IncidentSeverity.CRITICAL) {
            await IncidentContainment.execute(signal);
        }
    }
}
