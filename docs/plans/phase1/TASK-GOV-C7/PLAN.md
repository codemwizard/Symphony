# TASK-GOV-C7 Plan

## Mission
Maintain lifecycle taxonomy machine rules and artifact/process maps

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `python3 -c "import yaml; [yaml.safe_load(open(p)) for p in ['docs/operations/rules/lifecycle_phase_taxonomy.yml','docs/operations/rules/lifecycle_phase_artifacts.yml','docs/operations/rules/lifecycle_phase_process.yml']]; print('PASS')"`

## Evidence Paths
- `evidence/phase1/governance_c7_lifecycle_taxonomy.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
