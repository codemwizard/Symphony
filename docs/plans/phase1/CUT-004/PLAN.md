# CUT-004 PLAN

Task: CUT-004
Owner role: SUPERVISOR
Depends on: CUT-002, CUT-003, PROJ-002
failure_signature: PHASE1.CUT.004.REQUIRED

## objective
Projection cutover readiness gate

## scope
- Aggregate CUT-001/002/003 and PROJ-001/002 proofs into a fail-closed gate.
- Emit single readiness evidence for Sprint 3 completion.

## acceptance_criteria
- Readiness gate fails if any prerequisite verifier fails or required evidence is missing.
- Readiness evidence names the prerequisite proofs it validated.
- Phase-1 contract and verifier registry include CUT-004 as the cutover promotion gate.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `bash scripts/audit/verify_cut_004_projection_cutover_gate.sh`
- `python3 scripts/audit/validate_evidence.py --task CUT-004 --evidence evidence/phase1/cut_004_projection_cutover_gate.json`

## no_touch_warnings
- Do not treat missing prerequisite proof as warning-only.
- Do not promote cutover without aggregated evidence.

## evidence_output
- `evidence/phase1/cut_004_projection_cutover_gate.json`
