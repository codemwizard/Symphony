# PROJECT_CONTEXT.md

## 1) Project Overview

* **Project:** Symphony (high-stakes payment orchestrator)
* **Current focus:** Bottom-up hardening of the DB-authoritative outbox + strict DB role discipline
* **Stage:** “Option 2A” outbox architecture completed + tests passing; now moving to “Bottom-up fixes” Step 2/3 (explicit role parameter everywhere, remove global mutable role)

## 2) Goals (MVP + Non-goals)

**MVP Goals**

* Make the outbox **DB-authoritative (Option 2A)**:

  * Hot pending queue + append-only attempts archive
  * Strict participant sequencing
  * DB-enforced idempotency + atomic enqueue
  * Set-based claim that derives attempt numbers from attempts history
  * Requeue/zombie repair is **outbox_id authoritative**
  * NOTIFY + poll hybrid wakeup
  * Audit-grade immutability proof (ACL + trigger + SQLSTATE)
* Enforce **explicit DB role scoping per operation**:

  * Remove global mutable role (`currentRole` / `setRole`)
  * Require explicit `DbRole` passed everywhere (service boundary maps raw strings)
  * Prevent pooled-connection role leakage

**Non-goals**

* Keeping legacy outbox schema for compatibility (explicitly removed)
* Implementing full product UI / dashboards
* Implementing full auth/RBAC product flows beyond role scoping discipline

## 3) Current Status

* **Option 2A outbox is DONE**:

  * Migration and schema are in place
  * Privilege enforcement tests completed and passing
* **Step 2 (DB access discipline)** is planned and partially represented in code, but **global role APIs still exist** in `libs/db/index.ts` and must be removed
* **Next:** Step 3 = update all call sites to pass explicit role, remove legacy exports, add proof tests for role isolation + residue safety

## 4) Tech Stack

* **Runtime:** Node.js (TypeScript, ESM-style imports)
* **Database:** PostgreSQL
* **DB driver:** `pg` (Pool/PoolClient)
* **Testing:** `node:test` + `node:assert`
* **Validation:** zod middleware (identity envelope validation)
* **Context propagation:** AsyncLocalStorage via `RequestContext.run(...)`
* **Logging:** structured logger (`libs/logging/logger.js`)
* **Security:** mTLS/CA cert support via `DB_CA_CERT`

## 5) Architecture Summary

* **Services**

  * `control-plane` (admin/config operations)
  * `ingest-api` (enqueue producer path)
  * `read-api` (readonly queries)
  * `executor-worker` (relayer/dispatch/requeue/zombie repair)
* **Outbox Option 2A**

  * `payment_outbox_pending` = hot queue
  * `payment_outbox_attempts` = append-only ledger/archive
  * `participant_outbox_sequences` = strict per-participant sequence allocator
  * DB functions:

    * `bump_participant_outbox_seq(...)` (SECURITY DEFINER)
    * `enqueue_payment_outbox(...)` (SECURITY DEFINER, advisory locks, deterministic idempotency)
  * Claim is set-based, computes `MAX(attempt_no)+1` only for claimed outbox_ids
  * Zombie repair requeues by `outbox_id` only and preserves monotonic cache via `GREATEST(...)`
* **Role model**

  * Runtime DB roles: `symphony_control`, `symphony_ingest`, `symphony_executor`, `symphony_readonly`, `symphony_auditor`
  * Optional/retained: `symphony_auth` for security/admin trust-fabric operations (if used)
* **Key security posture**

  * DB is authoritative for correctness invariants (idempotency, sequencing, immutability)
  * Application code must not bypass DB contract via direct writes/sequence bumps

## 6) Repo Layout (make best guess if unknown)

* `libs/`

  * `libs/db/` (pool + role-scoped DB helpers)
  * `libs/bootstrap/` (startup/bootstrap + config guards)
  * `libs/context/` (identity + request context)
  * `libs/auth/` (capability checks)
  * `libs/outbox/` (producer + relayer logic)
  * `libs/repair/` (zombie repair worker)
  * `libs/logging/`, `libs/errors/`, `libs/audit/`, `libs/validation/`, `libs/crypto/`
* `services/`

  * `services/control-plane/src/index.ts`
  * `services/ingest-api/src/index.ts`
  * `services/read-api/src/index.ts`
  * `services/executor-worker/src/index.ts`
* `schema/`

  * `schema/v1/011_payment_outbox.sql`
  * `schema/v1/011_privileges.sql`
  * `schema/views/outbox_status_view.sql` (or equivalent)
* `docs/`

  * `docs/database_schema.md`

## 7) Development Setup (commands + env vars; mark unknowns clearly)

**Commands (UNKNOWN exact package manager)**

* `UNKNOWN` install deps: `npm install` / `pnpm install` / `yarn`
* `UNKNOWN` run tests: `npm test` / `pnpm test`
* `UNKNOWN` run service: `npm run start --workspace services/<name>`

**Required env vars (known from db module)**

* `DB_HOST`
* `DB_PORT`
* `DB_USER`
* `DB_PASSWORD`
* `DB_NAME`
* `DB_CA_CERT` (required in production/staging)
* `DB_SSL_QUERY` (`true|false`, `false` forbidden in production/staging)
* `NODE_ENV` (`production|staging|...`)
* `DATABASE_URL` (used in tests)

**UNKNOWN**

* Migration command/tooling (e.g., psql, node migration runner, knex, etc.)

## 8) Product Requirements (Behavior)

