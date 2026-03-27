# Green Finance Volatility Map

Date: 2026-03-22
Status: Canonical — must be reviewed and updated at closeout of every Wave 1 task
Owner: Architecture / Platform
Policy: docs/operations/AGENTIC_SDLC_PILOT_POLICY.md
Enforced by: GF-W1-FRZ-005 acceptance criteria

---

## Purpose

This document exists because Zambia's carbon market Statutory Instrument No. 5
of 2026 is new law, and government practice under it is still settling. Without
an explicit classification of what is legally stable versus what is likely to
change, agents and engineers will make schema placement decisions by instinct —
and those decisions will be wrong in ways that are expensive to reverse.

The rule this document enforces: **put volatility in tables, not code.**

Every time a green finance task introduces a new table, column, function, or
rule, the agent must consult this map, identify which volatility class the
addition belongs to, and ensure it is placed in the correct layer. If a proposed
addition does not fit cleanly into one class, that is a signal to escalate before
building — not to guess.

---

## Volatility Class Taxonomy

Three classes. Every green finance schema object belongs to exactly one.

### CORE_SCHEMA

Tables and constraints in Phase 0/1 migrations that encode structural truth
rather than legal interpretation. These should not change when regulations are
clarified, when methodology versions are updated, or when a new country is
added. They change only when the fundamental data model needs extending — which
requires a formal Phase 0/1 change process, the Core Contract Gate, and the
second-pilot test.

Full Core Contract Gate applies: all five criteria (neutrality, second-pilot
test, jurisdiction independence, replayability, access pattern check).

### POLICY_TABLE

Rows and data objects that encode regulatory rules, interpretations, and
configuration. The schema of these tables may need occasional adjustment as
the regulatory domain evolves, but the primary mode of change is inserting
or superseding rows, not altering columns. A new jurisdiction adds rows.
A regulatory clarification adds a new interpretation pack row. A new
checkpoint requirement adds a lifecycle_checkpoint_rules row.

Neutrality and second-pilot checks apply. Access-pattern check relaxed —
policy tables serve all adapters equally.

### ADAPTER_LAYER

Everything inside a Phase 2 adapter registration. Methodology-specific
calculation parameters, sector eligibility criteria, credit type definitions,
payload field schemas, checklist templates. These are free to vary per
methodology version and per country. The Core Contract Gate does not run
on adapter-layer files — pilot containment rules apply instead.

---

## Section 1 — Legally Stable / Phase 0 Locked (CORE_SCHEMA)

These are structural truths. They do not change when law is clarified, when
a methodology version is updated, or when a second country is onboarded.

**Project and methodology identity**
- The fact that a project exists and is tied to a methodology version
- The fact that a methodology version has a code, authority, and version string
- Append-only project lifecycle events
- Closed-state guards on projects

**Evidence lineage structure**
- The fact that evidence nodes exist with a class
- The fact that evidence edges connect nodes to governed records
- The seven-class evidence taxonomy: RAW_SOURCE, ATTESTED_SOURCE,
  NORMALIZED_RECORD, ANALYST_FINDING, VERIFIER_FINDING, REGULATORY_EXPORT,
  ISSUANCE_ARTIFACT
- Append-only constraint on evidence records

**Asset lifecycle states**
- The five neutral states: DRAFT, ACTIVE, ISSUED, RETIRED, CANCELLED
- The fact that lifecycle transitions are recorded as events
- The fact that retirement events are irrevocable

**Monitoring record structure**
- The fact that monitoring records are append-only
- The idempotency constraint on (tenant_id, instruction_id)
- The requirement that record_payload_json is opaque JSONB validated by
  schema_reference_id — not by field name

**Adapter contract structure**
- The fact that adapters are registered
- The registration fields: adapter_code, methodology_code, methodology_authority,
  version_code, issuance_semantic_mode, retirement_semantic_mode
- Append-only constraint on adapter_registrations

**Authority decision structure**
- The fact that authority decisions are append-only
- The requirement that every decision references an interpretation_pack_id

**Regulatory checkpoint structure**
- The fact that checkpoints exist and gate lifecycle transitions
- The fact that jurisdiction_code is non-nullable on all regulatory tables

---

