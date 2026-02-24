# TSK-P1-059 Plan

failure_signature: PHASE1.TSK.P1.059.PLAN_REQUIRED
origin_task_id: TSK-P1-059

## repro_command
- RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh

## scope
- Gate script modularization with no behavior changes.
- Preserve verifier order and evidence paths.
- Enforce single CI-parity diff base (`refs/remotes/origin/main`) and remove any `FETCH_HEAD` fallback semantics.

## implementation_steps
1. Keep top-level gate entrypoints stable.
2. Modularize internal script units without changing outcomes.
3. Remove optional diff-base fallback in pre_ci and fail closed when canonical base ref is unavailable.
4. Extend static parity verifier to assert canonical diff-base pinning and reject `FETCH_HEAD` references.
5. Verify behavior/evidence parity via pre_ci.

## verification_commands_run
- bash scripts/audit/verify_tsk_p1_059.sh --evidence evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json
- bash scripts/audit/verify_phase0_parity.sh
- scripts/audit/test_diff_semantics_parity.sh
- scripts/audit/verify_diff_semantics_parity.sh
- RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh

## final_status
- completed

## remediation_note_2026_02_24
- Removed optional `FETCH_HEAD` base-ref fallback from pre-CI parity path.
- Enforced fail-closed canonical base-ref resolution to `refs/remotes/origin/main`.
