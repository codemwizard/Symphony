/**
 * Symphony Guard Audit Logger — Phase 7.1
 * Phase Key: SYS-7-1
 *
 * Specialized audit logging for runtime guards.
 * Produces structured audit events without requiring full identity context.
 *
 * This is a lightweight wrapper for guard-specific audit events.
 */

import { AuditEventType } from './schema.js';
import { logger } from '../logging/logger.js';
import { db } from '../db/index.js';
import crypto from 'crypto';

interface LastHashRow {
    last_hash: string;
}

/**
 * Guard audit event structure.
 * More flexible than the full AuditRecordV1 for pre-identity guard events.
 */
export interface GuardAuditEvent {
    type: AuditEventType;
    requestId: string;
    ingressSequenceId: string;
    participantId?: string | null;
    [key: string]: unknown; // Additional event-specific fields
}

/**
 * Audit logger for runtime guards.
 * Simplified interface for guard decision logging.
 */
class GuardAuditLogger {
    private lastHash: string | null = null;

    private async ensureChainInitialized(): Promise<void> {
        if (this.lastHash !== null) return;

        try {
            const result = await db.query(
                `SELECT metadata->'integrity'->>'hash' as last_hash 
                 FROM audit_log 
                 ORDER BY created_at DESC 
                 LIMIT 1`
            );

            if (result.rows.length > 0) {
                const row = result.rows[0] as LastHashRow;
                this.lastHash = row.last_hash;
            } else {
                this.lastHash = '0'.repeat(64); // Genesis Hash
            }
        } catch (error) {
            logger.error({ error }, 'Failed to initialize audit chain');
            throw new Error('Audit substrate unavailable');
        }
    }

    /**
     * Log a guard audit event.
     */
    public async log(event: GuardAuditEvent): Promise<void> {
        await this.ensureChainInitialized();

        const eventId = crypto.randomUUID();
        const timestamp = new Date().toISOString();

        const record = {
            eventId,
            eventType: event.type,
            timestamp,
            requestId: event.requestId,
            ingressSequenceId: event.ingressSequenceId,
            participantId: event.participantId ?? null,
            ...event
        };

        // Construct integrity hash
        const prevHash = this.lastHash!;
        const contents = JSON.stringify(record);
        const hash = crypto.createHash('sha256')
            .update(contents + prevHash)
            .digest('hex');

        const signedRecord = {
            ...record,
            integrity: { prevHash, hash }
        };

        try {
            await db.query(
                `INSERT INTO audit_log (id, actor, action, target_id, metadata, created_at) 
                 VALUES ($1, $2, $3, $4, $5, $6)`,
                [
                    eventId,
                    event.participantId ?? 'SYSTEM',
                    event.type,
                    event.requestId,
                    signedRecord,
                    timestamp
                ]
            );

            this.lastHash = hash;

            logger.debug({
                auditEvent: event.type,
                requestId: event.requestId,
                integrityHash: hash.substring(0, 16) + '...'
            }, 'Guard audit event committed');
        } catch (error) {
            logger.error({ error, requestId: event.requestId }, 'Guard audit log write failed');
            throw new Error('Audit log failure - Operation aborted');
        }
    }
}

export const guardAuditLogger = new GuardAuditLogger();
