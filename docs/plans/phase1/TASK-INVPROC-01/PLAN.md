# TASK-INVPROC-01 Plan

## Mission
Canonicalize invariants governance baseline documents and precedence.

## Constraints
- No runtime/product behavior changes.
- Follow phase taxonomy from `PHASE_LIFECYCLE.md`.
- Keep governance references anchored to operation manual and manifest/workflow.

## Verification Commands
- `test -f docs/governance/invariant-register-v1.md`
- `test -f docs/governance/ci-gate-spec-v1.md`
- `test -f docs/governance/regulator-evidence-pack-template-v1.md`
- `rg -n "INVARIANTS_MANIFEST.yml|invariants.yml|pre_ci.sh" docs/governance/*.md`

## Evidence Paths
- `evidence/phase1/invproc_01_governance_baseline.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
