/**
 * Phase-7B: Outbox Relayer Service (Option 2A)
 *
 * This service implements a hybrid wakeup relayer:
 * - LISTEN/NOTIFY for low-latency wakeups
 * - fallback polling to ensure SLA stability
 *
 * It uses lease-based claim and DB-authoritative completion functions.
 */

import { pino } from 'pino';
import os from 'node:os';
import { db, DbRole, isLeaseLostError, ListenHandle } from '../db/index.js';
import { claimOutboxBatch, completeOutboxAttempt } from './db.js';

const logger = pino({ name: 'OutboxRelayer' });

// Configuration
const BATCH_SIZE = 50;
const POLL_INTERVAL_MS = 500;
const NOTIFY_DEBOUNCE_MS = 50;
const MAX_CONCURRENCY = 10;
const DISPATCH_TIMEOUT_MS = 30_000;
const DEFAULT_LEASE_SECONDS = Number(process.env.OUTBOX_LEASE_SECONDS ?? '30');
const SAFE_LEASE_SECONDS = Number.isFinite(DEFAULT_LEASE_SECONDS) && DEFAULT_LEASE_SECONDS > 0 ? DEFAULT_LEASE_SECONDS : 30;
const DEFAULT_WORKER_ID = process.env.OUTBOX_WORKER_ID ?? `${os.hostname()}-${process.pid}`;

const TERMINAL_RAIL_CODES = new Set([
    'INVALID_ACCOUNT',
    'INSUFFICIENT_FUNDS',
    'FRAUD_BLOCK',
    'INVALID_AMOUNT',
    'INVALID_DESTINATION',
    'INVALID_CURRENCY'
]);

// External Rail Client Interface
interface RailClient {
    dispatch(params: {
        reference: string;
        amount: number;
        currency: string;
        destination: string;
        participantId: string;
        railType: string;
        payload: Record<string, unknown>;
    }): Promise<{
        success: boolean;
        railReference?: string;
        railCode?: string;
        errorCode?: string;
        errorMessage?: string;
        retryable?: boolean;
    }>;
}

interface OutboxRecord {
    outbox_id: string;
    instruction_id: string;
    participant_id: string;
    sequence_id: number;
    idempotency_key: string;
    rail_type: string;
    payload: {
        amount: number;
        currency: string;
        destination: string;
        [key: string]: unknown;
    };
    attempt_count: number;
    created_at: Date;
    lease_token: string;
    lease_expires_at: Date;
}

class Semaphore {
    private inFlight = 0;
    private readonly queue: Array<() => void> = [];

    constructor(private readonly limit: number) {}

    async acquire(): Promise<() => void> {
        if (this.inFlight < this.limit) {
            this.inFlight += 1;
            return () => this.release();
        }

        return new Promise(resolve => {
            this.queue.push(() => {
                this.inFlight += 1;
                resolve(() => this.release());
            });
        });
    }

    private release(): void {
        this.inFlight -= 1;
        const next = this.queue.shift();
        if (next) {
            next();
        }
    }
}

export class OutboxRelayer {
    private isRunning = false;
    private pollInProgress = false;
    private pendingWakeup = false;
    private debounceTimer: NodeJS.Timeout | null = null;
    private pollTimer: NodeJS.Timeout | null = null;
    private listenHandle: ListenHandle | null = null;

    constructor(
        private readonly railClient: RailClient,
        private readonly role: DbRole = 'symphony_executor',
        private readonly dbClient = db,
        private readonly workerId: string = DEFAULT_WORKER_ID,
        private readonly leaseSeconds: number = SAFE_LEASE_SECONDS
    ) { }

    /**
     * Start the relayer polling loop
     */
    public async start(): Promise<void> {
        if (this.isRunning) {
            logger.warn('Relayer already running');
            return;
        }
        this.isRunning = true;

        await this.attachListener();

        this.pollTimer = setInterval(() => this.triggerPoll('interval'), POLL_INTERVAL_MS);
        this.triggerPoll('startup');
        logger.info('OutboxRelayer started');
    }

    /**
     * Stop the relayer gracefully
     */
    public async stop(): Promise<void> {
        this.isRunning = false;

        if (this.pollTimer) {
            clearInterval(this.pollTimer);
            this.pollTimer = null;
        }

        if (this.debounceTimer) {
            clearTimeout(this.debounceTimer);
            this.debounceTimer = null;
        }

        if (this.listenHandle) {
            await this.listenHandle.close();
            this.listenHandle = null;
        }

        logger.info('OutboxRelayer stopped');
    }

