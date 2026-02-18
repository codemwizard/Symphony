# Phase-0 Migration Spec — Business Foundation Hooks (Auditably Billable + Stitchable)

**Migrations:**
- `schema/migrations/0020_business_foundation_hooks.sql`
- `schema/migrations/0026_business_foundation_delta_tightening.sql`
- `schema/migrations/0027_billable_clients_client_key_index_concurrently.sql`

**Verifier:** `scripts/db/verify_business_foundation_hooks.sh`  
**Evidence:** `evidence/phase0/business_foundation_hooks.json`

## Intent

Add foundation-only schema hooks so the business model is:
- **auditably billable**: the database can mechanically answer “who pays?” for core billable events
- **stitchable**: operational artifacts can be correlated across ingress/outbox/proofs without relying on best-effort app behavior

Phase-0 rule: strengthen guarantees **for new writes** while deferring backfill/validation of historical rows to Phase-1+.

## What Phase-0 Enforces (New Rows Only)

This repo uses Postgres `NOT VALID` constraints to enforce guarantees for new writes immediately while avoiding a scan/backfill of historical rows.
`NOT VALID` constraints:
- are enforced for all **new rows**
- are not validated against existing rows until `VALIDATE CONSTRAINT` is run later

### 1) Financial responsibility (payer)

- `public.billable_clients` is the payer root entity.
- `public.tenants.billable_client_id` links each tenant to a payer.

New-row enforcement:
- `tenants_billable_client_required_new_rows_chk` (NOT VALID) ensures new tenants cannot be created without `billable_client_id`.

### 2) Stable payer identifier (`client_key`)

UUIDs are fine internally, but audits and billing operations need a stable, human-governed identifier.

New-row enforcement:
- `public.billable_clients.client_key` exists.
- `billable_clients_client_key_required_new_rows_chk` (NOT VALID) requires new billable clients to have a non-empty key.
- `ux_billable_clients_client_key` enforces uniqueness where `client_key IS NOT NULL`.

### 3) Stitching primitive (correlation_id)

Ingress and outbox tables include `correlation_id` as the primary stitching primitive.

Source policy:
- The application **may supply** `correlation_id`.
- The database **must guarantee** `correlation_id` exists for new rows.

New-row enforcement:
- Set-if-null triggers on INSERT:
  - `trg_set_corr_id_ingress_attestations`
  - `trg_set_corr_id_payment_outbox_pending`
  - `trg_set_corr_id_payment_outbox_attempts`
- NOT VALID checks (enforced for new rows):
  - `ingress_attestations_correlation_required_new_rows_chk`
  - `payment_outbox_pending_correlation_required_new_rows_chk`
  - `payment_outbox_attempts_correlation_required_new_rows_chk`

### 4) External proofs: directly billable attribution

`public.external_proofs` is an append-only ledger of proof events. Phase-0 requires direct billable attribution for new rows:
- `external_proofs.tenant_id`
- `external_proofs.billable_client_id`

Enforcement policy:
- DB derives attribution from `external_proofs.attestation_id` by joining:
  - `ingress_attestations(attestation_id -> tenant_id)`
  - `tenants(tenant_id -> billable_client_id)`
- If derivation cannot be resolved, INSERT fails closed.
- If the app supplies values, DB verifies they match the derived values.

New-row enforcement:
- Trigger: `trg_set_external_proofs_attribution` (BEFORE INSERT)
- NOT VALID checks:
  - `external_proofs_tenant_required_new_rows_chk`
  - `external_proofs_billable_client_required_new_rows_chk`

## Append-Only Posture

All business ledgers introduced here are append-only (no UPDATE/DELETE). The verifier checks that the deny-mutation triggers exist.

## Deferred to Phase-1+

- Backfill historical rows (e.g., tenant billable linkages, correlation ids).
- `VALIDATE CONSTRAINT` for NOT VALID constraints.
- Converting columns to `NOT NULL`.
- Pricing, invoicing, and operational billing workflows.

## Invariants

The hooks are covered under:
- `INV-090..INV-096` (see `docs/invariants/INVARIANTS_MANIFEST.yml` and `docs/invariants/INVARIANTS_IMPLEMENTED.md`).

