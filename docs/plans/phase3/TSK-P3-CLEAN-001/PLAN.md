# TSK-P3-CLEAN-001 PLAN — Repair Phase 3 contract YAML parse defect

Task: TSK-P3-CLEAN-001
Owner: ARCHITECT
Depends on: none
Blocked by: none (root gate)
failure_signature: PHASE3.STRICT.TSK-P3-CLEAN-001.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
surface_specific_plan: docs/PHASE3/implementation_plans/TSK-P3-CAP-000_governance_cleanup.md

---

## Objective

Repair the YAML indentation or syntax defect in docs/PHASE3/phase3_contract.yml
so that it is machine-parseable. This is the root cleanup gate for Pre-Phase 3
Wave 0 — all other CLEAN tasks are blocked by this task.

The repair must not alter contract row semantics, add execution authorization,
or introduce implementation-readiness language.

---

## Pre-conditions

- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/PHASE3/phase3_contract.yml` | MODIFY | Fix YAML parse defect |
| `scripts/audit/verify_tsk_p3_clean_001.sh` | CREATE | Verifier for this task |
| `evidence/phase3/tsk_p3_clean_001.json` | CREATE | Output artifact |
| `tasks/TSK-P3-CLEAN-001/meta.yml` | MODIFY | Update status upon success |
| `docs/plans/phase3/TSK-P3-CLEAN-001/EXEC_LOG.md` | MODIFY | Append completion data |

---

## Stop Conditions

- **If the repair changes the meaning of any contract row** -> STOP
- **If execution authorization or implementation-readiness language is introduced** -> STOP
- **If the repair adds or removes contract rows** -> STOP
- **If the repaired file still fails YAML parsing** -> STOP

---

## Implementation Steps

### Step 1: Diagnose parse defect
**What:** Identify the exact YAML defect in phase3_contract.yml.
**How:**
- Run `python3 -c "import yaml; yaml.safe_load(open('docs/PHASE3/phase3_contract.yml'))"` and capture error.
- Identify line/column of defect.
**Done when:** Root cause of parse failure is identified.

### Step 2: Repair defect
**What:** Fix the indentation or syntax issue.
**How:**
- [ID tsk_p3_clean_001_work_01] Fix the identified YAML indentation or syntax defect.
- [ID tsk_p3_clean_001_work_02] Verify P3-004 row fields remain semantically intact.
- [ID tsk_p3_clean_001_work_03] Confirm no execution-claim language is introduced.
**Done when:** File parses as valid YAML and row semantics are preserved.

### Step 3: Emit evidence
**What:** Run verifier and capture evidence.
**How:**
```bash
bash scripts/audit/verify_tsk_p3_clean_001.sh > evidence/phase3/tsk_p3_clean_001.json
```
**Done when:** Command exits 0 and evidence format complies.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p3_clean_001.sh

# 2. Local parity check
bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase3/tsk_p3_clean_001.json`

Required fields:
- `task_id`: "TSK-P3-CLEAN-001"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `observed_paths`: array of inspected file paths
- `observed_hashes`: object of {path: sha256_hex}
