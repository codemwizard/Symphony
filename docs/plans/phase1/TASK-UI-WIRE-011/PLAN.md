# TASK-UI-WIRE-011 Plan

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective
Close out the v3 supervisory UI port, retire the thin shell from primary demo use, and prove the remaining shell is operational and truthful.

## Scope
- remove or isolate the thin shell from normal demo navigation
- check the source-of-truth backing-mode matrix against the running UI
- fail if any LIVE surface still relies on static fallback under healthy pilot-demo conditions

## Verification
- bash scripts/audit/verify_task_ui_wire_011.sh
- python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-011 --evidence evidence/phase1/task_ui_wire_011_closeout.json
- bash scripts/dev/pre_ci.sh
