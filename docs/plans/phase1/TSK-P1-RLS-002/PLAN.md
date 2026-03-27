# PLAN: TSK-P1-RLS-002 — Born-secure RLS lint with order-aware validation

Status: planned
Phase: 1
Task: TSK-P1-RLS-002
Author: DB_FOUNDATION

---

## Objective

Implement a born-secure RLS lint gate that ensures every new tenant-scoped table
(post-baseline cutoff 0077) has ENABLE RLS, FORCE RLS, and an exactly-templated
tenant isolation policy — in strict order, in the same migration file.

Also add a born-secure exception to `lint_ddl_lock_risk.sh` so that inline
RLS on new tables does not require DDL-ALLOW entries.

---

## Pre-flight checks

- [ ] TSK-P1-RLS-001 completed (migration 0094 applied, verifier passing)
- [ ] `schema/baselines/current/baseline.cutoff` = `0077_harden_rls_onboarding_control_plane.sql`
- [ ] `scripts/security/lint_ddl_lock_risk.sh` exists and is functional
- [ ] `docs/invariants/INVARIANTS_MANIFEST.yml` exists

---

## Step 1 — Implement lint_rls_born_secure.sh

File: `scripts/db/lint_rls_born_secure.sh`

### Core logic

```
For each migration file AFTER baseline cutoff (> 0077):
  1. Parse CREATE TABLE statements; identify those with tenant_id column
  2. For each such table <T>, record line numbers of:
     - CREATE TABLE <T>         → line_create
     - ALTER TABLE <T> ENABLE ROW LEVEL SECURITY  → line_enable
     - ALTER TABLE <T> FORCE ROW LEVEL SECURITY   → line_force
     - CREATE POLICY ... ON <T> → line_policy
  3. Enforce strict ordering:
     line_create < line_enable < line_force < line_policy
     All four must exist in the SAME file.
  4. Reject any mutation of <T> after CREATE POLICY line
     (no ALTER TABLE <T> after line_policy)
```

### Partial compliance detection

Each of these independently produces a named violation:

| Condition | Violation code |
|-----------|---------------|
| ENABLE present, FORCE absent | `BORN_SECURE_VIOLATION:<file>:<table>:missing_force` |
| FORCE present, ENABLE absent | `BORN_SECURE_VIOLATION:<file>:<table>:missing_enable` |
| POLICY present, ENABLE absent | `BORN_SECURE_VIOLATION:<file>:<table>:missing_enable` |
| ENABLE+FORCE present, POLICY absent | `BORN_SECURE_VIOLATION:<file>:<table>:missing_policy` |

### Strict policy template enforcement

Extract the USING clause from CREATE POLICY. Normalize by:
1. Strip all whitespace
2. Lowercase
3. Compare as exact string equality against:

```
tenant_id=public.current_tenant_id_or_null()
```

WITH CHECK clause must match USING clause exactly.

Reject explicitly:
- `USING (true)`
- `USING (tenant_id IS NOT NULL)`
- `USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID)` ← current GF pattern!
- `USING (tenant_id = public.current_tenant_id_or_null() OR true)`
- `USING (true AND tenant_id = public.current_tenant_id_or_null())`
- Any expression containing `OR` after the required clause

This is **normalized string equality**, not substring or regex.

### Policy naming convention enforcement

Policy must follow the naming pattern:
```
rls_tenant_isolation_<table_name>
```
Must be `AS RESTRICTIVE FOR ALL TO PUBLIC`.

### Output

- Exit 0 if all post-cutoff migrations pass
- Exit non-zero with violation list if any fail
- Produce evidence: `evidence/phase1/rls_born_secure_gate.json`

---

## Step 2 — Add born-secure exception to lint_ddl_lock_risk.sh

File: `scripts/security/lint_ddl_lock_risk.sh`

### Logic (Python, not bash/grep)

For each flagged entry matching `ENABLE ROW LEVEL SECURITY` or
`FORCE ROW LEVEL SECURITY`:

```python
# Extract migration file path and table name from the flagged entry
# Open the migration file
# Record line numbers:
#   line_create = line of "CREATE TABLE <table>"
#   line_enable = line of "ALTER TABLE <table> ENABLE ROW LEVEL SECURITY"
#   line_force  = line of "ALTER TABLE <table> FORCE ROW LEVEL SECURITY"
#
# Skip (born-secure) ONLY if ALL three hold:
#   (1) line_create exists AND line_create < line_enable
#   (2) line_enable exists AND line_enable < line_force
#   (3) All in the same file
#
# If ANY condition fails → do NOT skip, require allowlist or fail
```

### What this does NOT exempt

- Retrofit ALTER TABLE on pre-existing table (no CREATE TABLE in file)
- Reversed order (ALTER before CREATE)
- Different file (CREATE in one migration, ALTER in another)

