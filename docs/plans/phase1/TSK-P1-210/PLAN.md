# TSK-P1-210 Plan

## mission
Remove supervisory fallback duplication and repeated reveal-model scans

## constraints
- Follow AGENT_ENTRYPOINT.md and docs/operations/AI_AGENT_OPERATION_MANUAL.md.
- Do not expand scope beyond the declared touches list.
- Regulated-surface changes must remain covered by approval metadata.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_210.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-210 --evidence evidence/phase1/tsk_p1_210_supervisory_optimization.json`
- `bash scripts/dev/pre_ci.sh`

## approval_references
- AGENT_ENTRYPOINT.md
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
- approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.md

## evidence_paths
- evidence/phase1/tsk_p1_210_supervisory_optimization.json
