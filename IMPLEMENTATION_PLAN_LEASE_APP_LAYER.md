# Implementation Plan: Lease-In-Pending App Layer

## Objective
Define the application-layer implementation plan for lease-aware views, role-scoped DB wrappers, and outbox relayer surgery that eliminates delete-on-claim and DISPATCHING inserts.

## Scope
- Lease-aware supervisor/ops views.
- `libs/db` wrappers for new DB functions.
- Outbox relayer changes to use claim/complete functions.

## Non-goals
- Schema changes or DB function definitions (covered in DB bedrock plan).
- Repair worker and test changes (handled in separate phases).

---

## 4) Views: update supervisor/ops visibility to lease-aware truth

### SQL file
- `schema/views/outbox_status_view.sql`

### Task 4.1 — Replace DISPATCHING-derived inflight logic
- Stop deriving inflight/stuck counts from attempts with `state = 'DISPATCHING'`.
- Replace with lease-aware counts from `payment_outbox_pending`:
  - leased: `claimed_by IS NOT NULL AND lease_expires_at > now()`
  - expired lease: `claimed_by IS NOT NULL AND lease_expires_at <= now()`
  - due unleased: `next_attempt_at <= now() AND (lease_expires_at IS NULL OR lease_expires_at <= now()) AND claimed_by IS NULL`

### Task 4.2 — Add lease-centric operational metrics
- Add counts for:
  - `leased_count`
  - `expired_lease_count`
  - `due_unleased_count`
- Keep existing pending/attempt aggregates, but ensure they are lease-aware.

### Task 4.3 — Remove stale DISPATCHING fields
- Remove any `dispatching_count` logic that depends on attempts state and replace it with `expired_lease_count`.
- Ensure the view does not require `DISPATCHING` to be inserted anywhere.

### Definition of Done
- Supervisor view reflects lease state directly from pending.
- No metric in the view depends on DISPATCHING attempts.

---

## 5) libs/db: add role-scoped wrappers for the new functions (no raw SQL elsewhere)

### Files
- `libs/db/index.ts` (or a dedicated `libs/outbox/db.ts` wrapper if that is the established pattern)

### Task 5.1 — Add claim wrapper
- Add a role-scoped wrapper for `claim_outbox_batch`.
- Inputs: `batchSize`, `workerId`, `leaseSeconds`.
- Returns the leased rows including `lease_token` and `lease_expires_at`.
- Make the return type explicit so `lease_token` and `lease_expires_at` are required fields.

### Task 5.2 — Add complete wrapper
- Add a role-scoped wrapper for `complete_outbox_attempt`.
- Inputs: `outbox_id`, `lease_token`, `worker_id`, `state`, and completion metadata.
- Ensure callers handle SQLSTATE `P7002` as a lease-loss concurrency event.

### Task 5.3 — Add repair wrapper
- Add a role-scoped wrapper for `repair_expired_leases`.
- Inputs: `batchSize`, `workerId`.
- Return repaired row IDs and attempt numbers for logging.

### Task 5.4 — Remove raw SQL usage for claim/complete
- Enforce use of wrappers inside libs/outbox and workers.
- Avoid direct DML in application code for pending/attempts.
- Add a small helper for error classification (for example, `isLeaseLostError(err)` for SQLSTATE `P7002`) to keep concurrency semantics consistent.
- Do not expose `PoolClient` from wrappers; return plain objects.

### Definition of Done
- All calls to claim/complete/repair use role-scoped wrappers.
- No raw SQL in application code for leasing or attempts insertion.

---

## 6) OutboxRelayer surgery: remove delete-on-claim; remove DISPATCHING inserts; complete via DB function

### File
- `libs/outbox/OutboxRelayer.ts`

### Task 6.1 — Replace claim path
- Remove DELETE-based claim logic.
- Call `claim_outbox_batch` wrapper and capture lease fields:
  - `lease_token`
  - `lease_expires_at`
- Ensure claim uses worker id and lease duration.

### Task 6.2 — Remove DISPATCHING attempt insertion
- Delete any insertion of DISPATCHING attempts.
- Do not allocate `attempt_no` in application code.

### Task 6.3 — Replace completion path
- Replace `insertOutcome` and any retry requeue SQL with a single call to `complete_outbox_attempt`.
- Let the DB:
  - validate lease ownership and token
  - derive `attempt_no`
  - insert outcome
  - delete or reschedule pending

### Task 6.4 — Handle lease loss deterministically
- If `complete_outbox_attempt` raises `P7002`, treat as concurrency event:
  - log and skip further action
  - do not retry completion

### Task 6.5 — Update in-memory record shape
- Add `lease_token` and `lease_expires_at` to the relayer’s claimed record shape.
- Ensure payload and identifiers are preserved for completion calls.
- Treat `lease_token` as required (non-optional) after claim.

### Task 6.6 — Completion idempotency rules
- On success: proceed as normal.
- On `P7002` (`LEASE_LOST`): log as concurrency event and stop (no retries).
- On any other error: treat as a real failure and follow worker retry policy.

### Definition of Done
- OutboxRelayer no longer deletes pending on claim.
- No DISPATCHING attempts are inserted.
- Completion and retry are mediated exclusively by `complete_outbox_attempt`.

---

## Open Questions / Decisions Needed
- Confirm whether `libs/db/index.ts` or a new `libs/outbox/db.ts` wrapper is the preferred location for outbox function wrappers.
- Confirm the canonical worker ID and lease duration sources used by the relayer (worker ID stable/unique, lease seconds config-driven).
