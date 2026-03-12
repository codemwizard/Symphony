# PLAN — TASK-GOV-AWC3

## Mission

Retroactively close the approval gap for TASK-GOV-AWC1 and TASK-GOV-AWC2 and
record the remediation directly in the canonical governance artifacts.

## Scope

This task is limited to:
- the retroactive approval artifacts
- approval metadata
- the workflow control plan anomaly note
- the AWC1/AWC2 evidence and exec logs
- its own task pack files

## Verification Commands

```bash
rg -n "BRANCH-main-gov-awc-retroactive-closeout" approvals/2026-03-12/BRANCH-main-gov-awc-retroactive-closeout.md approvals/2026-03-12/BRANCH-main-gov-awc-retroactive-closeout.approval.json evidence/phase1/approval_metadata.json
python3 - <<'PY'
import json
p='approvals/2026-03-12/BRANCH-main-gov-awc-retroactive-closeout.approval.json'
d=json.load(open(p))
paths=set(d['scope']['paths_changed'])
required={
    'AGENT_ENTRYPOINT.md','AGENTS.md','agent_manifest.yml',
    'docs/operations/AGENT_ASSIGNMENT_PROCESS.md','docs/operations/AGENT_PROMPT_ROUTER.md','docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md',
    'docs/operations/TASK_CREATION_PROCESS.md','docs/operations/POLICY_PRECEDENCE.md','docs/operations/PHASE_LIFECYCLE.md',
    'scripts/agent/run_task.sh','docs/plans/phase1/TASK-GOV-AWC1/EXEC_LOG.md','docs/plans/phase1/TASK-GOV-AWC2/EXEC_LOG.md',
    'evidence/phase1/task_gov_awc1.json','evidence/phase1/task_gov_awc2.json'
}
missing=sorted(required-paths)
assert not missing, missing
print('PASS')
PY
rg -n "Known Execution Anomaly|retroactive approval|late-approval" docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md docs/plans/phase1/TASK-GOV-AWC1/EXEC_LOG.md docs/plans/phase1/TASK-GOV-AWC2/EXEC_LOG.md
```

## Evidence

- `evidence/phase1/task_gov_awc3_retroactive_approval_closeout.json`

## Remediation Markers

```text
failure_signature: GOV.AWC3.RETROACTIVE_APPROVAL_CLOSEOUT
origin_task_id: TASK-GOV-AWC3
repro_command: rg -n "BRANCH-main-gov-awc-retroactive-closeout" approvals/2026-03-12/BRANCH-main-gov-awc-retroactive-closeout.md approvals/2026-03-12/BRANCH-main-gov-awc-retroactive-closeout.approval.json evidence/phase1/approval_metadata.json
verification_commands_run: see Verification Commands
final_status: PASS
```
