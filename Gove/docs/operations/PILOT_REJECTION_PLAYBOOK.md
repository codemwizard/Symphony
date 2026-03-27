# Pilot Rejection Playbook

Location: docs/operations/PILOT_REJECTION_PLAYBOOK.md
Policy: docs/operations/AGENTIC_SDLC_PILOT_POLICY.md
Gate: scripts/audit/verify_core_contract_gate.sh
Owner: Architecture / Platform

This document is for engineers and AI agents working on any task that touches
the green finance domain. It answers one question: why is my change being blocked,
and what is the correct alternative?

Read this before raising a Core Design Gap issue. Most blocks have a direct
solution that does not require any architecture exception.

---

## How to use this playbook

1. Find the violation pattern that matches your situation.
2. Read the rule it violates and why it exists.
3. Apply the correct alternative.
4. If no alternative here fits, use the Escalation Path at the bottom.

Do not attempt to work around the gate. The gate exists precisely because
deadline pressure will make workarounds feel reasonable. They are not.

---

## Violation 1 — "We need a new table for this pilot"

### Examples

- Add `plastic_credit_batches` for PWRM0001
- Add `solar_installation_records` for the solar pilot
- Add `collection_events` for field collection tracking
- Add `forest_carbon_credit_batches` for REDD+ issuance

### Rule violated

Rule 1 (no sector nouns in Phase 0/1 schema) and Rule 2 (all pilots are adapters).

### Why this is blocked

A table named after a sector is a silo. When the second pilot arrives,
it will also need its own table. By the fourth pilot you have four parallel
silos sharing nothing. The neutral host exists so that every pilot uses the
same tables with different methodology_version_id and record_type values.

### Correct alternative

Use the neutral host table and register the sector-specific structure
in the adapter layer.

| Blocked | Correct |
|---|---|
| `plastic_credit_batches` | `asset_batches` with `asset_type = 'PLASTIC_COLLECTION_CREDIT'` |
| `solar_installation_records` | `monitoring_records` with `record_type = 'SOLAR_INSTALLATION'` |
| `collection_events` | `monitoring_records` with `record_type = 'PWRM_COLLECTION_EVENT'` |
| `forest_carbon_credit_batches` | `asset_batches` with `asset_type = 'FOREST_CARBON_CREDIT'` |

The `record_type` and `asset_type` values are registered in the Phase 2
adapter, not in Phase 0/1 schema. The neutral host tables are agnostic.

---

## Violation 2 — "We need a new column for this pilot"

### Examples

- Add `capacity_kw` column to `monitoring_records`
- Add `contamination_rate_pct` column to `monitoring_records`
- Add `net_weight_kg` column to `monitoring_records`
- Add `panel_serial` column to `asset_batches`
- Add `biomass_baseline_tco2e` column to `verification_cases`

### Rule violated

Rule 10 (no sector semantics in core validation) and Rule 2.

### Why this is blocked

A named column for a sector-specific measurement embeds that sector's
data model into the platform layer. Every other sector then either
has a NULL column they do not use, or needs their own column, which
defeats the neutral host entirely.

### Correct alternative

The field goes in `record_payload_json` (for monitoring records) or
the equivalent JSONB payload field on the relevant neutral table.
The adapter registers a JSON schema that validates the field's presence
and type for that methodology.

The core function `record_monitoring_record()` stores whatever is in
`record_payload_json` after validating it against the registered
`schema_reference_id`. Core never reads `capacity_kw` by name.
The adapter reads it when processing calculation inputs.

```
-- WRONG: column in core table
ALTER TABLE monitoring_records ADD COLUMN net_weight_kg NUMERIC;

-- CORRECT: field in payload, validated by adapter schema
INSERT INTO monitoring_records (
  project_id, methodology_version_id, record_type,
  record_payload_json, schema_reference_id, ...
) VALUES (
  $1, $2, 'PWRM_COLLECTION_EVENT',
  '{"net_weight_kg": 450.5, "material_type": "HDPE", "facility_id": "..."}',
  'pwrm0001_collection_event_v1',
  ...
);
```

---

## Violation 3 — "This query is too slow, add an index"

### Examples

- Add index on `monitoring_records(record_type, project_id, created_at)`
  to speed up a PWRM dashboard query
- Add index on `asset_batches(asset_type, status)` for a solar reporting query
- Add partial index on `monitoring_records WHERE record_type = 'COLLECTION_EVENT'`

### Rule violated

Rule 9 (core is read-only from adapters) and Check 5 (access pattern check).

### Why this is blocked

An index added to serve one adapter's query pattern imposes a write
overhead on every other adapter. If five pilots each add their own index
on `monitoring_records`, the table accumulates indexes that benefit
one sector and slow writes for everyone. Core schema must remain
generalizable across all adapters.

