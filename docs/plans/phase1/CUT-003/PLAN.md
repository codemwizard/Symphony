# CUT-003 PLAN

Task: CUT-003
Owner role: SUPERVISOR
Depends on: CUT-001, CMD-001
failure_signature: PHASE1.CUT.003.REQUIRED

## objective
Projection cutover runbook and rollback discipline

## scope
- Define operator prerequisites, freeze point, cutover sequence, rollback, and evidence outputs.
- Keep the runbook phase-accurate and free of dual-write language.

## acceptance_criteria
- Runbook defines prerequisites, cutover sequence, stop conditions, rollback, and evidence outputs.
- Runbook is specific to the Phase-1 projection/query cutover, not generic deployment prose.
- Runbook verifier emits PASS evidence.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `bash scripts/audit/verify_cut_003_projection_cutover_runbook.sh`
- `python3 scripts/audit/validate_evidence.py --task CUT-003 --evidence evidence/phase1/cut_003_projection_cutover_runbook.json`

## no_touch_warnings
- Do not omit rollback or stop conditions.
- Do not reintroduce dual-write or compatibility-shim posture.

## evidence_output
- `evidence/phase1/cut_003_projection_cutover_runbook.json`
