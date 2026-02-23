# TSK-P0-KYC-003 PLAN

failure_signature: PHASE0.TSK.P0.KYC.003.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-KYC-003

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add forward-only migration for `public.payment_outbox_pending.kyc_hold` Phase-0 expand-first hook.
- Add fail-closed verifier `scripts/db/verify_kyc_hold_hook.sh`.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-KYC-002.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.
- Patch `docs/tasks/phase1_prompts.md` normalized block to repo-native verifier/evidence paths.

## verification_commands_run
- `bash scripts/db/verify_kyc_hold_hook.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