    private async attachListener(): Promise<void> {
        this.listenHandle = await this.dbClient.listenAsRole(
            this.role,
            'outbox_pending',
            () => this.scheduleDebouncedPoll()
        );
    }

    private scheduleDebouncedPoll(): void {
        if (!this.isRunning) return;
        if (this.debounceTimer) return;

        this.debounceTimer = setTimeout(() => {
            this.debounceTimer = null;
            this.triggerPoll('notify');
        }, NOTIFY_DEBOUNCE_MS);
    }

    private triggerPoll(reason: 'notify' | 'interval' | 'startup' | 'queued'): void {
        if (!this.isRunning) return;

        if (this.pollInProgress) {
            this.pendingWakeup = true;
            return;
        }

        this.pollInProgress = true;
        void this.runPoll(reason);
    }

    private async runPoll(reason: string): Promise<void> {
        try {
            await this.processDue(reason);
        } catch (error) {
            logger.error({ error }, 'Relayer poll failure');
        } finally {
            this.pollInProgress = false;
            if (this.pendingWakeup) {
                this.pendingWakeup = false;
                this.triggerPoll('queued');
            }
        }
    }

    private async processDue(reason: string): Promise<void> {
        if (!this.isRunning) return;

        let batchCount = 0;
        while (this.isRunning) {
            const records = await this.claimNextBatch();
            if (records.length === 0) break;

            batchCount += 1;
            logger.info({ count: records.length, reason }, 'Processing outbox batch');
            await this.processRecords(records);

            if (records.length < BATCH_SIZE) break;
        }

        if (batchCount > 0) {
            logger.info({ batchCount, reason }, 'Completed outbox batches');
        }
    }

    private async claimNextBatch(): Promise<OutboxRecord[]> {
        const rows = await claimOutboxBatch(this.role, BATCH_SIZE, this.workerId, this.leaseSeconds, this.dbClient);
        return rows.map(row => ({
            ...row,
            sequence_id: Number(row.sequence_id),
            attempt_count: Number(row.attempt_count)
        })) as OutboxRecord[];
    }

    private async processRecords(records: OutboxRecord[]): Promise<void> {
        const semaphore = new Semaphore(MAX_CONCURRENCY);
        await Promise.all(records.map(async record => {
            const release = await semaphore.acquire();
            try {
                await this.processRecord(record);
            } finally {
                release();
            }
        }));
    }

    private async processRecord(record: OutboxRecord): Promise<void> {
        const correlationId = record.outbox_id;
        const validationError = this.validatePayload(record.payload);

        if (validationError) {
            const completed = await this.completeOutcome(record, 'FAILED', {
                errorCode: validationError.code,
                errorMessage: validationError.message
            });
            if (completed === 'lease_lost') return;
            logger.warn({ correlationId, errorCode: validationError.code }, 'Validation failed');
            return;
        }

        const start = Date.now();
        let result: Awaited<ReturnType<RailClient['dispatch']>>;
        try {
            result = await this.dispatchWithTimeout(record);
        } catch (error: unknown) {
            const latencyMs = Date.now() - start;
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            const errorCode = errorMessage === 'DISPATCH_TIMEOUT' ? 'DISPATCH_TIMEOUT' : 'DISPATCH_ERROR';
            const completed = await this.completeOutcome(record, 'RETRYABLE', {
                errorCode,
                errorMessage,
                latencyMs
            });
            if (completed === 'lease_lost') return;
            logger.error({ correlationId, error: errorMessage }, 'Dispatch failure');
            return;
        }

        const latencyMs = Date.now() - start;
        if (result.success) {
            const details: {
                railReference?: string;
                railCode?: string;
                latencyMs?: number;
            } = { latencyMs };
            if (result.railReference !== undefined) {
                details.railReference = result.railReference;
            }
            if (result.railCode !== undefined) {
                details.railCode = result.railCode;
            }
            const completed = await this.completeOutcome(record, 'DISPATCHED', details);
            if (completed === 'lease_lost') return;
            logger.info({ correlationId, railReference: result.railReference }, 'Dispatch successful');
            return;
        }

        const classification = this.classifyError(result);
        const details: {
            railReference?: string;
            railCode?: string;
            errorCode?: string;
            errorMessage?: string;
            latencyMs?: number;
        } = {
            errorMessage: result.errorMessage ?? 'Dispatch failed',
            latencyMs
        };
        if (result.railReference !== undefined) {
            details.railReference = result.railReference;
        }
        if (result.railCode !== undefined) {
            details.railCode = result.railCode;
        }
        if (result.errorCode !== undefined) {
            details.errorCode = result.errorCode;
        }
        const completed = await this.completeOutcome(record, classification.state, details);
        if (completed === 'lease_lost') return;
    }

