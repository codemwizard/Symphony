# TASK-GOV-C6 Plan

## Mission
Canonicalize INVARIANTS_QUICK regeneration trigger rule

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `rg -n "INVARIANTS_MANIFEST|generate_invariants_quick" .codex/rules/02-invariants-contract.md`

## Evidence Paths
- `evidence/phase1/governance_c6_invariants_quick.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
