# EXEC_LOG — TASK-GOV-AWC7

Plan: `docs/plans/phase1/TASK-GOV-AWC7/PLAN.md`

## Log

### Start

- Opened to remove the approval-policy mismatch between the AGENTS contract and the mechanical enforcement layer.

### Implementation

- Added `docs/operations/**` and `evidence/**` to the mechanically enforced regulated-surface patterns.
- Updated the shared approval path matcher so `/**` patterns are treated as
  nested prefix matches rather than relying only on `Path.match`.
- Extended the approval-requirement test harness to cover docs/operations and evidence path cases.
- Updated the conformance spec so it names REGULATED_SURFACE_PATHS.yml as the mechanical source of truth.

## Final Summary

Completed. Mechanical approval enforcement now matches the broader regulated
surface contract for docs/operations and evidence paths.

```text
failure_signature: GOV.AWC7.REGULATED_SURFACE_ALIGNMENT
origin_task_id: TASK-GOV-AWC7
repro_command: bash scripts/audit/tests/test_approval_metadata_requirements.sh
verification_commands_run: rg regulated patterns; rg test coverage; rg spec source-of-truth; approval requirement test suite
final_status: PASS
```
