# Agentic SDLC Policy — Pilot Containment and Platform Neutrality

Date: 2026-03-21
Status: Canonical
Owner: Architecture / Platform
Applies to: All phases. All agents. All pilots.
References:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md (apex authority)
  - docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md
  - docs/operations/PHASE_LIFECYCLE.md
  - AGENTS.md

---

## 1) Purpose

This policy is a hard constraint document, not a guideline. It defines the rules
that prevent any pilot project from mutating the neutral platform foundation.
It is enforced mechanically by the Core Contract Gate (scripts/audit/verify_core_contract_gate.sh)
and by PR review. Violations block merge. There are no exceptions without a
formal Architecture Exception Record with an expiry date and rollback plan.

This policy applies at all lifecycle phases. It exists because the first real
pilot will arrive with deadline pressure and will create strong incentives to
"just add one table" or "just add one column." That is how platforms die.

A pilot is a consumer of the platform. It is not a co-author of it.

---

## 2) The Foundational Principle

> A pilot project must never drive development pace or structure beyond its
> own adapter module.

The corollary:

> If the second pilot (in a completely different sector) cannot run on the
> same Phase 0/1 schema, functions, and lifecycle without modification,
> something from the first pilot has leaked into the platform layer.

That condition — the Second Pilot Test — is the primary enforcement instrument.

---

## 3) The Four-Layer Architecture (frozen)

These layers are not negotiable. No task may blur the boundary between them.

**Layer A — Core substrate** (migrations 0001–0069, immutable)
Payment orchestration, outbox patterns, lease fencing, tenant isolation, RLS,
append-only ledgers, evidence anchoring, escrow, audit metadata.

**Layer B — Neutral host substrate** (Phase 0/1)
Core platform nouns shared by every pilot and every methodology:
projects, methodology_versions, monitoring_records, evidence_nodes,
evidence_edges, asset_batches, asset_lifecycle_events, retirement_events,
regulatory_authorities, regulatory_checkpoints, jurisdiction_profiles,
lifecycle_checkpoint_rules, interpretation_packs.
No sector nouns. No methodology names. No country-specific logic.

Claims and substantiation (claims, substantiation_cases, evidence_snapshots)
are a parallel schema zone on this substrate — they serve the greenwashing
auditor function. They share the evidence lineage infrastructure but are NOT
part of the green asset issuance critical path and must not drive the
foundation design. They are Phase 1 structural additions, not Phase 0
requirements.

**Layer C — Regulatory control plane engine** (Phase 0 hooks, Phase 1 logic)
Jurisdiction-profiled engine that reads regulatory rules as data.
jurisdiction_code is a required non-nullable field on every regulatory record.
The engine does not encode country-specific behaviour in code.

**Layer D — Methodology adapters and sector surfaces** (Phase 2 onward)
Every pilot lives here. PWRM0001, PWRM0002, solar, forestry, mining, tourism,
transport, water, and all subsequent sector packs. Also: ZGFT taxonomy packs,
registry adapters, sector-specific APIs. Nothing from this layer belongs in
Phase 0 or Phase 1.

---

## 4) The Ten Enforcement Rules

These are hard constraints enforced by the Core Contract Gate.
An agent that violates any of these rules must stop and escalate.

### Non-Negotiable Clause — Pilot Pressure Is Not An Exception

> **Pilot performance pressure, schedule slippage, or delivery urgency is
> never a valid reason to modify core schema, core indexing, core lifecycle
> states, or core validation logic.**

This clause has no exceptions. It is not subject to team-level override.
It is not subject to pilot sponsor override. The only path to a core
modification is the Architecture Exception Process in section 8, which
requires cross-sector justification, replayability impact assessment,
and formal approval — none of which can be completed under acute deadline
pressure by design. If a pilot cannot proceed without a core modification,
the correct response is to descope the pilot requirement, not to modify core.


### Rule 1 — Platform schema is frozen-neutral in Phase 0/1

No table name, column name, function name, or enum value in Phase 0 or Phase 1
may encode a sector, methodology, material type, or credit class.

The test: if you can identify the sector by reading the name, it does not belong
in Phase 0/1.

Forbidden at platform level:
  solar_*, plastic_*, forestry_*, agriculture_*, mining_*, pwrm_*,
  collection_*, recycling_*, and any equivalent sector noun.

