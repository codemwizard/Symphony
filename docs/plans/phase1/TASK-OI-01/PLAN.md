# TASK-OI-01 Plan

## Mission
Remediate branch discipline for INV-134 work currently on main

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `git branch --show-current`

## Evidence Paths
- `evidence/phase1/branch_remediation_inv134.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
