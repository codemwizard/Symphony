# TSK-P0-LEVY-004 PLAN

failure_signature: PHASE0.TSK.P0.LEVY.004.REMEDIATION_TRACE_REQUIRED
origin_task_id: TSK-P0-LEVY-004

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## scope
- Add forward-only migration for `public.levy_remittance_periods` Phase-0 structural hook.
- Add fail-closed verifier `scripts/db/verify_levy_remittance_periods_hook.sh`.
- Wire verifier into `scripts/dev/pre_ci.sh` after TSK-P0-LEVY-003.
- Register evidence path in `docs/PHASE0/phase0_contract.yml`.

## verification_commands_run
- `bash scripts/db/verify_levy_remittance_periods_hook.sh`
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## final_status
- completed