## Section 2 — Legally Volatile / Must Live in Policy Data, Not Code (POLICY_TABLE)

These items change when the law is clarified, when government practice evolves,
or when a new jurisdiction is onboarded. They must never be hardcoded in
function bodies or migration constraint logic. They live as data rows in
policy tables, readable and updatable without migrations.

**Which checkpoints are mandatory for which lifecycle transitions**
- Lives in: lifecycle_checkpoint_rules rows
- Changes when: MGEE clarifies which approvals are required before issuance
- Wrong placement: encoding `IF jurisdiction = 'ZM' THEN require_checkpoint(...)` in a function

**What evidence sufficiency threshold applies to a given use case**
- Lives in: admissibility profile rows (Phase 1+)
- Changes when: regulatory guidance clarifies minimum evidence requirements
- Wrong placement: CHECK constraint on evidence_nodes encoding a minimum count

**Which authority type gates which lifecycle transition**
- Lives in: lifecycle_checkpoint_rules.checkpoint_type and authority_level rows
- Changes when: SI practice clarifies that certain approvals belong to a
  different authority level than initially assumed
- Wrong placement: hardcoded authority type in attempt_lifecycle_transition function

**Which interpretation version was used at a decision point**
- Lives in: interpretation_pack_id foreign key on every decision record
- Changes when: a new interpretation pack is published superseding the prior one
- Wrong placement: a hardcoded rule text string inside a function body

**Which forms, letters, or external references are required**
- Lives in: interpretation_packs.rule_text and dependency_refs
- Changes when: MGEE publishes updated forms or approval templates
- Wrong placement: a VARCHAR column encoding a specific form reference code

**What qualifies as sufficient substantiation for a claim**
- Lives in: substantiation case control rows (Phase 1+ claims zone)
- Changes when: regulatory guidance clarifies what evidence a claim requires
- Wrong placement: a function that checks specific claim types against hardcoded thresholds

**Confidence level of a regulatory interpretation**
- Lives in: interpretation_packs.confidence_level enum
  (CONFIRMED, PRACTICE_ASSUMED, PENDING_CLARIFICATION)
- Changes when: MGEE confirms or modifies a previously assumed interpretation
- Wrong placement: a boolean column `is_confirmed` on checkpoints

**Jurisdiction-specific NDC accounting obligations**
- Lives in: ndc_accounting_rules rows (Phase 2+)
- Changes when: Zambia or Zimbabwe formalise their Article 6 accounting approach
- Wrong placement: `IF jurisdiction_code = 'ZM' THEN set_ndc_status(...)` in function

---

## Section 3 — Highly Volatile / Adapter Layer Only (ADAPTER_LAYER)

These items change per methodology version and per country. They must never
appear in Phase 0 or Phase 1 schema. They exist entirely inside Phase 2
adapter registrations as configuration data.

**Methodology-specific calculation parameters**
- e.g. PWRM0001 emission factors, VM0044 capacity thresholds
- Lives in: adapter_registrations.payload_schema_refs and entrypoint_refs
- Wrong placement: a column on monitoring_records for a specific factor value

**Sector eligibility criteria**
- e.g. ZGFT minimum project size, technology eligibility thresholds
- Lives in: adapter checklist template rows
- Wrong placement: a CHECK constraint on projects for minimum area

**Credit type definitions**
- e.g. PLASTIC_COLLECTION_CREDIT, FOREST_CARBON_CREDIT
- Lives in: adapter_registrations.issuance_semantic_mode and asset_type value
- Wrong placement: an ENUM column on asset_batches listing sector credit types

**Payload field schemas**
- e.g. PWRM0001 collection event requires weight_kg and contamination_rate_pct
- Lives in: adapter_registrations.payload_schema_refs JSON schema definitions
- Wrong placement: dedicated columns on monitoring_records

**Verification checklist items**
- e.g. PWRM0001 requires weighbridge certificate, photo evidence, GPS coordinates
- Lives in: adapter checklist template rows
- Wrong placement: required_documents column on verification_cases

**Sector-specific lifecycle gate rules**
- e.g. forestry requires biomass baseline before issuance
- Lives in: adapter-registered checkpoint configurations
- Wrong placement: a separate status FORESTRY_BASELINE_REQUIRED on asset_batches

