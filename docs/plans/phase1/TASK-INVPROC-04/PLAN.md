# TASK-INVPROC-04 Plan

## Mission
Normalize regulator evidence pack template to deterministic artifact mapping.

## Constraints
- Evidence references must match current repository artifact families.
- No invented runtime claims.

## Verification Commands
- `bash scripts/audit/verify_regulator_pack_template.sh`
- `rg -n "INV-|evidence/phase0|evidence/phase1" docs/governance/regulator-evidence-pack-template-v1.md`

## Evidence Paths
- `evidence/phase1/invproc_04_regulator_pack_template.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
