# TSK-P0-101 PLAN

Task: TSK-P0-101

## Scope
- Confirm ordered checks runner remains wired in `scripts/dev/pre_ci.sh`.
- Emit deterministic task evidence via `scripts/audit/verify_tsk_p0_101.sh`.

## Verification
- `bash scripts/audit/verify_tsk_p0_101.sh --evidence evidence/phase0/tsk_p0_101__ordered_checks_runner_gating.json`
