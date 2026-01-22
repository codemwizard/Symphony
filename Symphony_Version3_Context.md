# Symphony_Version-3_Context.md

## 1) Project Overview

* **Project name:** Symphony
* **What it is:** High-stakes payment/orchestration system (Node.js + PostgreSQL) with DB-enforced correctness, strict DB role boundaries, and audit-grade outbox dispatch semantics.
* **Current focus:** "No shortcuts" hardening: **explicit leasing in pending + fully append-only attempts ledger**.
* **Security posture:** Database is the source of truth; application must not bypass DB contracts.

---

## 2) Goals (MVP + Non-goals)

### MVP Goals

* Enforce **scoped DB roles** via `libs/db` only (no raw `SET ROLE` usage elsewhere).
* Maintain **append-only audit semantics** for `payment_outbox_attempts`:

  * INSERT-only for runtime roles
  * UPDATE/DELETE forbidden and provably blocked (SQLSTATE `P0001`)
* Implement outbox with **explicit leasing** (no delete-on-claim):

  * `payment_outbox_pending` holds lease fields (`claimed_by`, `lease_token`, `lease_expires_at`)
  * Lease expiry is authoritative for repair/requeue
* Provide **DB-authoritative attempt numbering**:

  * `attempt_no = MAX(attempt_no)+1` derived from attempts history
  * `attempt_count` is non-authoritative cache updated via `GREATEST(...)`
* Add proof tests:

  * Lease repair appends `ZOMBIE_REQUEUE`
  * Stale worker completion fails deterministically (`LEASE_LOST`)
  * Concurrent enqueue is idempotent
  * Terminal outcome uniqueness enforced (partial unique index)

### Non-goals

* Legacy compatibility paths / dual-path migration (explicitly disallowed)
* Full production deployment tooling / migrations runner (**UNKNOWN**)
* Full UI dashboards (views/logs only)
* Full auth/RBAC product flows beyond DB role discipline

---

## 3) Current Status

* **DB role discipline (Phase 3) completed:**

  * All production DB calls go through `libs/db`
  * No global mutable DB role
  * Guardrails enforced in CI
  * `libs/db/testOnly.ts` provides `queryNoRole` gated by `NODE_ENV=test`
* **Outbox schema exists (Option 2A baseline):**

  * `payment_outbox_pending` hot queue
  * `payment_outbox_attempts` append-only ledger (trigger proof)
  * `participant_outbox_sequences` allocator table
  * `enqueue_payment_outbox(...)` function exists (SECURITY DEFINER)
* **Identified correctness bug (must be removed):**

  * Old delete-on-claim + DISPATCHING attempt insertion caused duplicate `(outbox_id, attempt_no)` on outcome insert
* **Next architecture (deep surgery, no legacy):**

  * Replace delete-on-claim with **lease-in-pending**
  * Remove DISPATCHING attempt insertion
  * Implement DB functions:

    * `claim_outbox_batch(...)`
    * `complete_outbox_attempt(...)`
    * `repair_expired_leases(...)` (replaces ZombieRepair logic)

---

## 4) Tech Stack

* **Runtime:** Node.js (TypeScript, ESM imports)
* **Database:** PostgreSQL
* **DB driver:** `pg` (Pool/PoolClient)
* **Testing:** `node:test` + `node:assert`
* **Validation:** zod middleware (identity envelope validation)
* **Context propagation:** AsyncLocalStorage (`RequestContext.run(...)`)
* **Logging:** structured logging (`pino`)
* **Security:** mTLS/CA cert support via `DB_CA_CERT`

---

## 5) Architecture Summary

### Services

* `control-plane` (admin/config operations)
* `ingest-api` (enqueue producer path)
* `read-api` (readonly queries)
* `executor-worker` (dispatch + lease repair)

### DB Access Discipline

* Centralized in `libs/db`:

  * `queryAsRole(role, sql, params?)`
  * `transactionAsRole(role, cb)` using `SET LOCAL ROLE`
  * `listenAsRole(role, channel, handler)`
  * Nested transaction protection via AsyncLocalStorage
  * Role verified via `SELECT current_user`
  * Always `RESET ROLE`; tainted client is destroyed if reset fails
* Test-only privileged access:

  * `libs/db/testOnly.ts` exports `queryNoRole` (throws unless `NODE_ENV=test`)

### Outbox Model (Target: Lease-in-Pending + Append-only Attempts)

* **Pending (`payment_outbox_pending`)**

  * Contains durable queue identity + scheduling (`next_attempt_at`)
  * Contains lease fields:

    * `claimed_by`, `lease_token`, `lease_expires_at`
