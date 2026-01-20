import { AuditRecordV1, AuditEventType } from "./schema.js";
import { ValidatedIdentityContext } from "../context/identity.js";
import { logger } from "../logging/logger.js";
import { db, DbRole } from "../db/index.js";
import crypto from "crypto";

/**
 * Hardened Audit Logger (PostgreSQL Substrate)
 * Enforces hash-chaining and transaction-bound persistence.
 * INV-PERSIST-02: Log Immutability enforced at the database layer.
 */
class AuditLogger {
    private lastHash: string | null = null;

    constructor() { }

    /**
     * Bootstraps the hash chain by fetching the last verified record from the DB.
     */
    private async ensureChainInitialized(role: DbRole) {
        if (this.lastHash !== null) return;

        try {
            const result = await db.queryAsRole(
                role,
                `SELECT metadata->'integrity'->>'hash' as last_hash 
                 FROM audit_log 
                 ORDER BY created_at DESC 
                 LIMIT 1`
            );

            const row = result.rows[0];
            if (row?.last_hash) {
                this.lastHash = row.last_hash;
            } else {
                this.lastHash = "0".repeat(64); // Genesis Hash
            }
        } catch (error) {
            logger.error({ error }, "Failed to initialize audit chain from database");
            // If we can't read the chain, we must fail-closed to prevent "blind" writes
            throw new Error("Audit substrate unavailable - Chain initialization failed.");
        }
    }

    public async log(
        role: DbRole,
        event: {
            type: AuditEventType;
            context: ValidatedIdentityContext;
            action?: { capability?: string; resource?: string };
            decision: 'ALLOW' | 'DENY' | 'EXECUTED';
            reason?: string;
        }
    ): Promise<void> {
        await this.ensureChainInitialized(role);

        const { type, context, reason } = event;

        const record: Partial<AuditRecordV1> = {
            eventId: crypto.randomUUID(),
            eventType: type,
            timestamp: new Date().toISOString(),
            requestId: context.requestId,
            tenantId: context.tenantId,
            subject: {
                type: context.subjectType === 'user' ? 'client' : context.subjectType,
                id: context.subjectId,
                ou: context.issuerService
            },
            ...(event.action ? { action: event.action } : {}),
            decision: event.decision,
            policyVersion: context.policyVersion,
            ...(reason ? { reason } : {})
        };

        // Construct Integrity Hash
        const prevHash = this.lastHash!;
        const contents = JSON.stringify(record);
        const hash = crypto.createHash("sha256")
            .update(contents + prevHash)
            .digest("hex");

        const signedRecord: AuditRecordV1 = {
            ...(record as AuditRecordV1),
            integrity: { prevHash, hash }
        };

        // INV-OPS-02: Audit records must be committed before external side-effects.
        // We use the database's transactional guarantee.
        try {
            await db.queryAsRole(
                role,
                `INSERT INTO audit_log (id, actor, action, target_id, metadata, created_at) 
                 VALUES ($1, $2, $3, $4, $5, $6)`,
                [
                    signedRecord.eventId,
                    signedRecord.subject.id,
                    signedRecord.eventType,
                    signedRecord.action?.resource || signedRecord.requestId,
                    signedRecord,
                    signedRecord.timestamp
                ]
            );

            this.lastHash = hash;

            logger.info({
                auditEvent: type,
                requestId: context.requestId,
                integrityHash: hash
            }, "Audit record committed to PostgreSQL append-only substrate");
        } catch (error) {
            logger.error({ error, requestId: context.requestId }, "CRITICAL: Audit log write failed. Fail-closed engaged.");
            // Fail-closed: re-throw to abort the operation calling this log
            throw new Error("Audit log failure - Operation aborted to preserve integrity.");
        }
    }
}

export const auditLogger = new AuditLogger();
