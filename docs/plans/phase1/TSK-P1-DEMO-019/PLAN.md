# TSK-P1-DEMO-019 Plan

## mission
Add a hardened server snapshot script that captures the demo host posture reproducibly and safely.

## constraints
- No raw secret values written to evidence.
- Output must remain inside the resolved run-bundle root.
- No schema or product-feature changes.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_019.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-019 --evidence evidence/phase1/tsk_p1_demo_019_server_snapshot.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- regulated surface applies because `scripts/dev/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_019_server_snapshot.json`
