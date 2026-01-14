/**
 * Phase-7R: Monotonic ID Generator with Clock-Safety
 * 
 * This module implements the "Wait State" safeguard for UUIDv7-style ID generation.
 * If the system clock moves backwards, the generator MUST pause until time catches up.
 * 
 * Invariant: Monotonicity over Availability
 * 
 * @see PHASE-7R-implementation_plan.md Section "Clock-Safety & UUIDv7 Monotonicity"
 */

import pino from 'pino';

const logger = pino({ name: 'MonotonicIdGenerator' });

// Custom epoch: 2024-01-01 00:00:00 UTC (reduces timestamp size)
const CUSTOM_EPOCH = new Date('2024-01-01T00:00:00.000Z').getTime();

// Configuration
const MAX_WAIT_MS = 5000; // Maximum time to wait for clock to catch up (fail-safe)
const SEQUENCE_BITS = 12;
const MAX_SEQUENCE = (1 << SEQUENCE_BITS) - 1; // 4095

/**
 * Error thrown when clock moves backwards and wait times out
 */
export class ClockMovedBackwardsError extends Error {
    readonly code = 'CLOCK_MOVED_BACKWARDS';
    readonly statusCode = 503;

    constructor(
        public readonly lastTimestamp: number,
        public readonly currentTimestamp: number,
        public readonly driftMs: number
    ) {
        super(`Clock moved backwards by ${driftMs}ms. Refusing to generate ID to preserve monotonicity.`);
        this.name = 'ClockMovedBackwardsError';
    }
}

/**
 * Monotonic ID Generator
 * 
 * Generates Snowflake-style 64-bit IDs with guaranteed monotonicity.
 * Structure: [41-bit timestamp][10-bit worker][12-bit sequence]
 */
export class MonotonicIdGenerator {
    private lastTimestamp: number = -1;
    private sequence: number = 0;
    private waitStateActive: boolean = false;

    constructor(
        private readonly workerId: number
    ) {
        if (workerId < 0 || workerId > 1023) {
            throw new Error(`Worker ID must be 0-1023, got ${workerId}`);
        }
    }

    /**
     * Generate a new monotonic ID
     * 
     * @throws ClockMovedBackwardsError if clock drift exceeds MAX_WAIT_MS
     */
    public async generate(): Promise<bigint> {
        let timestamp = this.currentTimestamp();

        // Clock-Safety: Detect backward movement
        if (timestamp < this.lastTimestamp) {
            const drift = this.lastTimestamp - timestamp;

            logger.warn({
                event: 'CLOCK_DRIFT_DETECTED',
                lastTimestamp: this.lastTimestamp,
                currentTimestamp: timestamp,
                driftMs: drift
            });

            // Enter Wait State
            this.waitStateActive = true;

            if (drift <= MAX_WAIT_MS) {
                // Wait for clock to catch up
                await this.waitUntilTimeAdvances(this.lastTimestamp);
                timestamp = this.currentTimestamp();
                this.waitStateActive = false;

                logger.info({
                    event: 'CLOCK_RECOVERED',
                    newTimestamp: timestamp
                });
            } else {
                // Drift too large - fail safely
                this.waitStateActive = false;
                throw new ClockMovedBackwardsError(
                    this.lastTimestamp,
                    timestamp,
                    drift
                );
            }
        }

        // Handle same-millisecond sequence
        if (timestamp === this.lastTimestamp) {
            this.sequence = (this.sequence + 1) & MAX_SEQUENCE;

            // Sequence exhausted in same millisecond - wait for next
            if (this.sequence === 0) {
                timestamp = await this.waitForNextMillisecond(this.lastTimestamp);
            }
        } else {
            this.sequence = 0;
        }

        this.lastTimestamp = timestamp;

        // Construct the Snowflake ID
        // 41 bits: timestamp, 10 bits: worker, 12 bits: sequence
        const id = (BigInt(timestamp) << BigInt(22)) |
            (BigInt(this.workerId) << BigInt(12)) |
            BigInt(this.sequence);

        return id;
    }

    /**
     * Generate ID as string (for database insertion)
     */
    public async generateString(): Promise<string> {
        const id = await this.generate();
        return id.toString();
    }

    /**
     * Check if generator is in wait state (clock recovering)
     */
    public isInWaitState(): boolean {
        return this.waitStateActive;
    }

    /**
     * Get current timestamp relative to custom epoch
     */
    private currentTimestamp(): number {
        return Date.now() - CUSTOM_EPOCH;
    }

    /**
     * Wait until system time advances past the given timestamp
     */
    private async waitUntilTimeAdvances(lastTs: number): Promise<void> {
        const startWait = Date.now();

        while (this.currentTimestamp() <= lastTs) {
            if (Date.now() - startWait > MAX_WAIT_MS) {
                throw new ClockMovedBackwardsError(
                    lastTs,
                    this.currentTimestamp(),
                    lastTs - this.currentTimestamp()
                );
            }

            // Spin-wait with micro-sleep
            await new Promise(resolve => setTimeout(resolve, 1));
        }
    }

    /**
     * Wait for the next millisecond (sequence overflow)
     */
    private async waitForNextMillisecond(lastTs: number): Promise<number> {
        let current = this.currentTimestamp();
        while (current <= lastTs) {
            await new Promise(resolve => setTimeout(resolve, 1));
            current = this.currentTimestamp();
        }
        return current;
    }
}

/**
 * Factory function for creating worker-specific generators
 */
export function createIdGenerator(workerId: number): MonotonicIdGenerator {
    return new MonotonicIdGenerator(workerId);
}

/**
 * Default singleton for single-node deployments
 */
export const defaultIdGenerator = new MonotonicIdGenerator(0);
