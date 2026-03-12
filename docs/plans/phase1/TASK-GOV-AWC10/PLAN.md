# PLAN — TASK-GOV-AWC10

## Mission

Produce a repo-truthful audit of runner-targeted JSON evidence writers that
still omit `run_id`, and convert that inventory into explicit cleanup batches.

## Scope

This task is limited to:
- `docs/operations/RUN_ID_EVIDENCE_AUDIT.md`
- regulated approval metadata for this branch batch
- its own task pack files

## Non-Goals

- Do not patch the remaining verifier scripts in this task.
- Do not claim universal breakage where only some verifier families are affected.

## Exact Change

1. Record `TASK-INVPROC-06` as the resolved reference case after AWC9.
2. Audit the remaining runner-targeted JSON evidence backlog by verifier family.
3. Define explicit cleanup batches with task IDs and owner-role recommendations.

## Verification Commands

```bash
rg -n "Resolved Reference Case|TASK-INVPROC-06|Cleanup Batches|TASK-GOV-RUNID-INT1|TASK-GOV-RUNID-GOV1|TASK-GOV-RUNID-DEMO1|TASK-GOV-RUNID-HARD1|TASK-GOV-RUNID-CUT1|TASK-GOV-RUNID-P0A" docs/operations/RUN_ID_EVIDENCE_AUDIT.md
rg -n "run_id|SYMPHONY_RUN_ID" scripts/audit/verify_invproc_06_ci_wiring_closeout.sh scripts/audit/verify_human_governance_review_signoff.sh
bash scripts/audit/verify_agent_conformance.sh
```

## Evidence

- `evidence/phase1/task_gov_awc10_run_id_audit.json`

## Remediation Markers

```text
failure_signature: GOV.AWC10.RUN_ID_AUDIT
origin_task_id: TASK-GOV-AWC10
repro_command: rg -n "Resolved Reference Case|Cleanup Batches" docs/operations/RUN_ID_EVIDENCE_AUDIT.md
verification_commands_run: pending
final_status: PENDING
```
