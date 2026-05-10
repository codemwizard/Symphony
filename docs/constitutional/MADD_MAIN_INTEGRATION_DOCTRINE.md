# MADD_MAIN_INTEGRATION_DOCTRINE.md

---

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 8
**Phase-Scope:** GLOBAL
**Supersedes:** Any operational integration specification, API contract, data exchange agreement, or workflow configuration document that purports to define the constitutional relationship between Symphony and MGEE, MADD, MAIN, or ZEMA without explicit constitutional grounding.
**Depends-On:**
- `docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md`
- `docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md`
- `docs/constitutional/CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md`
- `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`
- `docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md`
- `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`
- `docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md`
- `docs/constitutional/REGULATORY_ALIGNMENT_CONSTITUTION.md`
- `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`
- `DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md`
- `CARBON_ASSET_LIFECYCLE_CONSTITUTION.md`

---

## 1. Purpose

This document establishes the constitutional integration doctrine governing the relationship between Symphony and the MGEE (Monitoring, Governance, Evaluation, and Enforcement) system operating through its MADD (Measurement, Attestation, and Data Delivery) and MAIN (Methodology, Attestation, and Integration Network) process frameworks, together with the ZEMA (Zambia Environmental Management Agency) sovereign integration boundary.

Symphony is not a data consumer of MGEE processes. Symphony is not a downstream reporting endpoint for MADD outputs. Symphony is not a verification layer subordinate to MAIN determinations. Symphony is not a registry façade for ZEMA operational systems.

Symphony is:

- a **sovereign trust arbitration fabric** within which MGEE process outputs achieve their constitutional evidentiary standing;
- an **evidentiary coordination system** within which MADD-originated measurement records acquire provenance-bearing, regulator-admissible status;
- a **replay-survivable regulatory interoperability substrate** within which MAIN attestations become permanently replayable across all regulator sovereign domains;
- and a **constitutional integration boundary** with ZEMA — not a subordinate data pipe to ZEMA's operational registry.

This doctrine defines the constitutional authority each process and system exercises at the integration boundary, the evidence exchange legality rules governing cross-system data flows, the provenance continuity obligations that bind all exchanged artefacts, and the replay obligations that survive all integration events indefinitely.

---

## 2. Constitutional Scope

This doctrine governs:

1. The sovereignty boundaries between Symphony and the MGEE system.
2. The constitutional authority of the MADD process within Symphony's evidentiary fabric.
3. The constitutional authority of the MAIN process within Symphony's evidentiary fabric.
4. The ZEMA integration boundary and the sovereignty constraints applicable at that boundary.
5. The evidence exchange legality rules governing all data flows at the integration boundary.
6. The provenance continuity obligations that bind all artefacts traversing the integration boundary.
7. The replay continuity obligations binding all integration event records.
8. The admissibility continuity obligations applicable to MGEE-originated evidence across all downstream regulator sovereign domains.
9. The compositional validation requirements applicable at each integration event.
10. The external verifier independence obligations applicable to cross-system trust reconstruction.
11. The historical audit survivability guarantees extending beyond operational continuity of any integrated system.

This doctrine does NOT govern:

- The internal operational design of MGEE, MADD, or MAIN systems beyond their integration boundary behaviour.
- The substantive methodological standards applied within MADD measurement processes.
- The internal ZEMA registry architecture beyond its constitutional interface with Symphony.
- The specific wire format or transmission protocol for integration data flows.
- The identity of specific regulated entities, project operators, or counterparties.
- The legal interpretation of any applicable regulatory text beyond its constitutional mapping to the integration boundary.

---

## 3. Constitutional Definitions

### 3.1 MGEE

**MGEE** (Monitoring, Governance, Evaluation, and Enforcement) is the overarching framework within which Zambia's carbon MRV, green finance oversight, and regulatory compliance processes are organised. MGEE operates through the MADD and MAIN process frameworks. Within Symphony's constitutional architecture, MGEE is classified as an **external sovereign process authority**: its determinations carry regulatory standing derived from ZEMA's domestic sovereign mandate and, where applicable, from Article 6 treaty obligations.

MGEE is not a subsystem of Symphony. It is not operationally subordinate to Symphony. It is a sovereign process authority that exchanges evidentiary artefacts with Symphony at a constitutionally defined integration boundary.

### 3.2 MADD

**MADD** (Measurement, Attestation, and Data Delivery) is the MGEE process framework governing the collection, quality assurance, and formal delivery of measurement data from carbon project activities, green finance instruments, and regulated MRV obligations. MADD outputs constitute **candidate evidentiary artefacts** at the point of delivery to Symphony.

Candidate evidentiary artefacts become **constitutionally recognised evidentiary data** within Symphony upon satisfaction of the compositional validation requirements defined in Section 8 of this doctrine. Prior to compositional validation, MADD outputs are not constitutionally established evidentiary records within Symphony, regardless of their regulatory standing within the MGEE framework.

### 3.3 MAIN

**MAIN** (Methodology, Attestation, and Integration Network) is the MGEE process framework governing the application of approved methodologies to MRV data, the production of formal attestations, and the integration of certified outputs with registry and regulatory reporting systems. MAIN produces **methodology-attested records**: outputs that carry the certification authority of the applicable methodology standard applied by an accredited verification body.

Within Symphony's constitutional architecture, MAIN attestations constitute **provenance-bearing candidate artefacts** at the point of integration. They become **constitutionally anchored provenance records** within Symphony upon cryptographic anchoring and compositional validation as defined in Section 9 of this doctrine.

### 3.4 ZEMA Integration Boundary

The **ZEMA integration boundary** is the constitutionally defined interface between Symphony and ZEMA's operational systems, including the ZEMA national carbon registry, MRV data repositories, and ITMO authorisation processes. The ZEMA integration boundary is a **sovereign boundary**, not a system interface. Data flowing across this boundary does not lose its originating sovereignty character upon crossing; it acquires additional constitutional attributes from its entry into Symphony's evidentiary fabric.

---

## 4. Sovereignty Domain Mapping

The following table defines which sovereignty domain governs each constitutional dimension of the MGEE / MADD / MAIN / ZEMA integration.

| Constitutional Dimension | Governing Sovereignty Domain | Authority Source | Non-Collapsible With |
|---|---|---|---|
| Measurement data quality threshold | Runtime Sovereignty (Wave 4) | Symphony enforcement triggers, `data_authority_level` invariants | MGEE process standards |
| Provenance of measurement artefacts | Provenance Sovereignty (Wave 8) | Cryptographic lineage, signing key authority, hash chain | Wave 4 runtime state |
| MADD output admissibility into Symphony | Compositional Validation | Both Wave 4 and Wave 8 determinations required jointly | Either domain alone |
| MAIN attestation cryptographic integrity | Provenance Sovereignty (Wave 8) | Attesting body's signing key, methodology version anchor | Runtime operational state |
| ZEMA domestic registry authority | Regulatory Sovereignty (ZEMA domain) | ZEMA statutory mandate, SI 5 of 2026 | BoZ, Gold Standard, Verra domains |
| Article 6 ITMO authorisation | Regulatory Sovereignty (Article 6 domain) | Paris Agreement treaty authority, bilateral agreement | ZEMA domestic registry authority |
| BoZ green finance evidentiary linkage | Regulatory Sovereignty (BoZ domain) | BoZ prudential authority, ZGFT classification | ZEMA, Article 6 domains |
| Replay survivability of integration records | Replay Sovereignty (Root) | REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md | All operational and regulatory domains |
| External verifier access to integration artefacts | External Verifier Independence | EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md | Symphony runtime availability |
| Integration event admissibility continuity | Root Constitutional Authority | EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md | Phase lifecycle, operational transitions |
| Methodology lineage continuity | Provenance Sovereignty (Wave 8) + Regulatory Sovereignty | Wave 8 cryptographic anchor + MAIN methodology record | Runtime reclassification |
| Cross-border trust transfer evidentiary status | Article 6 Regulatory Sovereignty + Wave 8 | Treaty authority + cryptographic lineage | Any unilateral domestic determination |