* **Enqueue**

  * Only via `enqueue_payment_outbox(...)`
  * Must be idempotent by `(instruction_id, idempotency_key)`
  * Must not burn sequence IDs under concurrency
  * Must use advisory lock (two-arg, distinct seeds)
* **Pending**

  * Unique `(participant_id, sequence_id)` ensures strict sequencing
  * Unique `(instruction_id, idempotency_key)` ensures enqueue-time idempotency
  * `attempt_count` is **cache of last_attempt_no**, never authoritative for next attempt
* **Attempts**

  * Append-only ledger
  * Unique `(outbox_id, attempt_no)` enforces attempt numbering invariant
  * UPDATE/DELETE forbidden (ACL + trigger raises SQLSTATE `P0001`)
  * TRUNCATE forbidden (explicit revoke)
* **Claim/Relayer**

  * Set-based claim (single SQL unit)
  * Derive `attempt_no` from attempts history only for claimed outbox_ids (no global scans)
  * Insert `DISPATCHING` attempt rows during claim
* **Requeue/Zombie repair**

  * Conflict target must be `outbox_id` only
  * Cache monotonicity enforced with `attempt_count = GREATEST(existing, excluded)`
  * Zombie repair inserts `ZOMBIE_REQUEUE` attempt with `attempt_no = last + 1`
* **Wakeup**

  * Hybrid LISTEN/NOTIFY + poll fallback
  * NOTIFY trigger function must set fixed `search_path` and not be SECURITY DEFINER

## 9) Important Decisions (and why)

* **DB-authoritative outbox (Option 2A)**

  * Correctness invariants enforced at the DB layer (idempotency, sequencing, attempt immutability)
* **Append-only attempts with provable immutability**

  * ACL + trigger with fixed SQLSTATE provides audit-grade proof
* **Set-based claim**

  * Avoids per-row loops, reduces race conditions, prevents scanning entire attempts table
* **Outbox identity is `outbox_id`**

  * Requeue/zombie repair must preserve identity and prevent duplicates
* **Explicit role scoping per operation**

  * Eliminates global mutable role and prevents pooled connection role leakage
* **Anonymous paths mapped to `symphony_readonly`**

  * No `anon` in `DbRole`; service boundary chooses role explicitly

## 10) Conventions (MUST follow)

* **No global DB role state**

  * Do not use `currentRole` / `setRole`
* **DB calls must always include an explicit `DbRole`**

  * Raw strings only allowed at service boundary → map/validate once
* **Transactions must use `SET LOCAL ROLE`**

  * `transactionAsRole(role, fn)` uses `BEGIN; SET LOCAL ROLE ...`
* **Single-statement calls may use `SET ROLE` + `RESET ROLE`**

  * Must be in `try/finally` before releasing pooled client
* **Never expose raw `PoolClient` outside db module**

  * Use RoleBoundClient / TxClient wrappers only
* **Outbox invariants**

  * attempt numbering from attempts history, not pending cache
  * requeue conflict target = outbox_id only
  * attempt_count monotonic via `GREATEST(...)`

## 11) “Do Not Break” Contract

* **Option 2A schema invariants**

  * `UNIQUE(outbox_id, attempt_no)`
  * pending uniqueness for idempotency + sequencing
  * attempts are append-only (no UPDATE/DELETE/TRUNCATE)
* **Enqueue contract**

  * Only DB function is allowed for ingest enqueue
  * Must remain deterministic under concurrency (unique_violation fallback)
* **Claim contract**

  * Must remain set-based and must not scan whole attempts table
* **Privilege model**

  * ingest cannot DML pending or touch sequence allocator
  * executor cannot UPDATE/DELETE attempts
  * readonly/auditor cannot read sequence table
* **Role discipline**

  * No role leakage across pooled connections
  * No implicit default role

## 12) Open Questions / TODO

* What is the exact migration runner / command used to apply `schema/v1/*.sql`? (UNKNOWN)
* Confirm `executor-worker` entrypoint: current file appears copy/pasted from read-api (role/name/logs mismatch). Should be `symphony_executor` and `executor-worker`.
* Confirm whether `symphony_auth` is actively used by any service. If not, exclude from `DbRole` until needed.
* Confirm whether any services require `symphony_auditor` runtime role or if it is purely external/reporting.
* Identify all remaining call sites using:

  * `db.query(...)`
  * `db.executeTransaction(...)`
  * `db.setRole(...)`

## 13) AI Working Rules (Cursor)

* Prefer **DB-authoritative correctness** over application-side best-effort logic.
* Do not introduce compatibility shims for removed legacy outbox.
* When refactoring DB access:

  * Remove exports rather than deprecating indefinitely
  * Make incorrect usage impossible by type (RoleBoundClient / TxClient)
  * Always `RESET ROLE` before releasing pooled clients
* Do not change outbox schema invariants without explicit instruction.
* Keep changes minimal, focused, and test-backed (node:test).
* If something is UNKNOWN, mark it and add to TODO.

## 14) Quick Commands Cheat Sheet

* Run tests (UNKNOWN): `UNKNOWN`
* Run privilege tests: `UNKNOWN (node:test suite)`
* Apply migrations: `UNKNOWN`
* Start services:

  * control-plane: `UNKNOWN`
  * ingest-api: `UNKNOWN`
  * read-api: `UNKNOWN`
  * executor-worker: `UNKNOWN`
* Required env:

  * `DATABASE_URL=...`
  * `DB_HOST=... DB_PORT=... DB_USER=... DB_PASSWORD=... DB_NAME=...`
  * `DB_CA_CERT=...` (prod/staging)
  * `DB_SSL_QUERY=true` (prod/staging)
