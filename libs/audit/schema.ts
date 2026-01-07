/**
 * Symphony Canonical Audit Schema — v1
 * Phase Key: SYM-33
 * 
 * Objectives:
 * - Immutability
 * - Non-repudiation
 * - Regulator-grade forensics
 */

export type AuditEventType =
    | 'IDENTITY_VERIFY'
    | 'AUTHZ_ALLOW'
    | 'AUTHZ_DENY'
    | 'INSTRUCTION_SUBMIT'
    | 'INSTRUCTION_CANCEL'
    | 'EXECUTION_ATTEMPT'
    | 'EXECUTION_ABORT'
    | 'POLICY_ACTIVATE'
    | 'KILLSWITCH_ENGAGE'
    | 'EVIDENCE_EXPORT'
    | 'INCIDENT_SIGNAL'
    | 'CONTAINMENT_ACTIVATE';

export interface AuditRecordV1 {
    eventId: string;        // UUID
    eventType: AuditEventType;
    timestamp: string;      // ISO-8601
    requestId: string;
    tenantId: string;
    subject: {
        type: 'client' | 'service';
        id: string;           // subjectId
        ou: string;           // issuerService / currentService
        certFingerprint?: string; // Phase 6.4: mTLS proof
    };
    action: {
        capability?: string;
        resource?: string;    // instructionId, providerId, etc.
    };
    decision: 'ALLOW' | 'DENY' | 'EXECUTED';
    policyVersion: string;
    reason?: string;
    integrity: {
        prevHash: string;     // Hash of the immediately preceding record
        hash: string;         // SHA-256(this_record_serialized || prevHash)
    };
}