### Correct alternative

Evaluate in this order:

**Step 1:** Can the query be restructured to use existing indexes?
Check what indexes already exist on the table before adding anything.

**Step 2:** Does this index benefit ALL adapters, not just this one?
If yes, raise a formal Phase 0/1 change request with cross-sector evidence.
An index on `(project_id, created_at)` that benefits every adapter
may legitimately belong in core.

**Step 3:** If the index only benefits one adapter:
- Materialise a read model in the adapter layer (a Phase 2 view or
  projection table that the adapter maintains).
- Use a caching layer in the adapter service.
- Accept the query cost and optimise the adapter's query shape.

The neutral host tables are not queryable via arbitrary adapter-shaped
indexes. Adapters work within the access patterns the host provides.

---

## Violation 4 — "We need a special lifecycle state"

### Examples

- `SOLAR_VERIFIED` for solar installations that passed inspection
- `FORESTRY_PENDING` for projects awaiting satellite confirmation
- `PLASTIC_ISSUED` for credited collection batches
- `PARTIALLY_RETIRED` as a distinct lifecycle state
- `AWAITING_LONO` for Zambia regulatory approval

### Rule violated

Rule 7 (pilots cannot introduce new lifecycle states).

### Why this is blocked

Lifecycle states are platform primitives. If every sector adds its own
states, the lifecycle table becomes a branching mess where assets in
different sectors travel through incompatible state paths. The platform
cannot reason uniformly about asset state across sectors.

### Correct alternative

The minimal lifecycle is: `DRAFT → ACTIVE → ISSUED → RETIRED → CANCELLED`.

**For staged approvals:** Use a `regulatory_checkpoints` row with status
`PENDING_AUTHORITY_CLARIFICATION` or `required`. The checkpoint blocks
the lifecycle transition. The lifecycle state does not change until
the checkpoint is satisfied.

**For partial retirement:** Use `retirement_events.retired_quantity`.
An asset with retirement events totalling less than `issuable_quantity`
is partially retired by arithmetic. No separate state required.

**For methodology-specific verification stages:** Use `verification_cases`
with the appropriate `case_type` registered in the adapter's checklist
template. The case status tracks the verification workflow. The asset
lifecycle state only changes on case closure.

**For regulatory holds:** Use a checkpoint row in `regulatory_checkpoints`
with `jurisdiction_code = 'ZM'` (or relevant jurisdiction) and
`checkpoint_status = 'PENDING_AUTHORITY_CLARIFICATION'`. Record the
interpretation pack version that defines the requirement.

---

## Violation 5 — "We need special core validation for this methodology"

### Examples

- Add a CHECK in the core DB function that requires `solar_capacity_kw` to be positive
- Add validation in `record_monitoring_record()` that enforces PWRM contamination thresholds
- Add a constraint that requires `evidence_nodes` of class `ATTESTED_SOURCE` for
  solar pilots specifically
- Add a trigger that fires only for `record_type = 'COLLECTION_EVENT'`

### Rule violated

Rule 4 (no pilot-specific invariants in core) and Rule 10.

### Why this is blocked

Core validation that is specific to one methodology is invisible debt.
It looks like a generic invariant but silently encodes domain logic
that other sectors never need and that may actively break them.
A trigger that fires on `record_type = 'COLLECTION_EVENT'` does nothing
for a forestry pilot, but it is executed on every insert regardless.

### Correct alternative

Methodology-specific validation belongs in the adapter layer:

- **Payload schema validation:** Register a JSON schema in the adapter's
  `schema_reference_id` entry. The core function validates only that the
  payload matches the registered schema. The schema enforces field presence,
  types, and ranges for this methodology only.
- **Precondition checks:** Implement precondition logic in the Phase 2
  adapter service before calling the core `record_monitoring_record()`
  function. The adapter enforces methodology rules. Core enforces
  platform rules.
- **Evidence requirements:** Register required evidence classes in the
  adapter's verification checklist template. The `verification_cases`
  workflow enforces them per checklist. Core does not know about
  methodology-specific evidence requirements.

---

## Violation 6 — "We need to encode the Zambia regulatory rule in code"

### Examples

- Add `if jurisdiction == 'ZM' and status == 'VERIFIED': require_lono()`
  in a Phase 1 function
- Hardcode `authority_type = 'ZEMA'` as a required value in a core function
- Add a Phase 0 trigger that enforces a Zambia-specific issuance precondition
- Hardcode `jurisdiction_code = 'ZM'` in a core DB function body

### Rule violated

Rule 6 (regulatory layer is jurisdictional not sectoral, expressed as data
not code) and Check 3 (jurisdiction independence check).

### Why this is blocked

