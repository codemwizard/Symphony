# TASK-GOV-C2C3 Plan

## Mission
Canonicalize branch and commit conventions under lifecycle taxonomy

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `test -f docs/operations/GIT_CONVENTIONS.md`
- `rg -n "^## (Allowed|Accepted|Normative)" docs/operations/GIT_CONVENTIONS.md`
- `rg -n "git-conventions" .agent/workflows/git-conventions.md`

## Evidence Paths
- `evidence/phase1/governance_c2c3_git_conventions.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
