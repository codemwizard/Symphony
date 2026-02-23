# TSK-P0-208 PLAN

failure_signature: PHASE0.TSK.P0.208.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-208

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Implement `scripts/audit/verify_tsk_p0_208.sh` for gate↔invariant linkage auditing.
- Emit deterministic evidence at `evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json`.
- Wire verifier into `scripts/dev/pre_ci.sh` after KYC hook verifiers.
- Register task evidence in `docs/PHASE0/phase0_contract.yml`.
- Add task metadata in `tasks/TSK-P0-208/meta.yml`.

## verification_commands_run
- `bash scripts/audit/verify_tsk_p0_208.sh --evidence evidence/phase0/tsk_p0_208__gate_invariant_linkage_audit.json`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
