# Implementation Plan: Lease-In-Pending DB Bedrock

## Objective
Define the bottom-up implementation plan for leasing primitives, authoritative DB functions, and least-privilege grants that match the new append-only attempts model.

## Scope
- Schema changes in `payment_outbox_pending` and supporting indexes.
- DB functions that define the only legal state transitions.
- Privilege changes aligned to the new primitives.

## Non-goals
- Worker refactors, tests, or views (handled in later phases).
- Migration shims or dual-path compatibility.

---

## 1) Schema: add explicit leasing primitives (DB bedrock)

### Task 1.1 — Add lease columns to `payment_outbox_pending`
- Add columns:
  - `claimed_by TEXT`
  - `lease_token UUID`
  - `lease_expires_at TIMESTAMPTZ`
- Use `ADD COLUMN IF NOT EXISTS` to keep idempotent schema application.
- Do not add defaults; lease values are explicitly set by claim/repair functions.
- Add a lease consistency CHECK constraint so lease fields are all NULL or all set:
  - `claimed_by`, `lease_token`, and `lease_expires_at` must be all NULL or all non-NULL.

### Task 1.2 — Index for claimable rows and lease repair
- Add a claimable index to support `next_attempt_at` ordering with lease filters.
- Add an index that supports finding expired leases quickly.
- Add an index for `claimed_by` to support operational queries and debugging.
- Avoid `now()` in index predicates; keep predicates static and filter by `now()` in queries.

### Task 1.3 — Confirm attempt count invariant remains cache-only
- Keep `attempt_count` as non-authoritative cache.
- No changes to `attempt_count` constraint; update logic moves to DB functions.

### Task 1.4 — Terminal uniqueness guard
- Add the partial unique index:
  - `UNIQUE(outbox_id) WHERE state IN ('DISPATCHED','FAILED')`
- This is a guardrail against double terminal outcomes.
- Name the index explicitly for tests and operational diagnostics:
  - `payment_outbox_attempts_one_terminal_per_outbox`
- Add a short COMMENT on the index describing the terminal-uniqueness invariant.

### Definition of Done
- Lease columns exist on `payment_outbox_pending` and are NULL by default.
- Indexes exist for claimable rows, expired leases, and claimed rows.
- No changes to attempts table mutability rules.

---

## 2) DB Functions: the only legal execution paths (authoritative state machine)

### Task 2.1 — `claim_outbox_batch(batch_size, worker_id, lease_seconds)`
- SECURITY DEFINER, fixed `search_path`.
- Uses `FOR UPDATE SKIP LOCKED` to select due and unleased rows.
- Updates lease fields and returns leased rows + `lease_token` and `lease_expires_at`.
- Leaves pending rows in place (no delete-on-claim).
- Ensure claim only leases rows that are unleased or expired:
  - `next_attempt_at <= now()` and `lease_expires_at IS NULL OR lease_expires_at <= now()`
- Always generate a fresh `lease_token` on each claim and set:
  - `claimed_by = worker_id`
  - `lease_token = gen_random_uuid()`
  - `lease_expires_at = now() + lease_seconds`

### Task 2.2 — `complete_outbox_attempt(...)`
- SECURITY DEFINER, fixed `search_path`.
- Verifies lease ownership and token; raises `P7002` (`LEASE_LOST`) on mismatch/expiry.
- Computes `attempt_no = MAX(attempt_no) + 1` from `payment_outbox_attempts`.
- Inserts exactly one outcome row (append-only) with `state` in:
  - `DISPATCHED`, `FAILED`, `RETRYABLE`.
- Updates pending:
  - terminal: delete pending row
  - retryable: reschedule `next_attempt_at`, clear lease, update `attempt_count = GREATEST(...)`
- Enforces retry ceiling (`attempt_count <= 20`), with deterministic SQLSTATE if exceeded.
- Do not allow `ZOMBIE_REQUEUE` here; reserve it for lease repair only.
- Lock the pending row with `FOR UPDATE` using `(outbox_id, worker_id, lease_token)` and `lease_expires_at > now()`; if not found, raise `P7002`.
- Force `FAILED` when retries are exhausted (append FAILED attempt + delete pending).

### Task 2.3 — `repair_expired_leases(batch_size, worker_id)`
- SECURITY DEFINER, fixed `search_path`.
- Selects expired leases (leased and `lease_expires_at <= now()`).
- Treat expired as `claimed_by IS NOT NULL` and `lease_expires_at <= now()`.
- Use `FOR UPDATE SKIP LOCKED` to avoid double repair by concurrent workers.
- Clears lease fields and reschedules `next_attempt_at` deterministically.
- Appends `ZOMBIE_REQUEUE` attempt row with `attempt_no = last + 1`.
- Updates `attempt_count = GREATEST(attempt_count, new_attempt_no)`.
- Make the reschedule policy explicit:
  - Fixed delay: `next_attempt_at = now() + interval '1 second'`.

### Task 2.4 — SQLSTATE discipline
- `P7002` for lease loss on completion.
- `P7003` (or similar) for invalid completion state.
- Preserve existing `P0001` for attempts UPDATE/DELETE trigger.
- Treat `23505` as an unexpected integrity failure signal, except when the constraint name matches `payment_outbox_attempts_one_terminal_per_outbox` (log as terminal uniqueness backstop event).

### Definition of Done
- The only legal claim/complete/repair actions are via DB functions.
- Attempts remain INSERT-only; no updates or deletes required.
- Lease loss is deterministic and surfaced via SQLSTATE.

---

## 3) Privileges: least privilege, but aligned to the new primitives

### Task 3.1 — Lock down direct table writes
- `payment_outbox_attempts`: no UPDATE/DELETE grants for runtime roles.
- Prefer INSERT-only via SECURITY DEFINER functions where possible.
- `payment_outbox_pending`: require function-only writes; revoke direct UPDATE/DELETE from runtime roles.

### Task 3.2 — Function grants
- Grant EXECUTE on:
  - `claim_outbox_batch`
  - `complete_outbox_attempt`
  - `repair_expired_leases`
  to `symphony_executor` only.
- Keep `enqueue_payment_outbox(...)` executable by `symphony_ingest`.
- Revoke direct DML on pending/attempts from `symphony_executor` to enforce function-only writes.
- Ensure SECURITY DEFINER functions execute as an owner role with required table privileges and a fixed `search_path`.

### Task 3.3 — Read-only visibility
- Ensure `symphony_readonly` and `symphony_auditor` can SELECT pending/attempts as required by views.
- Avoid granting write access outside of executor/definer functions.
- Keep `participant_outbox_sequences` hidden from read-only roles unless explicitly required.

### Task 3.4 — Guardrail updates (if enforced in SQL)
- If you maintain SQL-side guards, add assertions that attempts are INSERT-only.
- Confirm privileges match the new leasing path (no delete-on-claim outside complete function).

### Definition of Done
- Executor can only modify pending/attempts through the new functions.
- `symphony_ingest` can only enqueue via `enqueue_payment_outbox`.
- `symphony_readonly` and `symphony_auditor` cannot mutate outbox tables.

---

## Open Questions / Decisions Needed
- Decide whether to keep DISPATCHING enum value (do not insert it).
- Confirm whether `symphony_auth` needs any explicit grants for these primitives or remains out of scope.