**Registry adapter bindings**
- e.g. PWRM0001 credits must be registered in Zambia National Carbon Registry
- Lives in: registry_binding_configs rows (Phase 2+)
- Wrong placement: a registry_url column on asset_batches

---

## Section 4 — Placement Decision Guide

Before adding anything to the green finance domain, answer these four questions:

**Q1: Does this change when the law is clarified?**
If yes → POLICY_TABLE or ADAPTER_LAYER. Not CORE_SCHEMA.

**Q2: Does this change per methodology or per sector?**
If yes → ADAPTER_LAYER. Not CORE_SCHEMA or POLICY_TABLE.

**Q3: Would a second unrelated sector (e.g. solar energy and forestry) need
a different version of this?**
If yes → ADAPTER_LAYER. If it applies to all sectors identically → CORE_SCHEMA
or POLICY_TABLE.

**Q4: Can this be expressed as a data row in a policy table or adapter
configuration without loss of precision or auditability?**
If yes → use the data row. Do not create a schema object for it.

**The override rule: when in doubt, go higher in volatility class.**
It is always cheaper to promote a CORE_SCHEMA item to POLICY_TABLE later
than to demote a POLICY_TABLE item back to CORE_SCHEMA. Demotion requires
a migration, a gate process, and a second-pilot test. Promotion requires
only a table row.

---

## Section 5 — Enforcement per Volatility Class

### CORE_SCHEMA enforcement
- Full Core Contract Gate: all five criteria required on every PR
- AST verifier scans for sector nouns in all identifier positions
- Semantic drift verifier scans for payload field name references in function bodies
- Migration sidecar must declare `volatility_class: CORE_SCHEMA`
- Second-pilot test with two sectors from different SECTOR_CLASS groups required
- Architecture Owner sign-off required

### POLICY_TABLE enforcement
- Neutrality check and second-pilot check apply
- Access-pattern check relaxed — policy tables serve all adapters equally
- Migration sidecar must declare `volatility_class: POLICY_TABLE`
- No hardcoded jurisdiction-specific logic in the table's associated functions
- Row changes (INSERT of new interpretation packs, checkpoint rules, etc.) do
  not require Core Contract Gate — they are data operations

### ADAPTER_LAYER enforcement
- Pilot containment rules apply (no top-level tables, no new core functions)
- Core Contract Gate does not run on adapter-layer files
- Every adapter must register through GF-W1-DSN-001 adapter contract interface
- Pilot SCOPE.md must be present and approved before adapter work begins
- Second-pilot test required on all pilot tasks

---

## Section 6 — Known Volatile Dependencies (as of 2026-03-22)

These are external dependencies rated by current volatility. Every interpretation
pack that relies on one of these must set confidence_level = PENDING_CLARIFICATION
until the dependency is confirmed.

| Dependency | Volatility | Status | Impact |
|---|---|---|---|
| S.I. No. 5 of 2026 Letter of No Objection process | HIGH | Practice not yet confirmed | Issuance checkpoint gating |
| MGEE designated authority approval workflow | HIGH | Workflow not yet published | Authority decision recording |
| Zambia National Carbon Registry integration API | HIGH | Registry operational status unclear | External registry binding |
| ZGFT Annex criteria for each sector | MEDIUM | First edition published, refinement expected | Taxonomy eligibility assessment |
| Zambia Article 6 corresponding adjustment process | HIGH | Process not yet formalised | NDC accounting rules |
| PWRM0001/0002 local applicability interpretation | MEDIUM | Standard exists, local adaptation pending | Calculation entrypoints |

---

## Living Document Protocol

This document must be updated as part of the acceptance criteria for any
Wave 1 task that:
- introduces a new table (add to Section 1, 2, or 3 with explicit class)
- introduces a new function that reads or enforces a rule (classify the rule)
- introduces a new external dependency (add to Section 6 with volatility rating)
- promotes a provisional interpretation to CONFIRMED (update Section 6)

Failure to update this document is a FAIL_REVIEW condition. The document
is not maintained for audit purposes — it is maintained so that every
subsequent agent can make correct placement decisions without guessing.
