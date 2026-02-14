# TSK-P1-025 Execution Log

failure_signature: PHASE1.TSK.P1.025
origin_task_id: TSK-P1-025

## repro_command
`scripts/dev/pre_ci.sh`

## verification_commands_run
- `bash scripts/audit/verify_phase1_demo_proof_pack.sh`
- `bash scripts/dev/pre_ci.sh`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## final_status
COMPLETED

Plan: `docs/plans/phase1/TSK-P1-025_regulator_and_tier_1_demo_proof_pack/PLAN.md`

## Final Summary
- Added deterministic demo-proof pack verifier that emits regulator and tier-1 artifacts mapped to machine evidence.
- Wired demo-pack verification into pre-CI post-DB ordering for parity with produced evidence.
