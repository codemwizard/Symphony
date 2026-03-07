# TASK-OI-09 Plan

## Mission
Re-home SEC-G08 control-plane annotation onto INV-134 branch context

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `rg -n "SEC-G08" docs/control_planes/CONTROL_PLANES.yml`

## Evidence Paths
- `evidence/phase1/sec_g08_control_plane_rehome.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
