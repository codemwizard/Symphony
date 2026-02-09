# Implementation Plan: Tenant/Client/Member Rails (Phase-0)

task_id: TSK-P0-041
owner_role: DB_FOUNDATION
assigned_agent: db_foundation
created_utc: 2026-02-09T00:00:00Z

## Goal
Introduce Phase-0 tenant/client/member rails in the schema, using forward-only migrations and revoke-first posture.

## Scope
- In scope:
  - Tenant hierarchy tables: `tenants`, `tenant_clients`, `tenant_members`
  - Attribution columns on `ingress_attestations` and outbox tables (expand-first where needed)
  - Member/tenant consistency guard (ingress-only)
- Out of scope:
  - Runtime application logic
  - Backfills and validation scans beyond Phase-0

## Deliverables
- Forward-only migrations:
  - `schema/migrations/0014_tenants.sql`
  - `schema/migrations/0015_tenant_clients.sql`
  - `schema/migrations/0016_tenant_members.sql`
  - `schema/migrations/0017_ingress_tenant_attribution.sql`
  - `schema/migrations/0018_outbox_tenant_attribution.sql`
  - `schema/migrations/0019_member_tenant_consistency_guard.sql`

## Invariants / Evidence
- Invariants: INV-062..INV-066 (Tenant rails + member consistency)
- Evidence artifact (DB verifier):
  - `evidence/phase0/tenant_member_hooks.json`

## Verification
- Primary:
  - `scripts/db/verify_invariants.sh`
- Secondary:
  - `scripts/db/verify_tenant_member_hooks.sh`

## Acceptance Criteria
- Tables exist and privileges are revoke-first.
- `ingress_attestations.tenant_id` is UUID and NOT NULL.
- Unique index exists for `(tenant_id, instruction_id)` on `ingress_attestations`.
- Member/tenant guard function + trigger exist and are installed on `ingress_attestations`.
- Evidence is emitted deterministically and is PASS in CI.

