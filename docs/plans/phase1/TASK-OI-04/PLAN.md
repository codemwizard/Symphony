# TASK-OI-04 Plan

## Mission
Enforce Stage-A and Stage-B approval validation in conformance verifier

## Constraints
- lifecycle_phase must remain `1` and follow `PHASE_LIFECYCLE.md` taxonomy.
- Regulated-surface changes require Stage-A and Stage-B approval artifacts.
- DRD/trace semantics must defer to `REMEDIATION_TRACE_WORKFLOW.md`.

## Verification Commands
- `bash scripts/audit/verify_agent_conformance.sh --mode=stage-a --branch=test`
- `bash scripts/audit/verify_agent_conformance.sh --mode=stage-b --pr=1`

## Evidence Paths
- `evidence/phase1/agent_conformance_policy_guardian.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md` approval schema + sidecar requirements.
