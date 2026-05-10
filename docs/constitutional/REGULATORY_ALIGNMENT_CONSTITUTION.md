# REGULATORY ALIGNMENT CONSTITUTION

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: REGULATORY
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 7
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
  - docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md

---

## Purpose

This document establishes the constitutional mapping between Symphony's sovereign
trust coordination substrate and the regulatory authority surfaces that govern its
operational domain. It defines, for each applicable regulatory regime, the precise
admissibility implications, replay obligations, sovereignty boundaries, and
evidence survivability requirements that Symphony must satisfy as a constitutional
matter — not as a compliance posture.

Symphony is not constituted as a reporting platform toward these regulatory
regimes. It is constituted as an evidentiary substrate within them. The
distinction is constitutional: a reporting platform is a data source that regulators
may query. An evidentiary substrate is a constitutional actor within a regulator's
jurisdiction whose records carry legal evidentiary weight from the moment of their
production.

This document does not collapse regulatory regimes into generic compliance
semantics. Each regime is constitutionally distinct. Each carries its own
admissibility standards, its own evidence class requirements, its own replay
obligations, and its own sovereignty posture. The regimes mapped here coexist
within Symphony's constitutional architecture without merger, equivalence, or
mutual subordination.

---

## Constitutional Scope

This document governs:

1. The constitutional relationship between Symphony's sovereign trust coordination
   substrate and each named regulatory regime.
2. The admissibility conditions Symphony must satisfy for evidence to be legally
   and regulatorily valid within each regime.
3. The replay obligations arising from each regime's evidentiary requirements.
4. The sovereignty boundaries that define each regime's domain and the limits of
   that domain's authority over Symphony's architecture.
5. The regulator coexistence rules governing the simultaneous operation of
   multiple regulatory regimes across Symphony's evidence surfaces.
6. The evidence survivability requirements applicable per regime for the full
   retention period.
7. The phase interaction rules governing which regulatory obligations are active
   in which constitutional phases.

This document does NOT govern:

- The internal enforcement trigger implementation for any regulatory requirement.
- The specific wire format or transmission protocol for regulatory reporting.
- The identity of specific regulated entities, participants, or counterparties.
- The substantive interpretation of any regulatory text beyond its constitutional
  mapping to Symphony's architecture.
- The legal advice obligations of any party subject to the applicable regulations.
- The internal key custody posture or HSM configuration choices.

---

## Authority Boundaries

This document operates at Authority-Rank 7 (Regulator Partition Doctrine). It
defines the constitutional scope and admissibility standards within each
regulator sovereignty domain. It may not redefine Root Constitutional Doctrine
(Rank 10), Wave Sovereignty Doctrine (Rank 9), or Phase Constitutional Doctrine
(Rank 8). Its provisions operate within the constraints established by those
superior-rank documents. Where any provision of this document conflicts with a
superior-rank document, the superior-rank document is controlling.

Each regulatory domain defined herein is constitutionally orthogonal. No domain
definition may expand, contract, or subordinate any other domain definition. The
authority of this document within each domain is scoped to that domain exclusively.

---

## Part I: Regulatory Domain Register

The following regulatory domains are constitutionally recognized and individually
mapped in this document:

| Domain ID | Regulatory Instrument | Jurisdiction | Evidence Class Primary | Wave Boundary |
|---|---|---|---|---|
| REG-ZM-001 | Zambia Statutory Instrument 5 of 2026 | Republic of Zambia | Operational + Settlement | Wave 4 |
| REG-ZM-002 | Zambia Green Finance Taxonomy (ZGFT) | Republic of Zambia | Regulator (Green Finance) | Wave 8 |
| REG-ZM-003 | Bank of Zambia Evidentiary Standards | Republic of Zambia | Operational + Provenance + Settlement | Wave 4 + Wave 8 |
| REG-ZM-004 | Zambia Data Protection Act (ZDPA) | Republic of Zambia | Methodological + Retention | Wave 4 |
| REG-ZM-005 | ZEMA Authority Model | Republic of Zambia | Attestation + Regulator (Green Finance) | Wave 8 |
| REG-INT-001 | Paris Agreement Article 6 | International (UNFCCC) | Attestation + Regulator (Green Finance) | Wave 8 |
| REG-INT-002 | Verra Verified Carbon Standard | International (Verra) | Attestation + Methodological | Wave 8 |
| REG-INT-003 | Gold Standard (GS4GG) | International (Gold Standard Foundation) | Attestation + Methodological | Wave 8 |
| REG-INT-004 | EU Carbon Border Adjustment Mechanism (CBAM) | European Union | Regulator (Green Finance) + Retention | Wave 8 |

---

## Part II: REG-ZM-001 — Zambia Statutory Instrument 5 of 2026

### 2.1 Constitutional Description

Zambia SI 5 of 2026 constitutes the primary domestic regulatory instrument
governing payment system operations, financial infrastructure authority, and
evidentiary requirements for transaction records within the Republic of Zambia.
As a statutory instrument, it is a binding legislative act that supplements the
Bank of Zambia Act and the National Payment Systems Act and carries the full force
of Zambian law.

Symphony's relationship to SI 5 of 2026 is that of a regulated financial
infrastructure operator. Symphony's `state_transitions`, `payment_outbox_attempts`,
and `instruction_settlement_finality` surfaces are constitutionally within the
scope of SI 5 of 2026's evidentiary requirements.

### 2.2 Admissibility Implications

**ADM-ZM-001-1. Transaction Record Admissibility:**
For any transaction record to be admissible before Zambian regulatory authorities
under SI 5 of 2026, it must be produced from Symphony's `state_transitions` or
`instruction_settlement_finality` surfaces, not from `state_current` or
derivative projections. The append-only, trigger-enforced immutability of
`state_transitions` (EPG-1 in EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md)
is the constitutional mechanism by which SI 5 of 2026 admissibility is preserved.

**ADM-ZM-001-2. Finality Record Admissibility:**
Settlement finality records presented under SI 5 of 2026 must satisfy the
`is_final = TRUE` condition and the shape constraint enforced by
`instruction_settlement_finality`. A settlement record whose finality was
established by UPDATE rather than by insert-time enforcement is constitutionally
inadmissible under SI 5 of 2026 because its finality determination is not
immutably anchored at the moment of recording. The `deny_final_instruction_mutation`
trigger (SQLSTATE P7003) is the Wave 4 enforcement surface for this requirement.

**ADM-ZM-001-3. Cryptographic Admissibility Floor:**
SI 5 of 2026 requires that transaction records be attributable to authorized
actors. Symphony satisfies this requirement through the execution record binding
(FK from `state_transitions` to `execution_records`) and the policy decision
binding (FK to `policy_decisions` with `decision_hash` and `signature`).
Records produced before the Wave 8 cryptographic enforcement path was activated
on a given write path carry the evidentiary limitation declared in
§5.2 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md.

**ADM-ZM-001-4. Data-Authority Admissibility Classification:**
Under SI 5 of 2026, records carrying `data_authority = 'phase1_indicative_only'`
are admissible only as indicator records — they prove that an event was recorded
but do not establish cryptographic attribution. Records carrying
`data_authority = 'authoritative_signed'` satisfy the full SI 5 of 2026
admissibility standard for attributable transaction records.

### 2.3 Replay Obligations

