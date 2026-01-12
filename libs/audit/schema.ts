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
    | 'CONTAINMENT_ACTIVATE'
    // Phase 7.1: Participant Identity & Guard Events
    | 'PARTICIPANT_RESOLVED'
    | 'PARTICIPANT_RESOLUTION_FAILED'
    | 'PARTICIPANT_STATUS_DENY'
    | 'GUARD_IDENTITY_DENY'
    | 'GUARD_AUTHORIZATION_DENY'
    | 'GUARD_POLICY_DENY'
    | 'GUARD_LEDGER_SCOPE_DENY'
    // Phase 7.2: Execution, Retry & Repair Events
    | 'EXECUTION_ATTEMPT_CREATED'
    | 'EXECUTION_ATTEMPT_SENT'
    | 'EXECUTION_ATTEMPT_RESOLVED'
    | 'RETRY_EVALUATED'
    | 'RETRY_ALLOWED'
    | 'RETRY_BLOCKED'
    | 'REPAIR_INITIATED'
    | 'REPAIR_RECONCILIATION_RESULT_RECORDED'
    | 'REPAIR_COMPLETED';

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
