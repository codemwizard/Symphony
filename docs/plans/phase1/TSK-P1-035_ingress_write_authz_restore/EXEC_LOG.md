# Execution Log: Ingress Write Authorization Restore

failure_signature: P1.SECURITY.INGRESS_WRITE_AUTHZ_BYPASS
origin_task_id: TSK-P1-035
task_id: TSK-P1-035
Plan: docs/plans/phase1/TSK-P1-035_ingress_write_authz_restore/PLAN.md

## change_applied
- Added `ApiAuthorization.AuthorizeIngressWrite(...)` gate.
- Enforced `INGRESS_API_KEY` configuration and `x-api-key` validation.
- Added tenant and participant header-to-body scope checks before handler invocation.

## verification_commands_run
- `scripts/dev/pre_ci.sh`

## final_status
PASS

## Final Summary
Ingress write route now fails closed for missing config, invalid credentials, and scope mismatch before persistence logic executes.
