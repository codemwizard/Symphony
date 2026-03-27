# PLAN: TSK-P1-RLS-003 — Apply born-secure RLS to all GF migrations 0071+

Status: planned
Phase: 1
Task: TSK-P1-RLS-003
Author: DB_FOUNDATION

---

## Objective

Fix every GF migration (0080+) that creates a tenant-scoped table to include
correct inline ENABLE RLS, FORCE RLS, and an exactly-templated restrictive
tenant isolation policy. No DDL-ALLOW entries for RLS. No modification of
pre-existing tables. The born-secure lint from TSK-P1-RLS-002 must pass on
all GF migrations after this task completes.

---

## Pre-flight checks

- [ ] TSK-P1-RLS-001 completed (forward-fix migration applied)
- [ ] TSK-P1-RLS-002 completed (lint_rls_born_secure.sh exists and is wired)
- [ ] Confirm lint_rls_born_secure.sh currently FAILS on GF migrations (proves gate works)
- [ ] Catalog all GF tables with tenant_id across all GF migrations

---

## Current state analysis

### Three deficiencies in existing GF migrations

| Deficiency | Current state | Required state |
|------------|--------------|----------------|
| FORCE RLS | Missing entirely | `ALTER TABLE <T> FORCE ROW LEVEL SECURITY` |
| Policy template | `current_setting('app.current_tenant_id', true)::UUID` | `public.current_tenant_id_or_null()` |
| Policy type | `TO authenticated_role` (permissive) | `AS RESTRICTIVE FOR ALL TO PUBLIC` |

### Tables requiring correction (per migration)

| Migration | Tables |
|-----------|--------|
| 0080_gf_adapter_registrations | `adapter_registrations` |
| 0081_gf_interpretation_packs | `interpretation_packs` |
| 0082_gf_monitoring_records | `monitoring_records` |
| 0083_gf_evidence_lineage | `evidence_nodes`, `evidence_edges` |
| 0084_gf_asset_lifecycle | `asset_batches`, `asset_lifecycle_events`, `retirement_events` |
| 0085_gf_regulatory_plane | `regulatory_authorities`, `regulatory_checkpoints` |
| 0086_gf_jurisdiction_profiles | `jurisdiction_profiles`, `lifecycle_checkpoint_rules` |
| 0087_gf_verifier_registry | `verifier_registry`, `verifier_project_assignments` |
| 0091_gf_fn_regulatory_transitions | `authority_decisions` |
| 0093_gf_fn_verifier_read_token | `gf_verifier_read_tokens` |

**Total: 15 tables across 10 migrations.**

The authoritative source of truth for enforcement is column-level detection
of `tenant_id` in `lint_rls_born_secure.sh`. This list is informational only
and must not be used for validation logic. Any future table with `tenant_id`
will be caught automatically regardless of whether it appears here.

### Tables that do NOT need RLS (no tenant_id)

Verify at implementation time. Function-only migrations (0088, 0089, 0090, 0092)
create no tables and need no changes.

---

## Step 1 — Fix each GF migration inline

For each migration listed above, apply exactly this pattern after each
`CREATE TABLE` block and before the end of the migration. The RLS block
must appear after CREATE TABLE but other safe statements (e.g. CREATE INDEX)
may appear between CREATE TABLE and the RLS block:

```sql
ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.<table> FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_<table>
  ON public.<table>
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
```

### What changes per table

Each table's existing RLS block must be replaced:

**Remove** (example from 0080):
```sql
ALTER TABLE adapter_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_adapter_registrations ON adapter_registrations
    FOR ALL
    TO authenticated_role
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

CREATE POLICY system_full_access_adapter_registrations ON adapter_registrations
    FOR ALL
    TO symphony_system
    USING (true);
```

**Replace with**:
```sql
ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adapter_registrations FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_tenant_isolation_adapter_registrations
  ON public.adapter_registrations
  AS RESTRICTIVE FOR ALL TO PUBLIC
  USING (tenant_id = public.current_tenant_id_or_null())
  WITH CHECK (tenant_id = public.current_tenant_id_or_null());
```

### Important constraints on each edit

1. **After CREATE TABLE, before migration end** — not batched at file end
2. **Explicit public schema** — `ALTER TABLE public.<table>`
3. **FORCE RLS added** — was missing in all GF migrations
4. **Policy is RESTRICTIVE** — not permissive
5. **TO PUBLIC** — not `TO authenticated_role`
6. **Exact template function** — `public.current_tenant_id_or_null()`
7. **WITH CHECK matches USING** — both clauses identical
8. **No system_full_access policies** — those are non-restrictive bypasses
9. **No statements affecting the table after CREATE POLICY** — any ALTER TABLE
   on `<T>` that changes RLS state, ownership, policies, or structure after its
   CREATE POLICY line is a violation. This includes but is not limited to:
   `DISABLE ROW LEVEL SECURITY`, `OWNER TO`, `DROP POLICY`, `ALTER COLUMN`,
   `ADD COLUMN`, `DROP COLUMN`, `RENAME`. CREATE INDEX statements are permitted
   after CREATE POLICY. Index definitions do not affect RLS enforcement and are
   not considered post-policy mutations.
