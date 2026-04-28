# TSK-P2-PREAUTH-007-17 PLAN — INV-165 & INV-167 Correction Verifiers

Task: TSK-P2-PREAUTH-007-17
Owner: SECURITY_GUARDIAN
Gap Source: G-14, G-11 (W7_GAP_ANALYSIS.md lines 172, 169)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-17.PROOF_FAIL
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

Fix two broken verifier scripts that prove orthogonal facts instead of their claimed invariants, and fix a hardcoded ID bug that makes a verifier non-replayable.

**Bug 1 — G-11 (line 169): Hardcoded ID=175 in `verify_tsk_p2_preauth_007_01.sh`**
- The script hardcodes `if [ "$NEXT_INV_ID" -ne 175 ]`, but the manifest now contains IDs up to INV-179.
- The computed next ID is 180, not 175.
- This verifier fails today against the current codebase.
- The hardcoded assertion makes the script non-replayable — it breaks permanently the moment any invariant with ID ≥ 175 is added.

**Bug 2 — G-14 (line 172): INV-165 and INV-167 enforcement scripts prove orthogonal fact (ENUM count)**
- Current INV-165 verifier checks ENUM value count, which proves a Wave 6 structural fact, not the INV-165 invariant (interpretation_version_id required).
- Current INV-167 verifier similarly checks an orthogonal property.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.
- [ ] Stage A Approval artifact generated.
- [ ] `state_transitions` table has `interpretation_version_id` column.
- [ ] `interpretation_packs` table exists.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p2_preauth_007_17.sh` | CREATE | Combined correction verifier |
| `evidence/phase2/tsk_p2_preauth_007_17.json` | CREATE | Output artifact |

---

## Stop Conditions

- **If any verifier still uses hardcoded invariant IDs** → STOP
- **If any verifier proves an orthogonal fact instead of the claimed invariant** → STOP

---

## Implementation Steps

### Step 1: Fix INV-165 Verifier (Interpretation Version Required)

**Correct Query (from G-14, line 172):**
```sql
-- INV-165: All authoritative state_transitions must have interpretation_version_id
SELECT COUNT(*) FROM state_transitions
WHERE interpretation_version_id IS NULL
  AND data_authority NOT IN ('phase1_indicative_only', 'non_reproducible');
-- Expected: 0
-- If > 0, there are authoritative rows without interpretation binding
```

**Why The Old Query Was Wrong:**
The old verifier ran `SELECT COUNT(enum_range) ...` on `data_authority_level` ENUM — this proves the ENUM has the right number of values, which is a Wave 6 structural fact. It says nothing about whether `interpretation_version_id` is populated on authoritative rows.

### Step 2: Fix INV-167 Verifier (Interpretation Uniqueness)

**Correct Query (from G-14, line 172):**
```sql
-- INV-167: The active interpretation uniqueness index must exist
SELECT COUNT(*) FROM pg_indexes
WHERE indexname = 'interpretation_packs_active_unique';
-- Expected: 1
```

**Additional behavioral test:**
```sql
-- Negative test: attempt to create two active interpretation packs
-- for the same (domain, jurisdiction_code, authority_level)
BEGIN ISOLATION LEVEL SERIALIZABLE;
-- Insert first active pack (effective_to IS NULL)
INSERT INTO interpretation_packs (domain, jurisdiction_code, authority_level, effective_from, effective_to)
VALUES ('test_domain', 'TEST', 'primary', NOW(), NULL);
-- Insert second active pack for same combination → must be REJECTED
INSERT INTO interpretation_packs (domain, jurisdiction_code, authority_level, effective_from, effective_to)
VALUES ('test_domain', 'TEST', 'primary', NOW(), NULL);
-- If we reach here, the uniqueness constraint is broken
ROLLBACK;
```

### Step 3: Fix Hardcoded ID=175 Bug

**Current broken assertion:**
```bash
# BROKEN: fails when manifest grows
if [ "$NEXT_INV_ID" -ne 175 ]; then
  echo "FAIL"
fi
```

**Correct functional assertion:**
```bash
# CORRECT: verify ID logic is functional, not a fixed value
# The next ID should be MAX(existing IDs) + 1
LAST_ID=$(grep -oP 'id: INV-\K[0-9]+' INVARIANTS_MANIFEST.yml | sort -n | tail -1)
EXPECTED_NEXT=$((LAST_ID + 1))
if [ "$NEXT_INV_ID" -ne "$EXPECTED_NEXT" ]; then
  echo "FAIL: Expected next ID $EXPECTED_NEXT, got $NEXT_INV_ID"
fi
```

### Step 4: Update INVARIANTS_MANIFEST.yml

Update the `enforcement` fields for INV-165 and INV-167 to point to the new corrected verifier scripts instead of the orthogonal ones.

### Step 5: Execute Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_17.sh > evidence/phase2/tsk_p2_preauth_007_17.json
```

### Step 6: Rebaseline

```bash
bash scripts/db/generate_baseline_snapshot.sh
```
Update `docs/decisions/ADR-0010-baseline-policy.md`.
