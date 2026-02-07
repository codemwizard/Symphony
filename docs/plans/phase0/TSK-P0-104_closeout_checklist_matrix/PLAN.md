# PLAN — Closeout checklist matrix (Checklist -> Gate/Invariant/Task)

## Task IDs
- TSK-P0-104

## Scope
- Create a dedicated, auditor-friendly matrix mapping the Phase-0 closeout checklist items to:
  - mechanical gates (CONTROL_PLANES gate IDs where applicable)
  - invariants (INVARIANTS_MANIFEST IDs)
  - task IDs (implemented vs planned closeout tasks)
  - evidence artifact paths

## Non-Goals
- Implement any of the planned closeout tasks (this is documentation only).
- Claim compliance/certification.

## Files / Paths Touched
- `docs/PHASE0/CLOSEOUT_CHECKLIST_MATRIX.md`
- `docs/tasks/PHASE0_TASKS.md`
- `tasks/TSK-P0-104/meta.yml`
- `docs/PHASE0/phase0_contract.yml`
- `docs/plans/phase0/INDEX.md`

## Gates / Verifiers
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_phase0_contract.sh`

## Expected Failure Modes
- Matrix claims a control is enforced without a referenced script/gate/evidence.
- Matrix omits planned tasks that are required for Tier-1 closeout.

## Verification Commands
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/verify_phase0_contract.sh`

## Dependencies
- TSK-P0-090..103 (audit gap closeout scaffolding)