---

## 5. MGEE Trust Boundaries

### 5.1 The MGEE External Sovereign Process Authority

MGEE occupies the constitutional position of an **external sovereign process authority** in relation to Symphony. This classification carries the following constitutional implications:

**5.1.1 — Determination Independence:**
MGEE determinations (measurement validations, compliance findings, enforcement decisions) are made under MGEE's sovereign process authority. They are not derived from, overridden by, or subordinate to Symphony's operational determinations. Symphony records MGEE determinations as evidentiary data; it does not produce them.

**5.1.2 — Evidence Authority at Intake:**
MGEE outputs delivered to Symphony carry the evidentiary authority of their originating process. This authority is not augmented by Symphony's receipt of the output, nor diminished by it. Symphony's role at intake is compositional validation and constitutional anchoring — not substantive verification of MGEE's process conclusions.

**5.1.3 — Non-Substitution Principle:**
Symphony may not substitute its operational determinations for MGEE's process determinations. Where MGEE has produced a formal compliance finding, measurement validation, or enforcement decision, Symphony records that finding as-delivered. Symphony does not re-derive, re-score, or re-validate the substance of MGEE's determination. Runtime admissibility validation (Wave 4) addresses data structure and invariant conformance, not the substantive correctness of MGEE's findings.

**5.1.4 — Boundary at Constitutional Anchoring:**
MGEE's process authority terminates at Symphony's constitutional intake boundary. Once an MGEE output has been constitutionally anchored within Symphony as evidentiary data, it becomes subject to Symphony's constitutional governance including replay obligations, provenance immutability, and regulator partition preservation. MGEE may not subsequently direct deletion, modification, or re-classification of constitutionally anchored records.

### 5.2 MGEE Trust Boundary Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MGEE TRUST BOUNDARY                                │
├──────────────────────────────────┬──────────────────────────────────────────┤
│       MGEE SOVEREIGN DOMAIN      │       SYMPHONY CONSTITUTIONAL DOMAIN     │
│                                  │                                           │
│  ┌─────────────────────────┐     │     ┌─────────────────────────────────┐  │
│  │   MADD Process          │     │     │  Intake Compositional           │  │
│  │   - Measurement         │ ──► │ ──► │  Validation Gate                │  │
│  │   - QA/QC               │     │     │  (Wave 4 + Wave 8)              │  │
│  │   - Data Delivery       │     │     └──────────────┬──────────────────┘  │
│  └─────────────────────────┘     │                    │                      │
│                                  │                    ▼                      │
│  ┌─────────────────────────┐     │     ┌─────────────────────────────────┐  │
│  │   MAIN Process          │     │     │  Constitutional Anchoring       │  │
│  │   - Methodology         │ ──► │ ──► │  (Evidentiary Data Class        │  │
│  │   - Attestation         │     │     │   + Provenance Record)          │  │
│  │   - Integration         │     │     └──────────────┬──────────────────┘  │
│  └─────────────────────────┘     │                    │                      │
│                                  │                    ▼                      │
│        MGEE AUTHORITY            │     ┌─────────────────────────────────┐  │
│        TERMINATES HERE ─────────►│     │  Regulator Partition            │  │
│                                  │     │  Distribution                   │  │
│                                  │     │  (ZEMA / BoZ / A6 / CBAM)      │  │
│                                  │     └──────────────┬──────────────────┘  │
│                                  │                    │                      │
│                                  │                    ▼                      │
│                                  │     ┌─────────────────────────────────┐  │
│                                  │     │  Replay Anchor                  │  │
│                                  │     │  (Permanent Evidentiary Store)  │  │
│                                  │     └─────────────────────────────────┘  │
└──────────────────────────────────┴──────────────────────────────────────────┘

  MGEE retains: process determination authority, substantive methodology authority
  Symphony retains: constitutional anchoring, replay, partition, admissibility
  MGEE does NOT retain: authority over constitutionally anchored records
  Symphony does NOT substitute: its determinations for MGEE's process findings
```

---

## 6. MADD Process Authority

### 6.1 Constitutional Position

The MADD process exercises **external measurement and delivery authority**. Its constitutional position within Symphony's integration architecture is that of a **provenance-generating process**: MADD generates the originating measurement records from which Symphony's carbon asset provenance chains begin.

MADD's authority is material to Symphony because:
- Without MADD measurement records, no carbon asset has an originating evidentiary basis;
- The quality and integrity of MADD outputs determine the provenance validity of the resulting carbon assets throughout their full lifecycle;
- MADD's data delivery process constitutes the first evidentiary event in the carbon asset lifecycle and must satisfy all intake requirements from that moment.

### 6.2 MADD Evidence Intake Legality

A MADD output is legally receivable by Symphony as a candidate evidentiary artefact only if all of the following conditions are satisfied at the moment of delivery:

| Intake Condition | Governing Rule | Failure Consequence |
|---|---|---|
| Delivery includes complete monitoring boundary definition | Wave 4 schema conformance | Intake rejected; failure recorded as evidentiary defect |
| Measurement period is precisely specified with start and end timestamps | Wave 4 invariant satisfaction | Intake rejected |
| Methodology reference is explicit (identifier, version, applicable tools) | Provenance requirement | Intake rejected; methodology lineage cannot be established |
| Monitoring report is signed by the MADD-authorised submitting entity | Wave 8 signature requirement | Intake rejected; provenance chain cannot begin |
| Data quality tier is explicitly declared against Symphony's `data_authority_level` scale | Wave 4 `data_authority_level` invariant | Intake rejected |
| Submission includes cryptographic hash of the complete monitoring report package | Wave 8 integrity requirement | Intake rejected |
| Duplicate submission check: no prior MADD record with identical monitoring period and project boundary exists in Symphony | Wave 4 double-delivery prevention | Intake rejected; potential double-counting risk recorded |

**Rule 6.2.1 — No Provisional Intake:**
MADD outputs are not admitted provisionally. There is no provisional evidentiary status in Symphony. An output either satisfies all intake conditions and achieves candidate evidentiary artefact status, or it fails intake and is not recorded as evidentiary data. The failure event is itself recorded as evidentiary data permanently.

**Rule 6.2.2 — Intake Rejection is Not Evidence Destruction:**
A MADD output rejected at Symphony's intake boundary is not deleted. The delivery attempt, the rejection event, and the specific intake condition failures are recorded as permanently preserved evidentiary data. This record may be relevant to subsequent regulatory audits of the MADD process.

**Rule 6.2.3 — MADD Resubmission:**
Where a MADD output is rejected, a corrected resubmission is treated as a new intake event. The prior rejection record is not altered. The resubmission is assessed against all intake conditions independently. A successful resubmission does not retroactively validate the rejected submission.

### 6.3 MADD Provenance Continuity Obligation

From the moment a MADD output achieves candidate evidentiary artefact status through intake, Symphony assumes **provenance continuity obligations** over that artefact:

- The artefact's content must not be modified by any Symphony process;
- The cryptographic hash received at intake is the permanent integrity reference for the artefact;
- All downstream records deriving from the artefact must carry a cryptographic link to the intake hash;
- The artefact must be preserved as evidentiary data class in accordance with the Data Sovereignty and Retention Doctrine.

---

## 7. MAIN Process Authority

### 7.1 Constitutional Position

The MAIN process exercises **methodology attestation authority**. Its constitutional position within Symphony's integration architecture is that of a **provenance-chain completing process**: MAIN takes MADD measurement records and applies the certification authority of an approved methodology and accredited verifier to produce attestations that transform candidate evidentiary artefacts into attestation-bearing provenance records.

MAIN attestations are constitutionally significant because they:
- Establish the methodology lineage required for carbon asset provenance validity (as defined in the Carbon Asset Lifecycle Constitution);
- Supply the verifier accreditation records required for market admissibility and jurisdictional admissibility;
- Constitute the direct evidentiary basis for issuance decisions by certification authorities (Gold Standard, Verra, ZEMA registry).

### 7.2 MAIN Attestation Exchange Legality

A MAIN attestation is legally receivable by Symphony as a provenance-bearing candidate artefact only if all of the following conditions are satisfied:

| Attestation Condition | Governing Rule | Failure Consequence |
|---|---|---|
| Attestation references a specific, Symphony-anchored MADD intake record by intake hash | Provenance chain continuity | Attestation rejected; orphan attestation recorded as defect |
| Verifying body identity and accreditation certificate reference are explicit | Provenance requirement | Attestation rejected |
| Verifying body's accreditation status at the date of verification is evidenced | Provenance temporal validity | Attestation rejected |
| Methodology identifier, version, and all applicable tools/modules are explicitly stated | Methodology lineage requirement | Attestation rejected |
| Attestation is signed by the verifying body using its registered cryptographic key | Wave 8 signature requirement | Attestation rejected |
| Attestation opinion (positive, qualified, adverse) is explicitly stated | Wave 4 content requirement | Attestation rejected |
| Where opinion is qualified or adverse: all findings and material uncertainties are explicitly documented | Wave 4 content requirement + provenance | Attestation rejected as incomplete |
| Attestation date is within the temporal validity window for the applicable methodology | Temporal Validity Doctrine | Attestation rejected |

**Rule 7.2.1 — Attestation Authority Non-Delegation:**
A MAIN attestation carries the authority of the signing verifying body. That authority may not be delegated within Symphony to a subsequent runtime process. Symphony records the attestation as-delivered. It does not re-attest, summarise, or re-sign on behalf of the verifying body.

**Rule 7.2.2 — Qualified Attestations:**
A qualified attestation is not a rejected attestation. A MAIN attestation with a qualified opinion is a valid attestation carrying a qualified provenance status. Symphony records qualified attestations with their qualification precisely as stated. The qualification becomes part of the carbon asset's permanent provenance record and propagates to all downstream admissibility assessments.

**Rule 7.2.3 — Adverse Attestations:**
An adverse attestation is a provenance-bearing record establishing that the applicable methodology standard was not satisfied. It does not trigger deletion of the underlying MADD measurement record. Both the measurement record and the adverse attestation are permanently preserved as evidentiary data. The adverse attestation may constitute the evidentiary basis for ZEMA enforcement action or MGEE compliance determination.

### 7.3 Methodology Attestation Continuity

The methodology attestation continuity obligation requires that, for every MAIN attestation received by Symphony, the following lineage chain is established and preserved as immutable provenance data:

```
Methodology Standard (identifier + version)
        │
        ▼
Approved Tool/Module Composite (each component identified and versioned)
        │
        ▼
Accredited Verifying Body (identity + accreditation basis at verification date)
        │
        ▼
Verification Engagement Reference (engagement letter or equivalent)
        │
        ▼
MADD Monitoring Report (Symphony intake hash reference)
        │
        ▼
MAIN Attestation Record (signed, timestamped, opinion-bearing)
        │
        ▼
Symphony Provenance Anchor (cryptographic hash chain entry)
        │
        ▼
Carbon Asset Issuance Record (if applicable)
```

No link in this chain may be broken, omitted, or substituted. A gap in the chain constitutes a provenance lineage defect, recorded as evidentiary data, that impairs the downstream carbon asset's provenance validity status.

### 7.4 Runtime/Provenance Orthogonality at the MAIN Boundary

Symphony's runtime systems (Wave 4) that process MAIN attestations exercise no authority over the substantive content of those attestations. The following are constitutionally prohibited at the MAIN integration boundary:

- **Runtime re-scoring:** Symphony's runtime may not produce an alternative quality score or confidence metric that substitutes for or overrides the MAIN attestation opinion.
- **Runtime re-classification:** Symphony's runtime may not reclassify a qualified attestation as positive or an adverse attestation as qualified on the basis of internal data quality heuristics.
- **Runtime self-attestation:** Symphony may not generate an attestation of its own that purports to attest the underlying measurement data in place of a MAIN attestation. This is prohibited as runtime self-attestation (see Section 14, Prohibition P-4).
- **Attestation expiry without documentation:** Symphony may not treat a MAIN attestation as expired or superseded without a formal replacement attestation or formal withdrawal notice from the issuing verifying body, recorded as evidentiary data.

---

## 8. ZEMA Integration Authority

### 8.1 ZEMA Sovereignty at the Integration Boundary

ZEMA's integration with Symphony operates through two constitutionally distinct authority channels:

**Channel A — ZEMA as Domestic Registry Authority:**
ZEMA operates and maintains Zambia's national carbon registry. As domestic registry authority, ZEMA's registry records (issuance, transfer, cancellation, retirement) constitute evidentiary inputs to Symphony that carry the authority of ZEMA's domestic sovereign mandate. These records are received by Symphony as **regulatory sovereign artefacts** and are anchored as evidentiary data in ZEMA's regulator partition.

**Channel B — ZEMA as Host Country National Designated Authority:**
ZEMA exercises Zambia's host country authorisation authority under Article 6.2 of the Paris Agreement. In this capacity, ZEMA's ITMO authorisation decisions carry treaty-level authority. These records are received by Symphony as **treaty-level sovereign artefacts** and are anchored in both ZEMA's regulator partition and the Article 6 regulator partition, with appropriate cross-partition linkage.

These two channels are constitutionally distinct. ZEMA's domestic registry authority does not automatically extend to Article 6 authorisation. Article 6 authorisation requires a distinct formal determination that traverses both authority channels simultaneously.

### 8.2 ZEMA Integration Boundary Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ZEMA INTEGRATION BOUNDARY                           │
├──────────────────────────────────┬──────────────────────────────────────────┤
│        ZEMA SOVEREIGN DOMAIN     │      SYMPHONY CONSTITUTIONAL DOMAIN      │
│                                  │                                           │
│  ┌─────────────────────────┐     │     ┌──────────────────────────────────┐ │
│  │  Channel A:             │     │     │  ZEMA Regulator Partition        │ │
│  │  ZEMA Domestic          │ ──► │ ──► │  (Rank 7 sovereign data)         │ │
│  │  Registry Authority     │     │     │  Replay-preserved independently  │ │
│  │  (issuance, transfer,   │     │     └──────────────────────────────────┘ │
│  │  retirement records)    │     │                                           │
│  └─────────────────────────┘     │     ┌──────────────────────────────────┐ │
│                                  │     │  Article 6 Regulator Partition   │ │
│  ┌─────────────────────────┐     │     │  (Treaty-level sovereign data)   │ │
│  │  Channel B:             │ ──► │ ──► │  Replay-preserved permanently    │ │
│  │  ZEMA as NDA            │     │     │  without expiry                  │ │
│  │  (ITMO authorisation,   │     │     └──────────────────────────────────┘ │
│  │  corr. adjustment,      │     │                                           │
│  │  bilateral agreement)   │     │     ┌──────────────────────────────────┐ │
│  └─────────────────────────┘     │     │  Cross-Partition Linkage         │ │
│                                  │     │  (Channel A ↔ Channel B          │ │
│  ZEMA retains:                   │     │  cryptographic linkage)          │ │
│  - Registry operational control  │     └──────────────────────────────────┘ │
│  - NDA authorisation authority   │                                           │
│  - NDC accounting sovereignty    │  Symphony retains:                        │
│                                  │  - Constitutional anchoring of records    │
│  ZEMA does NOT retain:           │  - Replay preservation obligations        │
│  - Authority over Symphony-      │  - Partition sovereignty                  │
│    anchored evidentiary records  │  - Admissibility continuity               │
│  - Instruction to delete or      │  - External verifier access rights        │
│    modify anchored records       │                                           │
└──────────────────────────────────┴──────────────────────────────────────────┘
```

### 8.3 ZEMA Admissibility Requirements

For a ZEMA registry record to achieve constitutional status as an evidentiary record within Symphony's ZEMA regulator partition, the following conditions must be satisfied:

| Admissibility Condition | Governing Rule | Failure Consequence |
|---|---|---|
| Record carries ZEMA's official registry transaction reference | Wave 4 schema conformance | Record classified as unverified data, not evidentiary |
| Record is digitally signed by ZEMA's designated registry authority key | Wave 8 signature requirement | Record rejected from evidentiary partition |
| Record is temporally consistent with ZEMA's registry transaction log | Temporal Validity Doctrine | Record flagged for temporal conflict resolution |
| Record references a specific carbon asset or ITMO with Symphony-anchored provenance | Provenance chain continuity | Record anchored with provenance gap notation |
| For Channel B records: bilateral agreement reference is explicitly stated | Article 6 regulatory requirement | Record accepted in ZEMA partition only; Article 6 partition entry requires remediation |
| Record does not contradict a prior ZEMA registry record anchored in Symphony | Double-entry prevention | Conflict record created; both records preserved; regulatory notification generated |

### 8.4 ZEMA-Symphony Authority Boundary: Non-Subordination Rules

**Rule 8.4.1 — ZEMA Does Not Override Symphony's Constitutional Records:**
ZEMA's operational registry state does not override Symphony's constitutionally anchored evidentiary records. Where a discrepancy exists between ZEMA's current registry state and Symphony's anchored record, the discrepancy is recorded as an evidentiary conflict and both states are preserved. Symphony does not silently update anchored records to match ZEMA's operational state.

**Rule 8.4.2 — Symphony Does Not Override ZEMA's Sovereign Determinations:**
Symphony's operational or analytical processes do not produce determinations that substitute for ZEMA's sovereign registry decisions. Symphony may flag, analyse, or notify regarding potential discrepancies. It may not produce a determination that purports to override or replace ZEMA's domestic registry authority.

**Rule 8.4.3 — ZEMA's ITMO Authorisation is Self-Executing Within Its Domain:**
A formal ITMO authorisation issued by ZEMA as NDA is constitutionally self-executing within Symphony's Article 6 regulator partition upon receipt and compositional validation. Symphony does not perform substantive review of ZEMA's authorisation decision. Symphony records it, anchors it, and initiates the corresponding Article 6 lifecycle sub-state transition as defined in the Carbon Asset Lifecycle Constitution.

---

## 9. Evidence Exchange Legality

### 9.1 Constitutional Principle

Evidence exchange between Symphony and the MGEE/MADD/MAIN/ZEMA systems is constitutionally governed, not contractually governed. The legality of an evidence exchange event is determined by whether it satisfies Symphony's constitutional intake requirements and whether it preserves provenance continuity across the exchange boundary. A contractual agreement between Symphony's operating entity and an external system operator does not alter the constitutional requirements of an evidence exchange.

### 9.2 Legal Exchange Events

The following exchange events are constitutionally recognised as legal within Symphony's integration architecture:

| Exchange Event | Direction | Constitutional Requirements |
|---|---|---|
| MADD monitoring report delivery | MGEE → Symphony | All Section 6.2 intake conditions satisfied |
| MAIN attestation delivery | MGEE → Symphony | All Section 7.2 attestation conditions satisfied; reference to anchored MADD record confirmed |
| ZEMA domestic registry record delivery | ZEMA → Symphony | All Section 8.3 admissibility conditions satisfied |
| ZEMA ITMO authorisation delivery | ZEMA → Symphony | Section 8.3 conditions + bilateral agreement reference + Article 6 lifecycle sub-state transition |
| Symphony evidentiary record delivery to ZEMA | Symphony → ZEMA | Delivered as cryptographically signed evidentiary record; ZEMA partition content only |
| Symphony replay record delivery to external verifier | Symphony → Verifier | Delivered from regulator escrow; not from operational runtime; external verifier independence preserved |
| Symphony admissibility certificate delivery | Symphony → BoZ / A6 / CBAM | Regulator-partition-specific; non-transferable across domains |
| MGEE compliance determination delivery | MGEE → Symphony | Delivered as external regulatory finding; Symphony records as-delivered; does not re-determine |

### 9.3 Illegal Exchange Events

The following exchange events are constitutionally prohibited and must not be recorded as valid integration events:

| Prohibited Exchange Event | Prohibition Basis | Section Reference |
|---|---|---|
| MGEE instructing deletion of Symphony-anchored records | Evidentiary immutability | DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE §3.2 |
| ZEMA instructing modification of Symphony-anchored ZEMA partition records | Regulator partition sovereignty | §8.4.1 |
| MAIN producing an attestation that references no anchored MADD record | Orphan attestation; provenance chain break | §7.2 |
| Symphony producing a self-attestation substituting for MAIN attestation | Runtime self-attestation prohibition | §7.4; Prohibition P-4 |
| Cross-domain delivery: using ZEMA partition evidence as Article 6 evidence without bilateral linkage | Regulator partition non-collapse | REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE |
| MGEE receiving Symphony operational runtime data as evidentiary output | Operational/evidentiary data class confusion | DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE §3.6 |
| External system receiving pre-validation candidate artefacts as constitutionally anchored evidence | Premature admissibility assertion | §6.2 Rule 6.2.1 |

---

## 10. Provenance Continuity Across the Integration Boundary

### 10.1 Constitutional Principle

Provenance continuity is the unbroken chain of cryptographic linkages and authority references from the originating measurement event through MADD data collection, MAIN attestation, Symphony constitutional anchoring, and all downstream regulator partition uses. No integration event may break this chain. An integration event that introduces a gap in provenance continuity impairs all downstream admissibility determinations.

### 10.2 Provenance Continuity Obligations at Each Integration Stage

```
ORIGINATING MITIGATION EVENT
        │ (physical boundary, accounting period, baseline)
        ▼
MADD MONITORING REPORT
        │ Cryptographic hash: [H₁]
        │ Signed by: MADD submitting authority
        │ Methodology reference: [M₁ version V₁]
        ▼
SYMPHONY INTAKE VALIDATION ─── Wave 4 schema + Wave 8 signature check
        │ Symphony intake anchor: [A₁] = Hash(H₁ + intake_timestamp + validator_id)
        ▼
MAIN ATTESTATION
        │ References: [H₁] (MADD hash) → confirmed against [A₁]
        │ Methodology: [M₁ version V₁] → confirmed lineage
        │ Verifier: [VB₁] accreditation at [date_t]
        │ Signed by: [VB₁ signing key]
        │ Opinion: [positive / qualified / adverse]
        ▼
SYMPHONY ATTESTATION VALIDATION ─── Wave 4 content + Wave 8 signature check
        │ Symphony attestation anchor: [A₂] = Hash(A₁ + attestation_content + VB₁_signature)
        ▼
CARBON ASSET ISSUANCE (if attestation positive/qualified, proceeding to certification authority)
        │ Certification authority reference: [CA₁]
        │ Serial number: [SN₁]
        │ Symphony issuance anchor: [A₃] = Hash(A₂ + CA₁ + SN₁ + issuance_timestamp)
        ▼
REGULATOR PARTITION DISTRIBUTION
        │ ZEMA partition: [A₃] + ZEMA registry record
        │ BoZ partition: [A₃] + green finance linkage (if applicable)
        │ Article 6 partition: [A₃] + ITMO authorisation (if applicable)
        ▼
REPLAY ANCHOR (permanent evidentiary store)
        [A₁] → [A₂] → [A₃] → all partition records
        Full chain reconstructable from replay store without runtime dependency
```

### 10.3 Provenance Mutation Prohibition

Provenance mutation at any integration stage is constitutionally prohibited. Provenance mutation is defined as any modification to a provenance-bearing record after its constitutional anchoring in Symphony. This includes:

- Updating an anchored MADD record to reflect a revised monitoring report (prohibited; a revised report is a new intake event);
- Replacing an anchored MAIN attestation with a revised version (prohibited; a superseding attestation is a new attestation event that references and does not delete the prior);
- Altering the methodology reference in an anchored provenance record (prohibited regardless of the reason);
- Re-signing an anchored record with a new key (prohibited; re-signing constitutes a new evidentiary event; the original signed record is preserved alongside the re-signing event record).

---

## 11. Replay Continuity

### 11.1 Constitutional Principle

Every integration event — intake, attestation exchange, ZEMA delivery, regulator partition distribution — generates a replay anchor record in Symphony's permanent evidentiary store. Replay continuity is the unbroken capacity of that store to reconstruct any prior integration state independently of the operational availability of MGEE, MADD, MAIN, ZEMA, or Symphony's own runtime systems.

### 11.2 Replay Obligations per Integration Actor

| Integration Actor | Replay Obligation | Replay Independence Requirement |
|---|---|---|
| MADD | All delivered monitoring reports permanently preserved as evidentiary data from intake | Reconstructable from Symphony replay store without MGEE operational access |
| MAIN | All attestations permanently preserved with their methodology lineage chain | Reconstructable including verifier accreditation status at attestation date |
| ZEMA (Channel A) | All domestic registry records permanently preserved in ZEMA partition | Reconstructable independently by ZEMA from ZEMA escrow partition |
| ZEMA (Channel B) | All ITMO authorisations permanently preserved in both ZEMA and Article 6 partitions | Reconstructable permanently without expiry; treaty-level obligation |
| Symphony | All intake validation events, rejection events, and compositional validation results | Reconstructable from replay store; includes failure records |
| External Verifier | Must be capable of reconstructing full provenance chain from escrow | No Symphony runtime access required; escrow-only reconstruction sufficient |

### 11.3 Article 6 Replay Survivability

All integration events involving Article 6 ITMO records carry permanent replay obligations without expiry. This applies specifically to:

- ZEMA Channel B ITMO authorisation records;
- Cross-border corresponding adjustment confirmation records;
- Acquiring country bilateral confirmation records;
- UNFCCC registry synchronisation records where applicable.

These records must remain replayable in a form that satisfies the treaty-level verification requirements of the Paris Agreement's enhanced transparency framework, independently of the operational continuity of any system involved in their original generation.

### 11.4 Replay-Invalidating Transformations

The following transformation events constitute replay-invalidating transformations and are constitutionally prohibited:

- **Format migration without content preservation:** Migrating an integration record from one storage format to another without preserving the original byte-identical content and its cryptographic hash;
- **Hash chain interruption:** Any archival, compaction, or deduplication process that breaks the sequential hash chain between successive replay anchors;
- **Key destruction without replay preservation:** Retiring a cryptographic signing key that was used to sign anchored integration records without first ensuring that the signature verification chain is independently established in the replay store;
- **Regulator partition merge:** Merging ZEMA partition records with Article 6 partition records in the replay store (collapses regulator sovereignty);
- **Operational state substitution:** Replacing a replay anchor's original content with the current operational state of the relevant record (destroys historical truth).

---

## 12. Admissibility Continuity

### 12.1 Constitutional Principle

Admissibility continuity is the unbroken capacity of a Symphony-anchored integration record to satisfy the admissibility requirements of its governing regulator sovereign domain at any point in the future, regardless of changes in:

- Symphony's operational infrastructure;
- MGEE's process framework;
- ZEMA's operational systems;
- The applicable methodology standard (supersession does not retroactively impair);
- The verifying body's ongoing accreditation status (accreditation at the time of attestation is the governing fact);
- The political or regulatory status of the bilateral agreement framework.

### 12.2 Admissibility Continuity by Regulator Domain

| Regulator Domain | Admissibility Continuity Requirement | Continuity Mechanism |
|---|---|---|
| ZEMA | ZEMA-anchored records satisfy ZEMA domestic admissibility indefinitely | ZEMA regulator partition escrow; replay from escrow |
| Article 6 / UNFCCC | ITMO provenance chain satisfies treaty verification indefinitely | Article 6 partition escrow; external verifier escrow access; no expiry |
| BoZ | BoZ-linked evidentiary records satisfy prudential audit for applicable retention period | BoZ partition escrow; minimum 7 years plus instrument life |
| Gold Standard | GS-attested records satisfy GS registry audit indefinitely | Methodology lineage anchor; verifier accreditation anchor at attestation date |
| Verra / VCS | VCS-attested records satisfy Verra registry audit indefinitely | Methodology lineage anchor; verifier accreditation anchor at attestation date |
| EU CBAM | CBAM-lodged records satisfy CBAM audit for applicable regulatory retention | CBAM partition records; EU CBAM Regulation retention period |