* **Attempts (`payment_outbox_attempts`)**

  * Append-only ledger of outcomes/events
  * `UNIQUE(outbox_id, attempt_no)`
  * Trigger blocks UPDATE/DELETE (SQLSTATE `P0001`)
  * States: `DISPATCHING`, `DISPATCHED`, `RETRYABLE`, `FAILED`, `ZOMBIE_REQUEUE`
  * Terminal: `DISPATCHED`, `FAILED`
* **Functions**

  * `enqueue_payment_outbox(...)` (SECURITY DEFINER, idempotent by `(instruction_id, idempotency_key)`)
  * Planned:

    * `claim_outbox_batch(batch_size, worker_id, lease_seconds)`
    * `complete_outbox_attempt(outbox_id, lease_token, worker_id, state, ...)`
    * `repair_expired_leases(batch_size, worker_id)`
* **Terminal uniqueness hard guard**

  * Partial unique index:

    * `UNIQUE(outbox_id) WHERE state IN ('DISPATCHED','FAILED')`

---

## 6) Repo Layout (make best guess if unknown)

* `libs/`

  * `libs/db/`

    * `index.ts` (role-scoped DB API)
    * `roles.ts` (DbRole enum + validation)
    * `pool.ts` (pg Pool setup)
    * `testOnly.ts` (queryNoRole; NODE_ENV=test only)
  * `libs/outbox/`

    * `OutboxRelayer.ts` (claim + dispatch + complete)
  * `libs/repair/`

    * `ZombieRepairWorker.ts` (to be replaced by lease repair worker)
  * `libs/logging/` (pino logger)
  * `libs/context/` (AsyncLocalStorage request context)
* `services/`

  * `services/control-plane/src/index.ts`
  * `services/ingest-api/src/index.ts`
  * `services/read-api/src/index.ts`
  * `services/executor-worker/src/index.ts`
* `schema/`

  * `schema/v1/011_payment_outbox.sql`
  * `schema/v1/011_privileges.sql`
  * `schema/views/outbox_status_view.sql` (or equivalent)
* `scripts/guardrails/`

  * `scripts/guardrails/db-role-guardrails.sh`
* `tests/`

  * `tests/unit/outboxPrivileges.spec.ts`
  * `tests/unit/outboxAppendOnlyTrigger.spec.ts`
  * `tests/unit/zombieRepairProof.spec.ts` (to be replaced by lease repair proof)
  * `tests/integration/*` (**planned**)

---

## 7) Development Setup (commands + env vars; mark unknowns clearly)

### Required env vars

* `DATABASE_URL` (tests derive DB settings)
* `DB_HOST`
* `DB_PORT`
* `DB_USER`
* `DB_PASSWORD`
* `DB_NAME`
* `NODE_ENV` (`test` required for `queryNoRole`)
* `DB_CA_CERT` (required in prod/staging)
* `DB_SSL_QUERY` (`true|false`; `false` forbidden in prod/staging)
* `ZOMBIE_THRESHOLD_SECONDS` (legacy; to be replaced by lease-based repair) (**to remove/replace**)

### Commands

* Run guardrails:

  * `ENFORCE_NO_DB_QUERY=1 scripts/guardrails/db-role-guardrails.sh`
* Run tests (UNKNOWN exact package manager):

  * `DATABASE_URL=... NODE_ENV=test UNKNOWN test`
* Run single test (guess):

  * `DATABASE_URL=... NODE_ENV=test node --test tests/unit/outboxPrivileges.spec.ts`

### Unknowns

* Package manager: `npm` / `pnpm` / `yarn` (**UNKNOWN**)
* Canonical test script in `package.json` (**UNKNOWN**)
* Migration runner / how `schema/v1/*.sql` is applied (**UNKNOWN**)

---

## 8) Product Requirements (Behavior)

### Enqueue

* Must use DB function only:

  * `enqueue_payment_outbox(p_instruction_id, p_participant_id, p_idempotency_key, p_rail_type, p_payload)`
* Idempotent by `(instruction_id, idempotency_key)`
* Deterministic under concurrency (advisory lock + unique fallback)

### Pending + Leasing

* Claimable iff:

  * `next_attempt_at <= now()` AND lease is absent/expired
* Claim uses:

  * set-based selection + `FOR UPDATE SKIP LOCKED`
  * sets `claimed_by`, `lease_token`, `lease_expires_at`
* Completion requires matching lease token; stale worker must fail with deterministic SQLSTATE (`LEASE_LOST`)

### Attempts

* Append-only ledger:

  * INSERT-only
  * UPDATE/DELETE forbidden (trigger raises `P0001`)
