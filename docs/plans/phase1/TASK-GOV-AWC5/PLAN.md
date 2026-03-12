# PLAN — TASK-GOV-AWC5

## Mission

Make evidence-output inclusion in `touches` a canonical rule for all new task
packs without changing assignment derivation.

## Scope

Canonical governance/task-definition docs and the task DOD template only.

## Verification Commands

```bash
rg -n "evidence.*touches|do not determine `assigned_agent`|do not use declared evidence paths as assignment signals" docs/operations/AGENT_ASSIGNMENT_PROCESS.md docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md docs/operations/TASK_CREATION_PROCESS.md
rg -n "Mirror this concrete evidence path into the task pack `touches:` list" docs/contracts/templates/TASK_DOD_TEMPLATE.yml
python3 - <<'PY'
import yaml
yaml.safe_load(open('docs/contracts/templates/TASK_DOD_TEMPLATE.yml'))
print('PASS')
PY
```

## Evidence

- `evidence/phase1/task_gov_awc5_evidence_touches_rule.json`

## Remediation Markers

```text
failure_signature: GOV.AWC5.EVIDENCE_TOUCHES_RULE
origin_task_id: TASK-GOV-AWC5
repro_command: rg -n "evidence.*touches" docs/operations/AGENT_ASSIGNMENT_PROCESS.md docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md docs/operations/TASK_CREATION_PROCESS.md
verification_commands_run: see Verification Commands
final_status: PASS
```
