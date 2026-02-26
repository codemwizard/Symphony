# TSK-P1-REG-001 Plan

failure_signature: P1.REG.001.BOZ_OBSERVABILITY_READONLY
origin_task_id: TSK-P1-REG-001

## repro_command
- bash scripts/audit/verify_tsk_p1_reg_001.sh --evidence evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json

## scope
- Prove read-only regulator observability role posture.
- Provide deterministic reconstruction queries by instruction/correlation identifiers.
- Emit verifier-backed evidence including role/read-only/reconstruction checks.

## implementation_steps
1. Add reconstruction SQL set for ingress, dispatch attempts, and finality/reversal timelines.
2. Add verifier that checks role declarations, read-only markers, and query-set coverage.
3. Add optional runtime probes when `DATABASE_URL` is available.

## verification_commands_run
- bash scripts/audit/verify_tsk_p1_reg_001.sh --evidence evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json
- python3 scripts/audit/validate_evidence.py --task TSK-P1-REG-001 --evidence evidence/phase1/tsk_p1_reg_001__boz_observability_role_read_only_views.json