**REP-ZM-001-1.** Every `state_transitions` record within SI 5 of 2026 jurisdiction
must be replayable to its full authority tuple from persisted fields alone,
without requiring access to Symphony's operational runtime at the time of replay.
This is a direct consequence of the external verifier independence obligation
(VIG-1 in EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md) applied to the Zambian
regulatory domain.

**REP-ZM-001-2.** Settlement finality records must be replayable through the
complete reconstruction flow defined in §14.3 of
EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md. The Bank of Zambia may
conduct independent replay verification of settlement records without cooperation
from Symphony's runtime infrastructure. Symphony must not architect its settlement
finality surfaces in a way that makes this independent replay impossible.

**REP-ZM-001-3.** Replay obligations under SI 5 of 2026 persist for the statutory
retention period applicable to payment records under Zambian law. During this
entire period, the complete authority tuple, the FK references to execution records
and policy decisions, and the transition_hash must remain accessible from
persisted records without deletion, compaction, or format transformation.

### 2.4 Sovereignty Boundaries

**SOV-ZM-001-1.** SI 5 of 2026 exercises regulatory sovereignty over payment
transactions processed within the Republic of Zambia. Its sovereignty extends to
the admissibility and evidential weight of transaction records. It does not
extend to Symphony's internal cryptographic architecture, key custody model, or
constitutional document hierarchy.

**SOV-ZM-001-2.** SI 5 of 2026 does not exercise regulatory sovereignty over
Green Finance carbon accounting records. Records in `asset_batches`, `gf_projects`,
and related Green Finance surfaces are outside SI 5 of 2026's domain even when
they coexist within the same Symphony deployment.

**SOV-ZM-001-3.** Instructions from SI 5 of 2026's governing authority to modify,
correct, or delete transaction records do not override Symphony's append-only
constitutional permanence guarantees. Such instructions must be accommodated
through constitutional amendment procedures, not through direct record mutation.
The constitutional mechanism for resolving this conflict is defined in
CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, Scenario IC7.

### 2.5 Evidence Survivability

**EVS-ZM-001-1.** Transaction evidence under SI 5 of 2026 must survive: complete
key rotation cycles, operational runtime loss, phase transitions, and the
deployment of any future Symphony version that modifies the operational runtime.
The survivability mechanism is the persist-and-archive obligation defined in
§10 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md.

**EVS-ZM-001-2.** The statutory retention period under SI 5 of 2026 governs the
minimum duration for which evidence survivability must be maintained. During this
period, no optimization, migration, or architectural change may degrade the
accessibility or completeness of transaction evidence within this domain.

---

## Part III: REG-ZM-002 — Zambia Green Finance Taxonomy (ZGFT)

### 3.1 Constitutional Description

The Zambia Green Finance Taxonomy constitutes the national classification
framework for green economic activities within the Republic of Zambia. It defines
which activities qualify for green finance designation, the methodological
standards against which those activities are assessed, and the evidentiary
requirements for demonstrating taxonomy alignment.

Symphony's relationship to ZGFT is that of a taxonomy-aligned evidentiary
substrate. Symphony's `gf_projects`, `gf_monitoring_records`, `asset_batches`,
and `gf_methodology_versions` surfaces constitute the operational expression of
ZGFT taxonomy alignment claims. These claims are constitutional only when they
are backed by the complete evidence chain required by this domain.

### 3.2 Admissibility Implications

**ADM-ZM-002-1. Taxonomy Alignment Evidence:**
A taxonomy alignment claim under ZGFT is admissible before Zambian green finance
authorities only when it is backed by a complete evidence chain extending from
the `gf_projects` record through the `gf_monitoring_records`, through the
`gf_evidence_lineage`, and to the `asset_batches` record bearing a valid Wave 8
attestation. A claim backed only by `phase1_indicative_only` data-authority
records is not admissible as a ZGFT taxonomy alignment assertion.

**ADM-ZM-002-2. DNSH Compliance Evidence:**
The "Do No Significant Harm" (DNSH) criterion under ZGFT requires affirmative
evidence that green activities comply with environmental harm prohibitions. In
Symphony, this requirement is operationalized through the DNSH enforcement
trigger (GF057). Evidence of DNSH compliance is the trigger's enforcement log,
which constitutes Attestation Evidence (§4.7 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md).
A taxonomy alignment claim that does not include a corresponding DNSH enforcement
log entry is constitutionally inadmissible under ZGFT.

**ADM-ZM-002-3. K13 Taxonomy Alignment Admissibility:**
The K13 taxonomy alignment trigger (GF060) enforces compliance with Zambia's
specific sectoral taxonomy classification. Evidence of K13 alignment is the
trigger's enforcement log. This log entry is required for any ZGFT admissibility
claim in sectors covered by the K13 classification.

**ADM-ZM-002-4. Methodology Version Admissibility:**
ZGFT taxonomy alignment claims are methodology-version-specific. An alignment
claim must reference the specific `gf_methodology_version` against which it was
assessed. Supersession of a methodology version does not invalidate prior
alignment claims made under the prior version, but new claims must reference
the current version at the time of assessment. This is an application of the
replay-safe supersession rule (§8 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md).

### 3.3 Replay Obligations

**REP-ZM-002-1.** ZGFT taxonomy alignment evidence must be replayable to its
original assessment outcome. This requires that the `gf_methodology_version`
record referenced by the assessment remains available in the database in its
original form, that the `gf_monitoring_records` contributing to the assessment
remain unaltered, and that the Wave 8 attestation on the `asset_batches` record
remains verifiable from archive key material.

**REP-ZM-002-2.** Methodology version supersession is replay-safe: when a new
ZGFT methodology version is published and adopted, prior assessment records
reference the methodology version that was current at assessment time. Replay
verification uses that referenced version, not the current version. This is
the replay-safe supersession rule applied to the ZGFT domain.

### 3.4 Sovereignty Boundaries

**SOV-ZM-002-1.** ZGFT exercises regulatory sovereignty over taxonomy alignment
classifications of Zambian green economic activities. It does not exercise
sovereignty over the payment settlement records of the same projects, over the
international carbon credit standards (Verra, Gold Standard, Paris Article 6) to
which projects may also be aligned, or over Symphony's internal cryptographic
architecture.

**SOV-ZM-002-2.** ZGFT alignment is constitutionally independent of international
carbon registry alignment. A project may simultaneously satisfy ZGFT requirements
(REG-ZM-002), Verra VCS requirements (REG-INT-002), and Paris Article 6
requirements (REG-INT-001). These simultaneous satisfactions are constitutionally
additive; they are not mutually confirming. Satisfying one does not establish
satisfaction of the others.

### 3.5 Evidence Survivability

**EVS-ZM-002-1.** ZGFT taxonomy alignment evidence must survive the full lifecycle
of the green project to which it pertains, including post-project crediting periods.
Evidence artifacts must remain retrievable, verifiable, and complete for the
duration of any applicable Zambian regulatory retention obligation for green
finance records.

---

## Part IV: REG-ZM-003 — Bank of Zambia Evidentiary Standards

### 4.1 Constitutional Description

The Bank of Zambia (BoZ) exercises regulatory authority over financial
institutions and payment system operators in Zambia under the Bank of Zambia Act.
BoZ evidentiary standards define the records, formats, and authentication
requirements that financial entities must maintain and produce in the context of
regulatory examination, dispute resolution, and audit.

Symphony's relationship to BoZ evidentiary standards is dual: Symphony produces
both the payment operational evidence that BoZ may examine (overlapping with
SI 5 of 2026) and the provenance and methodological evidence that BoZ requires
to establish the authority chain behind payment decisions.

### 4.2 Admissibility Implications

**ADM-ZM-003-1. Audit Trail Completeness:**
BoZ examinations require a complete, unbroken audit trail from payment instruction
through execution through settlement finality. In Symphony's constitutional
architecture, this trail is the provenance chain defined in §9.1 of
EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md:
`state_transitions → execution_records → interpretation_packs → policy_decisions`.
An audit trail that cannot traverse this full chain from persisted records is
constitutionally inadmissible before BoZ as a complete audit trail.

**ADM-ZM-003-2. Authority Attribution:**
BoZ requires that every significant payment decision be attributable to an
authorized decision-maker. In Symphony, this is satisfied by the `declared_by`
field in `policy_decisions`, the `decision_hash` binding, and the Ed25519
signature. The `enforce_authority_transition_binding` function (INV-AUTH-TRANSITION-BINDING-01,
migration 0136) is the Wave 4 enforcement surface for authority attribution.

**ADM-ZM-003-3. Foreign Correspondent Evidentiary Requirements:**
BoZ evidentiary standards for cross-border payment transactions require that
evidence of settlement be portable to foreign correspondent banking jurisdictions.
Symphony satisfies this through the cross-jurisdiction evidence portability
obligations defined in §13 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
and the external verifier independence guarantees (VIG-1 through VIG-7 in
EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md).

**ADM-ZM-003-4. Conflict and Dispute Admissibility:**
In a BoZ-supervised dispute between payment system participants, evidence
presented must establish finality conclusively. `instruction_settlement_finality`
rows with `is_final = TRUE` constitute constitutionally conclusive finality
evidence. `instruction_finality_conflicts` rows constitute admissible evidence
of a contested finality determination and the containment response applied.

### 4.3 Replay Obligations

**REP-ZM-003-1.** BoZ retains the right to conduct independent examination of
Symphony's transaction records at any time within the applicable statutory period.
This right requires that Symphony maintain its evidence surfaces in a state that
is independently auditable without requiring Symphony's operational cooperation.
The external verification survivability obligations (EVS-1 through EVS-5 in
CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md) are the constitutional
mechanisms that satisfy this BoZ requirement.

**REP-ZM-003-2.** In the event of Symphony's operational failure or unavailability,
BoZ must retain the ability to access and verify transaction records from archived
evidence. Symphony must maintain an archive that supports offline verification
per §5 of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md.

### 4.4 Sovereignty Boundaries

**SOV-ZM-003-1.** BoZ exercises regulatory sovereignty over payment system
operations and financial institutions in Zambia. Its sovereignty over Symphony's
evidence surfaces extends to payment-related records only. It does not extend
to Green Finance carbon accounting records even when processed by the same
Symphony deployment.

**SOV-ZM-003-2.** BoZ examination authority does not extend to Symphony's
constitutional document hierarchy, wave sovereignty structure, or internal
cryptographic architecture. BoZ's authority is over the evidentiary outputs
of that architecture, not the architecture itself.

### 4.5 Evidence Survivability

**EVS-ZM-003-1.** BoZ evidentiary standards require retention of payment records
for not less than the applicable statutory period under Zambian law. This period
governs the minimum evidence survivability obligation for REG-ZM-003. The
7-year default in AUDIT_LOGGING_RETENTION_POLICY.md is the floor; where Zambian
statute requires longer retention, the statutory period governs.

---

## Part V: REG-ZM-004 — Zambia Data Protection Act (ZDPA)

### 5.1 Constitutional Description

The Zambia Data Protection Act establishes the rights of data subjects with
respect to personal information, the obligations of data processors and
controllers with respect to that information, and the conditions under which
personal information may be retained, processed, and erased.

Symphony's relationship to the ZDPA is that of a data controller and processor
with respect to personal information included in its operational surfaces. This
relationship creates a structural tension with Symphony's append-only evidence
permanence guarantees: the ZDPA creates erasure obligations, while Symphony's
constitutional architecture creates permanence obligations.

This tension is constitutionally resolved by the PII decoupling architecture
defined in §9.3 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md and
referenced in INV-107 (ZDPA_COMPLIANCE_MAP.md). The resolution is architectural,
not doctrinal: PII is placed outside the signed payload and outside the provenance
chain, so that its erasure does not break the provenance chain or the permanence
guarantees applicable to non-PII evidentiary material.

### 5.2 Admissibility Implications

**ADM-ZM-004-1. PII Erasure and Evidence Integrity:**
Where a valid ZDPA erasure request is received and executed, the erased PII
fields are removed from Symphony's operational surfaces. The corresponding
evidentiary records — `state_transitions`, `execution_records`, `policy_decisions` —
are not deleted. These records are retained with their non-PII fields and their
cryptographic proofs intact. The provenance chain remains traversable through
non-PII identifiers (`identity_hash`). Post-erasure evidence is constitutionally
admissible as evidence of the transaction event and its authority chain, with
the declared limitation that PII fields have been lawfully erased.

**ADM-ZM-004-2. PII-in-Payload Prohibition:**
It is constitutionally prohibited under both the ZDPA and Symphony's own
architecture to include raw PII fields in the signed payload of any
`state_transitions` record. Including PII in the signed payload creates an
irresolvable conflict between ZDPA erasure obligations and evidence permanence
guarantees. Any signed payload schema design that includes raw PII is
constitutionally non-compliant regardless of its operational convenience.

**ADM-ZM-004-3. Methodological Evidence under ZDPA:**
Records in `interpretation_packs` and `policy_versions` that reference individual
data subjects must be designed to allow PII erasure from the reference fields
without destroying the methodological evidence value of the record. The
methodological evidence function — proving which interpretation framework governed
a decision — is satisfied by non-PII policy and interpretation identifiers, not
by personal data fields.

### 5.3 Replay Obligations

**REP-ZM-004-1.** ZDPA creates no replay obligation on erased PII data. After
lawful erasure, Symphony is not obligated to retain or replay erased PII.

**REP-ZM-004-2.** ZDPA does not diminish Symphony's replay obligations with
respect to non-PII evidence. The erasure of PII from a record does not relieve
Symphony of its obligation to maintain the non-PII evidentiary fields of that
record in replayable form for the applicable transaction record retention period.
PII erasure and evidentiary permanence operate in distinct constitutional domains
within the same record.

### 5.4 Sovereignty Boundaries

**SOV-ZM-004-1.** The ZDPA exercises regulatory sovereignty over personal
information of natural persons within Zambia. Its authority over Symphony's
records extends only to records containing personal information as defined under
the Act.

**SOV-ZM-004-2.** The ZDPA does not exercise sovereignty over the non-PII
evidentiary content of Symphony's records. The `decision_hash`, `signature`,
`transition_hash`, `execution_id`, and `policy_decision_id` fields are not personal
information and are not subject to ZDPA erasure obligations. They remain under
Symphony's constitutional permanence guarantees.

**SOV-ZM-004-3.** Where an erasure request under the ZDPA appears to conflict with
Symphony's evidentiary permanence guarantees, the conflict is resolved through
the architectural PII decoupling mechanism, not through a doctrinal override
of either the ZDPA or Symphony's permanence guarantees. Both continue to apply
within their respective domains.

