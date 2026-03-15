# TSK-P1-208 Plan

## mission
Restore admin-only auth boundary for pilot-demo instruction generation

## constraints
- Follow AGENT_ENTRYPOINT.md and docs/operations/AI_AGENT_OPERATION_MANUAL.md.
- Do not expand scope beyond the declared touches list.
- Regulated-surface changes must remain covered by approval metadata.

## verification_commands
- `bash scripts/audit/verify_task_ui_wire_004.sh`
- `bash scripts/audit/verify_tsk_p1_208.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-208 --evidence evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json`

## approval_references
- AGENT_ENTRYPOINT.md
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
- approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.md

## evidence_paths
- evidence/phase1/tsk_p1_208_pilot_demo_generate_auth_boundary.json
