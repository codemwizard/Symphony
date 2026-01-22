import os from 'node:os';
import { pino } from 'pino';
import { db, DbRole } from '../db/index.js';
import { repairExpiredLeases } from '../outbox/db.js';

const logger = pino({ name: 'LeaseRepairWorker' });

// Configuration
const REPAIR_BATCH_SIZE = 100;
const REPAIR_INTERVAL_MS = 60000; // Run every 60 seconds
const DEFAULT_WORKER_ID = process.env.LEASE_REPAIR_WORKER_ID ?? `${os.hostname()}-${process.pid}`;
const LOG_OUTBOX_IDS = process.env.LEASE_REPAIR_LOG_IDS === 'true';
const MAX_LOG_IDS = 20;

export interface RepairResult {
    repairedCount: number;
    scannedCount: number;
    errors: string[];
}

/**
 * Lease Repair Worker
 *
 * Runs periodically to:
 * 1. Find expired leases in pending
 * 2. Clear leases and reschedule
 * 3. Append ZOMBIE_REQUEUE attempts via DB function
 */
export class LeaseRepairWorker {
    private isRunning = false;
    private intervalHandle: NodeJS.Timeout | null = null;

    constructor(
        private readonly role: DbRole = 'symphony_executor',
        private readonly dbClient = db,
        private readonly workerId: string = DEFAULT_WORKER_ID
    ) { }

    /**
     * Start the repair worker
     */
    public start(): void {
        if (this.isRunning) {
            logger.warn('LeaseRepairWorker already running');
            return;
        }

        this.isRunning = true;
        logger.info('LeaseRepairWorker started');

        // Run immediately, then on interval
        void this.runRepairCycle();
        this.intervalHandle = setInterval(() => void this.runRepairCycle(), REPAIR_INTERVAL_MS);
    }

    /**
     * Stop the repair worker
     */
    public stop(): void {
        this.isRunning = false;
        if (this.intervalHandle) {
            clearInterval(this.intervalHandle);
            this.intervalHandle = null;
        }
        logger.info('LeaseRepairWorker stopped');
    }

    /**
     * Run a single repair cycle
     */
    public async runRepairCycle(): Promise<RepairResult> {
        const result: RepairResult = {
            repairedCount: 0,
            scannedCount: 0,
            errors: []
        };

        try {
            const rows = await repairExpiredLeases(this.role, REPAIR_BATCH_SIZE, this.workerId, this.dbClient);
            result.repairedCount = rows.length;
            result.scannedCount = rows.length;

            if (result.repairedCount > 0) {
                const payload: Record<string, unknown> = {
                    workerId: this.workerId,
                    repairedCount: result.repairedCount,
                    scannedCount: result.scannedCount
                };
                if (LOG_OUTBOX_IDS) {
                    payload.outboxIds = rows.slice(0, MAX_LOG_IDS).map(row => row.outbox_id);
                }
                logger.info(payload, 'Lease repair complete');
            } else {
                logger.debug({ workerId: this.workerId }, 'Lease repair found no expired leases');
            }

            return result;
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            result.errors.push(errorMessage);
            logger.error({ error: errorMessage }, 'Lease repair failed');
        }

        return result;
    }

    /**
     * Get current zombie count (for monitoring)
     */
    public async getExpiredLeaseCount(): Promise<number> {
        const result = await this.dbClient.queryAsRole(
            this.role,
            `
            SELECT COUNT(*) as count
            FROM payment_outbox_pending
            WHERE claimed_by IS NOT NULL
              AND lease_expires_at <= NOW();
        `
        );
        return parseInt(result.rows[0]?.count ?? '0', 10);
    }
}

/**
 * Factory function for creating repair worker
 */
export function createLeaseRepairWorker(role: DbRole = 'symphony_executor'): LeaseRepairWorker {
    return new LeaseRepairWorker(role);
}
