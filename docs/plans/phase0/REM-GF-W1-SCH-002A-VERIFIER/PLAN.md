# Remediation Trace: REM-GF-W1-SCH-002A-VERIFIER

## Classification

- **Severity:** L1 — DRD Lite (script + migration corrections; no security regression introduced)
- **Domain:** green_finance
- **Phase:** 0
- **Date:** 2026-03-29
- **Author:** db_foundation_agent

---

## Scope of Changes

Two categories of production-affecting changes were made during GF-W1 scaffolding that require this trace:

### Change 1 — `verify_gf_sch_002a.sh`: Stub → Real 7-Check Verifier

**File:** `scripts/db/verify_gf_sch_002a.sh`

**Root Cause:**
The verifier was initially written as a stub that emitted hardcoded evidence (status always `PASS`, no `run_id`, no actual checks). This blocked `run_task.sh` evidence freshness checks because the emitted JSON lacked the `run_id` field required by the evidence contract.

**What Changed:**
- Replaced stub with a real verifier implementing 7 checks:
  1. `IF NOT EXISTS` anti-pattern detection in migration SQL
  2. Sidecar alignment (declared identifiers match SQL CREATE statements)
  3. Migration head correctness (MIGRATION_HEAD contains 0098)
  4. Ownership uniqueness (each identifier declared by exactly one sidecar)
  5. Reference order (no forward references in sidecar dependencies)
  6. AST consistency (SQL identifiers match sidecar declarations)
  7. Evidence emission with `run_id`, `git_sha`, `timestamp_utc`
- Fixed a bash boolean → Python boolean injection bug: `"true"`/`"false"` strings from bash were passed raw into a Python heredoc, causing `NameError`. Fixed by adding a helper function for string-to-bool conversion.

**Risk Assessment:**
- No security regression: the script is a read-only static analyzer with no DB connectivity.
- No runtime DDL: script only reads SQL files on disk.
- Blast radius: `scripts/db/` only.

**Invariants Preserved:**
- INV-SCHEMA-OWNERSHIP-001, INV-SCHEMA-SIDECAR-SQL-CONSISTENCY-012

---

### Change 2 — Remove `IF NOT EXISTS` from SQL Migrations 0097 and 0098

**Files:**
- `schema/migrations/0097_gf_projects.sql`
- `schema/migrations/0098_gf_methodology_versions.sql`

**Root Cause:**
Both migrations were scaffolded with `CREATE TABLE IF NOT EXISTS`, which is explicitly listed as an anti-pattern in the GF schema task negative tests. The `IF NOT EXISTS` clause masks accidental re-creation of a table (idempotency fiction) and the SCH-002A verifier was written to reject it. The migrations would have caused the verifier's own negative test (GF-W1-SCH-002A-N1) to fail if left in place.

**What Changed:**
- `CREATE TABLE IF NOT EXISTS projects` → `CREATE TABLE projects`
- `CREATE TABLE IF NOT EXISTS methodology_versions` → `CREATE TABLE methodology_versions`

**Risk Assessment:**
- These are pre-applied migrations in the Wave 4 scaffolding session, not yet applied to any production database. No rollback of live data is required.
- The change is strictly a correctness fix: removing a clause the verifier explicitly rejects.
- No privilege changes, no RLS changes, no DDL additions.

**Invariants Preserved:**
- INV-SCHEMA-OWNERSHIP-001, INV-SCHEMA-ORDER-002

---

## Verification

After both changes were applied:

```bash
bash scripts/db/verify_gf_sch_002a.sh
```

Expected: exits 0, `evidence/phase0/gf_sch_002a.json` emitted with `status=PASS` and `run_id` present.

```bash
python3 scripts/audit/verify_plan_semantic_alignment.py \
  --plan docs/plans/phase0/GF-W1-SCH-002A/PLAN.md \
  --meta tasks/GF-W1-SCH-002A/meta.yml
```

Expected: `[OK] Proof graph integrity PASSED`

---

## Non-Goals

- This trace does not authorize any new migration.
- This trace does not change the task status of GF-W1-SCH-002A (remains `planned`).
- No downstream task statuses are modified by this remediation.

---

## Approval Metadata

- **Requires human approval before production apply:** No (script-only + pre-production migration correction)
- **Regulated surface touched:** `schema/migrations/` (pre-production only), `scripts/db/`
- **Canonical reference:** `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
