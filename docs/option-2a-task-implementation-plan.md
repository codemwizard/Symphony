# Option 2A (Hot/Archive + Hybrid Wakeup) — Task & Implementation Plan

## Overview
This plan replaces the current outbox **in place** with a hot pending queue plus an append-only attempts archive. It enforces **strict participant sequencing**, adds **money-safety dispatch rails**, includes **NOTIFY + poll hybrid wakeup**, and provides **audit-grade observability**, all without keeping legacy tables or files.

## Task Plan
### A) Migration (DB authoritative, no legacy)
- [x] Drop `supervisor_outbox_status` before legacy objects to avoid dependency drift.
- [x] Drop legacy `payment_outbox` and `outbox_status` (no compat paths).
- [x] Create `outbox_attempt_state` enum and type `payment_outbox_attempts.state` to the enum.
- [x] Create `participant_outbox_sequences` + `bump_participant_outbox_seq(participant_id)` with `SECURITY DEFINER`, fixed `search_path`, and `OWNER TO symphony_control`.
- [x] Create `payment_outbox_pending` with `UNIQUE(participant_id, sequence_id)` and `UNIQUE(instruction_id, idempotency_key)`.
- [x] Create `payment_outbox_attempts` (append-only) with `UNIQUE(outbox_id, attempt_no)` for DB-enforced attempt numbering.
- [x] Add indexes (due claim, attempts lookup, dispatching age, idempotency lookup).
- [x] Add `notify_outbox_pending()` trigger with fixed `search_path` (non-definer).
- [x] Add append-only trigger on attempts (UPDATE/DELETE -> SQLSTATE `P0001`).
- [x] Add `enqueue_payment_outbox(...)` as `SECURITY DEFINER`, fixed `search_path`, `OWNER TO symphony_control`.
- [x] Recreate `supervisor_outbox_status` from pending + attempts after tables exist.

### B) Privileges (provably authoritative ACLs)
- [x] Ingest: **EXECUTE enqueue only**; no pending DML; no sequence table access; no bump execute.
- [x] Executor: pending `SELECT/DELETE/INSERT/UPDATE` (claim + `ON CONFLICT DO UPDATE` requeue), attempts `SELECT/INSERT` only.
- [x] Control plane: explicit read-only on pending/attempts/sequences (policy decision).
- [x] Readonly/Auditor: blanket `SELECT` grant followed by explicit revoke on `participant_outbox_sequences`.
- [x] Revoke UPDATE/DELETE on attempts from all runtime roles.
- [x] Revoke TRUNCATE on pending/attempts from PUBLIC and all runtime roles.
- [x] Revoke EXECUTE on outbox functions from PUBLIC, then grant EXECUTE only to intended roles.

### C) Producer (Ingest path)
- [x] Replace pre-check + bump + insert with a **single call** to `enqueue_payment_outbox(...)`.
- [x] Ensure enqueue is the **only** write path for ingest (no direct pending DML).
- [x] Preserve deterministic idempotency via unique-violation fallback in the DB function.

### D) Relayer2A (claim + dispatch)
- [x] LISTEN + debounced wakeup.
- [x] fallback poll every 250–1000ms.
- [x] Claim uses a **single set-based SQL statement**:
  - due rows selected with `FOR UPDATE SKIP LOCKED`,
  - deleted via `DELETE ... RETURNING`,
  - `MAX(attempt_no)` computed only for the claimed outbox_ids,
  - `DISPATCHING` attempts inserted with `last_attempt_no + 1`.
- [x] bounded concurrency.
- [x] rail timeout.
- [x] payload validation (amount/currency/destination).
- [x] explicit error taxonomy.
- [x] retry backoff + requeue.
- [x] terminal failures → FAILED attempt (DLQ).

### E) Zombie Reaper
- [x] detect stale DISPATCHING attempts.
- [x] requeue pending by **outbox_id only** (`ON CONFLICT (outbox_id)`).
- [x] set `attempt_count` as **last_attempt_no cache** using `GREATEST(...)`.
- [x] insert `ZOMBIE_REQUEUE` attempt row with `attempt_no = last_attempt_no + 1`.

