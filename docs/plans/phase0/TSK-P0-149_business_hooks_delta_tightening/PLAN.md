# Implementation Plan (TSK-P0-149)

failure_signature: P0.BIZ.HOOKS.DELTA_TIGHTENING.NEW_ROW_ENFORCEMENT_MISSING
origin_task_id: TSK-P0-149
repro_command: source infra/docker/.env && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}" && scripts/db/verify_business_foundation_hooks.sh

## Goal
Tighten Phase-0 Business Foundation Hooks so **new rows** are:
- **auditably billable**: tenant and proof events are payer-attributed by construction
- **stitchable**: correlation IDs are always present for new ingress/outbox/proof artifacts

This MUST preserve Phase-0 constraints:
- forward-only migrations
- expand-first semantics (no backfill required now)
- no runtime DDL in production paths

## Source Context
The intent and recommended mechanics are captured in:
- `Business-Hook_Delta_resolution.txt`
- `docs/PHASE0/BUSINESS_HOOK_DELTA_RESOLUTION_REVIEW.md`

Decisions locked in (user-provided):
1. `external_proofs` should be directly billable in Phase-0 for new rows only (derive in DB; fail-closed if unresolved).
2. `correlation_id` may be supplied by the app, but DB must enforce presence via set-if-null trigger.

## Scope
In scope:
- Add forward-only DB tightening migration(s) for:
  - `tenants.billable_client_id` required for new rows (NOT VALID CHECK)
  - `billable_clients.client_key` stable payer key (unique + required for new rows)
  - correlation_id set-if-null triggers + NOT VALID CHECK on:
    - `ingress_attestations`
    - `payment_outbox_pending`
    - `payment_outbox_attempts`
  - `external_proofs` direct billability:
    - `tenant_id`, `billable_client_id` columns (expand-first)
    - DB trigger derives them from `attestation_id` join path; fails closed if unresolved
    - NOT VALID CHECK(s) require they are present for new rows

Out of scope:
- Backfill and `VALIDATE CONSTRAINT` on historical rows (Phase-1+)
- Converting columns to `NOT NULL` in Phase-0
- Runtime pricing/invoicing logic (Phase-1+)

## Proposed Migration Set (forward-only)
1. `schema/migrations/0026_business_foundation_delta_tightening.sql`
   - Add constraints and triggers (no data rewrite; expand-first).
2. `schema/migrations/0027_billable_clients_client_key_index_concurrently.sql`
   - Create `UNIQUE` index on `billable_clients.client_key` concurrently.
   - Must be `-- symphony:no_tx` (or include `CONCURRENTLY`) to avoid transaction wrapper.

## Acceptance Criteria
- New tenants cannot be inserted without `billable_client_id` (enforced via NOT VALID CHECK).
- New ingress/outbox rows always have `correlation_id` (trigger set-if-null + NOT VALID CHECK).
- New external proofs are always payer-attributed:
  - `external_proofs.tenant_id` and `external_proofs.billable_client_id` are populated/required for new rows.
  - Insert fails closed if the DB cannot derive attribution from `attestation_id`.
- All changes are forward-only migrations and pass Phase-0 DB lints and tests.

## Verification Commands
verification_commands_run:
- "bash scripts/dev/pre_ci.sh"
- "source infra/docker/.env && export DATABASE_URL=\"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}\" && scripts/db/migrate.sh"
- "source infra/docker/.env && export DATABASE_URL=\"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}\" && scripts/db/verify_business_foundation_hooks.sh"
- "source infra/docker/.env && export DATABASE_URL=\"postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}\" && scripts/db/verify_invariants.sh"

## Toolchain prerequisites (checklist)
- [ ] `psql` available (catalog checks and migrations).
- [ ] `python3` available (evidence emission).
- [ ] `docker` available (local parity runner with `FRESH_DB=1`).

final_status: OPEN

