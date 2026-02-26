# TSK-P1-ADP-003 PLAN

Task: TSK-P1-ADP-003
origin_task_id: TSK-P1-ADP-003
failure_signature: PHASE1.TSK.P1.ADP.003.DETERMINISTIC_RAIL_ROUTING

## repro_command
- `bash scripts/audit/verify_adp_003_deterministic_rail_routing.sh && python3 scripts/audit/validate_evidence.py --task TSK-P1-ADP-003 --evidence evidence/phase1/adp_003_deterministic_rail_routing.json`

## scope
- Implement table-driven worker routing from `rail_type` to adapter factory.
- Enforce fail-closed unknown `rail_type` behavior with SQLSTATE-equivalent error code.
- Emit verifier-backed evidence for deterministic routing and unknown-type exception path.

## verification_commands_run
- `bash scripts/audit/verify_adp_003_deterministic_rail_routing.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-ADP-003 --evidence evidence/phase1/adp_003_deterministic_rail_routing.json`
- `bash scripts/audit/verify_agent_conformance.sh`
