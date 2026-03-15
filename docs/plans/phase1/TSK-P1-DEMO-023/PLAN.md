# TSK-P1-DEMO-023 Plan

## mission
Create a strict start-now checklist for beginning host-based demo deployment and end-to-end rehearsal without conflating rehearsal start readiness with full-demo signoff.

## constraints
- No runtime, schema, or workflow changes.
- No direct push to `main` and no direct pull from `main` into working branches.
- Checklist must align with the existing host-based runbook, provisioning runbook, and demo security posture.
- Checklist must preserve `rehearsal-only` as the start mode unless stronger signoff conditions are proven.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_023.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-023 --evidence evidence/phase1/tsk_p1_demo_023_start_now_checklist.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `docs/operations/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_023_start_now_checklist.json`
