# Implementation Plan: Outbox State Proofs + DB Boundary Hardening

## Goal
Provide auditable proof that outbox state transitions are safe and role boundaries cannot be bypassed, while keeping error sanitization production-safe and tests deterministic.

## Scope
- Outbox state machine invariants: PENDING → DISPATCHING → (DISPATCHED | RETRYABLE | FAILED) + ZOMBIE_REQUEUE.
- DB boundary enforcement and test-only escape hatches.
- Deterministic zombie repair testing.

## Plan

### Phase 1: DB Boundary Invariants (CI Enforcement)
- Forbid `pg` / `PoolClient` usage outside `libs/db/**`.
- Forbid `pool.query(` outside `libs/db/**`.
- Forbid `SET ROLE`, `RESET ROLE`, or `SET LOCAL ROLE` outside `libs/db/**`.
- Forbid `new Pool(` outside `libs/db/**`.
- Scope: applies to `libs/**` and `services/**`; tests/scripts are exempt for imports but should continue to use DB wrappers, and `SET ROLE`/`RESET ROLE`/`SET LOCAL ROLE` remain forbidden outside `libs/db/**`.
- Enforce via ESLint import restrictions or CI grep guard.

### Phase 2: Test-Only Escape Hatch Hardening
- Move `__testOnly.queryNoRole` into `libs/db/testOnly.ts`.
- Export only when `NODE_ENV === 'test'` and exclude from production build output.
- Make production build fail if `testOnly` is imported (via conditional exports or prod tsconfig excludes).
- Standardize import path to `libs/db/testOnly` and forbid runtime imports outside tests.
- Allowlist importers for `libs/db/testOnly`: `tests/**`, `libs/db/__tests__/**` only.
- Enforce allowlist via CI grep on import specifier `libs/db/testOnly` outside `tests/**` and `libs/db/__tests__/**`.

### Phase 3: Outbox Role-Boundary Proofs
- Update outbox privilege tests to assert on `sqlState` (primary: `42501`, `P0001`), with `cause.message` as a fallback.
- Add negative tests:
  - `symphony_readonly` cannot insert into `payment_outbox_pending`.
  - `symphony_executor` cannot update/delete `payment_outbox_attempts` (append-only).
  - Runtime roles cannot `TRUNCATE` outbox tables.
  - readonly/auditor cannot read `participant_outbox_sequences`.

### Phase 4: Deterministic Zombie Repair Proof
- Make zombie threshold configurable for tests via `ZOMBIE_THRESHOLD_SECONDS` (env var with default).
- Add deterministic test:
  - Insert a stale `DISPATCHING` attempt.
  - Set the attempt timestamp/lease so it is beyond the zombie threshold.
  - Run the worker once.
  - Assert:
    - `ZOMBIE_REQUEUE` attempt appended.
    - `ZOMBIE_REQUEUE` attempt references the same `outbox_id`.
    - Pending row requeued with same `outbox_id`.
    - No duplicate `PENDING` rows for the same `outbox_id` (conflict target proof).
    - `attempt_no` monotonic.
    - `attempt_count` monotonic.
  - The stale item remains represented by the same `outbox_id`, with a new `ZOMBIE_REQUEUE` attempt appended and the item returned to `PENDING`.

### Phase 5: Concurrency/Idempotency Proof
- Stress test concurrent enqueue with same `(instruction_id, idempotency_key)`.
- Assert:
  - Exactly one logical outbox item (one `outbox_id` for the `(instruction_id, idempotency_key)` tuple).
  - Exactly one `DISPATCHED` attempt for the logical operation; retries may create `RETRYABLE`/`DISPATCHING` but no additional `DISPATCHED`.

## Tasks
- [ ] Add CI guard: no `pg` / `PoolClient` outside `libs/db/**`.
- [ ] Add CI guard: no `pool.query(` outside `libs/db/**`.
- [ ] Add CI guard: no `SET ROLE` / `RESET ROLE` / `SET LOCAL ROLE` outside `libs/db/**`.
- [ ] Add CI guard: no `new Pool(` outside `libs/db/**`.
- [ ] Move test-only DB helpers to `libs/db/testOnly.ts` and gate exports.
- [ ] Update outbox privilege tests to assert on `sqlState`/`cause`.
- [ ] Add env-driven zombie threshold in `libs/repair/ZombieRepairWorker.ts`.
- [ ] Add deterministic zombie repair unit test.
- [ ] Add concurrency/idempotency stress test for outbox (requires DB; consider placing under `tests/integration`).

## Acceptance Criteria
- CI prevents DB boundary violations.
- Outbox privilege tests pass using `sqlState`/`cause`.
- Zombie repair test is deterministic and non-flaky.
- Concurrency/idempotency proof validates single successful dispatch per logical operation.
- Guardrails/tests map to files: `scripts/guardrails/db-boundary.sh`, `tests/unit/outboxPrivileges.spec.ts`, `tests/unit/zombieRepairProof.spec.ts`, `tests/unit/outboxConcurrency.spec.ts` (or `tests/integration/outboxConcurrency.test.ts`).
- CI jobs to verify: `guardrails:db-boundary`, `build:prod`, `test` (node + jest).
