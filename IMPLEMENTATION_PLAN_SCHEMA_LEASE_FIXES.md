# Implementation Plan: Lease Schema + DB Function Correctness Pass

## Objective
Fix blocking correctness bugs in lease schema and DB functions so claim/repair operate on real data and attempt_count behaves correctly.

## Scope
- Correct `attempt_count` constraint in `payment_outbox_pending`.
- Fix time comparisons in `claim_outbox_batch` and `repair_expired_leases`.
- Validate lease consistency constraint and prerequisites (uuidv7) ordering.

## Non-goals
- Redesigning the lease model or adding new features.
- Changing application-layer logic beyond what is required for DB correctness.

---

## 1) Fix attempt_count constraint (blocking)

### File
- `schema/v1/011_payment_outbox.sql`

### Issue Addressed
- The CHECK currently enforces `attempt_count = 20`, which blocks inserts/updates.

### Task 1.1 — Correct the CHECK constraint
- Replace the `attempt_count` constraint with:
  - `attempt_count >= 0 AND attempt_count <= 20`, or remove the ceiling and enforce retry limits in logic.
- Ensure existing rows remain valid after the change.

### Definition of Done
- Enqueue inserts succeed without violating `attempt_count` CHECK.

---

## 2) Fix claim query time predicates (blocking)

### File
- `schema/v1/011_payment_outbox.sql`

### Issue Addressed
- `claim_outbox_batch` uses equality against `NOW()` for due/lease checks, causing near-zero matches.

### Task 2.1 — Update due predicate
- Change:
  - `p.next_attempt_at = NOW()` → `p.next_attempt_at <= NOW()`
- Use `NOW()` intentionally (transaction timestamp) for deterministic function behavior.

### Task 2.2 — Update lease predicate
- Change:
  - `p.lease_expires_at = NOW()` → `p.lease_expires_at <= NOW()`
  - `p.lease_expires_at IS NULL OR p.lease_expires_at = NOW()` → `p.lease_expires_at IS NULL OR p.lease_expires_at <= NOW()`

### Definition of Done
- Claim returns rows when `next_attempt_at <= NOW()` and lease is expired or null.
- Claim returns 0 rows when `lease_expires_at > NOW()` (active lease).

---

## 3) Fix repair selection to target expired leases (blocking)

### File
- `schema/v1/011_payment_outbox.sql`

### Issue Addressed
- `repair_expired_leases` selection uses equality against `NOW()`, making repair a no-op.

### Task 3.1 — Update repair predicate
- Change:
  - `p.lease_expires_at = NOW()` → `p.lease_expires_at <= NOW()`
- Require row is leased (defensive): include `lease_token IS NOT NULL` (or `claimed_by IS NOT NULL`) in the repair selection.

### Definition of Done
- Repair finds expired leases and appends `ZOMBIE_REQUEUE` attempts.
- Repair does not touch rows with `lease_expires_at IS NULL`.

---

## 4) Deterministic schema sanity checks

### File
- `schema/v1/011_payment_outbox.sql`

### Task 4.1 — Lease consistency constraint completeness
- Confirm the constraint enforces either all lease fields are NULL or all are NOT NULL.

### Task 4.2 — uuidv7 availability before use
- Ensure `uuidv7()` is created/loaded before any table/function uses it.

### Task 4.3 — Completion semantics (spot check)
- Verify `complete_outbox_attempt` clears lease on retryable and deletes pending on terminal.
- Verify `complete_outbox_attempt(..., RETRYABLE, ...)` keeps `attempt_count` within the CHECK (increment or `GREATEST`).
- Verify repair keeps `attempt_count` within the CHECK.

### Definition of Done
- Schema objects create cleanly in a fresh DB with no missing dependencies.
- Step-A happy path: enqueue → claim returns 1 row when due; complete with valid lease succeeds; stale lease fails `P7002`; repair appends `ZOMBIE_REQUEUE`.

---

## 5) Test plan (DB-gated)

### Tests
- Unit:
  - `tests/unit/outboxAppendOnlyTrigger.spec.ts`
  - `tests/unit/leaseRepairProof.spec.ts`
- Integration:
  - `tests/integration/outboxLeaseLossProof.spec.ts`
  - `tests/integration/outboxCompleteConcurrencyProof.spec.ts`
  - `tests/integration/outboxConcurrency.test.ts`

### Definition of Done
- Claim/complete/repair behave correctly under DB-gated proofs.

---

## Open Questions / Decisions Needed
- Preferred retry-ceiling approach:
  - Remove the ceiling now (`attempt_count >= 0` only) and enforce retry exhaustion later in function logic with a dedicated SQLSTATE, or
  - Keep `attempt_count <= 20` as a hard limit if policy is fixed.
