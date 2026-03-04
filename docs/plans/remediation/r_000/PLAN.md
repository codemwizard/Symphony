# Phase 0.1 / Remediation Plan: R-000

## Mission
Contain the `supervisor_api` by enforcing local-only bind and removing the `x-admin-claim` bypass header. Also, implement strict `ADMIN_API_KEY` enforcement on admin endpoints.

## Constraints
- **Fail-Closed**: Missing or invalid `ADMIN_API_KEY` must result in an immediate 503/403 block.
- **Bind Verification**: The bind address must remain `127.0.0.1` locally and pass regression gating.
- **No Reliance on Upstream**: Must not depend on upstream gateway for admin boundary isolation.

## Verification
- Run `bash scripts/audit/verify_supervisor_bind_localhost.sh`
- Code scan: `semgrep --config security/semgrep --severity ERROR --error`
- Execute `bash scripts/audit/test_admin_endpoints_require_key.sh`
- Evidence artifact `evidence/security_remediation/r_000_containment.json` must be generated.

## Approvals
- Required: Human approval prior to gating, documented in `approvals/` as per the `AI_AGENT_OPERATION_MANUAL.md`.
