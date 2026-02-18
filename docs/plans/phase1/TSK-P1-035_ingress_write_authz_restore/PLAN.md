# Implementation Plan: Ingress Write Authorization Restore

failure_signature: P1.SECURITY.INGRESS_WRITE_AUTHZ_BYPASS
origin_task_id: TSK-P1-035
first_observed_utc: 2026-02-17T00:00:00Z

## intent
Restore fail-closed authentication/authorization before write handling on ingress endpoint.

## deliverables
- Add authz guard for `/v1/ingress/instructions`.
- Enforce API key and scope checks (`x-tenant-id`, `x-participant-id`) prior to `IngressHandler.HandleAsync`.
- Return deterministic error codes for config/auth/scope failures.

## acceptance
- Unauthorized callers cannot reach persistence path.
- Scope mismatch is blocked with 403.
- Missing auth config fails closed.

## final_status
COMPLETED
