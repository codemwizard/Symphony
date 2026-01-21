import { pino } from 'pino';
import { db, DbRole } from '../db/index.js';

const logger = pino({ name: 'ZombieRepairWorker' });

// Configuration
const ZOMBIE_THRESHOLD_SECONDS = (() => {
    const raw = process.env.ZOMBIE_THRESHOLD_SECONDS;
    const parsed = raw ? Number(raw) : 120;
    return Number.isFinite(parsed) && parsed > 0 ? parsed : 120;
})();    // Records stuck > threshold are zombies
const REPAIR_BATCH_SIZE = 100;
const REPAIR_INTERVAL_MS = 60000;       // Run every 60 seconds

/**
 * Zombie Repair Result
 */
export interface RepairResult {
    zombiesRequeued: number;
    errors: string[];
}

/**
 * Zombie Repair Worker
 *
 * Runs periodically to:
 * 1. Identify records whose latest attempt is DISPATCHING and stale
 * 2. Requeue them to pending with the same outbox_id/sequence_id
 * 3. Append a ZOMBIE_REQUEUE attempt for auditability
 */
export class ZombieRepairWorker {
    private isRunning = false;
    private intervalHandle: NodeJS.Timeout | null = null;

    constructor(
        private readonly role: DbRole = 'symphony_executor',
        private readonly dbClient = db
    ) { }

    /**
     * Start the repair worker
     */
    public start(): void {
        if (this.isRunning) {
            logger.warn('ZombieRepairWorker already running');
            return;
        }

        this.isRunning = true;
        logger.info('ZombieRepairWorker started');

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
        logger.info('ZombieRepairWorker stopped');
    }

    /**
     * Run a single repair cycle
     */
    public async runRepairCycle(): Promise<RepairResult> {
        const result: RepairResult = {
            zombiesRequeued: 0,
            errors: []
        };

        try {
            return await this.dbClient.transactionAsRole(this.role, async (client) => {
                const staleAttempts = await client.query(`
                SELECT latest.outbox_id,
                       latest.instruction_id,
                       latest.participant_id,
                       latest.sequence_id,
                       latest.idempotency_key,
                       latest.rail_type,
                       latest.payload,
                       latest.attempt_no AS last_attempt_no,
                       (latest.attempt_no + 1) AS next_attempt_no
                FROM (
                    SELECT DISTINCT ON (outbox_id)
                        outbox_id,
                        instruction_id,
                        participant_id,
                        sequence_id,
                        idempotency_key,
                        rail_type,
                        payload,
                        attempt_no,
                        state,
                        claimed_at
                    FROM payment_outbox_attempts
                    ORDER BY outbox_id, claimed_at DESC
                ) AS latest
                WHERE latest.state = 'DISPATCHING'
                  AND latest.claimed_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds'
                LIMIT $1;
            `, [REPAIR_BATCH_SIZE]);

                if (staleAttempts.rows.length > 0) {
                    const pendingValues: Array<unknown> = [];
                    const pendingPlaceholders: string[] = [];
                    const attemptValues: Array<unknown> = [];
                    const attemptPlaceholders: string[] = [];

                staleAttempts.rows.forEach((row, index) => {
                    const pendingOffset = index * 8;
                    pendingPlaceholders.push(`($${pendingOffset + 1}, $${pendingOffset + 2}, $${pendingOffset + 3}, $${pendingOffset + 4}, $${pendingOffset + 5}, $${pendingOffset + 6}, $${pendingOffset + 7}, $${pendingOffset + 8}, NOW())`);
                    pendingValues.push(
                        row.outbox_id,
                        row.instruction_id,
                        row.participant_id,
                        row.sequence_id,
                        row.idempotency_key,
                        row.rail_type,
                        JSON.stringify(row.payload),
                        row.last_attempt_no
                    );

                    const attemptOffset = index * 10;
                    attemptPlaceholders.push(`($${attemptOffset + 1}, $${attemptOffset + 2}, $${attemptOffset + 3}, $${attemptOffset + 4}, $${attemptOffset + 5}, $${attemptOffset + 6}, $${attemptOffset + 7}, 'ZOMBIE_REQUEUE', $${attemptOffset + 8}, NOW(), NOW(), $${attemptOffset + 9}, $${attemptOffset + 10}, NOW())`);
                    attemptValues.push(
                        row.outbox_id,
                        row.instruction_id,
                        row.participant_id,
                        row.sequence_id,
                        row.idempotency_key,
                        row.rail_type,
                        JSON.stringify(row.payload),
                        row.next_attempt_no,
                        'ZOMBIE_REQUEUE',
                        'Dispatch attempt exceeded threshold'
                    );
                });

                    await client.query(`
                    INSERT INTO payment_outbox_pending (
                        outbox_id,
                        instruction_id,
                        participant_id,
                        sequence_id,
                        idempotency_key,
                        rail_type,
                        payload,
                        attempt_count,
                        next_attempt_at
                    ) VALUES ${pendingPlaceholders.join(', ')}
                    ON CONFLICT (outbox_id)
                    DO UPDATE SET
                        attempt_count = GREATEST(payment_outbox_pending.attempt_count, EXCLUDED.attempt_count),
                        next_attempt_at = NOW(),
                        payload = EXCLUDED.payload;
                `, pendingValues);

                    await client.query(`
                    INSERT INTO payment_outbox_attempts (
                        outbox_id,
                        instruction_id,
                        participant_id,
                        sequence_id,
                        idempotency_key,
                        rail_type,
                        payload,
                        state,
                        attempt_no,
                        claimed_at,
                        completed_at,
                        error_code,
                        error_message,
                        created_at
                    ) VALUES ${attemptPlaceholders.join(', ')};
                `, attemptValues);

                    result.zombiesRequeued = staleAttempts.rows.length;
                }

                if (result.zombiesRequeued > 0) {
                    logger.info({ zombiesRequeued: result.zombiesRequeued }, 'Zombie requeue complete');
                }

                return result;
            });
        } catch (error: unknown) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            result.errors.push(errorMessage);
            logger.error({ error: errorMessage }, 'Repair cycle failed');
        }

        return result;
    }

    /**
     * Get current zombie count (for monitoring)
     */
    public async getZombieCount(): Promise<number> {
        const result = await this.dbClient.queryAsRole(this.role, `
            SELECT COUNT(*) as count
            FROM (
                SELECT DISTINCT ON (outbox_id)
                    outbox_id,
                    state,
                    claimed_at
                FROM payment_outbox_attempts
                ORDER BY outbox_id, claimed_at DESC
            ) AS latest
            WHERE latest.state = 'DISPATCHING'
              AND latest.claimed_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds';
        `);
        return parseInt(result.rows[0]?.count ?? '0', 10);
    }
}

/**
 * Factory function for creating repair worker
 */
export function createZombieRepairWorker(role: DbRole = 'symphony_executor'): ZombieRepairWorker {
    return new ZombieRepairWorker(role);
}
