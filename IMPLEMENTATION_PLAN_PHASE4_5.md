
# Implementation Plan: Phase 4–5 (Zombie Repair + Concurrency Proofs)

## Objective
Complete Phase 4 deterministic zombie repair proof and Phase 5 concurrency/idempotency proof, with audit-grade evidence and operational hardening.

## Scope
- Phase 4 deterministic zombie repair proof test (DB-backed).
- Phase 5 concurrency/idempotency proof test (DB-backed, integration-ish).
- Lightweight operational hardening for repair logs/metrics.
- Evidence artifact capture for audits.

## Phase 4 — Deterministic Zombie Repair Proof (audit-grade)

### Task 4.1 — Deterministic threshold handling
- Confirm `ZOMBIE_THRESHOLD_SECONDS` is read at runtime (already via `getZombieThresholdSeconds()`).
- Ensure test runner sets `ZOMBIE_THRESHOLD_SECONDS=1` (prefer env over in-test mutation).

### Task 4.2 — Hard DB isolation for proof test
- Add `beforeEach` TRUNCATE of:
  - `payment_outbox_pending`
  - `payment_outbox_attempts`
  - `participant_outbox_sequences`
- Use `queryNoRole` (DB owner) because attempts are append-only.
 - Reason: avoids cross-test contamination and preserves determinism under parallel runs.

### Task 4.3 — Seed a single stale DISPATCHING attempt
- Insert a single `DISPATCHING` attempt as the latest attempt for a new `outbox_id`.
- Backdate `claimed_at` (e.g., `NOW() - INTERVAL '10 seconds'`) to exceed threshold.
- Use unique identifiers per test run.
- Ensure exactly one qualifying zombie exists before running repair.

### Task 4.4 — Run repair and assert invariants
- Call `runRepairCycle()` once.
- Assert:
  - Exactly one new `ZOMBIE_REQUEUE` attempt for the same `outbox_id`.
  - `attempt_no` monotonic (`last + 1`).
  - `payment_outbox_pending` contains the same `outbox_id` exactly once.
  - `attempt_count` monotonic (reflects last attempt via `GREATEST(...)`).

### Task 4.5 — Determinism checks (optional)
- Pre-run assertion: exactly one qualifying zombie exists.
- Post-run assertion: re-running repair does not append additional attempts.

### Task 4.6 — Minimal logging hardening (optional)
- Add structured fields for repair logs:
  - `outbox_id`, `attempt_no`, `previous_state`, `new_state='ZOMBIE_REQUEUE'`, `threshold_seconds`.

## Phase 5 — Concurrency / Idempotency Proof (DB-backed)

### Task 5.1 — Test placement and gating
- Add a DB-backed test under `tests/integration/` (or `tests/unit/` with DB gating).
- Skip when `DATABASE_URL` is missing.

### Task 5.2 — Concurrency scenario
- Fire N concurrent `enqueue_payment_outbox(...)` calls with the same:
  - `instruction_id`
  - `participant_id`
  - `idempotency_key`
  - `rail_type`
  - `payload`
- Use a barrier so calls start together.
- Use distinct request/correlation IDs for diagnostics.

### Task 5.3 — Assertions
- Exactly one logical outbox item (single `outbox_id` for the tuple).
- Exactly one pending row for `(instruction_id, idempotency_key)`.
- Optional: assert identical `sequence_id` across all returned rows (no sequence burning).
- Optional: terminal success uniqueness using known terminal states (`DISPATCHED`, `FAILED`) when a DB-enforced invariant exists.
  - If adding a unique partial index on terminal states, assert `23505` on concurrent terminal insert attempts.

## Operational Hardening (lightweight)

### Task 6.1 — Structured logging for repair
- Include fields like `outbox_id`, `attempt_no`, `state_reset='ZOMBIE_REQUEUE'`, `zombie_threshold_seconds`.

### Task 6.2 — Requeue velocity signal
- Add a log counter or lightweight metric hook for:
  - `zombiesRequeued`
  - stuck dispatching count (based on existing view).

## Evidence Bundle / Audit Artifacts
- Capture:
  - guardrail outputs
  - role-usage scans (before/after)
  - test logs for Phase 4 and Phase 5
- Store in `reports/` or existing evidence bundle process.

## Definition of Done
- Phase 4 proof test passes deterministically against real Postgres.
- Phase 5 concurrency/idempotency test passes and is DB-gated.
- Operational logs include repair context fields.
- Evidence artifacts captured for audit.
