# PLAN: TSK-P1-RLS-001 — Forward-fix missing RLS on regulatory_incidents

Status: planned
Phase: 1
Task: TSK-P1-RLS-001
Author: DB_FOUNDATION

---

## Objective

Migration 0059 dynamically enables RLS on all tables with tenant_id at the
time it runs. Migration 0060 creates `regulatory_incidents` with tenant_id
AFTER 0059 executed, so the bulk loop never covered it. This task:

1. Writes a forward-fix migration (0094) to enable+force RLS on `regulatory_incidents`
2. Updates the TEN-002 verifier to make pg_attribute the authoritative source
3. Produces fresh evidence with post-fix git_sha

---

## Pre-flight checks

- [ ] MIGRATION_HEAD = 0093
- [ ] `regulatory_incidents` exists with `tenant_id NOT NULL` (from migration 0060)
- [ ] `regulatory_incidents` has NO RLS currently (verify via pg_class)
- [ ] `current_tenant_id_or_null()` function exists (from migration 0059)

---

## Step 1 — Write migration 0094_rls_forward_fix_post_0059_tables.sql

File: `schema/migrations/0094_rls_forward_fix_post_0059_tables.sql`

### Content

```sql
-- TSK-P1-RLS-001: Forward-fix RLS on regulatory_incidents (missed by 0059 temporal gap)
-- regulatory_incidents was created in 0060 AFTER 0059's dynamic loop ran.

ALTER TABLE public.regulatory_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_incidents FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_regulatory_incidents
  ON public.regulatory_incidents
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());

-- Fail-closed assertion: confirm RLS took effect
DO $$
DECLARE
  v_rls_enabled  boolean;
  v_rls_forced   boolean;
BEGIN
  SELECT c.relrowsecurity, c.relforcerowsecurity
    INTO v_rls_enabled, v_rls_forced
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public'
     AND c.relname = 'regulatory_incidents';

  IF NOT v_rls_enabled THEN
    RAISE EXCEPTION 'ASSERTION FAILED: regulatory_incidents relrowsecurity is false'
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT v_rls_forced THEN
    RAISE EXCEPTION 'ASSERTION FAILED: regulatory_incidents relforcerowsecurity is false'
      USING ERRCODE = 'P0001';
  END IF;
END;
$$;
```

### Notes

- Uses `public.current_tenant_id_or_null()` — the exact canonical template
- Policy is `AS RESTRICTIVE` — matches 0059 convention
- DO block asserts RLS took effect — migration fails closed if not

### Post-step

- Update `MIGRATION_HEAD` to `0094`

---

## Step 2 — Add DDL-ALLOW entries

File: `docs/security/ddl_allowlist.json`

Add two entries after DDL-ALLOW-0061:

```json
{
  "id": "DDL-ALLOW-0062",
  "migration": "schema/migrations/0094_rls_forward_fix_post_0059_tables.sql",
  "statement_fingerprint": "<computed at implementation time>",
  "reason": "Forward-fix RLS enable on pre-existing table missed by migration 0059; pre-production, no production traffic, zero lock contention risk. This entry documents corrective action, not a security exemption.",
  "expires_on": "2027-01-01",
  "reviewed_by": "architect",
  "approved_at": "2026-03-23"
},
{
  "id": "DDL-ALLOW-0063",
  "migration": "schema/migrations/0094_rls_forward_fix_post_0059_tables.sql",
  "statement_fingerprint": "<computed at implementation time>",
  "reason": "Forward-fix RLS enable on pre-existing table missed by migration 0059; pre-production, no production traffic, zero lock contention risk. This entry documents corrective action, not a security exemption.",
  "expires_on": "2027-01-01",
  "reviewed_by": "architect",
  "approved_at": "2026-03-23"
}
```

Fingerprints must be computed using the same hashing method as `lint_ddl_lock_risk.sh`.

---

## Step 3 — Update verify_ten_002_rls_leakage.sh

File: `scripts/audit/verify_ten_002_rls_leakage.sh`

### Changes required

The verifier already queries pg_class/pg_attribute as its primary source (lines 25-34).
This is correct and authoritative. Surgical additions only:

1. **Add temporal scan as secondary cross-check** (after the main pg_class loop):
   - Scan migration files after 0059 for `CREATE TABLE` with `tenant_id`
   - Cross-reference against the pg_class results
   - If temporal scan finds table not in pg_class: add `temporal_scan_table_not_in_db:<table>`
   - This is WARN-level diagnostic, not a FAIL condition

2. **Ensure exit non-zero on any pg_class failure** (already the case — lines 254-258)

3. **No changes to the primary pg_class loop** — it is already authoritative

---

## Step 4 — Run negative tests

### N1: RLS blocks access without tenant context

```sql
-- As rls_tester role, no app.current_tenant_id set
SET ROLE rls_tester;
SELECT * FROM public.regulatory_incidents;
-- Must return 0 rows
RESET ROLE;
```

### N2: Verifier catches missing RLS before fix

```
# Before applying migration 0094:
bash scripts/audit/verify_ten_002_rls_leakage.sh
# Must exit non-zero with failure: rls_not_enabled:regulatory_incidents
```

### N3: Cross-tenant leakage blocked

```sql
-- Insert row as tenant_A, query as tenant_B
SET LOCAL app.current_tenant_id = '<tenant_b_uuid>';
SELECT * FROM public.regulatory_incidents WHERE tenant_id = '<tenant_a_uuid>';
-- Must return 0 rows
```

---

## Step 5 — Generate fresh evidence

```bash
# After applying migration 0094:
bash scripts/db/migrate.sh
bash scripts/audit/verify_ten_002_rls_leakage.sh
```

Evidence file: `evidence/phase1/ten_002_rls_leakage.json`
- Must contain `git_sha` matching the commit with migration 0094
- Must show `regulatory_incidents` in `rls_tables` with all flags true
- Must show `failures: []`
- `tenant_table_count` must be ≥1 higher than prior evidence

---

## Step 6 — Verification gate

```bash
bash scripts/security/lint_ddl_lock_risk.sh   # DDL-ALLOW-0062/0063 must pass
bash scripts/audit/verify_ten_002_rls_leakage.sh  # exits 0
bash scripts/dev/pre_ci.sh                     # exits 0
```

---

## Risk assessment

| Risk | Mitigation |
|------|-----------|
| Migration 0094 applied to empty table (pre-prod) | Zero lock contention; DDL-ALLOW documents this |
| Stale evidence accepted | git_sha match enforced — old sha = task not complete |
| ENABLE without FORCE | Migration includes both; DO block asserts both |
| Wrong policy template | Uses exact `current_tenant_id_or_null()` function |

---

## Estimated scope

- 1 new migration file (~40 lines)
- 2 new DDL-ALLOW entries
- ~20 lines added to verifier (temporal scan)
- MIGRATION_HEAD bump to 0094
