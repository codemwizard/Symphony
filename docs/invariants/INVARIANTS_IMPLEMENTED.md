# Symphony Invariants (Implemented + Enforced)

This document lists invariants that are enforced **today** (via DB constraints/triggers/functions and/or CI/lint gates).
If an invariant is not mechanically enforced, it does **not** belong here.

Severity:
- **P0 MUST**: CI must fail if violated
- **P1 SHOULD**: strong preference; CI does not (yet) fail unless explicitly stated

**Change rule (P0):** If you change behavior touching an invariant, the same PR MUST:
1) update invariants docs
2) update enforcement (SQL/constraints/triggers/functions/scripts)
3) update verification (CI gate / tests / lint)

**Verification entrypoint:** `scripts/db/verify_invariants.sh`

---

## DB-MIG (Migrations + Ledger)

### I-MIG-02 (P0) Schema migration ledger immutability (checksum)
**Rule:** Applied migrations are immutable; checksum mismatch MUST fail.  
**Enforced by:** `public.schema_migrations` + `scripts/db/migrate.sh`.  
**Verified by:** `scripts/db/verify_invariants.sh` (applies migrations and fails on checksum mismatch).

### I-MIG-03 (P0) Runner-managed transactions per migration
**Rule:** Migration runner wraps each migration in a transaction; migration files MUST NOT contain top-level `BEGIN;` or `COMMIT;`.  
**Enforced by:** `scripts/db/migrate.sh` + `scripts/db/lint_migrations.sh`.  
**Verified by:** `scripts/db/verify_invariants.sh` lint.

---

## Security + Privileges

### I-SEC-01 (P0) Function-first runtime access
**Rule:** Runtime roles must not have direct DML on core tables; they use SECURITY DEFINER DB APIs.  
**Enforced by:** revoke-first + explicit grants in `schema/migrations/0004_privileges.sql`.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (PUBLIC posture + attempts override posture).

### I-SEC-02 (P0) SECURITY DEFINER search_path hardening
**Rule:** Every SECURITY DEFINER function MUST set `search_path = pg_catalog, public`.  
**Enforced by:** function definitions in migrations.  
**Verified by:** `scripts/db/lint_search_path.sh` (called by `verify_invariants.sh`).

### I-SEC-03 (P0) No runtime DDL
**Rule:** PUBLIC and runtime roles must not have `CREATE` on schema `public` (no runtime DDL).  
**Enforced by:** schema hardening + absence of CREATE grants in migrations.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (ACL-based check for PUBLIC + has_schema_privilege for runtime roles).

### I-SEC-04 (P0) No default PUBLIC privileges on core tables
**Rule:** PUBLIC must not have privileges on core tables.  
**Enforced by:** explicit `REVOKE ... FROM PUBLIC` for core tables.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (information_schema + ACL defense-in-depth checks).

---

## UUID

### I-UUID-01 (P0) Portable UUID generation
**Rule:** UUIDs use `public.uuid_v7_or_random()` chosen at migration-time (uuidv7 if present, else pgcrypto `gen_random_uuid()`).  
**Enforced by:** `schema/migrations/0001_init.sql`.  
**Verified by:** optional smoke query `SELECT public.uuid_strategy();`.

---

## Outbox substrate

### I-OUTBOX-01 (P0) Attempts are append-only (no overrides)
**Rule:** `payment_outbox_attempts` MUST never be UPDATE/DELETE’d by any role (Option A: **no override, period**).  
**Enforced by:** trigger `trg_deny_outbox_attempts_mutation` + privileges (including **no UPDATE/DELETE/TRUNCATE/TRIGGER for `symphony_control`**).  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (trigger present/enabled + grants check for `symphony_control`).

### I-OUTBOX-02 (P0) Idempotent enqueue
**Rule:** Enqueue is idempotent on `(instruction_id, idempotency_key)`; returns existing pending/attempt record if already present.  
**Enforced by:** unique constraint + `enqueue_payment_outbox()`.  
**Verified by:** schema constraints + function behavior (tests recommended).

### I-OUTBOX-03 (P0) Lease fencing
**Rule:** Completion only allowed when `(claimed_by, lease_token, lease_expires_at > now())` match.  
**Enforced by:** `complete_outbox_attempt()` lease checks.  
**Verified by:** function behavior (tests recommended).

### I-OUTBOX-04 (P0) Claim correctness
**Rule:** Claim only due rows and unleased/expired leases, using `FOR UPDATE SKIP LOCKED`.  
**Enforced by:** `claim_outbox_batch()` implementation.  
**Verified by:** function behavior (tests recommended).

### I-OUTBOX-05 (P0) Monotonic per-participant sequence allocation
**Rule:** Sequence IDs strictly increase per participant; allocation is atomic.  
**Enforced by:** `participant_outbox_sequences` + `bump_participant_outbox_seq()`.  
**Verified by:** function behavior (tests recommended).

### I-OUTBOX-06 (P0) Zombie repair appends evidence + requeues
**Rule:** Expired leases produce a `ZOMBIE_REQUEUE` attempt and clear lease deterministically.  
**Enforced by:** `repair_expired_leases()`.  
**Verified by:** function behavior (tests recommended).

### I-OUTBOX-07 (P0) Finite retry ceiling
**Rule:** Infinite retries are forbidden; retry ceiling is finite (default 20; configurable via GUC).  
**Enforced by:** `complete_outbox_attempt()` + `outbox_retry_ceiling()`.  
**Verified by:** function behavior (tests recommended).

---

## Policy (boot-critical)

### I-SCHEMA-BOOT-01 (P0) Boot schema coverage + query compatibility
**Rule:** Any relation/column referenced at service boot MUST exist after migrations on a fresh DB.  
**Enforced by:** CI invariant gate.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` checks required relations + `policy_versions.is_active` and executes the boot query shape.

### I-POLICY-BOOT-01 (P0) Policy table integrity binding (checksum required)
**Rule:** `policy_versions.checksum` MUST exist and be `NOT NULL` for every row (policy content is integrity-bound).  
**Enforced by:** `schema/migrations/0005_policy_versions.sql` + seed scripts refusing missing checksum.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (column exists + NOT NULL).

### I-POLICY-BOOT-02 (P0) Single ACTIVE policy row
**Rule:** The DB MUST enforce **at most one** `status = 'ACTIVE'` policy row.  
**Enforced by:** unique predicate index on `policy_versions` (unique on constant where status='ACTIVE').  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (index presence check).

### I-POLICY-BOOT-03 (P0) Grace scaffolding present (not behavior)
**Rule:** `policy_versions.status` column MUST exist (rotation/grace behavior is implemented later, but schema scaffolding is present now).  
**Enforced by:** `schema/migrations/0005_policy_versions.sql`.  
**Verified by:** `scripts/db/ci_invariant_gate.sql` (column presence check).
