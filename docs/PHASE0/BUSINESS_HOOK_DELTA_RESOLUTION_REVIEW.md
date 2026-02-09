# Business Hook Delta Resolution Review (Bundle vs Repo)

Source: `Business-Hook_Delta_resolution.txt`

## What This Document Is Doing (Top-to-Bottom Intent)

The document is a decision memo plus a concrete implementation sketch for **tightening** the existing Phase-0 “Business Foundation Hooks” so the system is:

- **Auditably billable**: the database can answer, mechanically, “who pays” and “what was billed”.
- **Stitchable**: core operational artifacts (ingress, outbox pending, outbox attempts, evidence packs) can be correlated across boundaries without relying on best-effort application behavior.

The key constraint thread that runs throughout the document is:

> Strengthen guarantees **for new rows immediately** while avoiding operational risk and rewrite/backfill work for existing rows.

It proposes doing this using the **Postgres `NOT VALID` constraint pattern** and (where needed) triggers, which matches Expand/Contract and “forward-only” migration discipline.

The document is split into two layers:

1. A prioritized delta assessment of “bundle ideas left out of the repo implementation”.
2. A “strict Phase-0 enforcement (new rows only)” implementation sketch showing how to land each delta with minimal blast radius.

## Core Mechanism: Why `NOT VALID` Is Central Here

The document explicitly relies on the Postgres behavior:

- `CHECK ... NOT VALID` is enforced for **new writes immediately**
- historical rows are not scanned until `VALIDATE CONSTRAINT`

This is the main technique used to:

- improve audit posture now
- defer expensive/operationally risky validation/backfill until Phase-1+

## My Understanding (What It Means for This Repo)

Your repo already implements a **stronger** Phase-0 business foundation than the bundle in several areas (verifier coverage, evidence metadata, signatures hook, evidence packs, privilege hygiene).

But the bundle contains tightening ideas that are **still missing** from the repo implementation today and would materially improve auditability without breaking Phase-0 constraints.

The missing deltas are primarily about **making certain hooks mandatory for new rows** (payer linkage and stitchability) instead of “present but optional”.

### Delta #1: Require `tenants.billable_client_id` for new rows (without backfill)

Current repo posture:
- `tenants.billable_client_id` exists and a `NOT VALID` FK exists.
- A `NOT VALID` FK does **not** prevent inserting `NULL`.

Document proposal:
- Add a `CHECK (billable_client_id IS NOT NULL) NOT VALID`.

Why it matters:
- It upgrades “billable client linkage exists” into “new tenants are always billable by construction”.

### Delta #2: Add a stable payer business identifier (`billable_clients.client_key`)

Current repo posture:
- `billable_clients` has UUID identity + `legal_name` (and `regulator_ref`).

Document proposal:
- Add `client_key` as a stable human/governed identifier, unique and required for new rows via `NOT VALID` CHECK.

Why it matters:
- It improves invoice/reconciliation narratives and reduces reliance on mutable names.

### Delta #3: Make correlation “hard” for new rows (Phase-0 safe)

Current repo posture:
- `correlation_id` is present on ingress/outbox tables but nullable (Phase-0 flexible).
- Stitchability becomes “best effort” unless all writers always set it.

Document proposal:
- Keep columns nullable (avoid backfill/rewrite), but enforce for new rows:
  - add a trigger to set correlation_id if NULL
  - add `CHECK (correlation_id IS NOT NULL) NOT VALID`

Why it matters:
- It upgrades stitchability to “always true for new data”, and does so without a table rewrite.

### Delta #4: Make external proofs directly billable (optional but strong)

Current repo posture:
- `external_proofs` is anchored via `attestation_id` (NOT NULL) plus provider/hashes.
- “who paid for this proof?” requires multi-hop joins.

Document proposal:
- Add `tenant_id` and `billable_client_id` columns (expand-first).
- Populate them for new rows (prefer application writes; or DB trigger deriving from attestation->tenant->billable client).
- Add enforcement via `NOT VALID` CHECKs.

