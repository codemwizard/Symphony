# PHASE_SPECIFICATION_CBAM_CAPABILITY_AUGMENTATION.md

Constitutional-Status: INTERPRETIVE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 6
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/architecture/Symphony-Phase-Specification-Document_v1.md
  - docs/constitutional/UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md
  - docs/constitutional/UNCERTAINTY_OPERATOR_REGISTRY.md
  - docs/constitutional/AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/PHASE3/PHASE3_CAPABILITY_BOUNDARY.md

---

## Purpose

This document augments the Phase Specification with CBAM-driven capability
additions across Phases 3 through 8E. It was produced through constitutional
review of the EU Carbon Border Adjustment Mechanism's architectural
implications for Symphony's evidence legitimacy substrate.

The augmentation is structured as addenda to each affected phase's
specification. It does not replace or contradict the original phase
specification. Where this augmentation adds a capability, that capability
is within the existing phase's constitutional scope as declared by the
phase specification and its governing doctrines.

---

## Cross-Phase Invariants

These rules govern all phases from Phase 3 through Phase 8E for all
CBAM-derived capabilities. They take precedence over any phase-specific
implementation convenience.

**XI-1 — Type Lock:**
No phase after Phase 3 may introduce a new uncertainty representation class.
New classes require a Phase 3 constitutional amendment to
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`.

**XI-2 — Operator Lock:**
No phase after Phase 3 may introduce a new propagation operator. New operators
require a Phase 3 amendment to `UNCERTAINTY_OPERATOR_REGISTRY.md`.

**XI-3 — Unknown-Uncertainty Rule:**
Missing uncertainty class = `U-UNKNOWN-UNCERTAINTY` in all phases. Never
defaulted to `U-EXACT`. Always flagged. Always held pending review before
any finality gate.

**XI-4 — Resolution Before Finality:**
Uncertainty must be resolved to a definite value before entering: settlement
finality, authorization request packs, registry submissions, or statutory
calculations. Resolution must produce an `uncertainty_propagation_steps`
record.

**XI-5 — Replay Continuity:**
Every uncertainty propagation step and authority transfer record is a Phase
3 evidence record subject to all permanence guarantees in
`EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` EPG-1 through EPG-7.

**XI-6 — No Presentation-Layer Calculation:**
Phases 6, 8D, and 8E display and package uncertainty findings. They do not
recalculate them. Any calculation appearing in a presentation-layer phase
is a constitutional phase-boundary violation.

**XI-7 — Authority Transfer Gate:**
No task pack at any phase may assume an authority transfer ownership mode
unless `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` exists and the
specific transfer is declared in that doctrine.

---

## Phase 3 Augmentation

### New Capability: 3.9 Uncertainty And Estimation Semantics

**Constitutional Purpose:** Establishes uncertainty as a first-class
evidentiary property with deterministic representation, operator-registry-
constrained propagation, admissibility classification, and replay-visible
findings.

**What this capability builds:**

- Constitutional persistence schemas for seven uncertainty classes
  (`U-EXACT`, `U-BOUNDED-RANGE`, `U-CONFIDENCE-INTERVAL`,
  `U-DECLARED-DISTRIBUTION`, `U-DATA-QUALITY-INDICATOR`,
  `U-METHODOLOGICAL-ASSUMPTION`, `U-UNKNOWN-UNCERTAINTY`)
- `UNCERTAINTY_OPERATOR_REGISTRY.md` with eleven registered operators
  (OP-001 through OP-011)
- `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` defining the four
  transfer modes (AT-EXCLUSIVE, AT-SHARED, AT-DELEGATED, AT-ADVISORY)
- `authority_transfer_records` persistence schema for replay-visible
  authority handoffs
- Verifier `scripts/audit/verify_p3_uncertainty_semantics.sh`
- Invariants INV-311 and INV-312

**What this capability does not build:**
Methodology-specific propagation execution (Phase 5); industrial carbon
ontology (Phase 5); CBAM evidence packaging (Phase 8D).

**Exit criteria addition to Phase 3:**
In addition to the existing Phase 3 exit criteria, Phase 3 is not complete
until: all seven uncertainty classes are persistable and schema-validated;
`U-UNKNOWN-UNCERTAINTY` is enforced as a non-default flag state at the DB
layer; authority transfer records are produced for all Phase 3 surface
handoffs involving uncertainty findings; INV-311 and INV-312 are promoted
to `status: implemented`.

---

## Phase 4 Augmentation

### Uncertainty Consumption Additions to §4.9 Statutory Kill Criteria

**New Kill Criterion 4.9.5 — Uncertainty Threshold Exceeded:**
A statutory calculation whose inputs carry `uncertainty_findings` with
outcome `INADMISSIBLE` or `UNKNOWN_UNCERTAINTY` must trigger an automatic
halt. The calculation may not proceed until the uncertainty is resolved to
a definite value via a Phase 3 registered decision policy.

**New Kill Criterion 4.9.6 — Unresolved Uncertainty in Settlement Input:**
Any evidence artifact carrying `U-UNKNOWN-UNCERTAINTY` may not serve as
an input to a settlement finality calculation. The artifact must be resolved
or reclassified before the settlement path can proceed.

### Financial Calculation Uncertainty Gate

**New §4.10 — Financial Calculation Uncertainty Gate:**
Phase 4 must declare, for each statutory calculation surface, which input
fields may carry uncertainty and which must be `U-EXACT`. The declaration
must be version-bound to the governing policy artifact. Fields not declared
as uncertainty-eligible are implicitly `U-EXACT` and must fail with SQLSTATE
P4001 if a non-exact uncertainty measurement is submitted.

BoZ FX reference rates are constitutionally classified as `U-EXACT` class
inputs. They may not be treated as estimates, ranges, or distributions. Any
financial calculation treating a BoZ rate as an uncertainty-bearing input
is constitutionally invalid.

**Authority Transfer at Phase 4:**
When a Phase 3 uncertainty finding triggers a Phase 4 kill criterion, the
transfer mode is `AT-EXCLUSIVE` per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4. Phase 4 holds
exclusive statutory enforcement authority from the moment the threshold is
exceeded. Phase 3 does not retain override rights over the kill decision.

**What Phase 4 must not build:**
New uncertainty representation types; uncertainty propagation operators;
any recalculation of Phase 3 uncertainty findings; authority transfer mode
definitions.

---

## Phase 5 Augmentation

### New §5.13 — Industrial Carbon Ontology

**Constitutional Purpose:** Represent industrial process emissions in a
machine-verifiable, adapter-governed form that consumes Phase 3 uncertainty
primitives.

**What this builds:**
- Ontology schemas for: smelting processes, refining processes, electricity
  attribution (direct and grid-average), precursor emissions (embedded in
  purchased inputs), embedded emissions decomposition (separating direct,
  process, and energy-source emissions)
- Coverage for: copper cathode production, aluminium smelting, cement
  manufacturing, fertilizer production, hydrogen production
- Integration with Phase 3 uncertainty classes: activity quantities,
  emission factors, and energy source attributions may carry `U-BOUNDED-RANGE`
  or `U-CONFIDENCE-INTERVAL` classes; the ontology schema must declare
  the uncertainty class for each field
- Version-bound ontology artifacts: each ontology version is a policy
  artifact under `POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`

**What this does not build:**
New uncertainty classes (Phase 3 lock); CBAM-specific regulatory
calculations (Phase 8D); external registry emissions factors (Phase 8B).

### New §5.14 — Supply Chain Carbon Provenance Graph

**Constitutional Purpose:** Track upstream inputs and embedded emissions
across supplier relationships in a replay-visible graph structure that
extends the Phase 3 typed dependency graph.

**What this builds:**
- Supply chain graph schema extending `P3-SURF-001` typed dependency graph
  into multi-enterprise scope
- Supplier relationship records: each supplier relationship carries a
  declared emissions intensity, uncertainty class, and provenance source
- Precursor emissions tracking: for each product, the graph records which
  input materials contributed embedded emissions and at what uncertainty class
- Chain-of-custody carbon propagation: embedded emissions from upstream
  inputs propagate through the graph using Phase 3 registered operators
  (OP-001 through OP-010)
- Cross-enterprise boundary markers: the graph declares where evidence
  transitions from internally-measured to supplier-declared data, with
  appropriate uncertainty class assignment (`U-METHODOLOGICAL-ASSUMPTION`
  or `U-DATA-QUALITY-INDICATOR` at the boundary)

**What this does not build:**
External registry integrations (Phase 8B); CBAM cross-enterprise evidence
sharing (Phase 8D); new uncertainty operators (Phase 3 lock).

### New §5.15 — Embedded Emissions Computation Engine

**Constitutional Purpose:** Execute uncertainty-aware product-level carbon
calculations within the adapter framework, consuming Phase 3 operators and
the Phase 5 industrial carbon ontology.

**What this builds:**
- Adapter execution of embedded emissions calculations using only Phase 3
  registered operators from `UNCERTAINTY_OPERATOR_REGISTRY.md`
- Deterministic sandbox: rejects any adapter calling a non-deterministic
  function during embedded emissions calculation
- Temporal compatibility: uncertainty inputs from prior reporting periods
  carry the uncertainty model version under which they were declared; an
  adapter recalculating historical values must use the historical uncertainty
  model version
- Adapter certification additions: an adapter performing embedded emissions
  calculations must declare: which input fields carry uncertainty, which
  Phase 3 operators are applied, what the admissibility threshold policy is,
  and which industrial ontology version governs the calculation. An adapter
  without these declarations cannot be certified.
- `uncertainty_propagation_steps` record production: every embedded emissions
  calculation step populates the Phase 3 persistence schema; the Phase 5
  adapter executes; Phase 3 schema records the step

**Authority Transfer at Phase 5:**
Phase 5 executes Phase 3 operators under `AT-DELEGATED` mode per
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4. Phase 3 retains
constitutional ownership of the operator registry. Phase 5's delegation
expires when the adapter's propagation step is finalized and the
`uncertainty_propagation_steps` record is committed.

**What this does not build:**
New uncertainty representation classes; new operators; CBAM regulatory
calculations; industrial ontology definition (that is §5.13 above).

### Additions to §5.5 — Adapter Certification

The following uncertainty-related requirements are added to adapter
certification:

- Adapter must declare its uncertainty model: which input fields may carry
  uncertainty, which classes are permitted for each field, which registered
  operators are applied.
- Adapter must declare its admissibility threshold policy with policy version
  binding.
- An adapter that applies `U-UNKNOWN-UNCERTAINTY` inputs to any calculation
  without first resolving them must fail certification.
- An adapter that calls any function not in `UNCERTAINTY_OPERATOR_REGISTRY.md`
  during uncertainty propagation must fail certification.

---

## Phase 6 Augmentation

### Additions to §6.3 — Intake Boundary

**Uncertainty Class Declaration at Intake:**
Field capture forms must surface uncertainty class declaration at intake.
When a field measurement is recorded, the operator must declare the
measurement class from the seven classes defined in
`UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`. This declaration is
captured as an `uncertainty_measurements` record with full provenance at
intake time — not after, not retroactively.

**Offline Capture Uncertainty Rule:**
Offline submissions without an explicit uncertainty class declaration receive
`U-UNKNOWN-UNCERTAINTY` on sync — not `U-EXACT`. They are flagged for
review. An offline capture system that defaults missing uncertainty to exact
is constitutionally non-compliant.

### Additions to §6.4 — Draft-to-Admitted Transition

**Uncertainty Gate at Admission:**
Evidence with `U-UNKNOWN-UNCERTAINTY` or with an `uncertainty_findings`
outcome of `INADMISSIBLE` must remain in draft status. Admission requires
either: resolution to a definite value via a Phase 3 registered decision
policy, or explicit constitutional exemption with a recorded justification.
The admission gate is enforced at the DB layer; application-layer-only
enforcement is constitutionally insufficient.

### Additions to §6.8 — VVB Portals

**Uncertainty Finding Display:**
VVB portals must display for each evidence item under review: the declared
uncertainty class, the operator applied (if any), and the `uncertainty_findings`
outcome. This is a read surface over Phase 3 data. VVB portals may not
modify uncertainty class declarations or produce new uncertainty findings.
Their role is verification, not reclassification.

### Additions to §6.9 — Regulator Review Workspaces

**Uncertainty Replay View:**
Regulator Review Workspaces must include the uncertainty propagation chain
in the replay view. A regulator replaying a legitimacy decision must see
the uncertainty inputs, each propagation step, the operator applied, and
the final finding. This chain must be reconstructable from persisted Phase
3 records without runtime service calls.

---

## Phase 7 Augmentation

### Additions to §7.1 — Zero Platform Schema Changes

**Uncertainty Substrate Non-Modification:**
The second methodology must not require modification to Phase 3 uncertainty
schemas, operator registry, or admissibility rules. If the second methodology
requires a new uncertainty class or operator, this constitutes a platform
schema change and fails Phase 7 certification. The correct resolution is a
Phase 3 constitutional amendment before Phase 7 certification proceeds.

### Additions to §7.4 — Strict Adapter Isolation

**Cross-Methodology Uncertainty Isolation:**
Uncertainty findings produced for Methodology A must not influence
admissibility determinations for Methodology B. The `cross_entity_replay_isolation`
property extends to uncertainty findings across methodology domains. An
adapter for Methodology B that reads uncertainty records produced by
Methodology A's adapter is constitutionally prohibited.

### New §7.7 — Uncertainty Methodology Neutrality Proof

**Proof Obligation:**
Phase 7 must prove that the uncertainty substrate is methodology-neutral by
demonstrating that the second methodology adapter:

- Uses only Phase 3 registered operators from `UNCERTAINTY_OPERATOR_REGISTRY.md`
  with no new registrations required
- Assigns only Phase 3 declared uncertainty classes with no new classes required
- Produces `uncertainty_propagation_steps` records using the same schema as
  the first methodology with no schema additions required
- Passes the same `verify_p3_uncertainty_semantics.sh` verifier as Phase 3

Failure of any of these proof obligations constitutes a Phase 7 exit
criteria failure.

### Additions to §7.5 — Unified DNSH Constraints

**DNSH Uncertainty Handling:**
Both methodologies must use the same spatial uncertainty operators when
evaluating DNSH constraints, proving that Phase 3's bounded-nondeterministic
spatial surface (`P3-SURF-009`) and the uncertainty engine are compositionally
compatible. A methodology that requires different spatial uncertainty
operators fails unified DNSH constraint certification.

---

## Phase 8A Augmentation

### New §8A.5 — Uncertainty Resolution Gate

**Pre-Authorization Uncertainty Resolution:**
All evidence destined for inclusion in a machine-readable host-country
authorization request pack must pass through an uncertainty resolution gate
before inclusion. Evidence carrying `U-UNKNOWN-UNCERTAINTY` or
`uncertainty_findings` outcome `INADMISSIBLE` may not be included.

Resolution must:
- Apply a registered Phase 3 decision policy, typically `DP-CONSERVATIVE-DEFAULT`
  or `DP-UPPER-BOUND`, to produce a definite `U-EXACT` value
- Produce an `uncertainty_propagation_steps` record documenting the resolution
- Produce an `uncertainty_findings` record with outcome `ADMISSIBLE` citing
  the resolved value

### §8A Corresponding Adjustment Uncertainty Rule

Corresponding Adjustment bindings must be on `U-EXACT` resolved values. A
Corresponding Adjustment that references an `uncertainty_measurements` record
with a range-bearing class is constitutionally invalid.

### §8A First-Transfer Proof Attachment

First-transfer proof attachments must include the `uncertainty_propagation_steps`
record proving the value used in the authorization was derived via a
registered conservative operator from the declared uncertainty inputs.

**Authority Transfer:**
Once an uncertainty value is resolved for authorization purposes, the
transfer mode is `AT-EXCLUSIVE`. The original uncertainty range cannot be
re-opened by Phase 3 for the purposes of the authorization record. The
original measurement remains in the Phase 3 evidence corpus permanently;
the authorization record is bound to the resolved value only.

---

## Phase 8B Augmentation

### New §8B.5 — Registry Submission Uncertainty Requirements

**Pre-Submission Uncertainty Verification:**
All quantities in a Verra issuance package or ZEMA notification must have
passed through Phase 8A's uncertainty resolution gate (for Article 6 credits)
or through a Phase 4 financial calculation uncertainty gate (for domestic
calculations). Raw uncertainty ranges must not appear in registry submissions.

**Uncertainty Audit Trail in Registry Packages:**
Where the target registry's schema supports provenance metadata, the
uncertainty resolution audit trail reference (the `uncertainty_propagation_steps`
record chain) must be included as supporting metadata. ZEMA receives the
definite resolved quantity; the audit trail documents its derivation.

**Bidirectional Reconciliation:**
Credit state reconciliation treats credit quantities as `U-EXACT`. Any
discrepancy between the registry's recorded quantity and Symphony's resolved
quantity triggers a contradiction finding under `P3-SURF-004`, not an
uncertainty reclassification.

---

## Phase 8D Augmentation

### New §8D.5 — CBAM Evidence Runtime

**Constitutional Purpose:** Produce machine-readable evidence packages for
EU CBAM declarations that carry full uncertainty provenance from Phase 3
through Phase 5.

**What this builds:**
- CBAM-compatible evidence packages containing: declared embedded emissions
  with confidence intervals, supplier uncertainty declarations, energy
  provenance with uncertainty class, methodology assumptions, and the Phase
  3 uncertainty propagation chain as the machine-readable assurance trail
- Authority transfer records documenting the transfer mode governing the
  producer-to-importer evidence handoff (AT-ADVISORY per
  `AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md` §4)
- Shipment-period accounting: evidence packages are scoped to declared
  shipment periods with temporal bounds; each package freezes the evidentiary
  state active at the time of the shipment declaration

**What this does not build:**
New uncertainty classes; new propagation operators; recalculation of
embedded emissions (Phase 5 outputs are consumed, not recomputed).

### New §8D.6 — Shipment-Level Replay Model

**Constitutional Purpose:** Freeze the exact evidentiary state used for
each export shipment declaration to support dispute resolution years after
the shipment date.

**What this builds:**
- Shipment replay records that capture: the uncertainty inputs active at
  declaration time, the propagation chain applied, the authority transfer
  records governing the producer-to-importer handoff, the policy versions
  active at declaration time, and the resolved definite values used in the
  CBAM certificate filing
- Replay reconstruction path: given a shipment ID and historical date,
  replay must reproduce the identical CBAM evidence package that was
  produced at declaration time
- Immutability: shipment replay records are append-only from the moment of
  declaration. No operational act may alter a finalized shipment replay
  record.

### New §8D.7 — Declarant/Importer Separation Doctrine

**Constitutional Purpose:** Separate the Zambian producer's evidence
ownership from the EU importer's declaration responsibility.

**What this builds:**
- Producer evidence scope: the Zambian producer's `uncertainty_measurements`,
  `uncertainty_propagation_steps`, and `uncertainty_findings` records remain
  under the producer's constitutional evidence sovereignty. The EU importer
  receives a scoped, read-only evidence room containing only the evidence
  relevant to the specific shipment(s) declared.
- Importer declaration scope: the EU importer's CBAM certificate filing
  references the producer's evidence package but is an independent declaration
  act. The importer holds declaration authority; the producer holds evidence
  authority.
- Authority transfer: the producer's uncertainty declaration is an `AT-ADVISORY`
  input to the importer's declaration. The importer's declaration authority
  is independent. The producer's uncertainty record is permanently preserved
  as the evidential basis; the importer's use of it does not transfer or
  revoke the producer's evidence ownership.
- Access scoping: the Enterprise Evidence API (§8D.8) enforces this
  separation by providing importer-scoped evidence rooms that expose only
  the uncertainty findings and propagation chain relevant to the declared
  shipment, without exposing the producer's full operational record.

### New §8D.8 — Enterprise Evidence API

**Constitutional Purpose:** Provide buyer-scoped evidence rooms and
machine-readable assurance interfaces for CBAM declarants, corporate
disclosure reporters, and financial auditors.

**What this builds:**
- Buyer-scoped evidence rooms: each buyer receives an evidence room scoped
  to their declared relationship with the producer (shipment-level,
  product-level, or period-level). Evidence rooms are read-only.
- Uncertainty scoping: the granularity of uncertainty exposure is determined
  by the buyer's disclosure obligation — a CBAM declarant receives the full
  confidence interval chain; a high-level disclosure recipient receives the
  resolved conservative value
- Machine-readable assurance trail: the trail demonstrates that confidence
  ranges are derived from Phase 3-registered operators applied to declared
  inputs, not invented at disclosure time. The trail is auditable without
  access to Symphony's runtime.
- Authority transfer records in the API response: where the producer-to-buyer
  handoff involves an authority transfer, the transfer record is included in
  the evidence room to document the transfer mode.

### New §8D.9 — Disclosure Adapters (ESRS E1, ISSB S2, CBAM)

**Constitutional Purpose:** Package Phase 3 uncertainty findings and Phase
5 propagation records into format-specific disclosure artifacts for corporate
climate reporting obligations.

**What these adapters build:**

*ESRS E1 Adapter:*
- Populates ESRS E1 Scope 1, 2, and 3 uncertainty fields from
  `uncertainty_findings` and `uncertainty_propagation_steps` records
- Maps Phase 3 uncertainty classes to ESRS E1 estimation uncertainty
  disclosure categories
- Version-bound to the ESRS E1 standard version declared in the governing
  interpretation pack

*ISSB S2 Adapter:*
- Populates ISSB S2 significant estimation uncertainty fields from Phase
  3/5 outputs
- Maps confidence intervals to ISSB S2 disclosure requirements
- Version-bound to the ISSB S2 standard version declared in the governing
  interpretation pack

*CBAM Adapter:*
- Produces the CBAM-compatible XML/JSON evidence package defined in §8D.5
- Applies `DP-UPPER-BOUND` decision policy by default for embedded emissions
  (conservative maximum as the regulatory conservative choice)
- Includes the full shipment-level replay record reference per §8D.6

**What these adapters must not do:**
Recalculate uncertainty values; introduce new uncertainty classes; define
new operators; alter Phase 3 evidence records.

### §8D Exit Criteria Additions

Phase 8D is not complete until:
- CBAM evidence packages are machine-readable and include full uncertainty
  provenance chains
- Shipment-level replay is demonstrably reproducible from persisted Phase
  3 records without runtime service calls
- Declarant/importer separation is enforced at the API access-control layer
- All three disclosure adapters produce outputs that trace to Phase 3
  `uncertainty_findings` records without recalculation

---

## Phase 8E Augmentation

### New §8E.5 — Green Bond Uncertainty Provenance

**Constitutional Purpose:** Expose uncertainty-resolved impact evidence to
capital market participants with full uncertainty provenance for the life of
the bond.

**What this builds:**
- BoZ/SEC green bond use-of-proceeds evidence packs that include the
  `uncertainty_propagation_steps` record chain proving that the reported
  impact quantity was derived conservatively from declared uncertainty inputs
- Impact-to-capital traceability chains: for each reported unit of impact
  (tonne CO2e, MWh renewable), the chain traces to the `uncertainty_measurements`
  record, declared class, and resolution operator applied
- Underwriter evidence rooms: read-only surfaces that display the uncertainty
  propagation summary alongside the impact claim, structured for audit
  without requiring access to Symphony's operational runtime
- Extended retention: `uncertainty_propagation_steps` records that supported
  a green bond issuance must be flagged for retention for the full term of
  the bond, not only the standard 7-year default. This is enforced by a
  bond-term retention record that FK-references the relevant propagation
  step IDs.

**What this does not build:**
New uncertainty classes; new operators; recalculation of impact quantities;
modification of Phase 3 evidence records.

### §8E Exit Criteria Additions

Phase 8E is not complete until:
- BoZ-format loan compliance reports trace impact quantities to Phase 3
  uncertainty findings without recalculation
- Bond-term retention records exist for all `uncertainty_propagation_steps`
  records that underpin issued green bonds
- Underwriter evidence rooms are demonstrably auditable without runtime
  service dependency

---

## Phase Ownership Summary (Complete)

| Capability | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 | Phase 8A | Phase 8B | Phase 8D | Phase 8E |
|---|---|---|---|---|---|---|---|---|---|
| Uncertainty representation classes (7) | Owns | — | Consumes | Consumes | Proves neutral | — | — | Consumes | — |
| Operator registry (11 operators) | Owns | — | Executes | — | Proves adapter-agnostic | — | — | — | — |
| `U-UNKNOWN-UNCERTAINTY` (non-default flag) | Owns | — | — | Enforces at intake | — | — | — | — | — |
| Authority transfer doctrine (4 modes) | Owns | Must cite | Must cite | Must cite | Must cite | Must cite | — | Must cite | — |
| Authority transfer records schema | Owns | — | Populates | Populates | — | Populates | — | Populates | — |
| Uncertainty admissibility verifier | Owns | — | Extends to sandbox | — | — | — | — | — | — |
| Statutory kill criterion (uncertainty threshold) | — | Owns | — | — | — | — | — | — | — |
| Financial calculation uncertainty gate | — | Owns | — | — | — | — | — | — | — |
| Industrial Carbon Ontology | — | — | Owns | — | — | — | — | Consumes | — |
| Supply Chain Provenance Graph | — | — | Owns | — | — | — | — | Extends externally | — |
| Embedded Emissions Computation | — | — | Owns | — | — | — | — | Consumes | — |
| Adapter certification (uncertainty model) | — | — | Owns | — | — | — | — | — | — |
| Field capture uncertainty declaration | — | — | — | Owns | — | — | — | — | — |
| Draft-to-admitted uncertainty gate | — | — | — | Owns | — | — | — | — | — |
| VVB uncertainty finding display | — | — | — | Owns | — | — | — | — | — |
| Regulator replay uncertainty view | — | — | — | Owns | — | — | — | — | — |
| Cross-methodology uncertainty isolation proof | — | — | — | — | Owns | — | — | — | — |
| Uncertainty methodology neutrality proof | — | — | — | — | Owns | — | — | — | — |
| Authorization uncertainty resolution gate | — | — | — | — | — | Owns | — | — | — |
| Corresponding Adjustment uncertainty rule | — | — | — | — | — | Owns | — | — | — |
| Registry submission uncertainty verification | — | — | — | — | — | — | Owns | — | — |
| CBAM Evidence Runtime | — | — | — | — | — | — | — | Owns | — |
| Shipment-Level Replay Model | — | — | — | — | — | — | — | Owns | — |
| Declarant/Importer Separation | — | — | — | — | — | — | — | Owns | — |
| Enterprise Evidence API | — | — | — | — | — | — | — | Owns | — |
| ESRS E1 / ISSB S2 / CBAM Adapters | — | — | — | — | — | — | — | Owns | — |
| Green bond uncertainty provenance | — | — | — | — | — | — | — | — | Owns |
| Bond-term retention extension | — | — | — | — | — | — | — | — | Owns |
| Underwriter uncertainty evidence rooms | — | — | — | — | — | — | — | — | Owns |

---

## Constitutional Self-Validation

**Sovereignty domains governed:**
CBAM-derived capability phase routing across Phases 3 through 8E.

**Sovereignty domains this document must not redefine:**
Phase constitutional boundaries (governed by
`Symphony-Phase-Specification-Document_v1.md`); uncertainty semantics
(governed by `UNCERTAINTY_AND_ESTIMATION_SEMANTICS_DOCTRINE.md`); authority
transfer modes (governed by
`AUTHORITY_TRANSFER_OWNERSHIP_SEMANTICS_DOCTRINE.md`).

**Phases this document applies to:**
Phases 3 through 8E. Global for CBAM-derived capabilities only.

**Constitutional layers with override authority:**
`Symphony-Phase-Specification-Document_v1.md` (Authority-Rank 7) and the
constitutional corpus. This augmentation (Authority-Rank 6) operates within
those constraints.

**Lower-layer documents prohibited from reinterpretation:**
Phase-specific implementation plans, wave plans, and task packs may not
reinterpret the phase ownership assignments in the summary table above.
Reassigning a capability to a different phase requires an amendment to this
augmentation document.