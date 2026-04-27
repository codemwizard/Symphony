# TSK-P2-PREAUTH-007-11 PLAN — Phase 1 Boundary Marker Schema

Task: TSK-P2-PREAUTH-007-11
Owner: DB_FOUNDATION
Gap Source: G-03 (W7_GAP_ANALYSIS.md line 161)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-11.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.
- Approval artifacts MUST be created BEFORE editing regulated surfaces.
- Stage A: Before editing (approvals/YYYY-MM-DD/BRANCH-<branch>.md and .approval.json)
- Stage B: After PR opening (approvals/YYYY-MM-DD/PR-<number>.md and .approval.json)
- Conformance check: `bash scripts/audit/verify_approval_metadata.sh --mode=stage-a --branch=<branch>`

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only - never delete or modify existing entries.
- Markers must be present when the file is modified - not deferred to `pre_ci.sh`.
- Mandatory `EXEC_LOG.md` markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Add `phase` and `data_authority` columns to `monitoring_records` with a BEFORE INSERT trigger that mechanically enforces Phase 1 boundary marking rules. This closes Gap G-03 from the Wave 7 Gap Analysis.

**Current State (from Gap Analysis):**
- `monitoring_records` table exists but has NO `phase` column and NO `data_authority` column.
- Only `audit_grade` column exists on `monitoring_records`.
- The spec's verification SQL (`SELECT COUNT(*) FROM monitoring_records WHERE phase='phase1' AND ...`) cannot currently execute because the columns are missing.
- INV-177 (Phase 1 Boundary Marked) is unenforceable in the current schema.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated for regulated changes.
- [ ] `monitoring_records` table exists in the database.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/XXXX_add_phase1_boundary_markers.sql` | CREATE | Migration adding columns and trigger |
| `scripts/audit/verify_tsk_p2_preauth_007_11.sh` | CREATE | Verifier with positive and negative tests |
| `evidence/phase2/tsk_p2_preauth_007_11.json` | CREATE | Output artifact |
| `tasks/TSK-P2-PREAUTH-007-11/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase2/TSK-P2-PREAUTH-007-11/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If approval metadata is not created before editing migration** → STOP
- **If EXEC_LOG.md does not contain all required markers** → STOP
- **If the verifier fails to execute negative tests transactionally** → STOP
- **If evidence is statically faked instead of derived** → STOP

---

## Implementation Steps

### Step 1: Author Migration

**What:** Create migration adding Phase 1 boundary columns to `monitoring_records`.

**Exact Schema Changes (from G-03):**
1. Add column `phase` to `monitoring_records`:
   - Type: `VARCHAR` or ENUM (must match the allowed values)
   - Allowed values: `'phase1'`, `'phase2'` (at minimum)
   - NOT NULL with a sensible default for existing rows

2. Add column `data_authority` to `monitoring_records`:
   - Type: `data_authority_level` (the existing ENUM: `phase1_indicative_only`, `non_reproducible`, `derived_unverified`, `policy_bound_unsigned`, `authoritative_signed`, `superseded`, `invalidated`)
   - NOT NULL with a sensible default for existing rows

3. Backfill legacy rows with `phase='phase1'` and `data_authority='phase1_indicative_only'`.

4. Create BEFORE INSERT trigger enforcing the Phase 1 boundary rule:
   - **Rule**: If `phase = 'phase1'` THEN `data_authority` MUST be `'phase1_indicative_only'` AND `audit_grade` MUST be `false`.
   - **Rejection**: RAISE EXCEPTION with clear message if rule is violated.
   - Trigger must fire on INSERT (and optionally UPDATE) to prevent future violations.

**Migration Template:**
```sql
BEGIN;

-- Add columns
ALTER TABLE monitoring_records
  ADD COLUMN phase VARCHAR NOT NULL DEFAULT 'phase1',
  ADD COLUMN data_authority data_authority_level NOT NULL DEFAULT 'phase1_indicative_only';

-- Backfill (if needed for rows inserted before default was set)
UPDATE monitoring_records
SET phase = 'phase1', data_authority = 'phase1_indicative_only'
WHERE phase IS NULL;

-- Create enforcement trigger function
CREATE OR REPLACE FUNCTION enforce_phase1_boundary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NEW.phase = 'phase1' THEN
    IF NEW.data_authority <> 'phase1_indicative_only' THEN
      RAISE EXCEPTION 'Phase 1 boundary violation: phase1 rows must have data_authority = phase1_indicative_only, got %', NEW.data_authority;
    END IF;
    IF NEW.audit_grade <> false THEN
      RAISE EXCEPTION 'Phase 1 boundary violation: phase1 rows must have audit_grade = false, got %', NEW.audit_grade;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- Bind trigger
CREATE TRIGGER trg_enforce_phase1_boundary
  BEFORE INSERT OR UPDATE ON monitoring_records
  FOR EACH ROW
  EXECUTE FUNCTION enforce_phase1_boundary();

COMMIT;
```

**Done when:** Migration applied, columns exist, trigger fires on boundary violation.

### Step 2: Build Verifier

**What:** Create `scripts/audit/verify_tsk_p2_preauth_007_11.sh` with positive and negative tests.

**Positive Tests:**
1. Verify `phase` column exists on `monitoring_records` via `information_schema.columns`.
2. Verify `data_authority` column exists on `monitoring_records` via `information_schema.columns`.
3. Verify trigger `trg_enforce_phase1_boundary` exists via `pg_trigger`.
4. INSERT a valid Phase 1 row (`phase='phase1'`, `data_authority='phase1_indicative_only'`, `audit_grade=false`) → must succeed (then ROLLBACK).

**Negative Tests (must all ROLLBACK):**
1. INSERT `phase='phase1'` with `data_authority='authoritative_signed'` → must be REJECTED by trigger.
2. INSERT `phase='phase1'` with `audit_grade=true` → must be REJECTED by trigger.
3. INSERT `phase='phase2'` with `data_authority='authoritative_signed'` → must SUCCEED (Phase 2 rows are not constrained by Phase 1 rules).

**Isolation:** All negative tests must run in `BEGIN; ... ROLLBACK;` blocks. Zero persistent side effects.

**Evidence Output:** JSON with `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_hashes`.

### Step 3: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_11.sh > evidence/phase2/tsk_p2_preauth_007_11.json
```

### Step 4: Rebaseline

After migration is applied:
```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md` log with the regeneration entry.
