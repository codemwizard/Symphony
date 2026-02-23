# TSK-P0-KYC-004 PLAN

failure_signature: PHASE0.TSK.P0.KYC.004.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-KYC-004

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add forward-only migration for `public.kyc_retention_policy` as immutable governance declaration table.
- Seed exactly one statutory Zambia FIC Act row.
- Add fail-closed verifier `scripts/db/verify_kyc_retention_policy_hook.sh`.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-KYC-003.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.
- Patch `docs/tasks/phase1_prompts.md` normalized block to repo-native verifier/evidence paths.

## verification_commands_run
- `bash scripts/db/verify_kyc_retention_policy_hook.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
