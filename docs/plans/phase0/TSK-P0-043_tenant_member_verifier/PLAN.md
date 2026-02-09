# Implementation Plan: Tenant/Member Verifier + SQLSTATE Mapping

task_id: TSK-P0-043
owner_role: DB_FOUNDATION
assigned_agent: db_foundation
created_utc: 2026-02-09T00:00:00Z

## Goal
Provide a deterministic DB verifier for tenant/client/member rails and ensure SQLSTATE codes used by the guard are registered.

## Scope
- In scope:
  - `scripts/db/verify_tenant_member_hooks.sh` verifier (evidence-emitting)
  - Wiring in `scripts/db/verify_invariants.sh`
  - SQLSTATE map entries for guard exceptions (`P7201`, `P7202`)
- Out of scope:
  - Application-layer error mapping beyond registry docs

## Deliverables
- Verifier:
  - `scripts/db/verify_tenant_member_hooks.sh`
- Wiring:
  - `scripts/db/verify_invariants.sh`
- Registry:
  - `docs/contracts/sqlstate_map.yml`

## Evidence
- `evidence/phase0/tenant_member_hooks.json`

## Verification
- `scripts/db/verify_invariants.sh`
- `bash scripts/db/verify_tenant_member_hooks.sh` (with `DATABASE_URL` set)

## Acceptance Criteria
- Verifier emits evidence JSON on PASS/FAIL deterministically.
- Verifier checks cover tables, ingress attribution + uniqueness, guard function + trigger, and outbox expand-first columns.
- SQLSTATE map includes `P7201` and `P7202`.
- Evidence is PASS in CI.

