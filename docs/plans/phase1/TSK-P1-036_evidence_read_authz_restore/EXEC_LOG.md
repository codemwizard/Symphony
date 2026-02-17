# Execution Log: Evidence-Pack Read Authorization Restore

failure_signature: P1.SECURITY.EVIDENCE_READ_AUTHZ_BYPASS
origin_task_id: TSK-P1-036
task_id: TSK-P1-036
Plan: docs/plans/phase1/TSK-P1-036_evidence_read_authz_restore/PLAN.md

## change_applied
- Added `ApiAuthorization.AuthorizeEvidenceRead(...)` gate.
- Enforced `INGRESS_API_KEY` configuration and `x-api-key` validation for read endpoint.
- Retained tenant-bound lookup checks in evidence store path.

## verification_commands_run
- `scripts/dev/pre_ci.sh`

## final_status
PASS

## Final Summary
Evidence-pack endpoint now fails closed on missing auth config or invalid API key before any lookup is performed.