Required neutral nouns:
  projects, monitoring_records, evidence_nodes, evidence_edges,
  asset_batches, asset_lifecycle_events, retirement_events,
  methodology_versions, calculation_runs, verification_cases,
  regulatory_authorities, regulatory_checkpoints, jurisdiction_profiles,
  lifecycle_checkpoint_rules, interpretation_packs.

### Rule 2 — All pilots are adapters, not platform extensions

Every pilot registers a methodology adapter at Phase 2. No pilot may add
top-level tables, standalone domain tables, or new FK roots in Phase 0/1.
Methodology-specific attributes live in adapter-registered payload schemas
validated against record_payload_json. They are not dedicated columns.

### Rule 3 — Core functions are generic verbs only

Phase 1 functions take neutral inputs and call registered adapters for
methodology-specific logic. Function names that encode a sector or methodology
name do not belong at Phase 0/1.

Allowed at Phase 0/1:
  register_project(...), record_monitoring_record(...), attach_evidence(...),
  open_verification_case(...), run_methodology_calculation(...),
  issue_asset_batch(...), retire_asset_batch(...),
  record_authority_decision(...), attempt_lifecycle_transition(...).

Forbidden at Phase 0/1:
  record_solar_installation(...), issue_plastic_credit(...),
  record_collection_event(...), issue_collection_credit_batch(...),
  or any function whose name encodes a sector or methodology.

### Rule 4 — No pilot-specific invariants in core

Validation rules specific to a methodology belong in the adapter's policy bundle
and checklist template. They do not belong in core DB functions or Phase 0/1
invariants.

A rule that applies universally across all methodologies is a core invariant.
A rule that applies only to one sector is an adapter rule.

### Rule 5 — Evidence model is universal

Every pilot uses the same evidence_nodes, evidence_edges, and evidence class
taxonomy. The class separation is a Phase 0 structural invariant enforced by
CHECK constraint:

  RAW_SOURCE, ATTESTED_SOURCE, NORMALIZED_RECORD, ANALYST_FINDING,
  VERIFIER_FINDING, REGULATORY_EXPORT, ISSUANCE_ARTIFACT.

No pilot may add a new evidence class without a formal Phase 0/1 change
that passes the Second Pilot Test.

### Rule 6 — Regulatory layer is jurisdictional, not sectoral

jurisdiction_code is a required non-nullable dimension on every regulatory
record. The jurisdiction profile contains what checkpoints are mandatory.
Sector adapters contain none of that logic. Regulatory checkpoint rules
apply across all sectors within a jurisdiction.

### Rule 7 — Pilots cannot introduce new lifecycle states

The minimal neutral lifecycle is:
  DRAFT → ACTIVE → ISSUED → RETIRED → CANCELLED

No pilot may introduce a state like SOLAR_VERIFIED, FORESTRY_PENDING,
or PLASTIC_ISSUED. Partial retirement is a quantity field on a retirement event.
Staged approvals and conditional issuance are expressed through checkpoint
configuration and case workflows, not through new lifecycle states.

### Rule 8 — Every proposed core addition must pass the Second Pilot Test

Before any change to Phase 0 or Phase 1 schema, functions, or invariants,
the following question must be answered explicitly in the task meta.yml:

  "Would this design work unchanged for a second pilot in a completely
  different sector?"

Tasks that cannot answer this affirmatively are blocked.
The answer must name two concrete unrelated sectors as evidence.

### Rule 9 — Core is read-only from adapters

Adapters have read access to core tables through defined query interfaces.
Adapters cannot:
  - modify core schema
  - require new indexes on core tables
  - require new constraints on core tables
  - require new columns in core tables

If an adapter's access pattern cannot be served by existing core query
interfaces, the core interface is redesigned through formal Phase 0/1 process.
Pilot operational pressure is not grounds for a core schema modification.

### Rule 10 — No sector semantics in core validation

Core validates that a payload is well-formed JSON matching a registered
schema reference. Core never interprets payload field semantics.
Adapters define payload schemas and own all payload meaning.

A core function that checks for capacity_kw, contamination_rate_pct, or
any other sector-specific named field is encoding sector physics in the
platform layer regardless of what the table is named. This is a Rule 10
violation even if no table name contains a sector noun.

---

## 5) The Five Gate Criteria (Core Contract Gate)

Every PR touching Phase 0/1 must pass all five checks. Any failure blocks merge.

**Check 1 — Neutrality Check**
Does the proposed addition encode a sector, methodology, material type, or credit
class by name (table, column, function, enum value)? → Block.

