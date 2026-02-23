# TSK-P0-210 PLAN

failure_signature: PHASE0.TSK.P0.210.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-210

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add `scripts/audit/verify_tsk_p0_210.sh` for BoZ observability role proof with SET ROLE denial posture.
- Ensure verifier refreshes canonical `scripts/db/verify_boz_observability_role.sh` evidence before task evidence.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-208.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.
- Add task metadata in `tasks/TSK-P0-210/meta.yml`.

## verification_commands_run
- `bash scripts/audit/verify_tsk_p0_210.sh --evidence evidence/phase0/tsk_p0_210__boz_observability_role_proof_include_set.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
