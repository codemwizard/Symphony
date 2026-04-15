---
failure_signature: PRECI.GOVERNANCE.TASK_META_SCHEMA
root_cause: 10 meta.yml files (GF-W1-UI-014 through GF-W1-UI-023) were missing required fields according to the canonical schema from Gove/tasks/_template/meta.yml. The TSK-CLEAN-001 verifier reported missing_status errors for these files.
---

# REM-2026-04-08_pre_ci-verify_task_meta_schema Remediation Plan

## Failure Signature
`PRECI.GOVERNANCE.TASK_META_SCHEMA`

## Root Cause
10 meta.yml files (GF-W1-UI-014 through GF-W1-UI-023) were missing required fields according to the canonical schema from `Gove/tasks/_template/meta.yml`. The TSK-CLEAN-001 verifier reported `missing_status` errors for these files.

## Required Fields Missing
- schema_version
- phase
- owner_role
- status
- must_read
- implementation_plan
- implementation_log
- notes
- client
- assigned_agent
- model
- domain (required for green_finance tasks)
- pilot (required for green_finance tasks)
- second_pilot_test (required for green_finance tasks)
- pilot_scope_ref (required for green_finance tasks)

## Remediation Steps Taken
1. Read canonical template from `Gove/tasks/_template/meta.yml`
2. Read recently fixed examples (GF-W1-UI-011, GF-W1-UI-012, GF-W1-UI-013)
3. Read PLAN.md files for tasks 014-023 to extract task details
4. Read `.kiro/specs/pilot-success-criteria/tasks.md` for complete task descriptions
5. Rewrote all 10 meta.yml files following canonical schema with all required fields
6. Verified TSK-CLEAN-001 passes (all 23 files now valid)

## Files Fixed
- tasks/GF-W1-UI-014/meta.yml
- tasks/GF-W1-UI-015/meta.yml
- tasks/GF-W1-UI-016/meta.yml
- tasks/GF-W1-UI-017/meta.yml
- tasks/GF-W1-UI-018/meta.yml
- tasks/GF-W1-UI-019/meta.yml
- tasks/GF-W1-UI-020/meta.yml
- tasks/GF-W1-UI-021/meta.yml
- tasks/GF-W1-UI-022/meta.yml
- tasks/GF-W1-UI-023/meta.yml

## Verification
```bash
bash scripts/audit/verify_tsk_clean_001.sh --evidence evidence/phase0/tsk_clean_001__task_metadata_truth_pass.json
# Result: PASS
```

## Status
RESOLVED - All 23 meta.yml files now conform to canonical schema and pass TSK-CLEAN-001 validation.