    private validatePayload(payload: OutboxRecord['payload']): { code: string; message: string } | null {
        if (!payload || typeof payload !== 'object') {
            return { code: 'INVALID_PAYLOAD', message: 'Payload is required.' };
        }
        if (typeof payload.amount !== 'number' || payload.amount <= 0) {
            return { code: 'INVALID_AMOUNT', message: 'Amount must be greater than zero.' };
        }
        if (typeof payload.currency !== 'string' || !/^[A-Z]{3}$/.test(payload.currency)) {
            return { code: 'INVALID_CURRENCY', message: 'Currency must be a 3-letter code.' };
        }
        if (typeof payload.destination !== 'string' || payload.destination.trim().length === 0) {
            return { code: 'INVALID_DESTINATION', message: 'Destination is required.' };
        }
        return null;
    }

    private async dispatchWithTimeout(record: OutboxRecord): Promise<Awaited<ReturnType<RailClient['dispatch']>>> {
        return new Promise((resolve, reject) => {
            const timeout = setTimeout(() => reject(new Error('DISPATCH_TIMEOUT')), DISPATCH_TIMEOUT_MS);
            this.railClient.dispatch({
                reference: record.outbox_id,
                amount: record.payload.amount,
                currency: record.payload.currency,
                destination: record.payload.destination,
                participantId: record.participant_id,
                railType: record.rail_type,
                payload: record.payload
            }).then(result => {
                clearTimeout(timeout);
                resolve(result);
            }).catch(error => {
                clearTimeout(timeout);
                reject(error);
            });
        });
    }

    private classifyError(result: Awaited<ReturnType<RailClient['dispatch']>>): { state: 'RETRYABLE' | 'FAILED' } {
        if (result.retryable === true) return { state: 'RETRYABLE' };
        if (result.retryable === false) return { state: 'FAILED' };
        if (result.railCode && TERMINAL_RAIL_CODES.has(result.railCode)) return { state: 'FAILED' };
        if (result.errorCode && TERMINAL_RAIL_CODES.has(result.errorCode)) return { state: 'FAILED' };
        return { state: 'RETRYABLE' };
    }

    private async completeOutcome(
        record: OutboxRecord,
        state: 'DISPATCHED' | 'RETRYABLE' | 'FAILED',
        details: {
            railReference?: string;
            railCode?: string;
            errorCode?: string;
            errorMessage?: string;
            latencyMs?: number;
        }
    ): Promise<'completed' | 'lease_lost'> {
        try {
            await completeOutboxAttempt(this.role, {
                outbox_id: record.outbox_id,
                lease_token: record.lease_token,
                worker_id: this.workerId,
                state,
                rail_reference: details.railReference ?? null,
                rail_code: details.railCode ?? null,
                error_code: details.errorCode ?? null,
                error_message: details.errorMessage ?? null,
                latency_ms: details.latencyMs ?? null,
                retry_delay_seconds:
                    state === 'RETRYABLE' ? this.calculateBackoffSeconds(record.attempt_count + 1) : null
            }, this.dbClient);
            return 'completed';
        } catch (error) {
            if (isLeaseLostError(error)) {
                logger.warn(
                    { correlationId: record.outbox_id, leaseToken: record.lease_token },
                    'Lease lost before completion'
                );
                return 'lease_lost';
            }
            throw error;
        }
    }

    private calculateBackoffSeconds(attemptNo: number): number {
        const base = 1;
        const backoff = base * Math.pow(2, Math.max(0, attemptNo - 1));
        return Math.min(backoff, 60);
    }
}

// Export for testing
export type { RailClient, OutboxRecord };
