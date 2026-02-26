# TSK-P1-REG-002 Plan

failure_signature: P1.REG.002.DAILY_REPORT_SIGNED_OUTPUT
origin_task_id: TSK-P1-REG-002

## repro_command
- bash scripts/audit/verify_reg_002_daily_report_signed_output.sh

## scope
- Implement deterministic daily regulatory report endpoint.
- Add report signing and key-id headers.
- Prove determinism/signature verification via self-test evidence.

## implementation_steps
1. Add `/v1/regulatory/reports/daily` endpoint with deterministic output fields.
2. Add signature generation/verification helper using evidence signing key material.
3. Add self-test mode and verifier evidence checks.

## verification_commands_run
- bash scripts/audit/verify_reg_002_daily_report_signed_output.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-REG-002 --evidence evidence/phase1/reg_002_daily_report_signed_output.json
