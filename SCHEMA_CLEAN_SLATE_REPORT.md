# Schema Clean-Slate Report: Legacy Removal + Rebuild Strategy

## Summary
The current schema sequence (`schema/v1/*.sql`) is **not idempotent** and fails when re-applied on an existing database because many migrations use `CREATE TABLE`/`CREATE TYPE` without `IF NOT EXISTS` guards or explicit replace logic. This blocks consistent rebuilding and makes it difficult to guarantee that legacy paths are fully removed.

## What failed and why
Running the full sequence against an existing DB produced multiple “already exists” errors, e.g.:
- `001_core_entities.sql`: `relation "clients" already exists`
- `002_orchestration.sql`: `relation "routes" already exists`
- `003_instructions.sql`: `relation "instructions" already exists`
- `004_transaction_attempts.sql`: `relation "transaction_attempts" already exists`
- `005_status_history.sql`: `relation "status_history" already exists`
- `006_provider_health.sql`: `relation "provider_health_snapshots" already exists`
- `007_audit_log.sql`: `relation "audit_log" already exists`
- `008_event_outbox.sql`: `relation "event_outbox" already exists`
- `011_policy_profiles.sql`: `relation "policy_profiles" already exists`
- `012_participants.sql`: `type "participant_role" already exists`
- `014_execution_attempts.sql`: `relation "execution_attempts" already exists`
- `016_ledger_entries.sql`: `relation "ledger_entries" already exists`
- `017_account_balances_view.sql`: `relation "account_balances" already exists`

These are not “safe to ignore” because they stop the schema apply mid-stream and leave the DB in an undefined state.

## Root cause
The schema was designed as **one-time migrations** rather than **idempotent rebuildable DDL**. That is fine for incremental upgrades, but it conflicts with the requirement to **eliminate legacy paths** and **rebuild the schema cleanly**.

## Clean‑slate approach (recommended)
If the goal is to eliminate legacy paths and make the schema rebuildable on demand, the schema should be **rewritten as a single canonical baseline** (or a clearly ordered baseline set) that is safe to apply to an empty database.

### Strategy A — New “baseline schema” file (recommended)
Create a new top‑level file (example: `schema/v1/999_baseline.sql`) that:
- Drops/replaces all legacy objects explicitly.
- Creates all tables, types, functions, triggers, and views in a consistent order.
- Includes required dependency guards (e.g., Postgres version check, `uuidv7()` availability).
- Is designed to be applied to a **fresh database only**.

Then change deployment/bootstrap to:
1) Recreate DB (or drop and recreate schema).
2) Apply **only** the baseline file.

### Strategy B — Full idempotent rewrite
Rewrite each existing `schema/v1/*.sql` to be idempotent:
- Use `CREATE TABLE IF NOT EXISTS`, `CREATE TYPE IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`.
- Add explicit `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` and `DO $$` guards.
- For `CREATE VIEW`, use `CREATE OR REPLACE VIEW`.
- For functions, always use `CREATE OR REPLACE FUNCTION`.

This enables reapplying the full sequence safely, but it requires careful auditing of all side effects.

## Clean‑slate rewrite checklist (detailed)

### 1) Dependency bootstrapping
- `000_require_postgres_18.sql` (already added)
- Ensure `uuidv7()` availability before any table/function references

### 2) Types and core tables
- Define all enum types in one place with `IF NOT EXISTS`
- Core tables (clients, participants, instructions, ledger, etc.)
- Ensure foreign keys are ordered correctly (create referenced tables first)

### 3) Outbox model (lease‑in‑pending)
- `payment_outbox_pending` (with lease columns)
- `payment_outbox_attempts` (append‑only)
- Functions: `enqueue_payment_outbox`, `claim_outbox_batch`, `complete_outbox_attempt`, `repair_expired_leases`
- Triggers: `deny_outbox_attempts_mutation`, `notify_outbox_pending`

### 4) Views and supervisor reporting
- Lease‑aware views only (no DISPATCHING derived metrics)
- `CREATE OR REPLACE VIEW` to allow reapply

### 5) Privileges
- Centralize grants in a single file that can be re‑run
- Ensure revokes happen before grants

### 6) Seed data
- Make seed scripts idempotent (UPSERTs / `ON CONFLICT DO NOTHING`)

## Proposed clean‑slate process
1) **Rebuild DB**:
   - `docker compose down -v`
   - `docker compose up -d db`
2) **Apply baseline** (new or rewritten):
   - `psql -f schema/v1/999_baseline.sql`
3) **Validate**:
   - Run DB‑gated integration tests
   - Run outbox proofs
   - Generate evidence bundle

## Decision points
- Do you want a single baseline file (Strategy A), or rewrite the existing sequence (Strategy B)?
- Are we allowed to drop/recreate the DB in environments outside local/dev?

## Recommendation
For the “remove legacy paths” requirement, Strategy A is the most deterministic and least risky: one clean baseline schema that is known to represent the authoritative model, applied only to a fresh DB. Strategy B is more work and still risks partial failures if any file remains non‑idempotent.

---

# Authoritative Plan: Clean-Slate Baseline DB (No Legacy Preservation)