10. **Before/after CREATE POLICY boundary** — statements before CREATE POLICY
    may include indexes, constraints, or comments. After CREATE POLICY, only
    CREATE INDEX is permitted. All other table mutations are forbidden.

### Migration-by-migration edit list

#### 0080_gf_adapter_registrations.sql
- Replace existing RLS block for `adapter_registrations`
- Remove `system_full_access_adapter_registrations` policy

#### 0081_gf_interpretation_packs.sql
- Replace existing RLS block for `interpretation_packs`
- Remove `interpretation_packs_system_full_access` policy

#### 0082_gf_monitoring_records.sql
- Replace existing RLS block for `monitoring_records`
- Remove `monitoring_records_system_full_access` policy

#### 0083_gf_evidence_lineage.sql
- Replace existing RLS blocks for `evidence_nodes` AND `evidence_edges`
- Remove system_full_access policies for both
- Each table gets its own inline block immediately after its CREATE TABLE

#### 0084_gf_asset_lifecycle.sql
- Replace existing RLS blocks for `asset_batches`, `asset_lifecycle_events`, `retirement_events`
- Remove system_full_access policies for all three

#### 0085_gf_regulatory_plane.sql
- Replace existing RLS blocks for `regulatory_authorities`, `regulatory_checkpoints`
- Remove system_full_access policies for both

#### 0086_gf_jurisdiction_profiles.sql
- Replace existing RLS blocks for `jurisdiction_profiles`, `lifecycle_checkpoint_rules`
- Remove system_full_access policies for both

#### 0087_gf_verifier_registry.sql
- Replace existing RLS blocks for `verifier_registry`, `verifier_project_assignments`
- Remove system_full_access policies for both

#### 0091_gf_fn_regulatory_transitions.sql
- Replace existing RLS block for `authority_decisions`
- Remove `authority_decisions_system_full_access` policy

#### 0093_gf_fn_verifier_read_token.sql
- Replace existing RLS block for `gf_verifier_read_tokens`
- Remove `gf_verifier_read_tokens_system_full_access` policy

---

## Step 1a — Validate system role access paths before policy removal

Before removing `system_full_access` policies, verify that all system roles
(e.g. `symphony_system`, `app_runtime`) that require access to GF tables either:

- Have `BYPASSRLS` attribute set, OR
- Have an alternative access path (e.g. SECURITY DEFINER functions)

Validation method:

```sql
SELECT rolname, rolbypassrls
FROM pg_roles
WHERE rolname IN ('symphony_system', 'app_runtime');
```

If any system role lacks BYPASSRLS and relies on the `system_full_access` policy
for data access, that role must be granted BYPASSRLS or an alternative access
path must be established BEFORE removing the policy. Silent access loss is a
production failure.

This check must be implemented as a script (`scripts/db/verify_system_roles_rls.sh`)
and executed against the CI database after migrations are applied.

The check must:
- Query `pg_roles` for `rolbypassrls`
- Fail if any required system role lacks BYPASSRLS

Detection of alternative access paths (e.g. SECURITY DEFINER functions)
is explicitly out of scope for automation and must not be inferred by CI.
If `pre_ci.sh` cannot confirm BYPASSRLS, it must exit non-zero.

---

## Step 2 — Scope enforcement scan (CI-enforced)

This check is implemented as `scripts/db/lint_gf_migration_scope.py`
(Python + sqlglot AST parser with regex fallback for PG-specific statements)
and wired into `pre_ci.sh` as a blocking gate — not run manually.

```bash
# For each GF migration file (0080+):
#   1. Extract all CREATE TABLE statements → created_tables[]
#   2. Extract all ALTER TABLE statements → altered_tables[]
#   3. For each altered_table: if not in created_tables → SCOPE_VIOLATION
#   4. For each table: if any statement modifies <T> after CREATE POLICY <T> → POST_POLICY_MUTATION
```

### Parser requirements

Scope lint MUST use a SQL AST parser (e.g. `sqlglot`). Regex-based approaches
are not permitted. The parser must correctly handle:
- **Schema-qualified names** — `public.<T>` and `<T>` must resolve to the same table
- **IF EXISTS / ONLY modifiers** — `ALTER TABLE IF EXISTS public.<T>` must extract `<T>`
- **Multiline ALTER TABLE statements** — statement may span multiple lines
- **Case insensitivity** — `ALTER TABLE` vs `alter table` vs `Alter Table`
- **POLICY statements** — must be detected and associated with their target table
  for ordering validation only. Policy expression correctness is enforced
  exclusively by `lint_rls_born_secure.sh` and `verify_ten_002_rls_leakage.sh`.

The implementation must include adversarial SQL test cases (schema-qualified,
IF EXISTS, ONLY, multiline) in its own test suite to prove parser correctness.

