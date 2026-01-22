# Implementation Plan: Lease-In-Pending Operations & Proofs

## Objective
Define the operational worker refactor, proof tests, and guardrails needed to complete the lease-in-pending migration without legacy paths.

## Scope
- Replace ZombieRepair with lease-aware repair worker.
- Update tests to prove the new lease model and append-only attempts.
- Add guardrails to prevent regression to delete-on-claim and DISPATCHING inserts.

## Non-goals
- Schema and DB function changes (covered in DB bedrock plan).
- App-layer relayer and view changes (covered in app-layer plan).

---

## 7) ZombieRepair becomes LeaseRepairWorker (simpler, more correct)

### File
- `libs/repair/ZombieRepairWorker.ts` (rename to `LeaseRepairWorker.ts`)

### Task 7.1 — Replace stale DISPATCHING logic
- Remove scanning attempts for stale `DISPATCHING` rows.
- Use `repair_expired_leases(batchSize, workerId)` instead.
- Do not use zombie thresholds; lease expiry is authoritative. If a config value is needed, name it `LEASE_SECONDS`.

### Task 7.2 — Lease-aware repair workflow
- On each cycle:
  - call `repair_expired_leases`
  - log repaired count and outbox IDs (bounded)
- Treat lease expiry as authoritative; do not infer from attempts.

### Task 7.3 — Logging semantics
- Log repair activity as operational, not error:
  - fields: `worker_id`, `repaired_count`, `scanned_count` (optional)
- Keep `outbox_ids` bounded and behind a debug flag.
- If `repair_expired_leases` returns zero rows, log at debug/trace level only.

### Definition of Done
- ZombieRepairWorker no longer references DISPATCHING attempts.
- Lease repair uses the DB function exclusively.
- Logs indicate lease repair activity clearly and deterministically.

---

## 8) Tests: bottom-up proofs, updated to the new ground truth

### 8.1 — Append-only attempts proof (unit)
- File: `tests/unit/outboxAppendOnlyTrigger.spec.ts`
- Keep existing assertions:
  - UPDATE fails with `P0001`
  - DELETE fails with `P0001`
  - INSERT succeeds
- Ensure failures assert SQLSTATE `P0001`, not privilege `42501`.

### 8.2 — Lease repair proof (unit)
- Replace `tests/unit/zombieRepairProof.spec.ts` with `tests/unit/leaseRepairProof.spec.ts`.
- Steps:
  1. enqueue one pending row
  2. claim with any lease duration (for example, 60 seconds)
  3. force lease expiry deterministically via `queryNoRole` by setting `lease_expires_at = now() - interval '1 second'`
  4. run one repair cycle
  5. assert:
     - pending row is unleased and due
     - `claimed_by`, `lease_token`, `lease_expires_at` are NULL
     - `ZOMBIE_REQUEUE` attempt appended
     - `attempt_no` monotonic (`last + 1`)
     - `attempt_count` monotonic via `GREATEST`

### 8.3 — Lease loss proof (integration)
- New test: `tests/integration/outboxLeaseLossProof.spec.ts` (DB-gated)
- Steps:
  1. claim row → lease token A
  2. force expiry
  3. claim again → lease token B
  4. complete with token A → fails `P7002` (not `23505`)
  5. complete with token B → succeeds

### 8.4 — Completion concurrency proof (integration)
- New test: `tests/integration/outboxCompleteConcurrencyProof.spec.ts` (DB-gated)
- Steps:
  1. claim row → token A
  2. race multiple `complete_outbox_attempt` calls
  3. exactly one succeeds; the rest fail deterministically with `P7002` (preferred)

### 8.5 — Enqueue idempotency proof (integration)
- Keep existing concurrency/idempotency proof for `enqueue_payment_outbox`.
- Confirm it still passes with leasing model.

### Definition of Done
- Unit proofs cover append-only attempts and lease repair.
- Integration proofs cover idempotent enqueue, lease loss, and completion concurrency.
- All tests are DB-gated and deterministic (no sleeps required).

---

## 9) Guardrails: ban the old anti-patterns forever

### Task 9.1 — Static SQL guardrails
- Update guardrail scripts to flag:
  - DELETE-as-claim patterns (for example, `DELETE FROM payment_outbox_pending` combined with `FOR UPDATE SKIP LOCKED`)
  - any INSERT of `DISPATCHING` into `payment_outbox_attempts`
  - any direct DML against pending/attempts outside of DB functions
  - allow legitimate terminal deletes and schema SQL under `schema/`
  - allow DB function bodies and test-only `queryNoRole` usage in `tests/`

### Task 9.2 — CI enforcement
- Ensure guardrails run in CI with `ENFORCE_NO_DB_QUERY=1`.
- Fail fast on violations.

### Task 9.3 — Test guard for DISPATCHING insertion
- Prefer static guardrail checks for `DISPATCHING` insertion.
- Keep the enum value if needed for historical reads, but do not insert it.

### Definition of Done
- Guardrails catch delete-on-claim, DISPATCHING inserts, and direct DML.
- CI blocks regressions.

---

## Open Questions / Decisions Needed
- Confirm whether to rename `ZombieRepairWorker` file or keep name with lease semantics.
- Decide if `DISPATCHING` enum stays for historical compatibility (no inserts).
