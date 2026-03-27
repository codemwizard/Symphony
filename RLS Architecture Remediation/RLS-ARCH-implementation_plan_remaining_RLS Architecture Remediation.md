# RLS-ARCH Remaining Phases Implementation Plan

**Phase Name:** RLS Architecture Remediation  
**Phase Key:** RLS-ARCH

---

## Pre_ci Failure Analysis

> [!IMPORTANT]
> `pre_ci.sh` fails at **DB/environment layer** (`PRECI.DB.ENVIRONMENT`), NOT at the RLS lint gate. The RLS lint gate now passes (0 violations, 10 GF files).

**Root cause chain:**
1. `pre_ci.sh` creates an **ephemeral fresh DB** (`FRESH_DB=1`)
2. Runs `scripts/db/migrate.sh` to apply all migrations from scratch
3. Migration `0081_gf_interpretation_packs.sql:46` has a **syntax error** (`WHERE` clause issue)
4. All subsequent migrations including 0095 fail to apply
5. DB verification gates fail because the ephemeral DB is incomplete

**What's needed to fix:** Fix the SQL syntax error in `0081_gf_interpretation_packs.sql`. This is a pre-existing bug unrelated to our RLS changes. Once fixed, the ephemeral DB will successfully apply all migrations through 0095, and the DB verification gates should pass.

---

## Proposed Changes

### Phase 3 — Lint Gates (3.1–3.6)

**What exists:**
- `scripts/db/lint_rls_born_secure.py` — lints GF migration SQL files (single PERMISSIVE policy pattern)
- `tests/rls_born_secure/run_tests.py` — 11 adversarial test fixtures, all pass
- `scripts/db/lint_rls_born_secure.sh` — bash wrapper (fixed to auto-discover)

**What's missing:** The existing linter covers GF tables (single-policy pattern). Phase 3 requires lint gates for the **0095 dual-policy architecture** (PERMISSIVE + RESTRICTIVE per table). These are different patterns.

#### [NEW] `scripts/db/lint_rls_0095_dual_policy.sh`
- **3.1** YAML↔DB parity: verify `rls_tables.yml` entries match `_rls_table_config`
- **3.2** No manual policy creation: grep new migration files for `CREATE POLICY` outside 0095
- **3.3** No direct `SET app.current_tenant_id`: grep source code for raw GUC manipulation
- **3.4** USING/WC parity: verify all `rls_iso_*` policies have matching USING and WITH CHECK (already tested by T18, but needs standalone lint)
- **3.5** DEFINER gate: verify tenant functions are `SECURITY DEFINER` with hardened `search_path`

#### [NEW] `tests/rls_0095/run_lint_tests.sh`
- **3.6** 13 lint test cases for the dual-policy architecture

---

### Phase 4 — Runtime Verifiers (4.3–4.5)

**What exists:**
- `scripts/audit/verify_gf_rls_runtime.sh` — GF-specific runtime verifier (16 tables)
- `verify_migration_bootstrap.sh` — 9 post-migration checks (4.1, 4.2 covered)
- `test_rls_dual_policy_access.sh` — 21 adversarial tests including structural validation

**What's missing:**

#### [NEW] `scripts/db/verify_rls_0095_runtime.sh`
- **4.3** FK integrity: verify no cross-tenant FK references exist (`parent.tenant_id != child.tenant_id`)
- **4.4** GUC leakage: verify `app.current_tenant_id` is not set outside transaction boundaries
- **4.5** Role audit: verify no role except admin has `BYPASSRLS` attribute

---

### Phase 7 — Admin Access (7.1–7.2)

#### [MODIFY] `schema/migrations/0095_rls_dual_policy_architecture.sql`
- **7.1** Set `OWNER TO` on tenant functions to a non-superuser role
- **7.2** 4-layer governance: document and enforce function ownership chain

> [!WARNING]
> Phase 7 modifies the deployed migration. This requires either a new migration (0096) or appending to 0095 with a guard. Recommend a new migration 0096 for clean separation.

---

### Phase 0.9 — Evidence Freeze

#### [NEW] `scripts/db/freeze_rls_evidence.sh`
- Capture all Phase 0 artifacts (pre-snapshot, fingerprints, config dump) into `evidence/phase1/`
- Generate evidence JSON with schema fingerprint and timestamp

---

## Implementation Order

1. **Phase 3** — Lint gates (standalone, no DB required)
2. **Phase 4** — Runtime verifiers (requires DB connection)  
3. **Phase 0.9** — Evidence freeze (requires DB connection)
4. **Phase 7** — Admin access (new migration, requires DB + design decision)

## Verification Plan

### Automated Tests
- `scripts/db/lint_rls_0095_dual_policy.sh` — standalone lint, no DB needed
- `tests/rls_0095/run_lint_tests.sh` — lint test fixtures
- `scripts/db/verify_rls_0095_runtime.sh` — runtime verification against live DB
- `scripts/db/freeze_rls_evidence.sh` — evidence generation
- `pre_ci.sh` — full pipeline (after 0081 fix)

### DB Tests
- All Phase 4 verifiers run against `localhost:55432`
- Non-superuser role `rls_test_user` for access tests
