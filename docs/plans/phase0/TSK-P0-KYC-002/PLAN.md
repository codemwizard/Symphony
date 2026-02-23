# TSK-P0-KYC-002 PLAN

failure_signature: PHASE0.TSK.P0.KYC.002.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-KYC-002

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add forward-only migration for `public.kyc_verification_records` Phase-0 structural hook.
- Add fail-closed verifier `scripts/db/verify_kyc_verification_records_hook.sh`.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-KYC-001.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.
- Patch `docs/tasks/phase1_prompts.md` TSK-P0-KYC-002 to canonical member FK target `public.tenant_members(member_id)`.

## verification_commands_run
- `bash scripts/db/verify_kyc_verification_records_hook.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
