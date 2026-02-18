# Phase 1: DB Foundation (DB-MIG + Outbox + Boot Policy Table)

## Goal
Establish the minimal production-grade database substrate:
- Forward-only migrations with ledger
- Outbox tables + lease-fencing functions
- Roles + least privilege posture (function-first)
- Boot-critical policy table exists and is query-compatible with runtime
- **No runtime DDL** (PUBLIC has no CREATE on schema public)

---

## Scope

### Database

#### Migrations 0001–0005
| Migration | Contents |
|-----------|----------|
| `0001_init.sql` | Extensions, UUID wrapper, outbox tables |
| `0002_outbox_functions.sql` | enqueue, claim, complete, repair functions |
| `0003_roles.sql` | Role definitions (NOLOGIN + test_user LOGIN) |
| `0004_privileges.sql` | Deny-by-default, function-first grants, Option A |
| `0005_policy_versions.sql` | Boot-critical policy table (future-proof for grace) |

#### Outbox Tables
- `payment_outbox_pending` - Hot queue for dispatch
- `payment_outbox_attempts` - Append-only attempt ledger
- `participant_outbox_sequences` - Monotonic sequence allocator

#### Outbox Functions
- `enqueue_payment_outbox()` - Idempotent enqueue
- `claim_outbox_batch()` - Lease-based claiming
- `complete_outbox_attempt()` - Terminal state recording
- `repair_expired_leases()` - Zombie requeue

#### Roles
| Role | Type | Purpose |
|------|------|---------|
| `symphony_ingest` | NOLOGIN | Payment ingestion |
| `symphony_executor` | NOLOGIN | Outbox processing |
| `symphony_readonly` | NOLOGIN | Read-only access |
| `symphony_auditor` | NOLOGIN | Audit log access |
| `symphony_control` | NOLOGIN | Admin operations |
| `test_user` | LOGIN | Test harness (password set outside migrations) |

#### Privileges
- **Deny-by-default**: REVOKE ALL before granting
- **Function-first**: Runtime roles access tables via SECURITY DEFINER functions
- **Option A**: `symphony_control` has NO UPDATE/DELETE/TRUNCATE on `payment_outbox_attempts`
- **No runtime DDL**: PUBLIC has no CREATE on schema public

#### Policy Bootstrap Support
- `policy_versions` table with future-proof schema (status enum + grace support)
- `is_active` as GENERATED STORED column for runtime boot query compatibility
- **Checksum required**: Integrity binding to policy content (NOT NULL)
- SELECT granted to `symphony_executor` (boot check)
- **Boot query compatibility**: `SELECT version FROM policy_versions WHERE is_active = true` must execute
- **If no ACTIVE policy exists, startup MUST fail.**

### Seeding (NOT in migrations)
- Seed mechanism reads pinned policy version and inserts ACTIVE row
- Must NOT read local files in migrations
- Must be idempotent
- **Seed must not mutate existing ACTIVE rows unless explicitly instructed** (control-plane rotation handles changes)
- Options:
  - `schema/seeds/dev/seed_policy_from_file.sh` (dev)
  - `schema/seeds/ci/seed_policy_from_env.sh` (CI)

---

## Non-goals
- Policy rotation/grace semantics (Phase 2+)
- Attestation tables
- Ledger posting tables

---

## Deliverables

### 1. Migration: `0005_policy_versions.sql`
Uses the future-proof DDL with **required checksum**:

```sql
-- Status enum supports future rotation with grace:
-- ACTIVE -> GRACE -> RETIRED
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'policy_version_status') THEN
    CREATE TYPE policy_version_status AS ENUM ('ACTIVE', 'GRACE', 'RETIRED');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.policy_versions (
  version TEXT PRIMARY KEY,

  status policy_version_status NOT NULL DEFAULT 'ACTIVE',
  activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  grace_expires_at TIMESTAMPTZ,

  -- Integrity binding to policy content (REQUIRED, no lying policy rows)
  checksum TEXT NOT NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Compatibility with current runtime check:
  -- SELECT version FROM policy_versions WHERE is_active = true
  is_active BOOLEAN GENERATED ALWAYS AS (status = 'ACTIVE') STORED,

  CONSTRAINT ck_policy_checksum_nonempty CHECK (length(checksum) > 0),
  CONSTRAINT ck_policy_grace_requires_expiry
    CHECK (status <> 'GRACE' OR grace_expires_at IS NOT NULL),
  CONSTRAINT ck_policy_active_has_no_grace_expiry
    CHECK (status <> 'ACTIVE' OR grace_expires_at IS NULL)
);

COMMENT ON TABLE public.policy_versions IS
  'Boot-critical policy version ledger. Current runtime expects is_active=true row; future supports rotation with GRACE.';

-- Enforce exactly one ACTIVE policy row (per DB).
CREATE UNIQUE INDEX IF NOT EXISTS ux_policy_versions_single_active
  ON public.policy_versions ((1))
  WHERE status = 'ACTIVE';

-- Helpful lookup for boot checks
CREATE INDEX IF NOT EXISTS idx_policy_versions_is_active
  ON public.policy_versions (is_active)
  WHERE is_active = true;
```

### 2. Updated `0004_privileges.sql`
- Add policy_versions grants (SELECT for boot roles)
- Enforce Option A: no UPDATE/DELETE/TRUNCATE on attempts for control

### 3. CI Invariant Gate Updates
Add checks to `scripts/db/ci_invariant_gate.sql`:
- [x] `policy_versions` table exists
- [x] `policy_versions.is_active` column exists (boot query compatibility)
- [x] `policy_versions.checksum` is NOT NULL (and non-empty via constraint)
- [x] Boot query executes: `SELECT 1 FROM policy_versions WHERE is_active = true LIMIT 1`
- [x] PUBLIC has no CREATE on public schema
- [x] `symphony_control` has no UPDATE/DELETE/TRUNCATE on attempts
- [x] Append-only trigger exists and is enabled

### 4. Seed Helpers
- `schema/seeds/dev/seed_policy_from_file.sh` ✅ (exists)
- `schema/seeds/ci/seed_policy_from_env.sh` ✅ (exists)

### 5. Operational Rules (DOCUMENTED)

> **Docker/CI must run seed step before services boot.**
>
> If no ACTIVE policy exists, startup MUST fail. Empty `policy_versions` table → fail closed.

> **Seed must be idempotent and safe.**
>
> Seed must not mutate existing ACTIVE rows unless explicitly instructed. Control-plane rotation handles policy changes.

### 6. Smoke Tests
- Can migrate fresh DB
- Can run boot query without missing relations/columns

---

## Acceptance Criteria
1. Docker runtime no longer fails with `relation "policy_versions" does not exist`
2. Boot query `SELECT version FROM policy_versions WHERE is_active = true` executes
3. CI gate passes on fresh DB after migrations + seed step
4. `verify_invariants.sh` passes

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `policy_versions` exists but not seeded | Boot fails closed | Expected behavior; seed step must run |
| Baseline drift | Schema inconsistency | CI enforces baseline freshness or removes baseline helper |

---

## Notes
- Keep policy rotation/grace in `INVARIANTS_ROADMAP.md` until implemented
- Keep tenant model out of Phase 1 unless required by boot paths
- `is_active` is a GENERATED STORED column for backward compatibility; new code should use `status`
- Checksum is required from Phase 1 to prevent "lying policy rows" backfill problem
