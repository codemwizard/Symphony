/**
 * Phase-7R: Temporal Idempotency & Zombie Repair Worker
 * 
 * This module implements the "Zombie Repair" mechanism that prevents
 * indefinite client lockout from stuck transactions.
 * 
 * Invariant: No transaction should remain in PENDING/IN_PROGRESS state
 * for more than the TTL window without being auto-repaired or escalated.
 * 
 * @see PHASE-7R-implementation_plan.md Section "Temporal Idempotency"
 */

import { Pool, PoolClient } from 'pg';
import pino from 'pino';

const logger = pino({ name: 'ZombieRepairWorker' });

// Configuration
const ZOMBIE_THRESHOLD_SECONDS = 60;    // Records stuck > 60s are zombies
const HARD_FAILURE_TTL_SECONDS = 600;   // Records stuck > 10min need manual intervention
const REPAIR_BATCH_SIZE = 100;
const REPAIR_INTERVAL_MS = 30000;       // Run every 30 seconds

/**
 * Zombie Repair Result
 */
interface RepairResult {
    zombiesRepaired: number;
    recordsEscalated: number;
    attestationsReconciled: number;
    errors: string[];
}

/**
 * Zombie Repair Worker
 * 
 * Runs periodically to:
 * 1. Identify "zombie" records stuck in PENDING/IN_FLIGHT state
 * 2. Reset them to RECOVERING for retry
 * 3. Escalate records past TTL to manual review
 * 4. Reconcile attestation gaps
 */
export class ZombieRepairWorker {
    private isRunning = false;
    private intervalHandle: NodeJS.Timeout | null = null;

    constructor(
        private readonly pool: Pool
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
        this.runRepairCycle();
        this.intervalHandle = setInterval(() => this.runRepairCycle(), REPAIR_INTERVAL_MS);
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
            zombiesRepaired: 0,
            recordsEscalated: 0,
            attestationsReconciled: 0,
            errors: []
        };

        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');

            // 1. REPAIR SOFT ZOMBIES (60s < age < TTL)
            // These are transactions stuck in IN_FLIGHT that should be retried
            const softZombies = await client.query(`
                UPDATE payment_outbox
                SET status = 'RECOVERING',
                    last_error = 'ZOMBIE_REPAIR: Stuck in flight > ${ZOMBIE_THRESHOLD_SECONDS}s',
                    retry_count = retry_count + 1
                WHERE status = 'IN_FLIGHT'
                  AND last_attempt_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds'
                  AND last_attempt_at > NOW() - INTERVAL '${HARD_FAILURE_TTL_SECONDS} seconds'
                RETURNING id, participant_id, sequence_id;
            `);
            result.zombiesRepaired = softZombies.rowCount ?? 0;

            // 2. ESCALATE HARD FAILURES (age > TTL)
            // These need manual intervention - move to FAILED with escalation flag
            const hardFailures = await client.query(`
                UPDATE payment_outbox
                SET status = 'FAILED',
                    last_error = 'ESCALATED: Transaction exceeded TTL of ${HARD_FAILURE_TTL_SECONDS}s',
                    processed_at = NOW()
                WHERE status IN ('PENDING', 'IN_FLIGHT', 'RECOVERING')
                  AND created_at < NOW() - INTERVAL '${HARD_FAILURE_TTL_SECONDS} seconds'
                RETURNING id, participant_id, sequence_id;
            `);
            result.recordsEscalated = hardFailures.rowCount ?? 0;

            // 3. RECONCILE GHOST ATTESTATIONS
            // Find attestations that have no corresponding outbox entry and recover them
            const ghostRecovery = await client.query(`
                INSERT INTO payment_outbox (
                    participant_id, 
                    sequence_id, 
                    idempotency_key, 
                    event_type,
                    payload, 
                    status
                )
                SELECT 
                    ing.participant_id,
                    ing.sequence_id,
                    'GHOST_RECOVERED_' || ing.id::TEXT,
                    'GHOST_RECOVERY',
                    '{"recovered": true}'::JSONB,
                    'RECOVERING'
                FROM ingress_attestations ing
                LEFT JOIN payment_outbox out 
                    ON ing.id = out.id
                WHERE out.id IS NULL
                  AND ing.execution_started = FALSE
                  AND ing.attested_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds'
                LIMIT ${REPAIR_BATCH_SIZE}
                ON CONFLICT DO NOTHING
                RETURNING id;
            `);
            result.attestationsReconciled = ghostRecovery.rowCount ?? 0;

            // 4. Update attestation execution flags for recovered ghosts
            if (result.attestationsReconciled > 0) {
                await client.query(`
                    UPDATE ingress_attestations
                    SET execution_started = TRUE
                    WHERE id IN (
                        SELECT ing.id
                        FROM ingress_attestations ing
                        INNER JOIN payment_outbox out 
                            ON ing.idempotency_key = REPLACE(out.idempotency_key, 'GHOST_RECOVERED_', '')
                        WHERE out.event_type = 'GHOST_RECOVERY'
                          AND ing.execution_started = FALSE
                    );
                `);
            }

            await client.query('COMMIT');

            // Log repair activity
            if (result.zombiesRepaired > 0 || result.recordsEscalated > 0 || result.attestationsReconciled > 0) {
                logger.info({
                    event: 'REPAIR_CYCLE_COMPLETE',
                    zombiesRepaired: result.zombiesRepaired,
                    recordsEscalated: result.recordsEscalated,
                    attestationsReconciled: result.attestationsReconciled
                });
            }

        } catch (error: unknown) {
            await client.query('ROLLBACK');
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            result.errors.push(errorMessage);
            logger.error({ error: errorMessage }, 'Repair cycle failed');
        } finally {
            client.release();
        }

        return result;
    }

    /**
     * Get current zombie count (for monitoring)
     */
    public async getZombieCount(): Promise<number> {
        const result = await this.pool.query(`
            SELECT COUNT(*) as count
            FROM payment_outbox
            WHERE status = 'IN_FLIGHT'
              AND last_attempt_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds';
        `);
        return parseInt(result.rows[0]?.count ?? '0', 10);
    }

    /**
     * Get ghost attestation count (for evidence bundle)
     */
    public async getGhostCount(): Promise<number> {
        const result = await this.pool.query(`
            SELECT COUNT(*) as count
            FROM ingress_attestations ing
            LEFT JOIN payment_outbox out ON ing.id = out.id
            WHERE out.id IS NULL
              AND ing.execution_started = FALSE
              AND ing.attested_at < NOW() - INTERVAL '${ZOMBIE_THRESHOLD_SECONDS} seconds';
        `);
        return parseInt(result.rows[0]?.count ?? '0', 10);
    }
}

/**
 * Factory function for creating repair worker
 */
export function createZombieRepairWorker(pool: Pool): ZombieRepairWorker {
    return new ZombieRepairWorker(pool);
}
