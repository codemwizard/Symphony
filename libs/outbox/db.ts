import { db, DbRole } from '../db/index.js';

export type OutboxDbClient = {
    queryAsRole: typeof db.queryAsRole;
};

export type OutboxClaimRow = {
    outbox_id: string;
    instruction_id: string;
    participant_id: string;
    sequence_id: number;
    idempotency_key: string;
    rail_type: string;
    payload: Record<string, unknown>;
    attempt_count: number;
    lease_token: string;
    lease_expires_at: Date;
};

export type OutboxCompletionState = 'DISPATCHED' | 'FAILED' | 'RETRYABLE';

export type OutboxCompletionResult = {
    attempt_no: number;
    state: OutboxCompletionState;
};

export type LeaseRepairResult = {
    outbox_id: string;
    attempt_no: number;
};

export async function claimOutboxBatch(
    role: DbRole,
    batchSize: number,
    workerId: string,
    leaseSeconds: number,
    dbClient: OutboxDbClient = db
): Promise<OutboxClaimRow[]> {
    const result = await dbClient.queryAsRole<OutboxClaimRow>(
        role,
        `
        SELECT
            outbox_id,
            instruction_id,
            participant_id,
            sequence_id,
            idempotency_key,
            rail_type,
            payload,
            attempt_count,
            lease_token,
            lease_expires_at
        FROM claim_outbox_batch($1, $2, $3);
        `,
        [batchSize, workerId, leaseSeconds]
    );

    return result.rows.map(row => ({
        ...row,
        sequence_id: Number(row.sequence_id),
        attempt_count: Number(row.attempt_count)
    }));
}

export async function completeOutboxAttempt(
    role: DbRole,
    params: {
        outbox_id: string;
        lease_token: string;
        worker_id: string;
        state: OutboxCompletionState;
        rail_reference?: string | null;
        rail_code?: string | null;
        error_code?: string | null;
        error_message?: string | null;
        latency_ms?: number | null;
        retry_delay_seconds?: number | null;
    },
    dbClient: OutboxDbClient = db
): Promise<OutboxCompletionResult> {
    const result = await dbClient.queryAsRole<OutboxCompletionResult>(
        role,
        `
        SELECT attempt_no, state
        FROM complete_outbox_attempt(
            $1::uuid,
            $2::uuid,
            $3::text,
            $4::outbox_attempt_state,
            $5::text,
            $6::text,
            $7::text,
            $8::text,
            $9::int,
            $10::int
        );
        `,
        [
            params.outbox_id,
            params.lease_token,
            params.worker_id,
            params.state,
            params.rail_reference ?? null,
            params.rail_code ?? null,
            params.error_code ?? null,
            params.error_message ?? null,
            params.latency_ms ?? null,
            params.retry_delay_seconds ?? null
        ]
    );

    const row = result.rows[0];
    if (!row) {
        throw new Error('complete_outbox_attempt returned no rows');
    }
    return {
        attempt_no: Number(row.attempt_no),
        state: row.state
    };
}

export async function repairExpiredLeases(
    role: DbRole,
    batchSize: number,
    workerId: string,
    dbClient: OutboxDbClient = db
): Promise<LeaseRepairResult[]> {
    const result = await dbClient.queryAsRole<LeaseRepairResult>(
        role,
        `
        SELECT outbox_id, attempt_no
        FROM repair_expired_leases($1, $2);
        `,
        [batchSize, workerId]
    );

    return result.rows.map(row => ({
        outbox_id: row.outbox_id,
        attempt_no: Number(row.attempt_no)
    }));
}