### 5.5 Evidence Survivability

**EVS-ZM-004-1.** Methodological and operational evidence records must survive
ZDPA erasure events with their non-PII content intact and their provenance chains
unbroken. Post-erasure records are constitutionally admissible for non-PII
evidentiary purposes. The fact of erasure must itself be recorded as a
constitutional fact in the evidence corpus.

---

## Part VI: REG-ZM-005 — ZEMA Authority Model

### 6.1 Constitutional Description

The Zambia Environmental Management Agency (ZEMA) exercises statutory authority
over environmental impact assessment, environmental compliance, and the
authorization of activities with significant environmental effects in the Republic
of Zambia under the Environmental Management Act.

For green finance instruments and carbon-related projects operating within Zambia,
ZEMA's authority model constitutes a mandatory sovereign authorization layer
that precedes and conditions the issuance of any green finance designation,
carbon credit, or environmental compliance certificate.

Symphony's relationship to ZEMA is that of an evidentiary substrate for ZEMA-
authorized activities. A Symphony project record is constitutionally authorized
to produce ZGFT-aligned green finance evidence only if the underlying activity
has received the requisite ZEMA authorization. The absence of ZEMA authorization
does not merely reduce the admissibility of Symphony evidence — it renders any
green finance claim on that project unconstitutionally founded.

### 6.2 Admissibility Implications

**ADM-ZM-005-1. ZEMA Authorization as Admissibility Precondition:**
Evidence produced from any Symphony green finance surface (`gf_projects`,
`asset_batches`, `gf_monitoring_records`) for a project that has not received
applicable ZEMA authorization is constitutionally inadmissible before any Zambian
regulatory authority for the purpose of establishing environmental compliance or
green finance designation. ZEMA authorization is not one factor among many —
it is a precondition to constitutional green finance admissibility.

**ADM-ZM-005-2. ZEMA Authorization Evidence Binding:**
Where a project has received ZEMA authorization, that authorization must be
recorded as Methodological Evidence (§4.6 of EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md)
in Symphony — specifically as a record in `gf_methodology_versions` or an
equivalent methodological substrate that binds the ZEMA authorization reference
to the project record. Evidence of ZEMA authorization must be part of the provenance
chain for all green finance claims arising from the project.

**ADM-ZM-005-3. ZEMA Scope and Taxonomy Alignment:**
ZEMA authorization establishes environmental permissibility. It does not by itself
establish ZGFT taxonomy alignment. Both ZEMA authorization (REG-ZM-005) and ZGFT
taxonomy alignment (REG-ZM-002) are independently required for a complete Zambian
green finance claim. Evidence satisfying REG-ZM-005 does not satisfy REG-ZM-002,
and vice versa.

### 6.3 Replay Obligations

**REP-ZM-005-1.** ZEMA authorization evidence must be retained in replayable form
for the full lifecycle of the authorized project and any applicable post-project
period. At any point during this period, an auditor must be able to trace from
a green finance claim back to the ZEMA authorization that conditioned it.

### 6.4 Sovereignty Boundaries

**SOV-ZM-005-1.** ZEMA exercises sovereign authority over environmental
authorization within Zambia. Its authority does not extend to the international
carbon registries (Verra, Gold Standard), to Paris Agreement compliance mechanisms,
or to EU CBAM determinations. A ZEMA authorization does not constitute a Verra
validation or a Paris Article 6 corresponding adjustment.

**SOV-ZM-005-2.** ZEMA's sovereignty over Symphony's green finance surfaces is
limited to the authorization layer. ZEMA does not govern Symphony's cryptographic
architecture, evidence structure, wave sovereignty model, or constitutional
document hierarchy.

### 6.5 Evidence Survivability

**EVS-ZM-005-1.** ZEMA authorization records must survive as part of the green
finance evidence chain for the duration applicable under Zambian environmental law.
They must be independently verifiable from archived records without dependency on
ZEMA's own registry remaining accessible.

---

## Part VII: REG-INT-001 — Paris Agreement Article 6

### 7.1 Constitutional Description

Paris Agreement Article 6 establishes the international framework for cooperative
climate action between Parties, including the mechanisms for internationally
transferred mitigation outcomes (ITMOs), the requirements for corresponding
adjustments, and the authorization procedures by which a host country approves
the use of mitigation outcomes for international purposes.

Article 6.2 governs bilateral cooperative approaches. Article 6.4 establishes
the UNFCCC Supervisory Body mechanism. The Paris Agreement Rulebook (CMA decisions)
establishes the technical requirements for Article 6 reporting, accounting, and
corresponding adjustments.

Symphony's relationship to Paris Article 6 is that of a trust coordination
substrate for mitigation outcome provenance. When Symphony records are used to
establish the provenance, authorization, and accounting of ITMOs, those records
must satisfy Article 6 requirements as a constitutional matter — not merely as a
reporting obligation.

### 7.2 Admissibility Implications

**ADM-INT-001-1. ITMO Authorization Provenance:**
An internationally transferred mitigation outcome that is traceable to Symphony's
evidentiary substrate must carry evidence of its authorization by the host Party
(Zambia, in the primary use case). This authorization must be recorded as
Methodological Evidence in Symphony's `policy_decisions` surface, with a
`decision_hash` binding that cryptographically commits to the authorization
parameters. A mitigation outcome lacking this authorization evidence is
constitutionally inadmissible before Article 6 accounting mechanisms.

**ADM-INT-001-2. Corresponding Adjustment Admissibility:**
Article 6.2 requires that the host country make a corresponding adjustment to its
own NDC accounting when it authorizes an ITMO transfer. Symphony evidence for
a corresponding adjustment must establish: (a) the original mitigation outcome
record, (b) the authorization event, (c) the accounting adjustment event, and
(d) the causal chain connecting them. All four elements must be traceable from
Symphony's evidentiary surfaces without reliance on external runtime assertions.

**ADM-INT-001-3. Article 6.4 Activity Registration:**
For activities seeking registration under the Article 6.4 mechanism, the
UNFCCC Supervisory Body requires evidence that the activity meets the approved
methodology requirements. Symphony's `gf_methodology_versions` and
`interpretation_packs` surfaces constitute the methodological evidence layer for
this requirement. The temporal binding of execution records to interpretation
versions (GF058 trigger) ensures that methodology evidence is tied to the
specific version operative at the time of each monitoring event.

**ADM-INT-001-4. Double-Counting Prevention:**
Article 6 rules prohibit the double-counting of mitigation outcomes. Symphony's
UNIQUE constraints and append-only architecture at the `asset_batches` level
provide structural double-counting prevention at the database layer. Evidence of
double-counting prevention must be demonstrable from Symphony's structural
constraints, not merely from runtime assertions.

### 7.3 Replay Obligations

**REP-INT-001-1.** The UNFCCC Article 6 reporting cycle requires that mitigation
outcome records be verifiable against each successive reporting period. Symphony
must maintain ITMO provenance evidence in replayable form across all national
communication cycles and global stocktake periods, which may extend for decades.
The replay obligations under Paris Article 6 are among the longest-duration
obligations in Symphony's constitutional architecture.

**REP-INT-001-2.** The admissibility-at-time-of-execution rule (§5.1 of
EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md) is directly applicable:
mitigation outcomes assessed against a methodology version that has since been
superseded remain admissible under Article 6 accounting under the methodology
version operative at their assessment time. Methodology supersession is
forward-only.

### 7.4 Sovereignty Boundaries

**SOV-INT-001-1.** Paris Agreement Article 6 sovereignty operates at the level of
UNFCCC Parties (nation-states). The UNFCCC does not exercise jurisdiction over
Symphony's internal architecture. The Article 6 framework governs the accounting
and transfer of mitigation outcomes; it does not govern Symphony's trust model,
wave sovereignty, or evidence hierarchy.

**SOV-INT-001-2.** Article 6 sovereignty is orthogonal to Zambian domestic
regulatory sovereignty (REG-ZM-001 through REG-ZM-005). Satisfying Article 6
requirements does not establish satisfaction of Zambian domestic regulatory
requirements, and vice versa. Both are required for internationally transferred
mitigation outcomes originating from Zambia.

**SOV-INT-001-3.** Article 6 rights of review held by the UNFCCC Supervisory Body
apply to the activity and its accounting. They do not authorize the Supervisory
Body to modify, delete, or direct the modification of Symphony's evidentiary
records. Symphony's response to any such direction is governed by
CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.

### 7.5 Evidence Survivability

**EVS-INT-001-1.** Article 6 mitigation outcome evidence must survive across
complete NDC cycles, global stocktake periods, and indefinitely in the case of
outcomes that contribute to long-term accounting baselines. The evidence
survivability minimum for Article 6 is not less than the longest applicable
national communication cycle plus the operative crediting period of the originating
project.

**EVS-INT-001-2.** Key rotation events must not compromise the verifiability of
historical ITMO provenance records. The archive key store obligation (§4.4 of
EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md) must be maintained for the full
Article 6 retention period, which may substantially exceed the 7-year default.

---

## Part VIII: REG-INT-002 — Verra Verified Carbon Standard (VCS)

### 8.1 Constitutional Description

The Verra Verified Carbon Standard (VCS), administered by Verra, constitutes the
dominant international private carbon crediting standard. VCS establishes approved
methodologies, monitoring requirements, validation and verification body (VVB)
requirements, and registry procedures for the issuance of Verified Carbon Units
(VCUs).

Symphony's relationship to the VCS is that of a monitoring data and provenance
substrate for VCS-eligible projects. Symphony's `gf_monitoring_records`,
`gf_projects`, `gf_methodology_versions`, and `asset_batches` surfaces produce
the monitoring and methodological evidence that VVBs require to validate and verify
emission reductions.

### 8.2 Admissibility Implications

**ADM-INT-002-1. Methodology Conformance Evidence:**
VCS requires that all monitoring be conducted in accordance with an approved
Verra methodology. Symphony's `gf_methodology_versions` surface must record,
for each monitoring event, which Verra-approved methodology version governed that
event. The temporal binding trigger (GF058) ensures that the methodology version
referenced by an execution record was the version active at the time of the
monitoring event. This temporal binding is the constitutional mechanism by which
methodology conformance is established.

**ADM-INT-002-2. Validation and Verification Body (VVB) Independence:**
VCS requires independent third-party validation and verification. A VVB
constitutes an external verifier within the meaning of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md.
Symphony must provide VVBs with the means to independently reconstruct and verify
monitoring records without access to Symphony's operational runtime. This is the
external verifier independence obligation applied to the Verra domain.

**ADM-INT-002-3. Monitoring Report Completeness:**
VCS monitoring reports must be traceable to their underlying monitoring data.
In Symphony, monitoring report admissibility requires that the complete chain
from `gf_monitoring_records` through `gf_evidence_lineage` to `asset_batches`
be traversable from persisted records. A monitoring report that relies on runtime
interpolation of missing monitoring records is constitutionally inadmissible
as a VCS monitoring report.

**ADM-INT-002-4. Additionality and Baseline Evidence:**
VCS requires evidence that emission reductions are additional — that they would
not have occurred in the absence of the project. This additionality claim must be
supported by baseline methodology evidence retained in `gf_methodology_versions`.
The baseline methodology version is not superseded by subsequent monitoring
methodology updates; it is retained as historical Methodological Evidence per
the replay-safe supersession rule.

### 8.3 Replay Obligations

**REP-INT-002-1.** Verra's registry maintains VCU issuance records and may require
re-verification of underlying monitoring data. Symphony must maintain monitoring
evidence in replayable form for the duration of any VCS crediting period plus
any applicable post-crediting verification period.

**REP-INT-002-2.** VVB verification of historical monitoring events must be
possible without requiring the VVB to access Symphony's operational runtime.
The offline verification procedure defined in §5 of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
constitutes the canonical procedure for VVB independent verification of Symphony
monitoring evidence.

### 8.4 Sovereignty Boundaries

**SOV-INT-002-1.** Verra's authority under the VCS is that of a standard-setting
and registry-operating private body. It exercises no governmental regulatory
authority. Its domain over Symphony's surfaces extends to VCS-eligible project
monitoring records only.

**SOV-INT-002-2.** Verra's VCS is constitutionally orthogonal to Paris Agreement
Article 6 (REG-INT-001), Gold Standard (REG-INT-003), and Zambian domestic
regulatory requirements (REG-ZM-001 through REG-ZM-005). A VCS verification does
not constitute Article 6 authorization. A ZGFT alignment does not constitute VCS
validation. These standards coexist within Symphony's evidence architecture
without merger or mutual confirmation.

**SOV-INT-002-3.** Verra registry instructions to modify, correct, or invalidate
VCUs do not authorize the modification of Symphony's underlying monitoring records.
Registry-level actions affect VCU status within Verra's registry; they do not
constitute authority to alter Symphony's append-only evidentiary substrate.

### 8.5 Evidence Survivability

**EVS-INT-002-1.** VCS monitoring evidence must survive the full VCU crediting
period plus any applicable post-crediting verification requirement. For long-term
permanence projects (e.g., afforestation, reforestation, revegetation), this may
extend across multiple decades.

---

## Part IX: REG-INT-003 — Gold Standard for Global Goals (GS4GG)

### 9.1 Constitutional Description

The Gold Standard for Global Goals (GS4GG), administered by the Gold Standard
Foundation, constitutes an international certification standard for climate and
sustainable development interventions. GS4GG distinguishes itself from VCS through
its emphasis on co-benefits — sustainable development outcomes beyond emission
reductions — and its requirements for community and stakeholder engagement evidence.

Symphony's relationship to GS4GG is that of a monitoring and co-benefit evidence
substrate. In addition to the emission reduction evidence applicable to VCS,
GS4GG requires evidence of sustainable development impacts, stakeholder engagement
processes, and safeguarding compliance.

### 9.2 Admissibility Implications

**ADM-INT-003-1. Safeguard Compliance Evidence:**
GS4GG's safeguarding requirements mandate evidence that projects have not caused
harm to communities, biodiversity, or cultural heritage. In Symphony, safeguarding
compliance evidence must be recorded as Attestation Evidence (§4.7 of
EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md), verifiable through
Symphony's invariant enforcement surfaces. A GS4GG claim that lacks safeguarding
attestation evidence is constitutionally inadmissible before Gold Standard
certification authorities.

**ADM-INT-003-2. Sustainable Development Goal (SDG) Impact Evidence:**
GS4GG requires evidence of contributions to specific UN Sustainable Development
Goals. This evidence must be traceable from Symphony's monitoring surfaces to
the specific SDG impact indicators relevant to the project type. The methodology
version binding (GF058 trigger) ensures that SDG impact measurement is tied to
the methodology operative at each monitoring event.

**ADM-INT-003-3. Stakeholder Consultation Evidence:**
GS4GG requires documentation of stakeholder consultation processes. This
documentation constitutes Methodological Evidence in Symphony's architecture —
specifically, evidence of the governance process that authorized the project's
implementation approach.

### 9.3 Replay Obligations

**REP-INT-003-1.** GS4GG certification review may require access to historical
monitoring and co-benefit evidence. Symphony must maintain GS4GG-relevant
evidence in replayable form for the duration of the GS4GG label issuance period
plus any applicable post-issuance verification period.

### 9.4 Sovereignty Boundaries

**SOV-INT-003-1.** Gold Standard Foundation's authority is that of a private
certification standard body. Its domain over Symphony's surfaces extends to
GS4GG-certified project records only. It does not exercise governmental regulatory
authority and does not override Zambian domestic regulatory sovereignty.

**SOV-INT-003-2.** GS4GG is constitutionally orthogonal to VCS (REG-INT-002),
Paris Article 6 (REG-INT-001), ZGFT (REG-ZM-002), and ZEMA (REG-ZM-005).
Projects may simultaneously seek GS4GG and VCS certification; each certification
pathway makes independent evidentiary demands on Symphony.

### 9.5 Evidence Survivability

**EVS-INT-003-1.** GS4GG label evidence must survive for the duration of the label
issuance period. Co-benefit evidence, stakeholder consultation records, and
safeguarding attestation records must remain retrievable and verifiable throughout
this period from archived records without dependency on Symphony's operational
runtime.

---

## Part X: REG-INT-004 — EU Carbon Border Adjustment Mechanism (CBAM)

### 10.1 Constitutional Description

The EU Carbon Border Adjustment Mechanism (CBAM), established by EU Regulation
2023/956, applies a carbon price to imports of specified goods into the European
Union where those goods are produced in countries without equivalent carbon pricing.
For goods originating from Zambia that are subject to CBAM, the embedded carbon
content must be declared and, where applicable, documented.

Symphony's relationship to EU CBAM is that of an embedded carbon content evidence
substrate. Where Symphony's green finance records document the carbon accounting
of production processes for CBAM-covered goods, those records constitute the
evidentiary foundation for CBAM declarations.

### 10.2 Admissibility Implications

**ADM-INT-004-1. Embedded Carbon Content Evidence:**
CBAM requires that embedded carbon content declarations be supported by evidence
of actual measurement or calculation in accordance with CBAM Regulation Annex IV
methodologies. In Symphony, embedded carbon evidence must be traceable through
`gf_monitoring_records` to the specific monitoring events that established the
carbon content measurement. A declaration based on default values that are
overridable by actual monitoring records must indicate that Symphony's monitoring
evidence has been used or not used, and why.

**ADM-INT-004-2. EU Declarant Access to Evidence:**
EU importers acting as CBAM declarants may require access to the underlying
monitoring evidence that supports embedded carbon content declarations. Symphony
must provide these declarants with evidence that satisfies the external verifier
independence requirement — specifically, the offline verification procedure of
§5 of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md. A declarant who cannot
independently verify the monitoring records underlying a carbon content claim
cannot constitutionally rely on that claim for CBAM purposes.

**ADM-INT-004-3. Temporal Scope of CBAM Evidence:**
CBAM declarations are made per calendar year. Evidence supporting each annual
declaration must cover the complete production year. Symphony's monitoring records
must be temporally complete for each CBAM-relevant production period, with no
gaps in monitoring coverage that would require default value substitution.

**ADM-INT-004-4. Verifier Accreditation Boundary:**
CBAM requires that embedded carbon content be verified by accredited verifiers
under EU Regulation 2018/2067 (for EU ETS) or equivalent. These accredited
verifiers constitute external verifiers within the meaning of EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md.
Symphony must enable these accredited verifiers to independently verify monitoring
evidence without access to Symphony's operational runtime.

### 10.3 Replay Obligations

**REP-INT-004-1.** CBAM declarations are subject to EU audit and review. Symphony
must maintain the monitoring evidence underlying CBAM declarations for the full
EU CBAM record retention period applicable under Regulation 2023/956 and
implementing regulations. This period is likely to extend beyond the 7-year
default in AUDIT_LOGGING_RETENTION_POLICY.md and, where it does, the EU
regulatory period governs.

**REP-INT-004-2.** The admissibility-at-time-of-execution rule applies to CBAM
evidence: monitoring records produced under a methodology version operative at
the time of monitoring remain admissible for CBAM purposes even if that
methodology version has since been superseded.

### 10.4 Sovereignty Boundaries

**SOV-INT-004-1.** EU CBAM exercises sovereignty over the import of covered goods
into the European Union. Its jurisdiction over Symphony's records extends to
records that establish the embedded carbon content of CBAM-covered goods produced
in Zambia. It does not extend to Symphony's domestic Zambian payment operations,
ZGFT taxonomy alignment, or general green finance evidence surfaces that are
unrelated to EU import declarations.

**SOV-INT-004-2.** EU CBAM is constitutionally orthogonal to Paris Agreement
Article 6 (REG-INT-001), Verra VCS (REG-INT-002), Gold Standard GS4GG
(REG-INT-003), and Zambian domestic regulatory requirements. Satisfying CBAM
requirements for embedded carbon documentation does not constitute satisfaction
of any other regulatory requirement, and vice versa.

**SOV-INT-004-3.** EU regulatory instructions directed at Symphony as a Zambian-
based entity do not override Zambian domestic regulatory sovereignty. Where EU
CBAM requirements and Zambian domestic regulatory requirements impose conflicting
obligations on Symphony evidence surfaces, the conflict must be resolved at the
diplomatic and legal level; Symphony's constitutional architecture does not
resolve cross-jurisdictional sovereignty conflicts by subordinating one jurisdiction
to the other.

### 10.5 Evidence Survivability

**EVS-INT-004-1.** CBAM evidence must survive the full EU regulatory retention
period, which includes both the CBAM reporting year and any subsequent audit or
dispute resolution period. Evidence artifacts must remain independently verifiable
by EU-accredited verifiers throughout this period.

---

## Part XI: Regulator Coexistence Rules

### 11.1 The Orthogonality Principle

All regulatory domains defined in this document are constitutionally orthogonal.
This orthogonality is not a formal convenience; it is a constitutional requirement
arising from the nature of regulatory sovereignty. Regulatory bodies are sovereign
within their own domains. No regulatory body is sovereign within another's domain.
No regulatory body's requirements, determinations, or instructions constitute
authority within another regulatory body's domain.

Orthogonality has the following operational consequences for Symphony:

**COE-1. Non-transitive admissibility.** Evidence that is admissible before
one regulatory domain is not thereby admissible before any other. Admissibility
determinations are domain-specific. ZGFT alignment does not establish VCS
validation. Paris Article 6 authorization does not establish ZEMA compliance.
BoZ audit admissibility does not establish CBAM evidence sufficiency.

**COE-2. Non-transitive satisfaction.** Satisfying the evidentiary requirements
of one regulatory domain does not satisfy the evidentiary requirements of any
other. Each domain's requirements must be independently satisfied from Symphony's
evidence surfaces.

**COE-3. Additive coexistence.** A single Symphony project may simultaneously
produce evidence for multiple regulatory domains. These simultaneous productions
are additive: Symphony's evidence surfaces serve multiple domains at once.
Additive coexistence does not imply merger, mutual validation, or cross-domain
admissibility transfer.

**COE-4. Independent replay paths.** Each regulatory domain must be able to
independently replay and verify its domain-relevant evidence from Symphony's
evidentiary substrate without access to evidence from other domains. The replay
paths for REG-ZM-001 (SI 5 of 2026) and REG-INT-001 (Paris Article 6) are
constitutionally separate.

### 11.2 Priority Ordering in Cross-Domain Conflicts

Where satisfying one regulatory domain's requirements appears to conflict with
satisfying another domain's requirements, the conflict must be resolved as follows:

**First:** Determine whether the conflict is genuine or apparent. Most apparent
conflicts arise from different evidence class requirements for the same underlying
event, which Symphony's multiple evidence class architecture can satisfy
simultaneously.

**Second:** Where the conflict is genuine and involves data retention obligations,
the longer retention period governs — Symphony must retain evidence for the
maximum period required by any applicable domain.

**Third:** Where the conflict is genuine and involves evidence modification
requirements (e.g., one domain requiring correction of a record that another
domain's append-only constraints prohibit), the conflict is resolved in favor
of append-only permanence. Correction is achieved through a new, separately
documented record that supersedes the prior record prospectively, not through
mutation of the prior record.

**Fourth:** Where the conflict cannot be resolved by the above rules, it is
escalated per CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.

### 11.3 Domain-Specific External Verifier Partitioning

Each regulatory domain's external verifier must be able to operate independently.
A BoZ examiner performing audit under REG-ZM-003 must not require access to CBAM
evidence under REG-INT-004. An Article 6 review team must not require access to
SI 5 of 2026 payment settlement records.

Symphony's evidence architecture must structurally support this partitioning:
Green Finance and payment settlement evidence surfaces must remain independently
accessible and independently verifiable without requiring access to each other's
domain.

---

## Part XII: Phase Interaction Rules

### 12.1 Phase-Boundary Regulatory Admissibility

The phase-admissibility classification of Symphony evidence (§5.2 of
EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md) interacts with regulatory
domain requirements as follows:

**PH-REG-1. Phase-1 indicative evidence.** Evidence carrying `data_authority = 'phase1_indicative_only'`
satisfies none of the regulatory domains defined in this document as a basis
for claims of cryptographic attribution. It is admissible within those domains
only as an indicator that an event was recorded — not as proof of authorized
execution. Regulators must be informed of this limitation when such evidence is
presented.

**PH-REG-2. Wave 8 attestation evidence.** Evidence produced through the Wave 8
attestation path (asset batches with valid `invariant_attestation_hash`,
`registry_snapshot_hash`, and Wave 8 cryptographic enforcement) satisfies the
attestation evidence requirements of REG-ZM-002, REG-ZM-005, REG-INT-001,
REG-INT-002, REG-INT-003, and REG-INT-004 as the primary cryptographic admissibility
basis.

**PH-REG-3. Phase transitions do not revoke regulatory admissibility.** Evidence
produced in Phase 1 that satisfied the regulatory admissibility conditions
operative in Phase 1 retains its regulatory admissibility in subsequent phases.
Phase transitions are forward-only; they do not retroactively alter the regulatory
admissibility of prior-phase evidence.

**PH-REG-4. Regulatory obligations activate with the evidence path.** Regulatory
obligations under this document become active for a given evidence class at the
moment that class's evidence path becomes constitutionally operative in Symphony.
Pre-activation records produced on paths that were not yet constitutionally
operative are assessed against the constitutional state operative at their
production time.

---

## Admissibility Implications Summary

| Regulatory Domain | Primary Evidence Classes | Wave 4 Required | Wave 8 Required | Append-Only Required | External Verifier Access Required |
|---|---|---|---|---|---|
| REG-ZM-001 (SI 5/2026) | Operational, Settlement | YES | YES (authoritative_signed) | YES | YES |
| REG-ZM-002 (ZGFT) | Regulator (GF), Attestation, Methodological | YES | YES | YES | YES |
| REG-ZM-003 (BoZ) | Operational, Provenance, Settlement, Methodological | YES | YES | YES | YES (archive survivability) |
| REG-ZM-004 (ZDPA) | Methodological, Retention | YES | Conditional | YES (PII decoupled) | Partial (non-PII only) |
| REG-ZM-005 (ZEMA) | Attestation, Methodological | YES | YES | YES | YES |
| REG-INT-001 (Paris Art.6) | Attestation, Methodological, Regulator (GF) | YES | YES | YES | YES (VVB independence) |
| REG-INT-002 (Verra VCS) | Methodological, Attestation, Regulator (GF) | YES | YES | YES | YES (VVB independence) |
| REG-INT-003 (Gold Standard) | Attestation, Methodological | YES | YES | YES | YES |
| REG-INT-004 (EU CBAM) | Regulator (GF), Retention, Methodological | YES | YES | YES | YES (accredited verifier) |

---

## Replay Obligations Summary

| Regulatory Domain | Minimum Replay Period | Key Archive Required | Methodology Version Retention | Notes |
|---|---|---|---|---|
| REG-ZM-001 | Zambian statutory payment record period | YES | N/A | Statutory period governs if > 7 years |
| REG-ZM-002 | Project lifecycle + post-project crediting period | YES | YES | Methodology version operative at assessment |
| REG-ZM-003 | Zambian statutory period + BoZ examination window | YES | YES | Archive survivability through runtime loss |
| REG-ZM-004 | Non-PII fields: transaction record period | N/A for PII | N/A | PII erased; non-PII permanent |
| REG-ZM-005 | Project authorization lifecycle | YES | YES | ZEMA authorization binding |
| REG-INT-001 | NDC cycle + crediting period (potentially decades) | YES | YES | Longest-duration obligation |
| REG-INT-002 | VCS crediting period + post-crediting period | YES | YES | Decades for permanence projects |
| REG-INT-003 | GS4GG label issuance period | YES | YES | Co-benefit evidence included |
| REG-INT-004 | EU CBAM regulatory retention period | YES | YES | May exceed 7-year default |

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the constitutional mapping between Symphony's sovereign
trust coordination substrate and each named regulatory domain:
REG-ZM-001 (SI 5/2026), REG-ZM-002 (ZGFT), REG-ZM-003 (Bank of Zambia),
REG-ZM-004 (ZDPA), REG-ZM-005 (ZEMA), REG-INT-001 (Paris Article 6),
REG-INT-002 (Verra VCS), REG-INT-003 (Gold Standard), REG-INT-004 (EU CBAM).
It governs the admissibility conditions, replay obligations, evidence survivability
requirements, and sovereignty boundaries applicable to each domain.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine: Wave 4 operational sovereignty (governed by
CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md); Wave 8 provenance/cryptographic
sovereignty (same); Root Constitutional Doctrine (CONSTITUTIONAL_AUTHORITY_HIERARCHY.md);
Phase Constitutional Doctrine; the authority hierarchy or conflict resolution
procedures (CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md); the evidence
permanence guarantees EPG-1 through EPG-7 (EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md);
the replay primacy doctrine (REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md); or the
external verifier independence guarantees VIG-1 through VIG-7
(EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md).

**Replay obligations preserved by this document:**
This document preserves and specifies the replay obligations applicable to each
regulatory domain. It explicitly extends replay obligations beyond the 7-year
default for domains requiring longer retention (Article 6, VCS, Gold Standard,
EU CBAM). It preserves the admissibility-at-time-of-execution rule for all
domains, ensuring that methodology supersession does not retroactively invalidate
historical regulatory evidence. It preserves the external verifier independence
obligation for all domains, requiring that regulators and accredited verifiers
can independently replay evidence without Symphony's operational runtime.

**Regulator boundaries constraining this document:**
Each regulatory domain defined herein constrains this document within its own
scope. This document must not grant any regulatory domain authority beyond its
constitutionally recognized scope. The orthogonality principle (§11.1) constrains
this document from merging, subordinating, or equivalencing any two regulatory
domains.

**Phases this document applies to:**
GLOBAL, with phase-interaction rules defined in Part XII. Phase-1 indicative
evidence limitations apply across all regulatory domains. Wave 8 attestation
requirements apply from the moment the Wave 8 attestation path is constitutionally
operative for the relevant evidence class.

**Constitutional layers possessing override authority over this document:**
- Root Constitutional Doctrine (Authority-Rank 10) overrides this document in all
  respects.
- Wave Sovereignty Doctrine (Authority-Rank 9) overrides this document within
  wave sovereignty scope.
- Phase Constitutional Doctrine (Authority-Rank 8) overrides this document within
  phase capability scope.
No regulatory domain, enforcement surface, migration record, or AI synthesis
possesses override authority over this document.

**Lower-layer documents prohibited from reinterpretation:**
The following lower-layer documents are prohibited from reinterpreting the
regulatory domain mappings, admissibility conditions, replay obligations,
sovereignty boundaries, or regulator coexistence rules defined herein:
- All migration records (Rank 5) for migrations 0001 through the current tip.
- All CI gate definitions (Rank 4).
- All operational enforcement artifacts (Rank 3): triggers, SECURITY DEFINER
  functions, RLS policies.
- All declarative substrate (Rank 2): dormant tables, unwired enforcement surfaces.
- All repository observations (Rank 1): audit reports, inspection summaries.
- All AI syntheses (Rank 0): NotebookLM outputs, agent analyses.
In particular: no migration, trigger, or operational artifact may reinterpret any
regulatory domain boundary to expand or contract that domain's reach over Symphony's
evidence surfaces beyond what this document defines.

---

## Prohibited Misinterpretations

**PM-01 — Regulatory Equivalence Collapse (PROHIBITED):**
It is prohibited to treat any two regulatory domains defined in this document as
equivalent, interchangeable, or mutually confirming. ZGFT alignment is not VCS
validation. Paris Article 6 authorization is not ZEMA compliance. BoZ audit
admissibility is not CBAM evidence sufficiency. Each domain is constitutionally
distinct with independent admissibility standards.

**PM-02 — Generic Compliance Semantics (PROHIBITED):**
It is prohibited to flatten the regulatory domains defined in this document into
generic compliance semantics — treating them collectively as "regulatory
requirements" that can be satisfied by a unified compliance posture. Each domain
imposes its own evidence class requirements, retention obligations, external
verifier access requirements, and replay specifications. Generic compliance postures
do not satisfy specific regulatory admissibility standards.

**PM-03 — Cross-Domain Admissibility Transfer (PROHIBITED):**
It is prohibited to present evidence admitted in one regulatory domain as
constituting admissible evidence in a different domain. Green Finance attestation
evidence that satisfies REG-ZM-002 (ZGFT) does not satisfy REG-INT-004 (EU CBAM)
by virtue of its ZGFT admission. Each domain requires independent evidence
satisfying its own standards.

**PM-04 — Regulatory Instruction as Override Authority (PROHIBITED):**
It is prohibited to treat instructions from any regulatory body as constituting
override authority over Symphony's constitutional architecture. A regulatory
instruction to modify, delete, or correct a record does not override Symphony's
append-only permanence guarantees or the authority hierarchy. Such instructions
must be processed through constitutional amendment procedures.

**PM-05 — Phase-1 Evidence as Regulatory Compliance Evidence (PROHIBITED):**
It is prohibited to present evidence carrying `data_authority = 'phase1_indicative_only'`
as satisfying the cryptographic attribution requirements of any regulatory domain
defined in this document. Phase-1 indicative evidence is admissible within
regulatory domains only as an indicator record, not as an attribution record.

**PM-06 — Runtime Availability as Regulatory Access Mechanism (PROHIBITED):**
It is prohibited to design or represent Symphony's regulatory evidence access
mechanism as dependent on Symphony's operational runtime availability. Each
regulatory domain requires the ability to independently access and verify evidence
from archived records. A regulatory access design that requires Symphony to be
operationally available for evidence access is constitutionally non-compliant.

**PM-07 — Domestic Sovereignty Subordination (PROHIBITED):**
It is prohibited to treat Zambian domestic regulatory sovereignty (REG-ZM-001
through REG-ZM-005) as subordinate to international regulatory frameworks
(REG-INT-001 through REG-INT-004). The regulatory domains defined in this
document are constitutionally orthogonal. International frameworks do not override
Zambian domestic regulatory requirements, and vice versa.

**PM-08 — Replay-Destructive Regulatory Accommodation (PROHIBITED):**
It is prohibited to accommodate any regulatory domain's requirements by deleting,
modifying, or compacting Symphony's replay-obligated evidentiary records. Where
regulatory accommodation appears to require such actions, the conflict is an
impossible compromise scenario governed by CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.
Replay survivability is Priority 1 and yields to no regulatory accommodation.

**PM-09 — PII Erasure as Evidence Destruction (PROHIBITED):**
It is prohibited to interpret ZDPA PII erasure obligations (REG-ZM-004) as
authorizing the destruction of the non-PII evidentiary content of any Symphony
record. PII erasure is domain-specific and architecturally confined to PII fields.
It does not authorize the deletion of the evidentiary record or the provenance
chain of which the record is a part.

**PM-10 — Single-Jurisdiction Evidence Architecture (PROHIBITED):**
It is prohibited to design Symphony's evidence surfaces under the assumption that
evidence will be presented to only one regulatory domain. The simultaneous
operation of multiple regulatory domains (§11.1, Regulator Coexistence Rules)
is a constitutional requirement. Evidence surfaces must be designed to serve all
applicable domains independently and simultaneously.

**PM-11 — CBAM as EU Territorial Jurisdiction over Zambian Architecture (PROHIBITED):**
It is prohibited to interpret EU CBAM's evidentiary requirements as granting the
European Union territorial jurisdiction over Symphony's constitutional architecture,
its wave sovereignty model, or its domestic Zambian regulatory relationships.
CBAM exercises jurisdiction over EU importers and the embedded carbon content of
covered goods. It does not exercise jurisdiction over Symphony's internal
constitutional structure.

**PM-12 — Active Phase as Retroactive Regulator (PROHIBITED):**
It is prohibited to treat the regulatory obligations of the current constitutional
phase as retroactively applicable to evidence produced in prior phases.
Regulatory admissibility of historical evidence is determined by the constitutional
state operative at the time of evidence production, not by the regulatory
requirements of the current phase.