Why it matters:
- It makes billing responsibility directly visible on the proof event itself, which is more audit-friendly.

### Delta #5: Partial indexes (nice-to-have)

The document correctly classifies partial indexes as optional:
- they improve bloat/perf
- they do not materially change audit semantics

## What I Intend To Implement (Repo-Safe, Forward-Only)

Per your stated preference and repo constraints, the “correct” implementation approach here is:

- Implement strict **Phase-0 “new rows only” enforcement** using `NOT VALID` constraints
- Avoid rewriting hot tables
- Keep migrations forward-only, no editing applied migrations
- Update mechanical verifiers + evidence so enforcement is audit-legible

### Implementation Cluster (Proposed)

1. **Schema tightening migration (forward-only)**

Add a new migration after the current latest migration (currently `0025_...` exists):

- `schema/migrations/0026_business_foundation_delta_tightening.sql`

Contains additive changes only:

- Add `CHECK ... NOT VALID` for new-row enforcement:
  - tenants: billable_client_id required (new rows)
  - ingress/outbox: correlation_id required (new rows)
- Add correlation auto-population trigger(s):
  - `BEFORE INSERT` on:
    - `public.ingress_attestations`
    - `public.payment_outbox_pending`
    - `public.payment_outbox_attempts`
  - only sets correlation_id when NULL
- Add stable payer key:
  - `ALTER TABLE public.billable_clients ADD COLUMN client_key text;`
  - unique partial index concurrently (`WHERE client_key IS NOT NULL`)
  - `CHECK (client_key IS NOT NULL AND length(trim(client_key)) > 0) NOT VALID`
- Optionally (if you want proofs directly billable in Phase-0):
  - Add `tenant_id` and `billable_client_id` to `external_proofs`
  - Add FKs (prefer NOT VALID to avoid validation scan)
  - Add either:
    - writer requirement (no trigger), or
    - a DB trigger deriving values from `attestation_id` join path
  - Add `NOT VALID` CHECK(s) to enforce presence for new rows

2. **Verifier tightening**

Update `scripts/db/verify_business_foundation_hooks.sh` to prove:

- Constraint presence (by name) for:
  - tenants billable required new rows
  - correlation required new rows (for each table)
  - billable_clients client_key required new rows
- Trigger presence:
  - correlation auto-population triggers exist on the expected tables
- External proofs (if enabled):
  - columns exist
  - trigger exists (if using DB-derivation approach)
  - constraints exist

Evidence remains:
- `evidence/phase0/business_foundation_hooks.json`

3. **Docs alignment**

The delta resolution doc is currently at repo root as `BUSINESS_FOUNDATION_HOOKS.md`.
Repo convention is Phase-0 documents under `docs/PHASE0/`.

Intended change:
- Move/duplicate content into `docs/PHASE0/BUSINESS_FOUNDATION_HOOKS.md`
- Update that doc to reflect the repo’s actual semantics:
  - what is enforced today
  - what is enforced for new rows after `0026_...`
  - what is deferred to Phase-1+ (validation/backfill)

4. **Invariant bookkeeping**

The existing invariants already cover the hooks (`INV-090..INV-096`).
If we add new “required for new rows” semantics, we either:

- extend the scope of the existing invariants (preferred, minimal churn), or
- add a new invariant for “new-row enforcement semantics are present” (only if you want it separately tracked).

## Non-Goals (Explicit)

This delta does **not** do any of:

- immediate backfill of existing nulls
- `VALIDATE CONSTRAINT` in Phase-0
- converting columns to `NOT NULL` in Phase-0
- operational billing workflows / invoice generation

Those remain Phase-1+.

## Preconditions / Questions That Must Be Answered Before Implementation

The document assumes “new rows only” enforcement is desired, but two points need an explicit repo decision:

1. **Do you want external_proofs to be directly billable in Phase-0?**
   - If yes: add columns + enforcement; decide trigger vs writer.
   - If no: keep join-path narrative and just document it.

2. **Should `correlation_id` be set only by DB (trigger) or also allowed from app?**
   - A “set-if-null” trigger supports both patterns and is safest.

