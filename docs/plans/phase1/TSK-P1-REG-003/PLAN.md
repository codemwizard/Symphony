# TSK-P1-REG-003 Plan

failure_signature: P1.TSK.REG.003.INCIDENT_48H_EXPORT_REQUIRED
origin_task_id: TSK-P1-REG-003

## repro_command
- bash scripts/audit/verify_reg_003_incident_48h_export.sh --evidence evidence/phase1/reg_003_incident_48h_export.json

## scope
- Add regulatory incident schema with append-only incident events timeline.
- Add admin incident registration and 48-hour report export endpoint with signature.
- Enforce open-status report block and emit verifier-backed evidence.

## implementation_steps
1. Add migration for `regulatory_incidents` and `incident_events`.
2. Add incident store + API endpoints and report generation/signing logic.
3. Add task verifier and evidence emission.
4. Wire contract and verifier registry metadata.

## verification_commands_run
- bash scripts/audit/verify_agent_conformance.sh
- bash scripts/audit/verify_reg_003_incident_48h_export.sh --evidence evidence/phase1/reg_003_incident_48h_export.json
- python3 scripts/audit/validate_evidence.py --task TSK-P1-REG-003 --evidence evidence/phase1/reg_003_incident_48h_export.json
- RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh
