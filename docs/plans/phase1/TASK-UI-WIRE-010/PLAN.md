# TASK-UI-WIRE-010 Plan

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective
Replace the decorative pilot success panel with rendering derived from DEMO-011 evidence and related rehearsal artifacts.

## Scope
- read DEMO-011 gate evidence
- render pass/fail/pending state from evidence
- fail closed when evidence is missing or contradictory

## Verification
- bash scripts/audit/verify_task_ui_wire_010.sh
- python3 scripts/audit/validate_evidence.py --task TASK-UI-WIRE-010 --evidence evidence/phase1/task_ui_wire_010_success_gate_panel.json
- bash scripts/audit/verify_tsk_p1_demo_011.sh
