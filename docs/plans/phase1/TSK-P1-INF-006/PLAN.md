# TSK-P1-INF-006 PLAN

Task: TSK-P1-INF-006
origin_task_id: TSK-P1-INF-006
failure_signature: PHASE1.TSK.P1.INF.006.EVIDENCE_SIGNING_KEY_MANAGEMENT

## repro_command
- `bash scripts/infra/verify_tsk_p1_inf_006.sh --evidence evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json`

## scope
- Define and enforce root/phase signing key hierarchy with OpenBao-backed phase key material.
- Sign sample evidence files with key-id sidecars and validate signature verification.
- Prove key rotation mutates signatures and fail closed if OpenBao is unreachable.

## verification_commands_run
- `bash scripts/infra/verify_tsk_p1_inf_006.sh --evidence evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-INF-006 --evidence evidence/phase1/tsk_p1_inf_006__evidence_signing_key_management_openbao_rotation.json`
