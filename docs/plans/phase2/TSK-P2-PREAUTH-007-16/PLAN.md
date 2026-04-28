# TSK-P2-PREAUTH-007-16 PLAN — INV-177 DB Verifier

Task: TSK-P2-PREAUTH-007-16
Owner: SECURITY_GUARDIAN
Gap Source: G-06, G-07, G-15 (W7_GAP_ANALYSIS.md lines 164-165, 173)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-16.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any regulated file without prior approval metadata.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Create a dedicated DB-querying verifier script for INV-177 (Phase 1 Boundary Marked). This depends on TSK-P2-PREAUTH-007-11 having added the `phase` and `data_authority` columns to `monitoring_records` with the enforcement trigger.

**What Exists Today (from G-15, line 173):**
- The current INV-177 verifier only checks property name presence in the manifest, not semantic values.
- It does NOT assert that `data_authority = 'phase1_indicative_only'` for Phase 1 rows.
- A grep for property names allows authoritative values to pass undetected.

**What Must Be Built:**
- A dedicated `verify_inv_177.sh`-equivalent that performs actual DB queries against `monitoring_records`.
- Must assert specific value assignments, not just column presence.
- Must include a negative test that proves the enforcement trigger rejects violations.

---

## Pre-conditions

- [ ] TSK-P2-PREAUTH-007-11 completed (`phase` and `data_authority` columns exist on `monitoring_records`, enforcement trigger active).
- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_preauth_007_16.sh` | CREATE | Verifier for INV-177 |
| `evidence/phase2/tsk_p2_preauth_007_16.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If verifier checks YAML manifest instead of database** → STOP
- **If verifier only checks column existence, not value enforcement** → STOP
- **If negative tests leave persistent data** → STOP

---

## Implementation Steps

### Step 1: Positive Tests

```sql
-- 1. Verify phase column exists on monitoring_records
SELECT column_name, is_nullable, data_type
FROM information_schema.columns
WHERE table_name = 'monitoring_records' AND column_name = 'phase';

-- 2. Verify data_authority column exists on monitoring_records
SELECT column_name, is_nullable, data_type
FROM information_schema.columns
WHERE table_name = 'monitoring_records' AND column_name = 'data_authority';

-- 3. Verify enforcement trigger exists
SELECT tgname FROM pg_trigger
WHERE tgrelid = 'monitoring_records'::regclass
  AND tgname = 'trg_enforce_phase1_boundary';

-- 4. Verify NO existing Phase 1 rows violate the boundary rule
SELECT COUNT(*) FROM monitoring_records
WHERE phase = 'phase1'
  AND (data_authority <> 'phase1_indicative_only' OR audit_grade <> false);
-- Expected: 0
```

### Step 2: Negative Tests (all ROLLBACK)

```sql
-- N1: INSERT phase1 row with wrong data_authority → must be REJECTED
BEGIN ISOLATION LEVEL SERIALIZABLE;
INSERT INTO monitoring_records (
  -- ... required columns ...
  phase, data_authority, audit_grade
) VALUES (
  'phase1', 'authoritative_signed', false
);
-- If we reach here, the test FAILED
ROLLBACK;

-- N2: INSERT phase1 row with wrong audit_grade → must be REJECTED
BEGIN ISOLATION LEVEL SERIALIZABLE;
INSERT INTO monitoring_records (
  -- ... required columns ...
  phase, data_authority, audit_grade
) VALUES (
  'phase1', 'phase1_indicative_only', true
);
-- If we reach here, the test FAILED
ROLLBACK;

-- N3: INSERT phase2 row with authoritative data_authority → must SUCCEED
-- (Phase 2 rows are NOT constrained by Phase 1 boundary rules)
BEGIN ISOLATION LEVEL SERIALIZABLE;
INSERT INTO monitoring_records (
  -- ... required columns ...
  phase, data_authority, audit_grade
) VALUES (
  'phase2', 'authoritative_signed', true
);
-- If this SUCCEEDS, the test PASSED (Phase 2 is unconstrained)
ROLLBACK;
```

### Step 3: Script Harness

Same pattern as 007-15:
- `DATABASE_URL` environment variable
- `SERIALIZABLE` isolation for all tests
- Structured JSON evidence output
- Exit 0 only if all checks pass

### Step 4: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_16.sh > evidence/phase2/tsk_p2_preauth_007_16.json
```

### Step 5: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.