### 12.3 Pre-Exchange Admissibility Continuity Validation

Before any integration record is delivered from Symphony to an external system (ZEMA, BoZ, Article 6 counterpart, CBAM authority, external verifier), Symphony performs a pre-delivery admissibility continuity check confirming:

1. The record's provenance chain is cryptographically intact to the replay store;
2. The record's data class has not been reclassified since anchoring;
3. The record's regulator partition assignment is correct for the receiving domain;
4. No invalidation, reversal, or dispute flag is outstanding against the record without disclosure;
5. The delivery is to the correct partition domain (cross-domain delivery is prohibited without explicit bilateral authorisation).

The pre-delivery check result is itself recorded as evidentiary data.

---

## 13. External Verifier Independence

### 13.1 Constitutional Position

External verifiers — UNFCCC supervisory bodies, Gold Standard accreditation body auditors, Verra technical review personnel, BoZ prudential examiners, EU CBAM verification authorities, bilateral agreement review panels — must be capable of independently reconstructing and verifying any Symphony-anchored integration record without access to:

- Symphony's operational runtime;
- MGEE's operational systems;
- ZEMA's operational registry;
- Any signing key in Symphony's custody.

This independence is a constitutional guarantee, not an operational convenience.

### 13.2 External Verifier Escrow Access Protocol

External verifiers access Symphony integration records through the regulator escrow partition allocated to their domain. The escrow partition contains:

- All MADD monitoring reports anchored in Symphony for the relevant project and accounting period;
- All MAIN attestations for those reports, including qualified and adverse attestations;
- All methodology lineage records, including verifier accreditation status at attestation date;
- All ZEMA registry records for the relevant assets;
- All Article 6 authorisation and corresponding adjustment records (for Article 6 verifiers);
- All replay anchor records for the complete integration event sequence;
- All rejection, defect, and dispute records for the relevant integration history.

### 13.3 Cross-System Trust Reconstruction

A cross-system trust reconstruction is the process by which an external verifier reconstructs the complete evidentiary basis for a carbon asset's admissibility claim, starting from Symphony's escrow and working backward through the provenance chain to the originating measurement event, without accessing any operational system.

Cross-system trust reconstruction must be achievable for any Symphony-anchored carbon asset without:

- Querying MGEE operational databases;
- Accessing ZEMA's live registry;
- Contacting the verifying body for original documents;
- Accessing Symphony's operational runtime API;
- Holding any cryptographic key beyond the public keys required for signature verification.

Public keys of signing authorities (MADD submitting entities, MAIN verifying bodies, ZEMA registry authority, Symphony intake validator) must be independently published and archived in a form that supports offline verification. Their publication is not Symphony's operational responsibility; it is a constitutional obligation of the respective signing authority. Symphony records the key reference; it does not custody the external signer's key.

---

## 14. Prohibited Acts

The following acts are constitutionally prohibited at the MGEE/MADD/MAIN/ZEMA integration boundary. Each prohibition is enumerated with its constitutional basis and the impairment it prevents.

**P-1 — Regulator Authority Collapse**
*Prohibition:* No process, document, or operational decision may treat ZEMA's domestic registry authority as equivalent to, subordinate to, or capable of substituting for ZEMA's Article 6 NDA authority, or vice versa.
*Constitutional basis:* REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE; §8.1 of this doctrine.
*Impairment prevented:* Invalidation of ITMO authorisations through domestic registry record gaps; double-use of domestic retirement records as Article 6 corresponding adjustments.

**P-2 — Provenance Mutation During Exchange**
*Prohibition:* No integration process may alter the content of a provenance-bearing record during transmission, storage, format conversion, or system migration.
*Constitutional basis:* EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE; §10.3 of this doctrine.
*Impairment prevented:* Destruction of cryptographic lineage; inadmissibility of downstream records.

**P-3 — Runtime Self-Attestation**
*Prohibition:* Symphony's runtime systems may not generate attestations that purport to certify the quality, accuracy, or completeness of MADD measurement data in substitution for a MAIN attestation from an accredited verifying body.
*Constitutional basis:* SYSTEM_SOVEREIGNTY_MODEL §1.2 (Symphony is not a policy engine); §7.4 of this doctrine.
*Impairment prevented:* Invalid provenance chain; inadmissible carbon assets; violation of accreditation requirements under Gold Standard, Verra, and ZEMA MRV standards.

**P-4 — Replay-Invalidating Transformation**
*Prohibition:* No archival, migration, compaction, deduplication, or format conversion process may be applied to integration records in a manner that breaks replay lineage continuity or destroys the capacity to reconstruct prior integration states.
*Constitutional basis:* REPLAY_AND_HISTORICAL_TRUTH_PRIMACY; §11.4 of this doctrine.
*Impairment prevented:* Loss of historical audit survivability; treaty-level non-compliance for Article 6 records.

**P-5 — Retroactive Invalidation of Historical Attestations**
*Prohibition:* No event occurring after a MAIN attestation has been constitutionally anchored in Symphony — including methodology retirement, verifying body de-accreditation, MGEE governance change, or regulatory policy revision — may retroactively alter the constitutional status of that attestation as a provenance record for the period it governed.
*Constitutional basis:* TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE; Carbon Asset Lifecycle Constitution §9.4.
*Impairment prevented:* Retroactive destruction of carbon asset provenance validity; inadmissibility of historical credits.

**P-6 — Cross-Domain Partition Delivery Without Authorisation**
*Prohibition:* No integration event may deliver ZEMA domestic partition records to the Article 6 partition, BoZ partition records to the CBAM partition, or any regulator partition records to another domain's partition without an explicit, constitutionally recorded cross-domain linkage authorisation.
*Constitutional basis:* REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE; §9.3 of this doctrine.
*Impairment prevented:* Regulator sovereign boundary violation; inadmissible cross-domain evidence claims.

**P-7 — MGEE Instruction to Delete Anchored Records**
*Prohibition:* MGEE, in any of its process capacities, may not instruct Symphony to delete, suppress, overwrite, or reclassify constitutionally anchored evidentiary data, regardless of the operational reason for the instruction.
*Constitutional basis:* DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE §5 (veto hierarchy Level 1); §5.1.4 of this doctrine.
*Impairment prevented:* Destruction of evidentiary record; regulatory audit failure; treaty non-compliance.

**P-8 — Methodology Version Substitution in Anchored Records**
*Prohibition:* The methodology version recorded in an anchored provenance record may not be updated to reflect a subsequent methodology version, even where the subsequent version is a direct successor to the original.
*Constitutional basis:* Carbon Asset Lifecycle Constitution §9.4 (methodology lineage permanence); §10.3 of this doctrine.
*Impairment prevented:* Destruction of temporal integrity of provenance chain; misrepresentation of verification basis.

---

## 15. Compositional Validation Semantics at the Integration Boundary

### 15.1 Constitutional Principle

Every integration event is a compositional validation event. An integration record achieves constitutional status within Symphony only when both Wave 4 operational sovereignty and Wave 8 provenance sovereignty have independently assessed and passed the record. A pass from one domain does not substitute for or imply a pass from the other.

### 15.2 Integration Compositional Validation Matrix

