# CUT-002 PLAN

Task: CUT-002
Owner role: SUPERVISOR
Depends on: CUT-001, SEC-001
failure_signature: PHASE1.CUT.002.REQUIRED

## objective
Query-surface trust-boundary enforcement after cutover

## scope
- Verify public read surfaces remain query-handler mediated.
- Preserve tenant/evidence authorization boundaries after cutover.
- Reject inline operational-table access in public read routes.

## acceptance_criteria
- Public GET read surfaces remain routed through query handlers, not inline data access logic.
- Admin mutation endpoints remain separate from public read surfaces.
- Query-surface boundary verifier emits PASS evidence against current code.

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## verification
- `bash scripts/audit/verify_cut_002_query_surface_boundary.sh`
- `python3 scripts/audit/validate_evidence.py --task CUT-002 --evidence evidence/phase1/cut_002_query_surface_boundary.json`

## no_touch_warnings
- Do not bypass query handlers from public read routes.
- Do not collapse admin mutation and public read route patterns.

## evidence_output
- `evidence/phase1/cut_002_query_surface_boundary.json`
