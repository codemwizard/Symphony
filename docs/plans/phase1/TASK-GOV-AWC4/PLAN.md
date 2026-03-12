# PLAN — TASK-GOV-AWC4

## Mission

Repair the `TASK-GOV-AWC2` task contract so it truthfully describes the
implemented bootstrap invocation hardening alongside the readiness gate.

## Scope

This task is limited to the AWC2 task pack and its evidence.

## Verification Commands

```bash
rg -n "bash scripts/agent/bootstrap.sh|No other lines in `run_task.sh` are modified" docs/plans/phase1/TASK-GOV-AWC2/PLAN.md
rg -n "bootstrap invocation|scope drift|Undeclared scope drift" tasks/TASK-GOV-AWC2/meta.yml docs/plans/phase1/TASK-GOV-AWC2/EXEC_LOG.md evidence/phase1/task_gov_awc2.json
bash scripts/audit/verify_task_pack_readiness.sh --task TASK-GOV-AWC2
```

## Evidence

- `evidence/phase1/task_gov_awc4_awc2_contract_repair.json`

## Remediation Markers

```text
failure_signature: GOV.AWC4.AWC2_CONTRACT_REPAIR
origin_task_id: TASK-GOV-AWC4
repro_command: bash scripts/audit/verify_task_pack_readiness.sh --task TASK-GOV-AWC2
verification_commands_run: see Verification Commands
final_status: PASS
```
