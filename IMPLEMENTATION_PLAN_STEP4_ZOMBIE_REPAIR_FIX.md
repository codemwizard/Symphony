# Implementation Plan: Step 4 — ZombieRepairWorker Fix + Deterministic Proof

## Objective
Fix the bulk insert parameter mismatch in `ZombieRepairWorker`, make the zombie threshold deterministic for tests, and add a proof-grade DB-backed test for zombie requeue behavior.

## Scope
- Correct placeholder/value alignment for bulk insert into `payment_outbox_attempts`.
- Make zombie threshold usage deterministic (either via runtime read or cache-busting import in tests).
- Add a deterministic zombie repair proof test that hits real Postgres.
- Harden interval handling in the stale-attempts query.

## Task Breakdown

### Task 1 — Fix `attemptValues` / `attemptPlaceholders` mismatch
- Locate the bulk insert for `payment_outbox_attempts` in `libs/repair/ZombieRepairWorker.ts`.
- Ensure `error_code` is intentional and not receiving the state value by accident.
- Recommended minimal fix:
  - Hardcode `state` and `error_code` in SQL as `'ZOMBIE_REQUEUE'`.
  - Param only `error_message`.
  - Adjust `attemptOffset` to **9 params per row**.

### Task 2 — Make zombie threshold deterministic
Choose one approach:
- **Preferred**: read `process.env.ZOMBIE_THRESHOLD_SECONDS` at runtime (per call or constructor arg).
- **Minimal change**: keep module-level constant, but tests must set env **before** import and use cache-busting dynamic import.

### Task 3 — Add deterministic zombie repair proof test
- Create `tests/unit/zombieRepairProof.spec.ts` (DB-backed).
- Use real Postgres via `DATABASE_URL`.
- Seed a stale DISPATCHING attempt in `payment_outbox_attempts`.
- Run one repair cycle:
  - Assert one pending row exists with same `outbox_id`.
  - Assert a `ZOMBIE_REQUEUE` attempt appended with `attempt_no = 2`.
- Run a second cycle:
  - Assert no additional attempts appended.

### Task 4 — Harden interval usage in stale-attempts query
- Avoid SQL string interpolation for the interval.
- Use parameterized interval math:
  - `claimed_at < NOW() - ($2::int * INTERVAL '1 second')`
  - Pass `[REPAIR_BATCH_SIZE, ZOMBIE_THRESHOLD_SECONDS]`.

## Definition of Done
- Bulk insert uses correct placeholders/values and writes `error_code` intentionally.
- Zombie threshold is deterministic in tests.
- Deterministic zombie repair proof test passes against real Postgres.
- Interval query uses parameters (no string interpolation).

## Notes / Risks
- `payment_outbox_attempts` is append-only; tests should use unique IDs to avoid cleanup.
- If the trigger or ACLs change, ensure the test still hits expected paths.
