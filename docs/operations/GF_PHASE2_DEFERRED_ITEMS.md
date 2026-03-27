# Green Finance Phase 2 Deferred Items Register

## Purpose

This document is the formal register of items explicitly deferred from Wave 1 (Phase 0 + Phase 1) to Phase 2. These are not cancellations — they are deliberate deferrals with clear blocking conditions and prerequisites.

Every deferred item must be converted to a Phase 2 contract row with invariant ID, verifier, and evidence path before Phase 2 implementation begins. No deferred item may be silently dropped from the backlog.

---

## DEFER-001: Verifier Read API Surface

**What it is:** The .NET endpoint that accepts a GF verifier token (issued by `issue_verifier_read_token` from FNC-006) and returns scoped evidence data with pagination, filtering, and projections. This is the read-only API surface through which third-party verifiers access governed evidence for a specific project.

**Why it is deferred:** The API layer requires stable schema, stable evidence lineage graph, and stable token semantics. Phase 1 delivers the DB primitive (`issue_verifier_read_token`) but the API surface requires additional design decisions: response projection rules, pagination semantics, evidence class filtering, and tenant boundary enforcement at the HTTP layer. Building this before the foundation is stable would hardcode assumptions about evidence structure.

**Blocked on:**
- GF-W1-FNC-006 (issue_verifier_read_token DB primitive) — completed
- Phase 2 entry gate passing
- Phase 2 API design approval

**Wave 1 prerequisite tasks:**
- GF-W1-SCH-004 (evidence lineage graph)
- GF-W1-SCH-008 (verifier registry)
- GF-W1-FNC-006 (token issuance primitive)
- GF-W1-GOV-006 (this gate)

---

## DEFER-002: Project Developer Submission API

**What it is:** The inbound API through which a project developer submits a monitoring record and receives validation feedback against their adapter-registered schema. This is the write path: developer submits data, the system validates it against the adapter's registered `payload_schema_refs`, and either accepts or rejects with structured feedback.

**Why it is deferred:** The submission API requires the adapter contract to be stable and the interpretation pack resolution algorithm to be verified. A submission triggers schema validation against `payload_schema_refs` from `adapter_registrations`, which must be correct and stable before building the validation layer. Building this API before adapter contract stability is proven would hardcode payload assumptions that break when adapters are revised.

**Blocked on:**
- Phase 2 entry gate passing
- Stable adapter contract (proven by SCH-001 + DSN-001 evidence)
- Phase 2 API design approval

**Wave 1 prerequisite tasks:**
- GF-W1-SCH-001 (adapter_registrations)
- GF-W1-DSN-001 (adapter contract interface)
- GF-W1-SCH-003 (monitoring_records)
- GF-W1-FNC-002 (record_monitoring_record)

---

## DEFER-003: Monitoring Report Generation

**What it is:** The verifier-facing export pack that becomes the monitoring report submitted to ZEMA under S.I. Regulation 10. This generates the formal regulatory document from governed evidence and monitoring records, structured per jurisdiction-specific reporting templates.

**Why it is deferred:** Monitoring report format depends on jurisdiction profiles (SCH-006), interpretation packs (SCH-002), and evidence lineage (SCH-004) all being stable. The report template is jurisdiction-specific and regulation-specific — it cannot be built until the interpretation pack resolution algorithm is verified and jurisdiction profiles are seeded. Building this before Phase 1 stability is proven would embed regulatory assumptions that change as jurisdictions clarify requirements.

**Blocked on:**
- Phase 2 entry gate passing
- Jurisdiction profile data seeding (Phase 2 operational task)
- Regulatory template approval (external dependency)

**Wave 1 prerequisite tasks:**
- GF-W1-SCH-006 (jurisdiction_profiles, lifecycle_checkpoint_rules)
- GF-W1-SCH-002 (interpretation_packs)
- GF-W1-SCH-004 (evidence_nodes, evidence_edges)
- GF-W1-FNC-003 (attach_evidence, link_evidence_to_record)

---

## DEFER-004: Interpretation Pack Confidence as User-Visible Artifact

**What it is:** What the API returns when an authority decision was made under a `PENDING_CLARIFICATION` interpretation pack. This is the user-facing representation of epistemic uncertainty — the API must communicate that a decision was governed by an interpretation that has not yet been confirmed by the relevant authority.

**Why it is deferred:** The confidence level is stored in `interpretation_packs.confidence_level` and propagated to decision records by FNC-007 (which adds `interpretation_confidence_level` NOT NULL to authority decision records). The DB layer captures this correctly. The API layer — how to present this to a user, what warnings to show, whether to block certain actions in the UI — is a Phase 2 design decision that depends on the stable DB schema and stakeholder UX decisions.

**Blocked on:**
- GF-W1-FNC-007 (interpretation_confidence_level enforcement) — planned
- Phase 2 entry gate passing
- Phase 2 API design approval
- UX design for confidence indicators

**Wave 1 prerequisite tasks:**
- GF-W1-SCH-002 (interpretation_packs with confidence_level)
- GF-W1-FNC-004 (provisional pass for PENDING_CLARIFICATION)
- GF-W1-FNC-007 (confidence propagation to decision records)

---

## DEFER-005: Phase 2 Contract Rows for Green Finance Domain

**What it is:** INV-159 and above invariant entries for the green finance API surface. These are the formal contract rows that define what the Phase 2 API must satisfy — each with an invariant ID, a verifier script, an evidence path, and acceptance criteria. They are the Phase 2 equivalent of the Phase 0/1 invariant entries that govern the DB schema.

**Why it is deferred:** Phase 2 contract rows cannot be written until Phase 1 is complete and the API surface is designed. The invariant entries for the API layer depend on knowing what the API does — which endpoints exist, what authorization model is used, what the response contracts are. Writing contract rows speculatively would create governance overhead for an API that might change shape during design.

**Blocked on:**
- Phase 2 entry gate passing
- Phase 2 API design document approved
- All Phase 1 tasks completed (including FNC-007)

**Wave 1 prerequisite tasks:**
- All GF-W1 tasks (the entire Phase 0 + Phase 1 tranche)
- GF-W1-GOV-006 (this task — establishes the gate that Phase 2 contract rows enforce)

---

## Governance

- This document is **authoritative** — if a deferred item is not listed here, it was not formally deferred and must go through the standard Phase 2 planning process.
- Each deferred item will be converted to one or more Phase 2 task meta files with proper contract rows before implementation begins.
- The Phase 2 entry gate (`scripts/audit/verify_gf_phase2_entry_gate.sh`) mechanically enforces that this document exists before Phase 2 work proceeds.
- Additions to this register require architecture owner approval.