## Objective
Make the database lifecycle **reset → apply baseline → verify** the only supported path. The schema should never be applied incrementally onto an existing database state.

## Non-goals
- Preserving any legacy DB objects or data
- Supporting re-apply of `schema/v1/*.sql` on an existing DB
- Migration shims / dual-path compatibility

---

## Phase 0 — Declare the contract in-repo (so nobody “migrates” again)

### Task 0.1 — Add a short contract doc

**File:** `schema/BASELINE.md`

Include:
- “Schema is baseline-only; do not run v1 migrations onto an existing DB.”
- “All environments may be reset. Staging will be rebuilt from baseline.”
- “The only supported entrypoints are the reset/apply scripts.”

**DoD:** A contributor can’t miss the rule.

---

## Phase 1 — Create a single baseline entrypoint (source of truth)

### Task 1.1 — Add the baseline file

**File:** `schema/baseline.sql`

This file should:
1. Verify Postgres version (PG18+).
2. Create extensions / prerequisites if any (only if needed).
3. Define **types → tables → indexes → functions → triggers → views → grants → seed** in strict order.
4. Use `CREATE OR REPLACE FUNCTION` for functions and `CREATE OR REPLACE VIEW` for views.
5. Avoid `IF NOT EXISTS` everywhere except where it’s genuinely harmless (extensions).

**Important:** This is designed for a **fresh DB**. It does not need to be idempotent against an existing DB because we will always reset first.

**DoD:** `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f schema/baseline.sql` succeeds on a fresh DB.

### Task 1.2 — Stop treating `schema/v1/*.sql` as the thing to apply

You have two good options (pick one and enforce it):

**Option A (recommended):**
- Keep `schema/v1/` for historical reference only.
- CI/dev/staging apply **only** `schema/baseline.sql`.

**Option B:**
- Delete `schema/v1/` entirely after baseline lands (hard cut, no confusion).

**DoD:** There is exactly one authoritative schema apply path.

---

## Phase 2 — Authoritative reset + apply scripts

### Task 2.1 — Add a hard reset script (schema-level reset)

**File:** `scripts/db/reset_db.sh`

Behavior:
- Connect to DB
- `DROP SCHEMA public CASCADE;`
- `CREATE SCHEMA public;`
- Restore minimal grants needed for your roles (or do all grants in baseline)
- Then apply baseline

This is safer than “drop database” and works in most managed DBs.

**DoD:** Running `scripts/db/reset_db.sh` twice yields the same clean state.

### Task 2.2 — Add “apply baseline only” script

**File:** `scripts/db/apply_baseline.sh`

Behavior:
- Runs `psql ... -f schema/baseline.sql`

**DoD:** CI and dev both use these scripts, not ad-hoc loops.

---

## Phase 3 — Make CI enforce the baseline contract

Your current CI step applies all `schema/v1/*.sql` in a loop. That’s the opposite of your new contract.

### Task 3.1 — Update CI schema step

**File:** `.github/workflows/ci-security.yml`

Replace:
- loop over `schema/v1/*.sql`

With:
- `scripts/db/reset_db.sh` (or: drop schema + apply baseline inlined)
- or at minimum `psql ... -f schema/baseline.sql` after ensuring the DB is clean

**DoD:** CI uses the same baseline path as humans.

### Task 3.2 — Keep the existing gates intact

- Unit tests
- Integration tests (DB-gated)
- DISPATCHING regression query
- Evidence bundle + outbox evidence (always)

These stay; the only change is “how schema is applied.”

**DoD:** No regression in CI gates; baseline is the only DB foundation.

---

## Phase 4 — Make dev experience “one command”

### Task 4.1 — Add npm scripts

**File:** `package.json`

Add:
- `db:reset` → `scripts/db/reset_db.sh`
- `db:apply` → `scripts/db/apply_baseline.sh`
- `test:db` → reset + apply + run DB-gated tests

**DoD:** Nobody needs to remember `psql` incantations.

---

## Phase 5 — Staging alignment

### Task 5.1 — “Rebuild staging from baseline” runbook

**File:** `docs/runbooks/staging-rebuild.md`

Include:
- backup policy (if any; but baseline implies no legacy)
- reset method (schema drop or recreate database)
- apply baseline
- run proofs
- generate evidence

**DoD:** Staging rebuild is routine, deterministic, and auditable.

---

# Final “Authoritative” Definition of Done

- There is **one** canonical schema file: `schema/baseline.sql`.
- The only supported workflows are:
  - `scripts/db/reset_db.sh`
  - `scripts/db/apply_baseline.sh`
- CI applies the baseline (not a v1 migration chain).
- All DB-gated proof tests pass from a fresh baseline.
- Outbox evidence + global evidence artifacts still generate with `if: always()`.

---

## What I need next to make this concrete

If you want, share a fresh repo zip (or keep it available) and I will:
- produce the exact file list + ordering for `schema/baseline.sql`
- propose the exact diff for `.github/workflows/ci-security.yml`
- draft `reset_db.sh` + `apply_baseline.sh` tailored to your roles/grants
