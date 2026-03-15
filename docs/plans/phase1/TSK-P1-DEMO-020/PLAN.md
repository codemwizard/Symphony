# TSK-P1-DEMO-020 Plan

## mission
Create the fail-closed host-based demo runner with strict source gating, explicit process supervision, and structured run evidence.

## constraints
- No delegation to `pre_ci_demo.sh`.
- Must fetch `origin` before source gating.
- Default host behavior is a single active run.
- Must fail with a blocker note if stable health or provisioning truth is missing.

## verification_commands
- `bash scripts/audit/verify_tsk_p1_demo_020.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P1-DEMO-020 --evidence evidence/phase1/tsk_p1_demo_020_demo_runner.json`

## approval_references
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/security/SYMPHONY_DEMO_KEY_AND_ROTATION_POLICY.md`
- regulated surface applies because `scripts/dev/**`, `scripts/audit/**`, and `evidence/**` are touched

## evidence_paths
- `evidence/phase1/tsk_p1_demo_020_demo_runner.json`