Add to `pre_ci.sh`:

```bash
echo "==> GF migration scope enforcement (TSK-P1-RLS-003)"
if [[ -x scripts/db/lint_gf_migration_scope.sh ]]; then
  scripts/db/lint_gf_migration_scope.sh
else
  echo "ERROR: scripts/db/lint_gf_migration_scope.sh not found"
  exit 1
fi
```

Expected result: zero violations. Every ALTER TABLE in a GF migration references
only tables created in the same file. No table is modified after its CREATE POLICY.

---

## Step 3 — Run born-secure lint

```bash
bash scripts/db/lint_rls_born_secure.sh
```

Must exit 0 on all GF migrations. If any fail, fix the migration — do NOT
add an allowlist entry.

---

## Step 4 — Run DDL lock risk lint

```bash
bash scripts/security/lint_ddl_lock_risk.sh
```

Must exit 0 with **zero new DDL-ALLOW entries** for any RLS statement in GF
migrations. The born-secure exception from RLS-002 handles them.

If the lint flags any GF RLS statement, the born-secure exception is not
firing correctly — debug `lint_ddl_lock_risk.sh`, not the migration.

---

## Step 5 — Run TEN-002 verifier against live DB

```bash
bash scripts/db/migrate.sh
bash scripts/audit/verify_ten_002_rls_leakage.sh
```

The pg_class check must show all GF tenant tables with:
- `rls_enabled: true`
- `rls_forced: true`
- `restrictive_policy_tenant_bound: true`
- `failures: []`

**Hard gate:** Step 5 is INVALID and this task must FAIL unless the verifier
includes an explicit assertion that the policy expression exactly matches the
canonical template (`tenant_id = public.current_tenant_id_or_null()`). Mere
presence of a policy or substring match is not sufficient.

The verifier must compare using **parsed expression tree (AST) or normalized
SQL via `pg_get_expr`** — not naive string equality, which will produce false
negatives on whitespace or casting normalization differences.

If the verifier's current check is weaker than exact template match, it must
be strengthened BEFORE this step runs. Evidence produced by a weak verifier
is not valid evidence for this task.

---

## Step 6 — Negative tests

### N1: Missing ENABLE RLS detected

```
# Temporarily remove ENABLE RLS from one GF migration
# Run lint_rls_born_secure.sh → must exit non-zero
# Restore the block
```

### N2: Weak policy detected at runtime

```
# Temporarily replace one policy with USING (true)
# Apply to test DB
# Run verify_ten_002_rls_leakage.sh → must fail
# Restore correct policy
```

### N3: Scope violation detected (CI-enforced)

```
# Temporarily add: ALTER TABLE public.tenants ADD COLUMN gf_test TEXT
# to one GF migration
# Run scripts/db/lint_gf_migration_scope.sh → must emit SCOPE_VIOLATION
# Run pre_ci.sh → must exit non-zero (scope lint is a blocking gate)
# Remove the line
```

### N4: Zero new DDL-ALLOW entries

```bash
# Count RLS-related DDL-ALLOW entries pointing to GF migrations
# Must be zero
git diff --name-only | grep ddl_allowlist  # should show no changes
```

---

## Step 7 — Final verification gate

```bash
bash scripts/db/lint_rls_born_secure.sh         # exits 0
bash scripts/security/lint_ddl_lock_risk.sh      # exits 0
bash scripts/audit/verify_ten_002_rls_leakage.sh # exits 0
bash scripts/dev/pre_ci.sh                       # exits 0
```

---

## Risk assessment

| Risk | Mitigation |
|------|-----------|
| Removing system_full_access policies breaks app | Step 1a validates system roles have BYPASSRLS via `scripts/db/verify_system_roles_rls.sh` (CI-enforced, binary check). Silent access loss is caught before it reaches production. |
| Editing applied migrations | GF migrations 0080-0093 are NOT yet applied to production. They are draft GF wave 1 migrations in active development. |
| Policy template change breaks existing queries | Queries that set `app.current_tenant_id` work with both `current_setting()` and `current_tenant_id_or_null()`. The function wraps the same setting. |
| Scope enforcement too strict | GF migrations should only create new tables. If a GF migration legitimately needs ALTER on an existing table, that's a separate reviewed task. |

---

## Estimated scope

- 10 migration files modified (RLS block replacement)
- ~15 table RLS blocks corrected
- 1 new script: `scripts/db/lint_gf_migration_scope.py` (AST-based scope + post-policy mutation enforcement)
- 1 new script: `scripts/db/verify_system_roles_rls.sh` (BYPASSRLS binary check)
- 9 adversarial test cases in `tests/rls_scope/` (structural enforcement proof)
- 3 adversarial test cases in `tests/rls_born_secure/` (policy expression proof, deferred until TSK-P1-RLS-002)
- Zero new DDL-ALLOW entries
- pre_ci.sh updated to wire in scope enforcement gate + adversarial test suite
