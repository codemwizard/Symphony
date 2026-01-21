# Implementation Plan: Step 3B — Role-Boundary Proofs (Outbox ACL)

## Objective
Prove role-boundary enforcement on outbox tables by asserting SQLSTATE `42501` for disallowed operations, using real Postgres and explicit role-scoped queries.

## Scope
- Add/confirm tests that exercise ACL boundaries (INSERT/UPDATE/DELETE/TRUNCATE/SELECT).
- Use SQLSTATE assertions (`42501`) as primary proof signal.
- Avoid reliance on sanitized error messages; allow minimal message fallback only if needed.

## Task Breakdown

### Task 1 — Add a SQLSTATE matcher helper
- Implement a small helper in the test file:
  - Read from `err.sqlState`, `err.code`, `err.cause.sqlState`, `err.cause.code`.
  - Allow list: `['42501']`.
- Keep the helper local to the test file unless reuse is needed.

### Task 2 — Role-boundary proofs (DB-backed)
Use `db.queryAsRole` with explicit roles and assert SQLSTATE `42501`.

#### A) Readonly cannot insert into pending
- Role: `symphony_readonly`
- SQL: `INSERT INTO payment_outbox_pending (...) VALUES (...)`
- Expect: `42501`

#### B) Ingest cannot insert into pending
- Role: `symphony_ingest`
- SQL: `INSERT INTO payment_outbox_pending (...) VALUES (...)`
- Expect: `42501`

#### C) Executor cannot update/delete attempts
- Role: `symphony_executor`
- SQL:
  - `UPDATE payment_outbox_attempts SET ... WHERE 1=0`
  - `DELETE FROM payment_outbox_attempts WHERE 1=0`
- Expect: `42501` (ACL boundary, not trigger `P0001`)

#### D) Runtime roles cannot truncate outbox tables
- Role: `symphony_executor` (or another runtime role)
- SQL:
  - `TRUNCATE payment_outbox_pending`
  - `TRUNCATE payment_outbox_attempts`
- Expect: `42501`

#### E) Readonly and auditor cannot see sequence table
- Roles: `symphony_readonly`, `symphony_auditor`
- SQL: `SELECT * FROM participant_outbox_sequences LIMIT 1`
- Expect: `42501`

### Task 3 — Ensure DB gating is consistent
- Ensure tests run only when DB config is available (e.g., `DATABASE_URL` or `RUN_DB_TESTS` gating).
- No seed data required; migrations must be applied.

## Definition of Done
- All role-boundary tests pass against real Postgres.
- SQLSTATE `42501` is asserted for each boundary.
- No reliance on sanitized `.message` for primary proof.

## Notes / Risks
- If a test receives `P0001`, it indicates the trigger fired before ACL; adjust role or SQL to hit ACL first.
- If `DATABASE_URL` is missing, tests should be skipped.
