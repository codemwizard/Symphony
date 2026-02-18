# Business Invariants Addition - Implementation (Phase-0)

## Source
- Input: `BusinessInvariantsAddition.txt`
- Intent: convert business-model requirements into Phase-0 mechanical schema hooks and invariant gates.

## What the source is trying to achieve
The document is pushing one core idea: Phase-0 must not only be secure, it must be commercially and regulatorily provable.

It tries to move Symphony from:
- Technical integrity only (migrations, outbox, attestation)
to:
- Business integrity + governance provenance (billable events, external proof anchoring, dispute stitchability, tenant-to-payer accountability, multi-signature readiness).

Concretely, it asks for:
- Stronger security depth beyond grep heuristics (SAST tooling parity in local + CI).
- Evidence files that include reproducibility metadata, not only pass/fail status.
- Supply-chain gating.
- Governance artifacts (key policy stub, logging retention policy, ADRs, DDL allowlist governance).
- Business-foundation schema hooks so future monetization is mechanically enforceable:
  - billing usage ledger
  - external proofs ledger
  - correlation stitching columns
  - evidence pack primitives
  - tenant billable hierarchy
  - multi-signature ingress support

## Scope for this implementation file
Phase-0 only. Schema hooks + invariant checks + evidence emission.

Out of scope for Phase-0:
- Full runtime pricing/invoicing logic
- Deep runtime signature verification semantics
- Full ISO-20022 payload validation engine
- External WORM anchoring execution (schema support only)

## Phase-0 implementation cluster

### 1) Billing usage hook (cash-register tape)
Deliver:
- `billing_usage_events` append-only table.
- Subject attribution columns for billable traceability.
- Correlation linkage fields.

Required invariant:
- `INV-BILL-01`: billing usage table exists and is append-only.

### 2) External proof hook
Deliver:
- `external_proofs` append-only table bound to `ingress_attestations`.
- Provider, request hash, response hash, provider reference metadata.

Required invariant:
- `INV-PROOF-01`: third-party proof schema exists and is immutable.

### 3) Correlation stitching hook
Deliver:
- `correlation_id` on `ingress_attestations`, `payment_outbox_pending`, `payment_outbox_attempts`.
- Cross-rail placeholders: `upstream_ref`, `downstream_ref`, `nfs_sequence_ref` (nullable in Phase-0).
- Supporting indexes.

Required invariant:
- `INV-STITCH-01`: stitch columns and indexes exist.

### 4) Evidence pack primitive
Deliver:
- `evidence_packs` and `evidence_pack_items` append-only grouping primitive.
- Root hash field present (nullable in Phase-0).

Required invariant:
- `INV-EVID-PACK-01`: pack primitive exists and is append-only.

### 5) Billable hierarchy hook
Deliver:
- `billable_clients` table.
- `tenants.billable_client_id` and `tenants.parent_tenant_id` (expand-first).
- Tenant type classification field and constraints.

Required invariants:
- `INV-TEN-BILL-01`: tenant->billable root hook exists.
- `INV-TEN-HIER-01`: tenant hierarchy hook exists.

### 6) Multi-signature ingress hook
Deliver:
- `ingress_attestations.signatures JSONB NOT NULL DEFAULT '[]'::jsonb`.
- Keep existing single-signature fields as legacy-compatible.

Required invariant:
- `INV-IPDR-SIG-01`: multi-signature column exists with default empty array.

## Important semantic corrections (from mixed guidance in source)
- Do not overload "participant" for farmer/member subject identity.
- Use subject columns aligned to existing domain entities:
  - `subject_member_id` (member subject)
  - optional `subject_client_id` (entity subject)
- Keep member attribution optional where flows require no member subject, but enforce consistency when present.
- Treat signature-subject matching as Phase-1/2 enforcement, not Phase-0 schema invariant.

## Migration strategy (forward-only, expand then tighten)

### Migration A: expand hooks
- Add new tables, columns, indexes, append-only triggers/functions.
- Use nullable fields and `NOT VALID` constraints where backfill may be required.

### Migration B: contract/tighten
- Validate deferred constraints.
- Apply `NOT NULL` only after data backfill and compatibility checks.

## Verification and evidence
Add verifier:
- `scripts/db/verify_business_foundation_hooks.sh`

Verifier must assert:
- Table/column/constraint/index/trigger presence for all hooks above.
- Append-only enforcement on ledger-like tables.
- Multi-signature column presence/default.

Evidence output:
- `evidence/phase0/business_foundation_hooks.json`

Evidence must include:
- `status`
- checked objects (tables/columns/constraints/indexes/triggers)
- schema fingerprint
- git SHA
- check timestamp

## CI wiring
Wire verifier into:
- `scripts/db/verify_invariants.sh`
- optionally `scripts/audit/run_invariants_fast_checks.sh` if runtime is acceptable.

Phase-0 gate behavior:
- fail-closed for missing required hooks/invariants.

## Suggested task split (task-first workflow)
- `TSK-P0-080`: Billing usage ledger hook + invariant.
- `TSK-P0-081`: External proofs hook + invariant.
- `TSK-P0-082`: Correlation stitching hook + invariant.
- `TSK-P0-083`: Evidence pack primitives + invariant.
- `TSK-P0-084`: Tenant billable hierarchy hook + invariants.
- `TSK-P0-085`: Multi-signature ingress hook + invariant.
- `TSK-P0-086`: Business foundation verifier + evidence wiring.

## Acceptance criteria
- All new schema hooks exist through forward-only migrations.
- Invariant verifier emits deterministic evidence JSON.
- Invariants gate fails on missing hooks and passes when present.
- No runtime DDL introduced.
- Existing append-only and security hardening posture remains intact.
