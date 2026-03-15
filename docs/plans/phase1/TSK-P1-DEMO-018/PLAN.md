# TSK-P1-DEMO-018 Plan

## mission
Create the primary operator-grade host-based runbook for the Phase-1 Symphony demo on the current server.

## constraints
- No schema or runtime business-logic changes.
- No direct push to `main` and no direct pull from `main` into working branches.
- Deployment source must be a clean deployment checkout tracking `origin/main`.
- Kubernetes remains appendix-only for this host.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_018.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-018 --evidence evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `docs/operations/**` and `scripts/audit/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_018_e2e_runbook.json`
