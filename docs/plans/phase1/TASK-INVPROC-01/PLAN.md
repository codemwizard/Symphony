# TASK-INVPROC-01 Plan

## Mission
Canonicalize invariants governance baseline documents and precedence.

## Constraints
- No runtime/product behavior changes.
- Follow phase taxonomy from `PHASE_LIFECYCLE.md`.
- Keep governance references anchored to operation manual and manifest/workflow.

## Verification Commands
- `bash scripts/audit/verify_invproc_01_governance_baseline.sh`
- `rg -n "AI_AGENT_OPERATION_MANUAL.md|INVARIANTS_MANIFEST.yml|INVARIANT_ENFORCEMENT_MATRIX.md|invariants.yml|pre_ci.sh" docs/governance/*.md`
- `rg -n "INVARIANTS_MANIFEST.yml|INVARIANT_ENFORCEMENT_MATRIX.md|invariants.yml|pre_ci.sh" docs/operations/POLICY_PRECEDENCE.md`

## Evidence Paths
- `evidence/phase1/invproc_01_governance_baseline.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
