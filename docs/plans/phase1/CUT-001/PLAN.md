# CUT-001 PLAN

Task: CUT-001
Owner role: SUPERVISOR
Depends on: PROJ-002
failure_signature: PHASE1.CUT.001.REQUIRED

## objective
One-shot projection cutover completeness

## scope
- Enforce one-shot projection cutover semantics for active Phase-1 artifacts.
- Fail closed on surviving legacy projection/read contract references.
- Treat PROJ-002 proof as a prerequisite.

## acceptance_criteria
- Projection cutover task, plan, verifier, and contract references are complete and self-consistent.
- No banned legacy contract references remain in active Phase-1 projection cutover artifacts.
- PROJ-002 verifier passes as a prerequisite for CUT-001 completion.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `bash scripts/audit/verify_cut_001_one_shot_projection_cutover.sh`
- `python3 scripts/audit/validate_evidence.py --task CUT-001 --evidence evidence/phase1/cut_001_one_shot_projection_cutover.json`

## no_touch_warnings
- Do not retain legacy contract references or dual-write posture.
- Do not declare cutover complete without PROJ-002 proof.

## evidence_output
- `evidence/phase1/cut_001_one_shot_projection_cutover.json`
