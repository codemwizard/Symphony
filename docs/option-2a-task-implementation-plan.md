# Option 2A (Hot/Archive + Hybrid Wakeup) — Task & Implementation Plan

## Overview
This plan replaces the current outbox **in place** with a hot pending queue plus an append-only attempts archive. It enforces **strict participant sequencing**, adds **money-safety dispatch rails**, includes **NOTIFY + poll hybrid wakeup**, and provides **audit-grade observability**, all without keeping legacy tables or files.

## Task Plan
### A) Migration (DB)
- [x] Create `participant_outbox_sequences`
- [x] Implement `bump_participant_outbox_seq(participant_id)`
- [x] Create `payment_outbox_pending`
- [x] Add `UNIQUE(participant_id, sequence_id)`
- [x] Add `UNIQUE(instruction_id, idempotency_key)`
- [x] Create `payment_outbox_attempts` (append-only)
- [x] Add indexes (due claim, attempts lookup, dispatching age)
- [x] Add NOTIFY trigger on pending insert
- [x] Drop old outbox tables (no legacy)

### B) Producer (Ingest)
- [x] Allocate sequence via bump function **in txn**
- [x] Insert pending with `outbox_id`, `instruction_id`, `rail_type`, etc.
- [x] Handle idempotency conflict: return existing outbox record, don’t enqueue twice

### C) Relayer2A
- [x] LISTEN + debounced wakeup
- [x] fallback poll every 250–1000ms
- [x] claimBatch = DELETE…RETURNING + DISPATCHING insert (same txn)
- [x] bounded concurrency
- [x] rail timeout
- [x] payload validation (amount/currency/destination)
- [x] explicit error taxonomy
- [x] retry backoff + requeue
- [x] terminal failures → FAILED attempt (DLQ)

### D) Zombie Reaper
- [x] detect stale DISPATCHING attempts
- [x] requeue pending idempotently
- [x] insert ZOMBIE_REQUEUE attempt row

### E) Tests (minimum)
- [x] sequence allocator monotonic per participant
- [x] enqueue idempotency `(instruction_id, idempotency_key)` uniqueness
- [x] claim removes pending + inserts DISPATCHING attempt
- [x] success inserts DISPATCHED and does not requeue
- [x] retry inserts RETRYABLE + requeues with backoff
- [x] zombie repair requeues stale DISPATCHING
- [x] notify wakeup + poll fallback both drive processing

## Implementation Plan
### Phase-7B-A — Database Migration (Replace In-Place)
**Goal:** Replace the current outbox with:
- **Hot pending queue** (small, always in RAM / tiny indexes)
- **Append-only attempts archive** (forensics + audit)
- **Strict sequencing** per participant (hard invariant)
- **NOTIFY wakeup** for low latency
- **Idempotency uniqueness** at enqueue-time

#### A1) Participant sequence allocator (authoritative)
**Table**
- `participant_outbox_sequences(participant_id PK, next_sequence_id BIGINT NOT NULL)`

**Function**
- `bump_participant_outbox_seq(participant_id)`:
  - atomic: `UPDATE ... SET next_sequence_id = next_sequence_id + 1 RETURNING ...`
  - creates row if missing (first bump) via upsert pattern

**Invariant**
- One monotonic sequence stream per participant.

#### A2) Hot table: `payment_outbox_pending`
**Columns**
- `outbox_id UUID PRIMARY KEY DEFAULT uuidv7()`
- `instruction_id TEXT NOT NULL` (match your authoritative instructions schema type)
- `participant_id TEXT NOT NULL`
- `sequence_id BIGINT NOT NULL`
- `idempotency_key TEXT NOT NULL`
- `rail_type TEXT NOT NULL`
- `payload JSONB NOT NULL`
- `attempt_count INT NOT NULL DEFAULT 0`
- `next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`

**Constraints (hard invariants)**
- `UNIQUE (participant_id, sequence_id)` (strict continuity proof)
- `UNIQUE (instruction_id, idempotency_key)` (enqueue-time idempotency guardrail)

**Indexes**
- `ix_pending_due (next_attempt_at, created_at)`
- Optional: `ix_pending_participant_due (participant_id, next_attempt_at)`

#### A3) Archive table: `payment_outbox_attempts` (append-only)
**Purpose:** The system of record for “what happened” (claim, dispatch, outcome, errors).

