# TASK-GOV-C5 Plan

## Mission
Split editable vs regulated path authority in agent docs

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `rg -n "Editable paths|Regulated paths requiring approval metadata" AGENTS.md .codex/agents/security_guardian.md`

## Evidence Paths
- `evidence/phase1/governance_c5_path_authority.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
