# TASK-INVPROC-05 Plan

## Mission
Bind PR and exception governance to invariant process contracts.

## Constraints
- Keep DRD semantics aligned with canonical remediation policy.
- Do not create duplicate governance definitions.

## Verification Commands
- `bash scripts/audit/verify_invariant_process_governance_links.sh`
- `test -f .github/pull_request_template.md`
- `test -f docs/invariants/exceptions/EXCEPTION_TEMPLATE.md`

## Evidence Paths
- `evidence/phase1/invproc_05_governance_links.json`

## Approval References
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
