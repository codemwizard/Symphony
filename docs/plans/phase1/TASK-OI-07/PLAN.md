# TASK-OI-07 Plan

## Mission
Wire dependency audit script into CI as fail-closed gate

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `rg -n "dotnet_dependency_audit|dep-audit" .github/workflows/*.yml`
- `bash scripts/security/dotnet_dependency_audit.sh --test-fail`

## Evidence Paths
- `evidence/phase1/dep_audit_ci_wiring.json`
- `evidence/phase1/dep_audit_gate.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
