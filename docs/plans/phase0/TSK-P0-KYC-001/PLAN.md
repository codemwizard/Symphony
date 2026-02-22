# TSK-P0-KYC-001 PLAN

failure_signature: PHASE0.TSK.P0.KYC.001.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-KYC-001

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add forward-only migration for `public.kyc_provider_registry` Phase-0 structural hook.
- Add fail-closed verifier `scripts/db/verify_kyc_provider_registry_hook.sh`.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-LEVY-004.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.

## verification_commands_run
- `bash scripts/db/verify_kyc_provider_registry_hook.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