Hardcoded country logic in core functions means the system cannot operate
under a different jurisdiction without a code change. This destroys
the multi-country scalability that the jurisdiction profile system exists
to provide. It also makes the system impossible to audit for a different
country without understanding code branches.

### Correct alternative

Every jurisdiction-specific rule lives in a `lifecycle_checkpoint_rules`
row or a `jurisdiction_profiles` row, not in function bodies.

```sql
-- WRONG: jurisdiction logic in core function
IF p_jurisdiction_code = 'ZM' THEN
  -- require LONO before issuance
  PERFORM check_lono_present(p_asset_batch_id);
END IF;

-- CORRECT: rule in data, engine reads it
-- lifecycle_checkpoint_rules row:
-- jurisdiction_code: ZM
-- lifecycle_transition: VERIFIED_TO_ISSUED
-- checkpoint_type: REGULATORY_AUTHORITY_DECISION
-- authority_decision_type: LETTER_OF_NO_OBJECTION
-- is_mandatory: true
-- interpretation_version_id: <active ZM carbon market pack>

-- Core function:
SELECT evaluate_checkpoint_rules(
  p_asset_batch_id, 'VERIFIED_TO_ISSUED', p_jurisdiction_code
);
-- Returns blocked/satisfied based on data rows, not code branches.
```

When Zimbabwe's rules differ from Zambia's, add a `ZW` row with different
values. The function body does not change.

---

## Violation 7 — "Just add this one thing for the pilot deadline"

### Pattern

Any request framed as: "just this once", "temporary", "we'll clean it up later",
"the deadline is next week", "it's only a small change."

### Rule violated

All ten rules. And the entire point of this playbook.

### Why this is blocked

"Just this once" is how platforms die. The architecture is designed to
be neutral precisely because deadline pressure will make violations feel
reasonable. The gate does not have a deadline override. There is no
"temporary" in a forward-only migration system. A column added under
deadline pressure is a column that exists forever.

### Correct alternative

There are two legitimate paths:

**Path A — Adapter workaround:** Almost every pilot deadline can be met
by implementing the requirement in the Phase 2 adapter layer without
touching Phase 0/1 schema. This is always the first option. The adapter
can be built quickly. The neutral host does not change.

**Path B — Formal architecture change request:** If the requirement
genuinely cannot be expressed through the neutral host or adapter
contract, raise a Core Design Gap issue. This pauses the pilot task
until the architecture change is reviewed and approved. The pilot timeline
adjusts. The platform integrity does not.

The pilot timeline is not a valid reason for an architecture exception.

---

## Escalation path — when nothing here fits

If a genuine requirement cannot be expressed through any of the correct
alternatives above:

**Step 1:** Confirm the requirement is real by restating it without sector
framing. "PWRM0001 needs net weight per collection event" → "a monitoring
record for this methodology needs a numeric field validated by the adapter
schema." If it fits that framing, use Violation 2's solution.

**Step 2:** Write a Core Design Gap issue with label `architecture-gap`.
The issue must contain:
- The specific requirement in neutral terms
- Why the adapter layer cannot satisfy it
- Second Pilot Test: how would this affect two unrelated sectors?
- Proposed solution: extend neutral host tables vs adapter extension table

**Step 3:** The issue is reviewed as a formal Phase 0/1 change.
If approved, a new task is created through normal Phase 0/1 process with
full evidence, verifier, and contract wiring. This takes days, not hours.

**Step 4:** The pilot task that blocked on this requirement is marked
`depends_on` the architecture change task. It does not proceed until
the architecture change is merged and green.

**Never:** implement the requirement informally and "fix it later."
There is no later in a forward-only migration system.

---

## Quick reference card

| Blocked pattern | Correct layer | Mechanism |
|---|---|---|
| Sector-named table | Phase 2 adapter | neutral table + `record_type` field |
| Sector-specific column | Phase 2 adapter | `record_payload_json` + adapter JSON schema |
| Pilot-specific index | Phase 2 adapter or query redesign | adapter read model / cache |
| New lifecycle state | Phase 0/1 checkpoints | `regulatory_checkpoints` + checkpoint rules |
| Methodology validation in core | Phase 2 adapter | adapter precondition + schema validation |
| Country logic in function body | Phase 0/1 data row | `lifecycle_checkpoint_rules` + jurisdiction profile |
| Deadline exception | Adapter workaround or formal GAP issue | see Escalation path |

---

## The one test that cuts through everything

Before any change to Phase 0/1, ask:

> "If we removed this pilot entirely and ran a completely different sector
> through the platform, would this change still make sense?"

If yes: the change may belong in Phase 0/1 (still needs gate approval).
If no: it belongs in the adapter layer. Full stop.
