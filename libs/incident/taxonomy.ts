/**
 * Symphony Incident Taxonomy (SYM-34)
 * Aligned with Bank of Zambia supervisory expectations.
 */

export enum IncidentClass {
    SEC_1 = "SEC-1", // Security Control Failure
    SEC_2 = "SEC-2", // Integrity Breach (Audit Chain)
    OPS_1 = "OPS-1", // Execution Failure
    OPS_2 = "OPS-2", // Availability Outage
    REG_1 = "REG-1", // Regulatory Impact/Disclosure Failure
}

export enum IncidentSeverity {
    CRITICAL = "CRITICAL", // Immediate automated containment
    HIGH = "HIGH",        // Fast-track manual review
    MEDIUM = "MEDIUM",    // Standard investigation
    LOW = "LOW",          // Periodic review
}

export interface MaterialityOverlay {
    financialImpactZMW?: number;
    customerCount?: number;
    dataExposure: boolean;
    systemicRisk: boolean;
}

export interface IncidentSignal {
    id: string;
    class: IncidentClass;
    severity: IncidentSeverity;
    source: string; // Service or component emitting the signal
    timestamp: string;
    details: string;
    materiality?: MaterialityOverlay;
    regulatorAck?: RegulatorAckSchema;
}

export interface RegulatorAckSchema {
    regulatorId: string;
    ackId: string;
    timestamp: string;
    followUpRequired: boolean;
    notes?: string;
}

/**
 * Incident Response Roles & Capabilities
 */
export const INCIDENT_ROLE_MAP = {
    INCIDENT_COMMANDER: ['incident:declare', 'killswitch:activate', 'escalate:manual'],
    FORENSICS_OFFICER: ['audit:export', 'evidence:bundle', 'integrity:verify'],
    COMPLIANCE_OFFICER: ['regulator:notify', 'disclosure:sign'],
    PLATFORM_OPERATOR: ['service:restart', 'config:patch', 'recovery:execute'],
};

/**
 * Materiality Thresholds (Configurable)
 */
export const MATERIALITY_THRESHOLDS = {
    ZMW_THRESHOLD: 100000, // 100k ZMW
    CUSTOMER_THRESHOLD: 100, // 100 Customers
};

export function isMaterial(materiality: MaterialityOverlay): boolean {
    if (materiality.dataExposure || materiality.systemicRisk) return true;
    if (materiality.financialImpactZMW && materiality.financialImpactZMW >= MATERIALITY_THRESHOLDS.ZMW_THRESHOLD) return true;
    if (materiality.customerCount && materiality.customerCount >= MATERIALITY_THRESHOLDS.CUSTOMER_THRESHOLD) return true;
    return false;
}
