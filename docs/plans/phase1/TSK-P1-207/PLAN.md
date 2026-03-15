# TSK-P1-207 Plan

## mission
Harden supervisor API privileged routes and token transport

## constraints
- Follow AGENT_ENTRYPOINT.md and docs/operations/AI_AGENT_OPERATION_MANUAL.md.
- Do not expand scope beyond the declared touches list.
- Regulated-surface changes must remain covered by approval metadata.

## verification_commands
- `bash scripts/audit/verify_hier_011_supervisor_access_mechanisms.sh`
- `bash scripts/audit/verify_tsk_p1_207.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-207 --evidence evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json`

## approval_references
- AGENT_ENTRYPOINT.md
- docs/operations/AI_AGENT_OPERATION_MANUAL.md
- approvals/2026-03-14/BRANCH-feat-demo-deployment-repair.md

## evidence_paths
- evidence/phase1/tsk_p1_207_supervisor_api_auth_hardening.json