| Integration Event | Wave 4 Validation | Wave 8 Validation | Constitutional Status on Joint Pass | Constitutional Status on Any Failure |
|---|---|---|---|---|
| MADD intake | Schema conformance; `data_authority_level` assertion; duplicate check; methodology reference present | Submitter signature valid; hash of package confirmed | Candidate evidentiary artefact — intake anchored | Intake rejected; failure record anchored permanently |
| MAIN attestation intake | Content completeness; opinion explicitly stated; MADD reference present; temporal validity | Verifying body signature valid; key is registered; methodology lineage hash consistent | Attestation-bearing provenance record anchored | Attestation rejected; failure record anchored |
| ZEMA Channel A record | Schema conformance; transaction reference format; no contradiction with prior record | ZEMA registry authority signature valid | ZEMA partition evidentiary record | Rejected or accepted with defect notation |
| ZEMA Channel B ITMO authorisation | Schema conformance; bilateral reference present; NDA role assertion | ZEMA NDA signing key valid; linked to prior Channel A asset record | Article 6 partition treaty-level record + ZEMA partition cross-link | Rejected; bilateral partner notification generated |
| Symphony → external delivery | Pre-delivery admissibility continuity check passed | Delivery package signed by Symphony partition authority key | Admissible delivery | Delivery withheld; non-delivery record anchored |

### 15.3 Joint Pass Semantics

A joint Wave 4 / Wave 8 pass at the integration boundary establishes:

- The record is constitutionally anchored as the applicable data class;
- The record's provenance chain is intact to the point of anchoring;
- The record is available for regulator partition distribution;
- The record is subject to permanent replay preservation obligations;
- The record may not be subsequently modified, deleted, or reclassified without a formal constitutional event.

A joint pass does not establish:

- The substantive correctness of the underlying measurement data;
- The admissibility of the record in any regulator domain beyond its intake validation;
- The absence of subsequent defects that may be discovered through MGEE's ongoing monitoring processes.

---

## 16. Historical Audit Survivability

### 16.1 Guarantee

Symphony guarantees that for any integration event whose records were constitutionally anchored within Symphony, the complete chain of custody from originating measurement event through MADD delivery, MAIN attestation, constitutional anchoring, regulator partition distribution, and final disposition is reconstructable from Symphony's durable evidentiary store at any future point, independently of:

- The continued operational existence of MGEE;
- The continued operational existence of any MADD or MAIN process implementation;
- The continued operational availability of ZEMA's registry systems;
- Symphony's own operational runtime availability;
- The continued tenure of any person, organisation, or authority involved in the original integration events.

### 16.2 Audit Survivability Time Horizons

| Integration Record Type | Survivability Horizon |
|---|---|
| MADD monitoring reports | Duration of carbon asset crediting period + applicable registry retention + BoZ retention floor |
| MAIN attestations | Same as MADD; not less than 10 years from attestation date |
| ZEMA domestic registry records | As mandated by ZEMA regulations and SI 5 of 2026 |
| Article 6 ITMO authorisation records | Permanently, without expiry; treaty obligation |
| Corresponding adjustment confirmation records | Permanently, without expiry |
| BoZ green finance linkage records | BoZ prudential retention period + instrument life |
| CBAM lodgement records | EU CBAM Regulation retention period |
| Integration rejection and defect records | Same as the underlying integration record class to which they relate |

---

## 17. Constitutional Glossary References

- **Candidate Evidentiary Artefact:** A MADD or MAIN output that has been received at Symphony's intake boundary but has not yet completed compositional validation. It does not possess constitutional evidentiary status within Symphony until compositional validation passes.
- **Channel A (ZEMA):** ZEMA's domestic registry authority channel, governing issuance, transfer, and retirement records within Zambia's national carbon registry.
- **Channel B (ZEMA):** ZEMA's host country NDA authority channel, governing ITMO authorisation decisions under Article 6.2 of the Paris Agreement.
- **Compositional Validation:** The joint assessment by Wave 4 (operational) and Wave 8 (provenance/cryptographic) sovereignty domains required before an integration record achieves constitutional status within Symphony.
- **Cross-System Trust Reconstruction:** The process by which an external verifier reconstructs the complete evidentiary basis for a carbon asset's admissibility claim from Symphony's escrow without accessing any operational system.
- **External Sovereign Process Authority:** The constitutional classification of MGEE as an authority whose determinations are produced under its own sovereign process mandate, not derived from or subordinate to Symphony's operational determinations.
- **MADD:** Measurement, Attestation, and Data Delivery — the MGEE process framework governing measurement data collection and delivery to Symphony.
- **MAIN:** Methodology, Attestation, and Integration Network — the MGEE process framework governing methodology application, attestation production, and system integration.
- **MGEE:** Monitoring, Governance, Evaluation, and Enforcement — the overarching framework governing Zambia's carbon MRV and regulatory compliance processes.
- **Methodology Attestation Continuity:** The unbroken provenance chain from approved methodology standard through verifying body attestation to Symphony constitutional anchor, preserved permanently as provenance data.
- **Orphan Attestation:** A MAIN attestation that references no Symphony-anchored MADD monitoring report. An orphan attestation constitutes a provenance chain defect and is rejected at intake.
- **Provenance-Bearing Candidate Artefact:** A MAIN attestation received at Symphony's intake boundary, carrying the certification authority of the applicable methodology and verifying body, pending compositional validation.
- **Replay Anchor:** A durable, cryptographically signed record created at each integration event, sufficient to reconstruct the integration state at that event without dependency on operational runtime.
- **Runtime Self-Attestation:** The constitutionally prohibited act of Symphony's runtime systems generating an attestation that purports to certify measurement data quality in substitution for a MAIN attestation from an accredited verifying body.

---

# Constitutional Self-Validation

## Sovereignty Domains Governed

This doctrine governs:

- The MGEE external sovereign process authority boundary and its interaction with Symphony's constitutional domains;
- The MADD evidence intake authority boundary including compositional validation requirements and provenance continuity obligations;
- The MAIN attestation authority boundary including methodology lineage obligations and runtime/provenance orthogonality requirements;
- The ZEMA integration authority boundary across both Channel A (domestic registry) and Channel B (Article 6 NDA) authority surfaces;
- The evidence exchange legality rules governing all integration events;
- The replay continuity obligations binding all integration records permanently;
- The admissibility continuity obligations across all six regulator sovereign domains;
- The external verifier independence obligations at the integration boundary.

## Sovereignty Domains This Doctrine Must NOT Redefine

This doctrine must not redefine:

- The internal operational design or process authority of MGEE, MADD, or MAIN systems;
- ZEMA's domestic registry operational governance or NDC accounting sovereignty;
- The constitutional authority hierarchy established in CONSTITUTIONAL_AUTHORITY_HIERARCHY.md;
- Wave 4 and Wave 8 sovereignty boundaries as defined in CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md;
- The carbon asset lifecycle states and transition conditions defined in CARBON_ASSET_LIFECYCLE_CONSTITUTION.md;
- The data class classification rules of DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md.

## Replay Obligations Preserved

This doctrine preserves:

- Permanent replay preservation of all MADD monitoring reports from intake as evidentiary data;
- Permanent replay preservation of all MAIN attestations including qualified and adverse opinions;
- Permanent replay preservation of all ZEMA Channel B ITMO authorisation records without expiry;
- Permanent replay preservation of all integration rejection, defect, and dispute records;
- Replay anchor creation at every integration event;
- Cross-domain replay reconstruction capability from each regulator partition's escrow independently;
- External verifier escrow access without Symphony runtime dependency.