### F) Tests / Proof Checks (minimum)
- [ ] ingest cannot INSERT into pending directly; can only EXECUTE enqueue.
- [ ] executor cannot UPDATE/DELETE attempts.
- [ ] TRUNCATE fails for everyone on pending/attempts.
- [ ] sequences table is not readable to readonly/auditor after blanket grants.
- [ ] attempt numbering invariant: duplicate `(outbox_id, attempt_no)` fails.
- [ ] claim removes pending + inserts DISPATCHING attempt in one set-based statement.
- [ ] retry inserts RETRYABLE + requeues with `GREATEST(...)` on attempt_count.
- [ ] zombie repair requeues stale DISPATCHING with `ON CONFLICT (outbox_id)`.
- [ ] NOTIFY wakeup + poll fallback both drive processing.

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
  - **SECURITY DEFINER** with fixed `search_path`, owned by `symphony_control` (privilege-safe).

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
- `state outbox_attempt_state NOT NULL` (enum enforced: DISPATCHING, DISPATCHED, RETRYABLE, FAILED, ZOMBIE_REQUEUE)
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

**Attempt numbering invariant**
- `UNIQUE (outbox_id, attempt_no)` so numbering is DB-enforced.

**Append-only proof**
- ACL: no UPDATE/DELETE/ TRUNCATE for runtime roles.
- Trigger: `BEFORE UPDATE OR DELETE` raises SQLSTATE `P0001`.

#### A4) Wakeup trigger (NOTIFY)
- Trigger on `INSERT` into `payment_outbox_pending`
- `NOTIFY outbox_pending, 'new_work'`
- `notify_outbox_pending()` sets a fixed `search_path` (non-definer).

#### A5) Replace in-place (no legacy)
- Drop old `payment_outbox` and any older outbox artifacts once migration is applied.
- Update any code paths to write only to:
  - `participant_outbox_sequences`
  - `payment_outbox_pending`
  - `payment_outbox_attempts`

#### A6) Authoritative enqueue function (DB-only write path)
**Function**
- `enqueue_payment_outbox(instruction_id, participant_id, idempotency_key, rail_type, payload)`
  - advisory lock with **distinct seeds** (`hashtextextended` per key)
  - check pending → return existing
  - check attempts → return existing
  - bump sequence only if new
  - insert pending with unique-violation fallback
  - **SECURITY DEFINER** with fixed `search_path`, owned by `symphony_control`

### Phase-7B-B — Producer Path (Strict Sequencing + Idempotency)
**Goal:** Enqueue is “money-safe” and deterministic.

**Producer flow (single call, DB-authoritative)**
1. `SELECT * FROM enqueue_payment_outbox(...)`
2. Commit → trigger fires NOTIFY

**Rules**
- Retries **must reuse the same** `outbox_id` + `sequence_id`
- No new sequence is allocated for retries (requeues do not bump)

**Idempotency handling**
- `enqueue_payment_outbox` handles idempotency and **unique-violation fallback** to return the existing row deterministically.

### Phase-7B-C — Relayer2A (Hybrid Wakeup + Crash Consistent Claim)
**Goal:** Very low latency when healthy, deterministic recovery when not.

**Wake strategy**
- `LISTEN outbox_pending`
- Debounce NOTIFY (e.g., coalesce events for 25–50ms to avoid thundering herd)
- Fallback poll every **250–1000ms** (SLA-tight, still cheap at your TPS)

**Claim pattern (atomic, set-based)**
Inside a single DB transaction:
1. Select due rows with `FOR UPDATE SKIP LOCKED`.
2. `DELETE ... RETURNING` by outbox_id (the same rows locked).
3. Compute `MAX(attempt_no)` **only for claimed outbox_ids**.
4. Insert `DISPATCHING` attempts with `last_attempt_no + 1`.
5. Commit.

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
- Requeue pending with same `outbox_id/sequence_id` (idempotent insert).
- Conflict target = `outbox_id` only (never `(instruction_id, idempotency_key)`).
- Maintain cache monotonicity: `attempt_count = GREATEST(existing, excluded)`.
- Insert a `ZOMBIE_REQUEUE` attempt row with `attempt_no = last_attempt_no + 1`.

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
