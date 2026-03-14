# TSK-P1-DEMO-027 Execution Log

failure_signature: PHASE1.DEMO.027.EXECUTION
origin_task_id: TSK-P1-DEMO-027
Plan: docs/plans/phase1/TSK-P1-DEMO-027/PLAN.md

## repro_command

Finish the operator demo gate split by extending `scripts/dev/pre_ci_demo.sh` into a lean deployment gate that runs the exact enumerated verifier set plus runtime readiness checks, while leaving `scripts/dev/pre_ci.sh` as the engineering gate.

## verification_commands_run
- `bash scripts/audit/verify_tsk_p1_demo_025.sh`
- `bash scripts/audit/verify_tsk_p1_demo_026.sh`
- `bash scripts/audit/verify_tsk_p1_demo_027.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-027 --evidence evidence/phase1/tsk_p1_demo_027_demo_gate_split.json`

## Final Summary

Extended the existing demo-vs-`pre_ci` split from `TSK-P1-DEMO-015` into a real operator bring-up gate. `scripts/dev/pre_ci_demo.sh` now runs the exact narrow verifier set and runtime readiness checks required for demo bring-up, while deployment docs and the checklist now point operators to the lean gate instead of full `pre_ci.sh`.

## final_status
COMPLETED
