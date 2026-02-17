# Implementation Plan: Evidence-Pack Read Authorization Restore

failure_signature: P1.SECURITY.EVIDENCE_READ_AUTHZ_BYPASS
origin_task_id: TSK-P1-036
first_observed_utc: 2026-02-17T00:00:00Z

## intent
Restore fail-closed authentication on evidence-pack read path.

## deliverables
- Add authz guard for `/v1/evidence-packs/{instruction_id}`.
- Require API key validation before handler execution.
- Keep tenant-scoped store lookup as secondary control.

## acceptance
- Unauthenticated requests fail before read handler.
- Existing tenant mismatch behavior remains fail-closed.

## final_status
COMPLETED
