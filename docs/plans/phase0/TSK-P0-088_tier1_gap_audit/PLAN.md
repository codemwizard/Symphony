# PLAN — Tier-1 gap audit vs business goals (Phase-0)

## Task IDs
- TSK-P0-088

## Scope
- Produce an evidence-minded audit report of gaps between stated business goals (orchestration + evidence products) and current Phase-0 implementation.
- Include security/policy/compliance gaps that would block a Tier-1 audit posture.
- Provide concrete Phase-0-safe recommendations (schema hooks, gates, policy stubs, verifiers).

## Non-Goals
- Implement Phase-1/2 runtime services.
- “Declare compliance” without mechanical enforcement.

## Files / Paths Touched
- `docs/audits/TIER1_GAP_AUDIT_2026-02-06.md`
- `docs/tasks/PHASE0_TASKS.md`
- `tasks/TSK-P0-088/meta.yml`
- `docs/PHASE0/phase0_contract.yml`
- `docs/plans/phase0/INDEX.md`

## Gates / Verifiers
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_phase0_contract.sh`

## Expected Failure Modes
- Report claims controls are implemented without a script/test/gate.
- Report does not distinguish Phase-0 hooks vs Phase-1/2 runtime enforcement.

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_phase0_contract.sh`

## Dependencies
- None
