# TASK-UI-WIRE-009 Plan

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective
Preserve the SIM-swap tab in the new shell while forcing truthful DEMO_BACKED labeling for Phase 1.

## Scope
- keep the panel visible
- explicitly label it DEMO_BACKED
- update source-of-truth and verifier coverage

## Verification
- bash scripts/audit/verify_task_ui_wire_009.sh
- python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-009 --evidence evidence/phase1/task_ui_wire_009_sim_swap.json