---

## Step 3 — Register INV-146 in INVARIANTS_MANIFEST.yml

File: `docs/invariants/INVARIANTS_MANIFEST.yml`

```yaml
- id: INV-146
  aliases: ["I-RLS-BORN-SECURE-01"]
  status: implemented
  severity: P1
  title: >-
    All new tenant-scoped tables (migrations after baseline cutoff 0077) must
    have RLS enabled, forced, and exactly-templated tenant isolation policy
    defined in the same migration as CREATE TABLE in strict order
  owners: ["team-db", "team-security"]
  sla_days: 7
  enforcement: "scripts/db/lint_rls_born_secure.sh"
  verification: "scripts/db/lint_rls_born_secure.sh"
  notes: >-
    Applies only to migrations after baseline cutoff.
    Pre-cutoff tables covered by verify_ten_002_rls_leakage.sh (runtime).
```

---

## Step 4 — Wire into CI gates

### pre_ci.sh

Add after the existing DB verifier section:

```bash
echo "==> Born-secure RLS lint gate (INV-146)"
if [[ -x scripts/db/lint_rls_born_secure.sh ]]; then
  scripts/db/lint_rls_born_secure.sh
else
  echo "ERROR: scripts/db/lint_rls_born_secure.sh not found"
  exit 1
fi
```

### .github/workflows/invariants.yml

Add `lint_rls_born_secure.sh` as a blocking step.

---

## Step 5 — Run negative tests

### N1: Missing RLS entirely

```
# Temp migration: CREATE TABLE public.test_no_rls (id UUID PK, tenant_id UUID NOT NULL)
# No RLS statements.
# Run lint_rls_born_secure.sh → must exit non-zero
# Violations: missing_enable, missing_force, missing_policy
```

### N2: Retrofit without CREATE TABLE

```
# Temp migration: ALTER TABLE public.ingress_attestations ENABLE ROW LEVEL SECURITY;
# No CREATE TABLE in file.
# Run lint_ddl_lock_risk.sh → must NOT be exempted by born-secure
```

### N3: Reversed order

```
# Temp migration: ALTER TABLE ENABLE RLS before CREATE TABLE
# Run lint_ddl_lock_risk.sh → must NOT be exempted
```

### N4: Weak policy — USING (true)

```
# Temp migration: correct structure but USING (true) policy
# Run lint_rls_born_secure.sh → must exit non-zero
```

### N5: Logical bypass — OR true (THE CRITICAL TEST)

```
# Temp migration: USING (tenant_id = public.current_tenant_id_or_null() OR true)
# Run lint_rls_born_secure.sh → must exit non-zero
# This proves normalized string equality, not substring matching
```

### N6: Partial compliance (three separate tests)

```
# (a) ENABLE present, FORCE absent, POLICY absent → missing_force
# (b) ENABLE + FORCE present, POLICY absent → missing_policy
# (c) POLICY present, ENABLE absent, FORCE absent → missing_enable
```

---

## Step 6 — Evidence generation

File: `evidence/phase1/rls_born_secure_gate.json`

```json
{
  "task_id": "TSK-P1-RLS-002",
  "git_sha": "<current>",
  "timestamp_utc": "<now>",
  "status": "PASS",
  "migrations_checked": ["0080_gf_...", "0081_gf_...", ...],
  "violations": [],
  "exempted_pre_baseline": ["0001-0077"]
}
```

---

## Step 7 — Verification gate

```bash
bash scripts/db/lint_rls_born_secure.sh       # exits 0
bash scripts/security/lint_ddl_lock_risk.sh    # exits 0
bash scripts/dev/pre_ci.sh                     # exits 0
```

---

## Known issue: Current GF migrations will FAIL this lint

The existing GF migrations (0080-0093) have three deficiencies:

1. **No FORCE ROW LEVEL SECURITY** — all use only ENABLE
2. **Wrong policy template** — use `current_setting('app.current_tenant_id', true)::UUID`
   instead of `public.current_tenant_id_or_null()`
3. **Non-restrictive policies** — use `TO authenticated_role` not `AS RESTRICTIVE FOR ALL TO PUBLIC`

These will be corrected by TSK-P1-RLS-003. This lint MUST be implemented
to fail on these before RLS-003 fixes them, proving the gate works.

---

## Estimated scope

- 1 new script: `scripts/db/lint_rls_born_secure.sh` (~200-300 lines)
- ~50 lines added to `lint_ddl_lock_risk.sh` (born-secure exception)
- 1 INV-146 entry in INVARIANTS_MANIFEST.yml
- ~5 lines in pre_ci.sh
- ~5 lines in invariants.yml workflow
- Evidence artifact generation