* Attempt numbering:

  * derived from attempts history (`MAX(attempt_no)+1`)
  * uniqueness enforced by `(outbox_id, attempt_no)`
* Terminal uniqueness:

  * at most one terminal outcome (`DISPATCHED` or `FAILED`) per outbox_id (partial unique index)

### Lease Repair (replaces zombie repair)

* Finds expired leases in pending and repairs them:

  * clears lease fields
  * reschedules `next_attempt_at`
  * appends `ZOMBIE_REQUEUE` attempt with `attempt_no = last + 1`
  * updates `attempt_count = GREATEST(existing, new_attempt_no)`

---

## 9) Important Decisions (and why)

* **DB-authoritative correctness:** invariants enforced in Postgres (not app best-effort).
* **Append-only attempts ledger:** audit-grade proof; prevents history rewriting.
* **Explicit leasing in pending:** avoids delete-on-claim ambiguity; makes "in-flight" state explicit and repair deterministic.
* **Lease token enforcement:** prevents stale workers from completing after lease loss (zombie safety).
* **Role scoping per call:** prevents pooled connection role leakage.
* **Terminal uniqueness partial index:** prevents ledger disaster (DISPATCHED + FAILED) even under concurrency bugs.

---

## 10) Conventions (MUST follow)

* No raw `SET ROLE`, `RESET ROLE`, `SET LOCAL ROLE` outside `libs/db`.
* No raw `pg` usage outside `libs/db` (except `libs/db/testOnly.ts`).
* All production DB calls must include explicit `DbRole`.
* `transactionAsRole` must use `SET LOCAL ROLE`.
* Always `RESET ROLE` before releasing pooled clients; destroy tainted clients.
* `payment_outbox_attempts` must remain INSERT-only for runtime roles.
* Repair must be **lease-based** (no stale DISPATCHING inference).
* SQLSTATE assertions in tests:

  * privileges: `42501`
  * append-only trigger: `P0001`
  * lease lost: `P7002` (planned)

---

## 11) "Do Not Break" Contract

* `libs/db/index.ts` remains the only production DB entrypoint.
* `libs/db/testOnly.ts` must throw unless `NODE_ENV=test`.
* Outbox invariants:

  * `UNIQUE(outbox_id, attempt_no)`
  * `payment_outbox_pending` uniqueness:

    * `(participant_id, sequence_id)`
    * `(instruction_id, idempotency_key)`
  * attempts append-only enforced by trigger
  * attempt numbering derived from attempts history
  * `attempt_count` monotonic cache via `GREATEST(...)`
* No delete-on-claim pattern; pending must not be removed to lease work.
* No DISPATCHING attempt insertion (inflight state is pending lease fields).

---

## 12) Open Questions / TODO

* **UNKNOWN:** What is the canonical package manager and test command in `package.json`?
* **UNKNOWN:** What is the migration runner / command used to apply `schema/v1/*.sql`?
* Confirm whether `symphony_auth` role exists/needed (exclude unless required).
* Implement and GRANT:

  * `claim_outbox_batch(...)`
  * `complete_outbox_attempt(...)`
  * `repair_expired_leases(...)`
* Add lease columns + indexes to `payment_outbox_pending`.
* Add terminal uniqueness partial index:

  * `payment_outbox_attempts_one_terminal_per_outbox`
* Replace ZombieRepairWorker with lease repair worker + proof tests.
* Update supervisor views to lease-aware operational truth.
* Add integration proofs:

  * enqueue concurrency idempotency
  * stale worker cannot complete after lease loss
  * concurrent completion safety

---

## 13) AI Working Rules (Cursor)

* Prefer DB-enforced invariants over application-side logic.
* No legacy compatibility shims; delete old paths entirely.
* Keep attempts ledger fully append-only (INSERT-only).
* Leasing must be explicit and DB-authoritative (pending lease columns + lease token).
* Keep changes minimal per PR, but bottom-up:

  * schema -> functions -> privileges -> libs/db -> workers -> tests -> views
* Add tests for every invariant; assert SQLSTATEs deterministically.
* If something is UNKNOWN, mark it and add to TODO.

---

## 14) Quick Commands Cheat Sheet

* Guardrails:

  * `ENFORCE_NO_DB_QUERY=1 scripts/guardrails/db-role-guardrails.sh`
* Run tests (guess):

  * `DATABASE_URL=... NODE_ENV=test UNKNOWN test`
* Run single test (guess):

  * `DATABASE_URL=... NODE_ENV=test node --test tests/unit/outboxPrivileges.spec.ts`
* Enqueue function signature:

  * `enqueue_payment_outbox(instruction_id, participant_id, idempotency_key, rail_type, payload)`