**Check 2 — Second Pilot Test**
Would this work for a second, unrelated pilot without modification?
Must explicitly name two unrelated sectors as evidence. Weak or empty answer → Block.

**Check 3 — Jurisdiction Independence Check**
Does this encode the rules or procedures of a specific country in code rather
than in a jurisdiction profile data row? → Block.

**Check 4 — Replayability Check**
If the interpretation of a rule changes, can decisions made under the prior
interpretation be identified and assessed under the new one?
Missing interpretation_version_id reference on a new decision record → Block.

**Check 5 — Access Pattern Check**
Does this change introduce an index, constraint, or schema modification whose
primary purpose is to serve a specific adapter's access pattern?
Answer: block from core. The adapter operates within existing query interfaces
or the core interface is redesigned formally.

---

## 6) Pre-Pilot Governance Requirements

The following must be merged and green in CI before any pilot task is created:

A. This policy document (AGENTIC_SDLC_PILOT_POLICY.md) in docs/operations/
B. Neutral host invariant register entries INV-135 through INV-144 in
   docs/invariants/INVARIANTS_MANIFEST.yml
C. Pilot scope declaration template at docs/pilots/PILOT_SCOPE_TEMPLATE.md
D. Core Contract Gate script at scripts/audit/verify_core_contract_gate.sh
E. Rejection playbook at docs/operations/PILOT_REJECTION_PLAYBOOK.md

Every agent MUST read this policy before accepting any task tagged
phase: green or pilot: true in task meta.yml.

---

## 7) Pilot Scope Declaration Requirement

Before any pilot task is created, a file must exist at:
  docs/pilots/PILOT_<NAME>/SCOPE.md

This file must declare:
  - Which methodology adapter this pilot exercises
  - Which neutral host tables it will populate
  - Which Phase 2 adapter components it depends on
  - Explicit confirmation that no new neutral-layer tables are required
  - Explicit confirmation that no neutral-layer tables will be altered
  - Which jurisdiction profile it operates under
  - Which interpretation pack version is currently active
  - Second Pilot Test answer naming two different sectors

A gate script verifies that all tables referenced in pilot task meta.yml
are listed in the canonical neutral host schema. If any are new, the task
is blocked until either the neutral host is extended through proper Phase 0/1
process, or an exception is approved with expiry date and rollback plan.

---

## 8) Architecture Exception Process

If something genuinely cannot be expressed through the neutral host or
adapter contract, the escalation path is:

1. Raise a Core Design Gap issue with label: architecture-gap
2. Issue must include:
   - Second Pilot Test analysis for two unrelated sectors
   - Cross-sector justification
   - Replayability impact assessment
   - Proposed solution (extend neutral host vs adapter extension table)
3. Reviewed as a formal Phase 0/1 change request
4. If approved: goes through normal Phase 0/1 task process with full
   evidence, verifier, and contract wiring
5. Never patched via pilot pressure or deadline override

Pilot deadlines are not grounds for an architecture exception.

---

## 9) PWRM Supersession Declaration

Migrations 0070–0078 as specified in the PWRM gap analysis document
(PWRM_GAP_ANALYSIS_AND_TASKS.md) are superseded and must not be built.
Those migrations created plastic-shaped schema at the wrong abstraction layer.

PWRM0001 and PWRM0002 are Phase 2 methodology adapters.
They plug into the neutral host.
They do not define the neutral host.

Migration numbers 0070 onward are reserved for the neutral Phase 0 host tables
defined in this policy.

---

## 10) Agent Stop Conditions Specific to This Policy

An agent working on any task tagged phase: green or pilot: true must stop
and escalate to a human supervisor when:

- Any proposed table or column name contains a sector noun (Rule 1)
- A function signature encodes a sector or methodology name (Rule 3)
- A payload field is referenced by name in core validation logic (Rule 10)
- An index is proposed to serve a single adapter's query pattern (Rule 9)
- The Second Pilot Test answer is weak, empty, or names only one sector (Rule 8)
- A lifecycle state with a sector prefix is proposed (Rule 7)
- Regulatory logic is expressed in code rather than in a profile row (Rule 6)
- A decision record lacks an interpretation_version_id reference (Rule 4 / Check 4)

- A pilot deadline or schedule pressure is cited as justification for a core schema change (Non-Negotiable Clause / Rule 9)

Stop condition triggers remediation trace requirement per
docs/operations/AI_AGENT_OPERATION_MANUAL.md.
