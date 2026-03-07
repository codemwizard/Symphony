# TASK-GOV-C1 Plan

## Mission
Establish policy precedence and remove apex-authority contradictions

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `test -f docs/operations/POLICY_PRECEDENCE.md`
- `rg -n "single source of truth" AGENTS.md .agent/README.md docs/operations | wc -l`

## Evidence Paths
- `evidence/phase1/governance_c1_policy_precedence.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
