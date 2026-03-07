# TASK-OI-11 Plan

## Mission
Create retroactive scaffolds for all resolved governance contradiction tasks

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `find tasks -maxdepth 2 -type f -name meta.yml | rg 'TASK-GOV|TASK-INV-134'`

## Evidence Paths
- `evidence/phase1/retro_scaffold_completion.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
