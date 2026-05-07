# Phase-0 Migration Spec — Business Foundation Hooks

**Migration:** `schema/migrations/0020_business_foundation_hooks.sql`  
**Verifier:** `scripts/db/verify_business_foundation_hooks.sh`  
**Evidence:** `evidence/phase0/business_foundation_hooks.json`

## Intent

Add *foundation-only* schema hooks so the business model can be **auditably billable** (who pays, what was billed, who/what the event was about) and **stitchable** (correlation across ingress/outbox/evidence) without introducing custody or settlement.

## What it adds

### Financial responsibility (payer)
- `public.billable_clients` (root payer entity)
- `public.tenants.billable_client_id` (FK) with `CHECK (billable_client_id IS NOT NULL) NOT VALID`  
  - enforced for **new** tenant rows immediately
  - avoids forcing an immediate backfill for any pre-existing rows

### Operational hierarchy
- `public.tenants.parent_tenant_id` (self-FK) for nested programs/coops

### Stitching primitive
- `correlation_id UUID NOT NULL` with defaults on:
  - `public.ingress_attestations`
  - `public.payment_outbox_pending`
  - `public.payment_outbox_attempts`
- Optional references:
  - `upstream_ref`, `nfs_sequence_ref` on the same tables

### Auditably billable usage ledger (append-only)
- `public.billing_usage_events`
  - links payer (`billable_client_id`) + data boundary (`tenant_id`)
  - optional operational actor (`client_id`)
  - optional *subject* (`subject_member_id`) for member-level billing
  - correlation + instruction/outbox/attempt/attestation pointers
  - append-only trigger enforced

### External proof hashes (append-only)
- `public.external_proofs`
  - stores only hashes + minimal metadata (no raw 3rd-party payloads)
  - links to `tenant_id`, `billable_client_id`, optional `attestation_id`, optional `subject_member_id`
  - append-only trigger enforced

## Invariant

- `INV-090` — Business foundation hooks are present and enforced (see `docs/invariants/INVARIANTS_MANIFEST.yml`).
