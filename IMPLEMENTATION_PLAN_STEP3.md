# Implementation Plan: Step 3 — Append-Only Trigger Proof (Outbox Attempts)

## Objective
Prove `payment_outbox_attempts` is append-only at the database layer by showing that UPDATE/DELETE fails due to the immutability trigger (SQLSTATE `P0001`) even when using the DB owner/migration role.

## Scope
- Add a DB-backed test that:
  - Inserts a single row into `payment_outbox_attempts`
  - Attempts UPDATE and DELETE using `queryNoRole()` (owner/migration user)
  - Asserts trigger error `P0001` (not `42501`)
- Keep the DB clean via transaction + rollback.

## Task Breakdown

### Task 1 — Add append-only trigger proof test (owner/migration role)
- Create `tests/unit/outboxAppendOnlyTrigger.spec.ts` (node:test).
- Use `queryNoRole` from `symphony/libs/db/testOnly`.
- Insert a row using the real table schema:
  - Required columns: `outbox_id`, `instruction_id`, `participant_id`, `sequence_id`,
    `idempotency_key`, `rail_type`, `payload`, `attempt_no`, `state`.
  - Defaults cover `attempt_id`, `claimed_at`, `created_at`.
- Use a transaction with `BEGIN`/`ROLLBACK` so the test is non-destructive.
- Assert the mutation attempt fails with `P0001`:
  - UPDATE: `state` or `error_message` field.
  - DELETE: delete the inserted row by `(outbox_id, attempt_no)`.

### Task 2 — Ensure SQLSTATE extraction is robust
- Add a small helper in the test to read SQLSTATE:
  - `err.code`
  - `err.sqlState`
  - `err.internalDetails?.sqlState`
  - `err.cause?.code`
- For the proof test, require `P0001` to confirm the trigger is the backstop.

### Task 3 — Verify test wiring and runtime isolation
- Confirm `tests/unit` runner includes `node:test` specs.
- Ensure `NODE_ENV === "test"` and `--conditions=test` are used (already done in Phase 2).
- Confirm `queryNoRole` is only reachable in tests (Phase 2 done).

## Definition of Done
- `tests/unit/outboxAppendOnlyTrigger.spec.ts` added and passing.
- UPDATE and DELETE attempts fail with SQLSTATE `P0001` using `queryNoRole`.
- DB state remains clean after test (rollback).

## Suggested SQL Insert Template (real schema)
```sql
INSERT INTO payment_outbox_attempts (
  outbox_id,
  instruction_id,
  participant_id,
  sequence_id,
  idempotency_key,
  rail_type,
  payload,
  attempt_no,
  state
)
VALUES (
  gen_random_uuid(),
  'inst-test',
  'participant-test',
  1,
  'idem-test',
  'sepa',
  '{"test": true}',
  1,
  'DISPATCHING'
)
RETURNING outbox_id, attempt_no;
```

## Notes / Risks
- If `gen_random_uuid()` is not available in the test DB, swap to
  `uuid_generate_v4()` or a fixed UUID (test runs in a transaction).
- If a stricter insert path is required (e.g., only via a function), replace
  the direct INSERT with the authoritative insert function and use the returned
  `outbox_id` / `attempt_no`.