**Recommended columns**
- `attempt_id UUID PRIMARY KEY DEFAULT uuidv7()`
- `outbox_id UUID NOT NULL`
- `instruction_id TEXT NOT NULL`
- `participant_id TEXT NOT NULL`
- `sequence_id BIGINT NOT NULL`
- `idempotency_key TEXT NOT NULL`
- `rail_type TEXT NOT NULL`
- `payload JSONB NOT NULL`
- `attempt_no INT NOT NULL`
- `state TEXT NOT NULL` (enum recommended: DISPATCHING, DISPATCHED, RETRYABLE, FAILED, ZOMBIE_REQUEUE)
- `claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- `completed_at TIMESTAMPTZ`
- `rail_reference TEXT`
- `rail_code TEXT`
- `error_code TEXT`
- `error_message TEXT`
- `latency_ms INT`
- `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`

**Indexes**
- `ix_attempts_by_outbox (outbox_id, claimed_at DESC)`
- `ix_attempts_dispatching_age (claimed_at) WHERE state = 'DISPATCHING'`
- Optional: `ix_attempts_by_instruction (instruction_id, claimed_at DESC)`

#### A4) Wakeup trigger (NOTIFY)
- Trigger on `INSERT` into `payment_outbox_pending`
- `NOTIFY outbox_pending, 'new_work'`

#### A5) Replace in-place (no legacy)
- Drop old `payment_outbox` and any older outbox artifacts once migration is applied.
- Update any code paths to write only to:
  - `participant_outbox_sequences`
  - `payment_outbox_pending`
  - `payment_outbox_attempts`

### Phase-7B-B — Producer Path (Strict Sequencing + Idempotency)
**Goal:** Enqueue is “money-safe” and deterministic.

**Producer flow (single transaction)**
1. `sequence_id := bump_participant_outbox_seq(participant_id)`
2. `INSERT INTO payment_outbox_pending (...) VALUES (...)`
3. Commit → trigger fires NOTIFY

**Rules**
- Retries **must reuse the same** `outbox_id` + `sequence_id`
- No new sequence is allocated for retries (requeues do not bump)

**Idempotency handling**
- If `(instruction_id, idempotency_key)` conflicts:
  - treat as “already enqueued / already done”
  - return the existing `outbox_id` (query by instruction/idempotency)

### Phase-7B-C — Relayer2A (Hybrid Wakeup + Crash Consistent Claim)
**Goal:** Very low latency when healthy, deterministic recovery when not.

**Wake strategy**
- `LISTEN outbox_pending`
- Debounce NOTIFY (e.g., coalesce events for 25–50ms to avoid thundering herd)
- Fallback poll every **250–1000ms** (SLA-tight, still cheap at your TPS)

**Claim pattern (atomic)**
Inside a DB transaction:
1. `DELETE FROM payment_outbox_pending WHERE next_attempt_at <= NOW() ORDER BY next_attempt_at, created_at LIMIT $BATCH RETURNING *`
2. For each returned row: `INSERT payment_outbox_attempts(state='DISPATCHING', attempt_no=attempt_count+1, ...)`
3. Commit

**Outcome**
- **Exactly-once claim** (DB is the arbiter)
- **Crash consistency** (claimed rows are always visible in attempts)

### Phase-7B-D — Rail Call Safety Rails (Required)
**Goal:** Prevent “money-dangerous dispatches” and keep SLA stable.

**Minimum hardening (must-have)**
1. **Input validation** before dispatch:
   - amount > 0
   - currency present and valid (3-letter)
   - destination format (rail-specific minimal checks)
2. **Hard timeout** on rail dispatch:
   - AbortController or client-level timeout (e.g., 30s)
3. **Error taxonomy**:
   - terminal vs retryable based on **explicit rail codes**
   - no substring-only logic
4. **Bounded concurrency**:
   - semaphore per process is fine for your scale
   - optional per-rail concurrency caps

**Outcome recording (append-only attempts)**
- success → insert `DISPATCHED`
- retryable failure → insert `RETRYABLE` + requeue with backoff
- terminal failure → insert `FAILED` (DLQ semantics)

### Phase-7B-E — Zombie Repair (Self-Heal ≤ 120s)
**Goal:** If a worker dies mid-dispatch, the system heals automatically.

**Logic (every 60s)**
- Find latest attempt per outbox_id where:
  - state = `DISPATCHING`
  - claimed_at < NOW() - timeout (e.g., 120s)
- Requeue pending with same `outbox_id/sequence_id` (idempotent insert)
- Insert an attempt row:
  - `ZOMBIE_REQUEUE` (or `RETRYABLE` with error_code=`ZOMBIE_REQUEUE`)

### Phase-7B-F — Observability & Alerts (Required)
**Goal:** Auditable operational posture without overbuilding.

**Must-have metrics**
- `outbox_pending_depth`
- `oldest_pending_age_seconds`
- `notify_wakeups_total`
- `claim_batches_total`
- `dispatch_latency_ms` (histogram)
- `attempts_total{state}`
- `dlq_depth` (FAILED terminal count)
- `reaper_requeues_total`
- `stuck_dispatching_count`

**Alerts**
- oldest pending age > threshold
- DLQ growth rate
- stuck DISPATCHING count > threshold
- sustained retryable rate spike