## Regulator Boundaries That Constrain This Doctrine

- ZEMA's domestic registry sovereignty constrains Symphony's authority to unilaterally determine ZEMA registry record validity;
- ZEMA's Article 6 NDA sovereignty constrains the conditions under which ITMO authorisation records achieve Article 6 partition status;
- Gold Standard and Verra's attestation authority constrains the conditions under which MAIN attestations achieve provenance-bearing status;
- BoZ's prudential authority constrains green finance linkage records in the BoZ partition;
- EU CBAM's admissibility authority constrains CBAM-partition record delivery conditions;
- UNFCCC Article 6 supervisory body authority constrains the permanence obligations for treaty-level integration records.

## Phases to Which This Doctrine Applies

This doctrine applies globally across all Symphony phases. Integration events completed in any phase remain subject to all constitutional obligations of this doctrine indefinitely. Phase completion does not extinguish replay, admissibility continuity, or provenance obligations for integration records created within that phase.

## Constitutional Layers Possessing Override Authority

Override authority over this doctrine is restricted to:

- Root Constitutional Doctrine at Authority-Rank 10 (CONSTITUTIONAL_AUTHORITY_HIERARCHY.md; REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md; CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md);
- Wave Sovereignty Doctrine at Authority-Rank 9 for wave-specific boundary definitions;
- Treaty-level obligations that impose stricter requirements, which supersede this doctrine to the extent of the stricter requirement.

## Lower-Layer Documents Prohibited From Reinterpretation

The following are prohibited from reinterpreting any provision of this doctrine:

- MGEE/MADD/MAIN operational integration specifications or API contracts;
- ZEMA registry technical integration guides;
- Phase-specific operational runbooks addressing integration event handling;
- Any document below Authority-Rank 8 addressing MGEE/MADD/MAIN/ZEMA integration;
- Analytical or synthesis documents describing the integration architecture.

---

# Prohibited Misinterpretations

## Invalid Simplifications

1. **"MGEE is a Symphony data source":** MGEE is an external sovereign process authority. Its outputs are candidate artefacts that become evidentiary data upon compositional validation. MGEE is not a data source in a data pipeline sense. The constitutional relationship is sovereign exchange, not upstream data feed.

2. **"MADD delivery constitutes evidentiary record creation":** MADD delivery constitutes delivery of a candidate evidentiary artefact to Symphony's intake boundary. The evidentiary record is constituted by Symphony's constitutional anchoring after compositional validation, not by the delivery act itself.

3. **"MAIN attestation is equivalent to Symphony's confirmation of the underlying data":** MAIN attestation is the verifying body's independent certification under an approved methodology. Symphony records it. Symphony does not confirm, endorse, or re-certify the underlying data. These are categorically distinct acts.

4. **"ZEMA registry records are the authoritative source; Symphony mirrors them":** ZEMA registry records are sovereign inputs to Symphony's evidentiary system. Once constitutionally anchored, Symphony's anchored records are the evidentiary record. ZEMA's operational registry state is not a post-hoc override authority over anchored records.

## Forbidden Authority Collapses

5. **"ZEMA Channel A and Channel B are the same authority":** ZEMA's domestic registry authority (Channel A) and its Article 6 NDA authority (Channel B) are constitutionally distinct. A ZEMA domestic registry record does not automatically constitute Article 6 authorisation. These channels must not be collapsed in any document, database schema, or operational process.

6. **"A MAIN attestation passing Wave 4 validation implies it passed Wave 8 validation":** Wave 4 and Wave 8 validations are constitutionally independent. A MAIN attestation may satisfy schema and content requirements (Wave 4 pass) while bearing an invalid or unregistered signing key (Wave 8 fail). Joint pass is required for constitutional anchoring.

7. **"MGEE's operational compliance finding overrides Symphony's evidentiary record":** MGEE's compliance findings are external regulatory determinations. They are recorded by Symphony as regulatory findings. They do not override, delete, or modify Symphony's anchored evidentiary records. The finding and the underlying record coexist as independent evidentiary data.

## Replay-Destructive Interpretations

8. **"Rejected MADD outputs do not need to be preserved":** MADD intake rejection events are evidentiary data permanently preserved from the moment of rejection. Rejection records constitute the audit trail of MADD process integrity and may be material to subsequent regulatory investigations.

9. **"Methodology retirement means prior attestations can be reclassified":** A methodology's retirement or revision does not alter the provenance status of attestations produced under that methodology while it was approved. The temporal validity of the attestation is determined at the time of attestation, not at the time of retrospective review.

10. **"Once a carbon asset is retired, its MADD and MAIN records are no longer needed":** Carbon asset retirement transitions the asset to REPLAY ONLY state, which carries the strongest permanent preservation obligation. MADD and MAIN records underlying a retired asset must remain reconstructable, including for Article 6 treaty verification, indefinitely.

## Regulator-Flattening Interpretations

11. **"A single regulator partition can store all MGEE integration records for efficiency":** Regulator partition sovereignty requires that ZEMA Channel A, ZEMA Channel B (Article 6), BoZ, CBAM, Gold Standard, and Verra records are maintained in operationally independent partitions. Merging partitions for storage efficiency is a constitutional violation of regulator sovereignty non-collapse doctrine.

12. **"ZEMA's ITMO authorisation is sufficient for Gold Standard market admissibility":** ZEMA's ITMO authorisation establishes Article 6 jurisdictional admissibility. Gold Standard market admissibility is a distinct determination made by Gold Standard under its programme rules. These are sovereign and independent determinations. One does not imply the other.

## Phase-Illegality Misreadings

13. **"Integration events completed in a prior phase are subject to that phase's rules only":** Integration event records created in any phase are subject to the permanent constitutional obligations of this doctrine indefinitely. Phase-specific operational rules govern what integration events may occur within a phase. They do not extinguish replay, provenance, or admissibility obligations for records created within that phase.

## Provenance/Runtime Collapse Interpretations

14. **"Symphony's data quality scoring replaces MAIN attestation":** Symphony's `data_authority_level` invariant enforces a minimum quality threshold for MADD data intake. It does not produce a substantive attestation of measurement quality. It is a Wave 4 operational gate, not a Wave 8 provenance certification. Conflating them constitutes runtime self-attestation (Prohibition P-3).

15. **"An external system's API confirmation constitutes constitutional anchoring":** Constitutional anchoring occurs when Symphony's Wave 4 and Wave 8 validation processes jointly pass the integration record and a replay anchor is created in Symphony's durable evidentiary store. An API confirmation from ZEMA, MGEE, or any external system does not constitute constitutional anchoring within Symphony.

16. **"Provenance continuity is maintained by the MGEE system, not Symphony":** Provenance continuity within Symphony's constitutional domain is Symphony's obligation. From the moment of constitutional anchoring, Symphony is responsible for maintaining the cryptographic lineage of all anchored records. MGEE's maintenance of its own process records is a separate obligation that does not discharge Symphony's provenance continuity obligations.

---

*End of MADD_MAIN_INTEGRATION_DOCTRINE.md*
