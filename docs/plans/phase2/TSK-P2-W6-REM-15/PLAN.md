# Implementation Plan: TSK-P2-W6-REM-15

## Mission
Reassign the `K13` exception code in `enforce_k13_taxonomy_alignment` from `GF060` to `GF061` to avoid collision with legacy codes.

## Constraints
- **Forward-only migration**: Must be a new migration file (`0155_reassign_k13_sqlstate_gf061.sql`), do not edit `0151`.
- **Trigger Integrity**: Ensure the function signature and execution behavior remains identical except for the SQLSTATE.

## Verification Commands
- `bash scripts/db/verify_tsk_p2_w6_rem_15.sh`
- `python3 scripts/audit/validate_evidence.py --task TSK-P2-W6-REM-15 --evidence evidence/phase2/tsk_p2_w6_rem_15.json`

## Approval References
- Phase: 2
- Architect Decision: `W6-REM-implementation_plan.md` (v8)

## Evidence Paths
- `evidence/phase2/tsk_p2_w6_rem_15.json`
