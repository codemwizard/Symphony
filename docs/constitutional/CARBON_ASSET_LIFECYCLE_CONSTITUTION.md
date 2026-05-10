# CARBON_ASSET_LIFECYCLE_CONSTITUTION.md

---

**Constitutional-Status:** AUTHORITATIVE  
**Interpretation-Authority:** ROOT  
**NotebookLM-Ingestion:** CANONICAL  
**Authority-Rank:** 9  
**Phase-Scope:** GLOBAL  
**Supersedes:** Any operational carbon credit record management policy, registry synchronisation procedure, or MRV workflow specification that purports to define the lifecycle of a carbon asset within Symphony without constitutional grounding.  
**Depends-On:**
- `DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md`
- `SOVEREIGNTY_ARCHITECTURE_DOCTRINE.md`
- `REPLAY_SURVIVABILITY_DOCTRINE.md`
- `REGULATOR_PARTITIONING_DOCTRINE.md`
- `PROVENANCE_INDEPENDENCE_DOCTRINE.md`
- `PHASE_LEGALITY_DOCTRINE.md`
- `CRYPTOGRAPHIC_LINEAGE_DOCTRINE.md`
- `COMPOSITIONAL_VALIDATION_DOCTRINE.md`

---

## 1. Purpose

This document establishes the constitutional doctrine governing the full lifecycle of a carbon asset within Symphony.

A carbon asset within Symphony is not an ordinary database record, financial instrument entry, or registry token. It is a **sovereign evidentiary asset**: a cryptographically anchored, provenance-bearing, regulator-partitioned, replay-survivable record whose constitutional status derives from the certification authority that issued it, the treaty or regulatory framework that governs its use, and the unbroken evidentiary lineage that establishes its integrity from originating mitigation event to final disposition.

Symphony serves as the sovereign trust coordination substrate for carbon asset lifecycle management across the following regulatory and treaty domains:

- **ZEMA** — Zambia Environmental Management Agency: national carbon market sovereignty and domestic MRV authority;
- **Article 6 ITMOs** — Paris Agreement international transfer of mitigation outcomes: treaty-level cross-border carbon accounting authority;
- **Gold Standard** — independent carbon project certification, verification, and credit issuance authority;
- **Verra / VCS** — independent carbon methodology, verification, and credit issuance authority;
- **EU CBAM** — European Union Carbon Border Adjustment Mechanism: import carbon pricing and admissibility authority;
- **BoZ-linked green finance flows** — Bank of Zambia prudential oversight of green finance instruments linked to carbon assets.

This constitution defines the constitutionally valid states a carbon asset may occupy, the transitions between those states, the admissibility conditions applicable at each state, the replay obligations binding each transition, and the regulator sovereignty boundaries governing each domain of the lifecycle.

---

## 2. Constitutional Scope

This constitution governs:

1. The complete lifecycle of every carbon asset whose provenance chain includes Symphony as a trust coordination substrate.
2. The admissibility conditions applicable at each lifecycle state across all governing regulator and treaty domains.
3. The compositional validation requirements that must be satisfied before any lifecycle state transition is recorded.
4. The replay lineage obligations that bind every lifecycle transition record permanently.
5. The methodology lineage requirements that establish and maintain provenance validity throughout the lifecycle.
6. The sovereignty boundaries applicable to each regulator domain across the lifecycle.
7. The constitutional treatment of reversal and invalidation events, including the prohibition on retroactive attestation destruction.
8. The cross-border trust transfer architecture governing Article 6 ITMO flows.
9. The historical audit survivability guarantees that extend beyond Symphony operational continuity.

---

## 3. Constitutional Definition: Carbon Asset

**A carbon asset** within Symphony is defined as the composite constitutional record comprising:

- **Originating Mitigation Evidence:** The verified measurement, reporting, and verification record establishing that a quantum of greenhouse gas reduction or removal occurred within a defined project boundary, accounting period, and methodology framework;
- **Certification Provenance:** The certification authority's attestation that the originating mitigation evidence satisfies the applicable methodology standard;
- **Issuance Record:** The formal record of credit issuance by the competent registry authority, including serial number, vintage, methodology reference, project identifier, and issuing registry identity;
- **Custody Chain:** The complete sequence of ownership, transfer, and holding records from issuance to current state;
- **Disposition Record:** The retirement, cancellation, or corresponding adjustment record constituting final use of the asset, where applicable;
- **Cryptographic Lineage:** The unbroken hash and signature chain linking all of the above records from originating event to current constitutional state.

The carbon asset is the totality of this composite record. No single component is independently the asset. Separation or isolation of any component from the composite record degrades the asset's constitutional status and may impair its admissibility.

---

## 4. Admissibility Validity Domains

Symphony distinguishes four constitutionally independent admissibility domains. A carbon asset may possess valid status within some domains and not others simultaneously. These domains must not be collapsed.

### 4.1 Provenance Validity

**Definition:** The carbon asset's originating mitigation evidence, methodology compliance, and certification lineage satisfy the requirements of the issuing certification authority.

**Governing authority:** Gold Standard certification standards; Verra VCS methodology framework; ZEMA domestic MRV standards; applicable UNFCCC methodological guidance.

**Conditions for provenance validity:**
- The originating mitigation event is documented by a qualifying MRV process;
- The applicable methodology is a currently approved or historically approved version traceable through methodology lineage records;
- The verification was conducted by an accredited third-party auditor whose accreditation status at the time of verification is documented;
- The certification authority's issuance record is cryptographically linked to the verification report.

**Loss of provenance validity:** Provenance validity is not lost by subsequent operational events unless a formal certification authority finding of provenance defect is issued. A reversal or invalidation event that does not impugn the originating mitigation evidence does not retroactively destroy provenance validity for the period prior to the finding.

---

### 4.2 Operational Admissibility

**Definition:** The carbon asset is in a state that permits its use within Symphony's operational processes, including transfer, retirement initiation, ITMO nomination, and BoZ green finance linkage.

**Governing authority:** Wave 4 operational sovereignty; ZEMA domestic registry rules; Symphony phase legality.

**Conditions for operational admissibility:**
- The asset is in an active, non-retired, non-invalidated lifecycle state;
- All predecessor lifecycle transitions are cryptographically validated;
- The asset is not subject to a regulatory hold, dispute flag, or pending reversal determination;
- The asset's custody chain is unambiguous and complete.

**Relationship to provenance validity:** Operational admissibility requires provenance validity. An asset whose provenance validity is suspended pending investigation may have its operational admissibility suspended correspondingly. Suspension of operational admissibility does not itself impugn provenance validity.

---

### 4.3 Market Admissibility

**Definition:** The carbon asset satisfies the eligibility requirements of the relevant carbon market or procurement standard for the purpose of offset claims, compliance submissions, or voluntary market transactions.

**Governing authority:** Gold Standard market eligibility rules; Verra VCS approved uses list; applicable Article 6 bilateral agreements designating authorised uses; EU CBAM eligible instrument definitions.

**Conditions for market admissibility:**
- The asset possesses provenance validity;
- The asset satisfies vintage, geography, and methodology eligibility criteria for the target market;
- The asset has not been previously retired, cancelled, or used in a corresponding adjustment;
- The asset is not subject to restrictions arising from applicable bilateral Article 6 agreements;
- For EU CBAM purposes: the asset satisfies EU CBAM Regulation admissibility criteria specific to the importing sector.

**Regulator-domain specificity:** Market admissibility is regulator-domain specific. An asset may be market-admissible under Gold Standard voluntary market rules but not yet authorised for Article 6 use. These are orthogonal determinations. One does not imply the other.

---

### 4.4 Jurisdictional Admissibility

**Definition:** The carbon asset satisfies the admissibility requirements of a specific national, supranational, or treaty jurisdiction for the specific purpose asserted.

**Governing authority:** ZEMA national registry rules; Article 6 bilateral agreements; EU CBAM Regulation; BoZ green finance instrument eligibility criteria; Zambia SI 5 of 2026.

**Conditions for jurisdictional admissibility:**
- The asset satisfies all applicable domestic registration, authorisation, or endorsement requirements of the relevant jurisdiction;
- For Article 6: the asset has received the authorisation of Zambia as the host country for international transfer;
- For EU CBAM: the asset has been assessed against the applicable embedded carbon calculation methodology for the relevant product sector;
- For BoZ green finance: the asset satisfies the ZGFT classification criteria applicable to the linked financial instrument.

**Jurisdictional admissibility is non-transferable:** Jurisdictional admissibility in one jurisdiction does not confer jurisdictional admissibility in another. Each jurisdiction's admissibility determination is sovereign and independent.

---

### 4.5 Replay Validity

**Definition:** The carbon asset's complete lifecycle record, including all transitions, attestations, and provenance data, is in a state from which any prior constitutional moment of the asset can be reconstructed from Symphony's durable evidentiary store, independently of operational runtime availability.

**Governing authority:** Replay Survivability Doctrine; all regulator domains with historical audit rights over the asset.

**Conditions for replay validity:**
- All lifecycle transition records are cryptographically anchored in Symphony's replay store;
- The cryptographic lineage from originating mitigation evidence through all transitions to current state is unbroken;
- All methodology lineage references are resolvable from the replay store;
- All verifier attestations are preserved in their original signed form;
- Tombstone records, where applicable, do not break replay structural integrity.

**Replay validity is perpetual:** Replay validity does not expire upon asset retirement, cancellation, or Symphony operational transition. The obligation to maintain replay validity extends permanently for evidentiary data classes as defined in the Data Sovereignty and Retention Doctrine.

---

## 5. Carbon Asset Lifecycle: Constitutional State Definitions

The following lifecycle states are constitutionally defined. A carbon asset occupies exactly one primary lifecycle state at any given constitutional moment. Sub-states are defined where applicable.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CARBON ASSET CONSTITUTIONAL LIFECYCLE                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [ORIGINATION] ──► [ATTESTATION] ──► [VERIFICATION] ──► [ISSUANCE]        │
│                                                              │              │
│                          ┌───────────────────────────────────┘              │
│                          ▼                                                  │
│                    [ACTIVE/HELD] ◄──────────────────────────────────┐      │
│                          │                                          │      │
│            ┌─────────────┼──────────────┬──────────────┐           │      │
│            ▼             ▼              ▼              ▼           │      │
│       [TRANSFER]   [ITMO NOMINATED]  [CBAM LODGED]  [HELD:BoZ]   │      │
│            │             │              │              │           │      │
│            └──────┬───────┘              │              │          │      │
│                   ▼                      │              │          │      │
│         [CORRESPONDING ADJUSTMENT]       │              │          │      │
│         LINKAGE PENDING                 │              │          │      │
│                   │                     │              │          │      │
│                   ▼                     ▼              ▼          │      │
│         [CORRESPONDING ADJUSTMENT] [RETIRED]      [RETIRED:CBAM] │      │
│         CONFIRMED                       │                         │      │
│                   │                     │                         │      │
│                   ▼                     ▼                         │      │
│              [RETIRED:A6]        [REPLAY ONLY]  ◄─────────────────┘      │
│                   │                     ▲                                  │
│                   ▼                     │                                  │
│           [REPLAY ONLY] ────────────────┘                                  │
│                                                                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ EXCEPTIONAL STATE TRANSITIONS ─ ─ ─ ─ ─ ─ ─ ─ ─ ─   │
│                                                                             │
│  [ANY ACTIVE STATE] ──► [REVERSAL PENDING] ──► [REVERSED]                 │
│  [ANY STATE] ──► [INVALIDATION PENDING] ──► [INVALIDATED]                 │
│  [ANY STATE] ──► [DISPUTED] (sub-state overlay)                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 5.1 ORIGINATION

**Constitutional definition:** The state in which a mitigation event has occurred and MRV documentation has been initiated but no certification authority attestation has been issued.

**Admissibility status:**
- Provenance validity: Pending
- Operational admissibility: Not established
- Market admissibility: Not established
- Jurisdictional admissibility: Not established
- Replay validity: Active (originating MRV records are evidentiary data from inception)

**Replay obligation:** MRV documentation generated during origination is evidentiary data subject to permanent replay preservation from the moment of creation. Origination records must not be treated as provisional or transient.

**Transition conditions to ATTESTATION:** Completed MRV documentation package submitted to a qualifying certification authority, with submission cryptographically recorded in Symphony.

---

### 5.2 ATTESTATION

**Constitutional definition:** The state in which a certification authority has received and acknowledged the MRV documentation and has initiated the attestation process under its applicable standard.

**Admissibility status:**
- Provenance validity: Conditional (certification authority review in progress)
- Operational admissibility: Not established
- Market admissibility: Not established
- Jurisdictional admissibility: Not established
- Replay validity: Active

**Attestation record requirements:** Symphony must record the following as evidentiary data at attestation state entry:
- Certification authority identity and accreditation reference;
- Applicable standard and methodology version;
- Submission receipt timestamp and reference;
- Cryptographic hash of submitted MRV documentation package.

**Transition conditions to VERIFICATION:** Certification authority has engaged an accredited third-party verifier and verification engagement has been formally initiated.

---

### 5.3 VERIFICATION

**Constitutional definition:** The state in which an accredited third-party verifier is conducting independent assessment of the MRV documentation against the applicable methodology standard.

**Admissibility status:**
- Provenance validity: Conditional
- Operational admissibility: Not established
- Market admissibility: Not established
- Jurisdictional admissibility: Not established
- Replay validity: Active

**Verification lineage requirements:**
- Verifier identity, accreditation body, and accreditation certificate reference must be recorded as evidentiary data;
- Verifier's accreditation status at the date of verification engagement must be captured and preserved as provenance data;
- All material verification findings, queries, and responses must be recorded as evidentiary data, not discarded as working papers.

**Verra methodology lineage obligation:** Where the applicable methodology is a Verra VCS methodology, Symphony must record:
- The specific methodology identifier and version number;
- The approved methodology status as of verification date, sourced from the Verra methodology registry;
- Any applicable tool or module references forming part of the methodology composite;
- The VM number, project description document version, and monitoring report version.

This methodology lineage record constitutes provenance data and is permanently immutable once recorded.

**Gold Standard verification semantics:** Where the applicable standard is Gold Standard, Symphony must record:
- The Gold Standard project ID and project design document version;
- The performance standard version applicable at verification date;
- The safeguarding principles assessment reference;
- The SDG impact claim documentation reference, where applicable.

Gold Standard verification attestations carry independent constitutional weight as provenance data. They may not be subordinated to or overridden by operational system determinations.

**Transition conditions to ISSUANCE:** Verification report with positive opinion issued by accredited verifier; certification authority review completed; issuance decision formally recorded by the competent registry.

---

### 5.4 ISSUANCE

**Constitutional definition:** The state in which the competent registry authority has formally issued the carbon credit, assigning it a unique serial identifier and recording it in the registry ledger. Issuance constitutes the asset's entry into its fully constituted lifecycle as a sovereign evidentiary asset.

**Admissibility status:**
- Provenance validity: **Established**
- Operational admissibility: **Established**
- Market admissibility: Established for the issuing registry's market domain (Gold Standard marketplace, Verra registry marketplace, or ZEMA national registry, as applicable)
- Jurisdictional admissibility: Established for the issuing jurisdiction; pending for other jurisdictions
- Replay validity: **Active and permanent from this point forward**

**Issuance record constitutional requirements:** The following must be recorded as immutable evidentiary data at issuance:

| Field | Constitutional Status |
|---|---|
| Unique serial number(s) | Evidentiary, immutable |
| Issuing registry identity | Provenance, immutable |
| Project identifier | Provenance, immutable |
| Vintage year(s) | Evidentiary, immutable |
| Methodology reference and version | Provenance, immutable |
| Quantity (tCO₂e) | Evidentiary, immutable |
| Issuance date | Evidentiary, immutable |
| Verification report reference | Provenance, immutable |
| Third-party verifier identity | Provenance, immutable |
| Issuance cryptographic signature | Cryptographic lineage, immutable |
| Symphony reception timestamp and hash | Replay anchor, immutable |

**ZEMA sovereignty at issuance:** Where a carbon asset is issued under ZEMA's national registry authority, ZEMA's issuance record is sovereign within Zambia's domestic carbon accounting framework. It is not subordinate to Gold Standard or Verra issuance records for domestic accounting purposes, even where the same underlying mitigation activity is dual-certified. ZEMA's registry sovereignty is orthogonal to international certification authority sovereignty.

---

### 5.5 ACTIVE / HELD

**Constitutional definition:** The state in which an issued carbon asset is held by an identified account holder within a recognised registry, with no pending transfer, retirement, or corresponding adjustment process active.

**Admissibility status:** All four admissibility domains are assessed at their established levels. No state transition alters admissibility status without a formally recorded transition event.

**Custody record requirements:** Each change in the identity of the account holder within the ACTIVE state constitutes a custody transfer and must be recorded as evidentiary data. Custody record requirements include:
- Transferor account identity;
- Transferee account identity;
- Transfer date and registry transaction reference;
- Cryptographic hash of the registry transfer confirmation.

---

### 5.6 TRANSFER

**Constitutional definition:** The state in which a formal transfer of the carbon asset between account holders or between registries is in progress.

A transfer within a single registry is a **registry-internal transfer**. A transfer between registries is a **cross-registry transfer** and carries additional constitutional requirements.

**Cross-registry transfer constitutional requirements:**
- The transferring registry must issue a cancellation record linked to the receiving registry's issuance record;
- The cryptographic linkage between cancellation and re-issuance records must be established in Symphony before the asset is considered transferred;
- The identity of both registries, both account holders, the transfer authority reference, and the transfer quantity must be recorded as evidentiary data;
- No gap in cryptographic custody chain is constitutionally permissible. A transfer that creates a gap in custody chain impairs the asset's admissibility across all domains until the gap is resolved.

**Transition conditions:** Transfer completes upon recording of the transferee's custody record with unbroken cryptographic linkage to the transferor's record.

---

### 5.7 ITMO NOMINATION AND ARTICLE 6 CROSS-BORDER TRUST TRANSFER

**Constitutional definition:** The state in which a carbon asset has been nominated by ZEMA (as Zambia's designated national authority) for authorisation as an ITMO for international transfer under Article 6.2 of the Paris Agreement.

**This is the most constitutionally complex lifecycle state.** It involves the simultaneous engagement of:
- Zambia's sovereign host-country authorisation authority;
- The acquiring country's designated national authority;
- The applicable Article 6 bilateral agreement framework;
- UNFCCC Article 6 supervisory body requirements;
- Symphony's cross-border trust transfer architecture.

#### 5.7.1 Article 6 Cross-Border Trust Transfer Architecture

The cross-border trust transfer of an ITMO through Symphony proceeds through the following constitutionally defined sub-states:

**Sub-state 5.7.1 — ITMO NOMINATION RECEIVED:**  
ZEMA has submitted a formal nomination of the asset for ITMO authorisation. Symphony records the nomination as evidentiary data, including the nominating authority identity, nomination date, bilateral agreement reference, and the asset's current serial and custody state.

**Sub-state 5.7.2 — HOST COUNTRY AUTHORISATION PENDING:**  
Zambia's designated national authority (acting through ZEMA under SI 5 of 2026 delegation) is reviewing the nomination against:
- Zambia's nationally determined contribution accounting constraints;
- The applicable bilateral Article 6 agreement terms;
- ZEMA domestic carbon market integrity requirements.

The asset's operational admissibility is suspended for non-Article-6 transactions during this sub-state.

**Sub-state 5.7.3 — HOST COUNTRY AUTHORISATION ISSUED:**  
Zambia's designated national authority has formally authorised the asset as an ITMO for transfer to the nominated acquiring country for the nominated authorised use. Symphony records the authorisation as evidentiary data including:
- Authorisation reference number;
- Authorising authority identity and delegation basis;
- Acquiring country identity;
- Authorised use specification;
- Corresponding adjustment obligation confirmation;
- Authorisation date;
- Cryptographic signature of the authorising authority.

This record is permanently immutable from the moment of recording.

**Sub-state 5.7.4 — CORRESPONDING ADJUSTMENT LINKAGE PENDING:**  
The ITMO has been transferred to the acquiring country's account or registry. The corresponding adjustment to Zambia's NDC accounting has been initiated but not yet confirmed in Zambia's biennial transparency report or equivalent national accounting submission.

**Sub-state 5.7.5 — CORRESPONDING ADJUSTMENT CONFIRMED:**  
Zambia's corresponding adjustment has been formally recorded in its national accounting submission, with the adjustment linked to the specific ITMO serial reference. Symphony records the corresponding adjustment confirmation as evidentiary data.

**Constitutional constraint:** A corresponding adjustment confirmed in a national accounting submission may not be retroactively reversed without the formal agreement of both host and acquiring country designated national authorities, recorded as evidentiary data in Symphony. Unilateral retroactive reversal of a corresponding adjustment is constitutionally prohibited.

**Sub-state 5.7.6 — RETIRED: ARTICLE 6 (ITMO):**  
The ITMO has been formally used by the acquiring country for its authorised purpose (NDC achievement, authorised international mitigation purpose, or other designated use). Retirement is final. The asset transitions to REPLAY ONLY state.

#### 5.7.2 Article 6 Historical Replay Obligations

All records created during ITMO nomination, authorisation, transfer, corresponding adjustment, and retirement are subject to permanent replay preservation without expiry. These records constitute the evidentiary basis for:
- Zambia's national accounting integrity;
- The acquiring country's NDC accounting claims;
- UNFCCC supervisory body audits;
- Third-party market integrity assessments;
- Potential treaty dispute resolution.

External verifiers must be capable of reconstructing the complete Article 6 trust transfer chain from Symphony's regulator escrow, independently of ZEMA operational systems and Symphony operational runtime.

---

### 5.8 CBAM LODGEMENT

**Constitutional definition:** The state in which a carbon asset has been lodged as evidence of embedded carbon cost for the purposes of EU CBAM compliance by an importing entity.

**EU CBAM Admissibility Requirements:**

For an asset to achieve CBAM admissibility within Symphony, the following must be established and recorded as evidentiary data:

- The asset's provenance validity under an eligible certification standard as recognised under EU CBAM Regulation implementing acts;
- The correspondence between the asset's project geography and the importing entity's product supply chain;
- The calculation methodology linking the asset's quantity (tCO₂e) to the embedded carbon content of the imported product;
- The CBAM declarant's identity and CBAM authorisation reference;
- The customs declaration reference for the relevant import;
- The lodgement timestamp and CBAM registry confirmation reference.

**CBAM Sovereignty Boundary:** EU CBAM admissibility is determined by the European Union's competent authority under the CBAM Regulation. Symphony records the evidence supporting CBAM admissibility claims. Symphony does not determine CBAM admissibility. The EU CBAM authority's determination is sovereign within the EU jurisdiction and is not overrideable by ZEMA, BoZ, Gold Standard, or Verra.

**Transition conditions:** The asset transitions to RETIRED: CBAM upon confirmation of successful CBAM declaration acceptance by the EU CBAM authority.

---

### 5.9 BOZ GREEN FINANCE LINKAGE

**Constitutional definition:** The state in which a carbon asset has been formally linked to a BoZ-regulated green finance instrument as qualifying collateral, underlying asset, or performance reference under the ZGFT classification framework.

**BoZ Linkage Constitutional Requirements:**
- The asset must possess provenance validity and operational admissibility;
- The asset must satisfy the applicable ZGFT taxonomy classification for the linked financial instrument;
- The linkage must be recorded as evidentiary data in both Symphony and the BoZ-regulated institution's prudential record;
- The linkage creates a lien or encumbrance on the asset: it may not be transferred, retired, or used in a corresponding adjustment without BoZ or delegated authority consent while the linkage is active;
- BoZ's prudential retention obligations for the linked financial instrument extend to the carbon asset evidentiary record for the duration of the instrument's life and the applicable BoZ retention period thereafter.

---

### 5.10 RETIREMENT

**Constitutional definition:** The state in which a carbon asset has been formally and permanently cancelled for a specified end-use purpose, extinguishing its tradeable status.

**Retirement is constitutionally final.** It may not be reversed, re-activated, or re-issued. A retired asset transitions to REPLAY ONLY state.

**Retirement record constitutional requirements:**

| Field | Constitutional Status |
|---|---|
| Retirement serial reference | Evidentiary, immutable |
| Retiring account holder identity | Evidentiary, immutable |
| Retirement purpose / beneficiary | Evidentiary, immutable |
| Retirement date | Evidentiary, immutable |
| Registry retirement confirmation | Evidentiary, immutable |
| Cryptographic signature of retirement | Cryptographic lineage, immutable |
| Corresponding adjustment linkage (if applicable) | Provenance, immutable |

**Double-counting prevention obligation:** Before recording a retirement, Symphony must validate that the asset serial has not been previously retired, cancelled, or used in a corresponding adjustment in any connected registry domain. This validation must be recorded as a pre-retirement admissibility continuity check. A retirement recorded without this validation is constitutionally defective.

---

### 5.11 REVERSAL

**Constitutional definition:** The state in which a certification authority, registry, or regulator sovereign domain has formally determined that a previously issued or transferred carbon asset must be revoked due to a material defect in the underlying mitigation evidence, methodology application, or verification process identified after issuance.

**Reversal is an exceptional lifecycle event. It is not a routine correction mechanism.**

**Constitutional constraints on reversal:**

**Rule 5.11.1 — Retroactive Attestation Preservation:**  
A reversal finding does not retroactively destroy the evidentiary status of prior attestations, verifications, or issuance records. Those records remain in Symphony as permanent evidentiary data, now accompanied by the reversal record. The reversal record supplements the historical record; it does not replace or delete it.

**Rule 5.11.2 — Prospective Effect Only:**  
Reversal operates prospectively from the date of the reversal determination. It does not alter the constitutional status of transactions completed prior to the reversal determination date, except to the extent that the governing authority's reversal decision expressly requires prior-period accounting adjustments, in which case those adjustments are separately recorded as evidentiary data.

**Rule 5.11.3 — Reversal Authority Sovereignty:**  
A reversal may only be recorded in Symphony upon formal written determination by the competent authority for the asset's governing standard: Gold Standard Programme Committee or equivalent; Verra Technical Review Panel or equivalent; ZEMA national registry authority; or Article 6 supervisory body. Operational or runtime determinations do not constitute reversal authority.

**Rule 5.11.4 — Replacement Credit Linkage:**  
Where a reversal requires the retirement of replacement credits from a buffer pool or insurance mechanism, the replacement retirement must be cryptographically linked to the reversal record in Symphony.

**Rule 5.11.5 — Replay Obligation on Reversal:**  
All reversal records are evidentiary data subject to permanent replay preservation. The reversal record and all prior lifecycle records of the affected asset must remain jointly replayable.

---

### 5.12 INVALIDATION

**Constitutional definition:** The state in which a carbon asset's operational admissibility has been suspended or permanently terminated by a regulator sovereign domain, registry authority, or judicial/regulatory order, without necessarily impugning the underlying mitigation evidence.

Invalidation differs from reversal. Reversal addresses a defect in the mitigation evidence or verification. Invalidation addresses a defect in the asset's legal or regulatory standing: fraud, misrepresentation, sanctions violation, double-counting determination, or regulatory order.

**Constitutional constraints on invalidation:**

**Rule 5.12.1 — Invalidation Does Not Destroy Historical Record:**  
An invalidation event does not authorise deletion of any lifecycle record. All records of the asset remain in Symphony as permanently preserved evidentiary data. The invalidation record is appended as additional evidentiary data.

**Rule 5.12.2 — Invalidation Authority Jurisdiction:**  
Invalidation may be effected by:
- ZEMA, for domestic registry-based assets;
- The applicable international registry (Gold Standard, Verra) within their respective governance authority;
- The EU CBAM authority, for assets lodged in CBAM declarations;
- BoZ, for assets linked to regulated financial instruments;
- A court of competent jurisdiction, recorded through the relevant registry authority.

No single invalidation authority has jurisdiction over all domains simultaneously. An invalidation order from one authority does not automatically effect invalidation in other regulator sovereign domains.

**Rule 5.12.3 — Pending Invalidation Sub-State:**  
Where an invalidation investigation is initiated but not concluded, the asset enters the DISPUTED sub-state overlay. Operational admissibility is suspended. No transfer, retirement, or ITMO nomination may proceed. The DISPUTED sub-state does not alter replay obligations.

---

### 5.13 REPLAY ONLY

**Constitutional definition:** The terminal state of a carbon asset that has been retired, confirmed as corresponding-adjustment-retired under Article 6, invalidated, or reversed. The asset no longer possesses operational admissibility but its complete evidentiary record remains permanently preserved and replayable.

**REPLAY ONLY is not dormancy. It is constitutional permanence.**

The asset in REPLAY ONLY state continues to:
- Satisfy replay validity obligations;
- Serve as the evidentiary basis for historical audit reconstructions;
- Provide the provenance anchor for treaty-level accounting verifications;
- Be accessible to regulator sovereign domains through their escrow partitions;
- Support external verifier independence for historical chain-of-custody reconstructions.

No record of an asset in REPLAY ONLY state may be deleted, archived offline without retrieval capability, or rendered inaccessible to any regulator with historical audit rights over that asset.

---

## 6. Compositional Validation Requirements

### 6.1 Constitutional Principle

A lifecycle state transition within Symphony is constitutionally valid if and only if all compositional validation requirements applicable to that transition are satisfied at the time of transition. A transition recorded without compositional validation is constitutionally defective and does not alter the asset's valid lifecycle state.

### 6.2 Compositional Validation Components

Each lifecycle state transition must satisfy the following validation components before recording:

**Component 6.2.1 — Predecessor State Integrity:**  
The asset's current state record must be cryptographically verified as unmodified since the last valid transition. Any evidence of modification, gap, or corruption in the predecessor state record prevents transition.

**Component 6.2.2 — Transition Authority Verification:**  
The entity initiating the transition must be verified as possessing the constitutional authority to initiate that transition for the asset in question. Authority verification records are evidentiary data.

**Component 6.2.3 — Admissibility Domain Satisfaction:**  
The transition must satisfy all admissibility domain conditions applicable to the target state (Section 4). A transition that would place an asset in a state it cannot constitutionally occupy is rejected.

**Component 6.2.4 — Regulator Partition Notification:**  
Where a transition affects records within a regulator sovereign domain's partition, that domain must receive a cryptographically anchored notification of the transition before the transition is recorded as complete. Notification failure does not prevent recording, but must itself be recorded as an evidentiary defect requiring resolution.

**Component 6.2.5 — Replay Anchor Creation:**  
Each transition must create a replay anchor record in Symphony's durable evidentiary store before the transition is considered complete. Transition without replay anchor creation is constitutionally incomplete.

**Component 6.2.6 — Double-Disposition Prevention Check:**  
For transitions involving retirement, ITMO nomination, CBAM lodgement, or BoZ linkage, a cross-domain disposition check must confirm that no prior disposition of the same asset serial has been recorded in any connected regulator partition or registry domain.

### 6.3 Validation Failure Semantics

Where compositional validation fails:
- The transition is not recorded;
- The failure event is recorded as evidentiary data;
- The asset remains in its current valid state;
- A failure report is generated and retained as evidentiary data;
- The initiating party is notified of the specific validation component failure.

Validation failure records are permanently preserved. They constitute the evidentiary record of attempted but failed transitions.

---

## 7. Runtime / Provenance Orthogonality

### 7.1 Constitutional Principle

Runtime systems and provenance records are constitutionally orthogonal within Symphony. The operational state of Symphony's runtime substrate has no authority over, and no capacity to modify, the constitutional status of provenance records. This orthogonality is maintained across all phases, wave transitions, and substrate migrations.

### 7.2 Operational Implications

- A runtime failure does not alter any carbon asset's lifecycle state. The last validly recorded state persists as the asset's constitutional state until a valid transition is recorded.
- A runtime upgrade, migration, or refactoring does not constitute a lifecycle transition event. No such operational event may be recorded as a transition in the asset's lifecycle record.
- Runtime systems may read and present provenance records but may not overwrite, delete, or modify them under any operational authority.
- The authority to determine an asset's constitutional lifecycle state derives from the asset's evidentiary record, not from the runtime system's current data model or operational state.

### 7.3 Wave Sovereignty Application

- **Wave 4** governs the operational runtime through which lifecycle transitions are initiated and processed. Wave 4 possesses no authority over the content of evidentiary and provenance records once recorded.
- **Wave 8** governs the cryptographic integrity of the provenance record. Wave 8's authority is independent of Wave 4's operational state. A Wave 4 operational failure does not impair Wave 8's cryptographic governance of existing records.

---

## 8. Regulator Sovereignty Boundaries

### 8.1 ZEMA Sovereignty

ZEMA exercises sovereign authority over:
- The domestic carbon registry within Zambia;
- The designation and de-designation of ITMO-eligible assets within Zambia's NDC framework;
- The corresponding adjustment obligations arising from authorised Article 6 transfers;
- The domestic MRV standards applicable to Zambian project activities.

ZEMA does not exercise authority over:
- Gold Standard or Verra certification decisions;
- EU CBAM admissibility determinations;
- BoZ prudential instrument classifications;
- Article 6 bilateral agreement terms beyond Zambia's host-country obligations.

### 8.2 Article 6 / UNFCCC Supervisory Body Sovereignty

The UNFCCC Article 6 supervisory body exercises authority over:
- The centralised accounting and reporting infrastructure for Article 6.4 activities;
- The methodology approval framework for Article 6.4 emission reductions;
- Consistency review of corresponding adjustments.

For Article 6.2 bilateral transfers, authority is distributed between the host and acquiring country designated national authorities, governed by the applicable bilateral agreement. Symphony records the outputs of these sovereign determinations; it does not substitute for them.

### 8.3 Gold Standard Sovereignty

Gold Standard's Programme Committee exercises sovereign authority over:
- The approval and revision of Gold Standard project activities;
- The approval of Gold Standard-accredited validation and verification bodies;
- Reversal determinations for Gold Standard Verified Emission Reductions (VERs) / Gold Standard CERs;
- The Gold Standard registry's issuance and cancellation records.

Gold Standard determinations are constitutionally independent of ZEMA determinations. Dual certification under Gold Standard and ZEMA national registry does not merge their respective authorities.

### 8.4 Verra / VCS Sovereignty

Verra exercises sovereign authority over:
- The approval of Verra Verified Carbon Standard methodologies and tools;
- The accreditation of VCS validation/verification bodies;
- Reversal determinations for Voluntary Carbon Units (VCUs);
- The Verra registry's issuance and cancellation records.

**Verra Methodology Lineage Obligation:** Symphony must maintain an immutable methodology lineage record for every Verra-standard asset, comprising the complete version history of the applicable VM/VMR/tool/module from project registration through verification. This lineage record constitutes provenance data. It survives all asset lifecycle states including REPLAY ONLY.

### 8.5 EU CBAM Sovereignty

The EU CBAM competent authority exercises sovereign authority within the European Union over:
- CBAM declaration acceptance and rejection;
- CBAM authorised declarant eligibility;
- The embedded carbon calculation methodology applicable to each product sector;
- The eligibility of carbon pricing instruments for CBAM purposes.

Symphony records and preserves the evidentiary basis for CBAM declarations. It does not determine CBAM admissibility. EU CBAM determinations are binding within EU jurisdiction and are not subject to override by any other regulator domain enumerated in this constitution.

### 8.6 BoZ Green Finance Sovereignty

BoZ exercises sovereign authority over:
- The prudential classification of green finance instruments issued by regulated institutions;
- The ZGFT taxonomy criteria applicable to carbon-asset-linked instruments;
- Retention obligations for carbon asset evidentiary records linked to regulated instruments;
- The prudential integrity of BoZ-linked carbon asset positions.

BoZ sovereignty operates over the financial instrument dimension of carbon asset linkages. BoZ does not exercise authority over carbon asset certification, registry management, or ITMO authorisation.

---

## 9. Methodology Lineage

### 9.1 Constitutional Principle

Every carbon asset within Symphony carries a methodology lineage record as part of its provenance data. The methodology lineage establishes that the originating mitigation evidence was measured, reported, and verified in accordance with a specific, identifiable, approved methodology at a specific version as of the relevant accounting period. This lineage is a condition of provenance validity.

### 9.2 Methodology Lineage Record Requirements

The following must be recorded as immutable provenance data for each carbon asset:

| Field | Description |
|---|---|
| Standard identifier | The governing standard (Gold Standard, Verra VCS, ZEMA, CDM, etc.) |
| Methodology identifier | The specific methodology code or designation |
| Methodology version | The version number or revision date applicable at time of monitoring and verification |
| Applicable tools / modules | All subsidiary tools and modules applied, with version references |
| Methodology approval status at verification date | Active, approved, or grandfathered status as of verification date |
| Additionality assessment method | The method used to demonstrate additionality, with version reference |
| Baseline scenario version | The approved baseline methodology and applicable scenario |

### 9.3 Methodology Version Change Events

Where a methodology version changes between a project's registration and its verification, or between successive verification periods, Symphony must record:
- The methodology version applicable to each monitoring period;
- The transition date between versions;
- Any grandfathering provision applied;
- The certification authority's acknowledgement of the version transition.

Methodology version changes do not retroactively alter the provenance validity of credits verified under prior approved versions, provided the prior version was approved at the time of verification.

### 9.4 Methodology Lineage Permanence

Methodology lineage records are provenance data and are permanently immutable from the moment of recording. No operational update, registry migration, or methodology retirement event may alter a recorded methodology lineage. A retired methodology does not retroactively impair the provenance validity of credits issued under that methodology while it was approved.

---

## 10. Replay Lineage Continuity

### 10.1 Constitutional Principle

Replay lineage continuity is the unbroken capacity of Symphony's evidentiary store to reconstruct any prior constitutional state of a carbon asset from the replay anchor records of each lifecycle transition, without dependency on operational runtime availability.

### 10.2 Replay Anchor Requirements per Transition

Each lifecycle transition creates one or more replay anchor records in Symphony's durable evidentiary store. A replay anchor must contain:

- The asset's unique serial reference;
- The transition type (state from → state to);
- The transition timestamp;
- The transition authority identity and authority basis reference;
- A cryptographic hash of the complete asset evidentiary record at the moment of transition;
- A cryptographic hash of all transition-specific documentation (verification reports, authorisation letters, registry confirmations, bilateral agreement references);
- A cryptographic signature from the transition recording authority;
- The replay anchor's position in the asset's sequential transition log.

### 10.3 Replay Lineage Gaps

A replay lineage gap occurs when a transition cannot be reconstructed from available replay anchor records. Replay lineage gaps constitute:
- A violation of replay survivability obligations;
- A potential impairment of the asset's admissibility across all domains;
- A mandatory subject for reporting to all regulator sovereign domains with rights over the affected asset.

Gap remediation must be pursued through available evidentiary sources (registry records, certification authority archives, bilateral agreement records) and the remediation effort itself must be recorded as evidentiary data.

### 10.4 Cross-Domain Replay Reconstruction

Where an asset has passed through multiple registry domains (e.g., from Verra registry to ZEMA national registry to acquiring country registry under Article 6), replay lineage continuity requires that:
- Each domain's records are independently anchored in Symphony;
- Cross-domain transition records establish the cryptographic linkage between domains;
- Regulator escrow partitions for each domain contain sufficient anchor records for independent reconstruction;
- No domain's records are dependent on another domain's operational availability for reconstruction.

---

## 11. Sovereignty Domain Mapping

| Lifecycle State / Event | ZEMA | Article 6 / UNFCCC | Gold Standard | Verra | EU CBAM | BoZ |
|---|---|---|---|---|---|---|
| Origination (Zambian project) | **Primary** | Advisory | Certification | Certification | None | None |
| Attestation | Domestic | None | **Primary** (GS) / None (VCS) | None / **Primary** (VCS) | None | None |
| Verification | Domestic | None | **Primary** (GS) | **Primary** (VCS) | None | None |
| Issuance | **Primary** (domestic registry) | None | **Primary** (GS registry) | **Primary** (VCS registry) | None | ZGFT classification |
| ITMO Nomination | **Primary** | **Co-sovereign** | Advisory | Advisory | None | None |
| ITMO Transfer | **Host sovereign** | **Supervisory** | None | None | None | None |
| Corresponding Adjustment | **Primary** | **Supervisory** | None | None | None | None |
| CBAM Lodgement | Advisory | None | Advisory | Advisory | **Primary** | None |
| BoZ Green Finance Linkage | Advisory | None | None | None | None | **Primary** |
| Retirement | Registry authority | NDC accounting | Registry authority | Registry authority | CBAM authority | Prudential release |
| Reversal | Registry authority | Notification | **Primary** (GS) / None | None / **Primary** (VCS) | None | Prudential notification |
| Invalidation | **Domestic primary** | Notification | Registry authority | Registry authority | **Domestic primary** (EU) | Prudential authority |

---

## 12. Admissibility State Transition Table

| From State | To State | Admissibility Change | Transition Authority |
|---|---|---|---|
| ORIGINATION | ATTESTATION | Provenance: Pending → Conditional | Certification authority acknowledgement |
| ATTESTATION | VERIFICATION | Provenance: Conditional (verified) | Verifier engagement |
| VERIFICATION | ISSUANCE | All domains: Established | Registry issuance |
| ISSUANCE | ACTIVE/HELD | No change | Custody record |
| ACTIVE/HELD | TRANSFER | Operational: Suspended during transfer | Account holder initiation |
| TRANSFER | ACTIVE/HELD | Operational: Restored to transferee | Registry transfer confirmation |
| ACTIVE/HELD | ITMO NOMINATED | Operational: Suspended for non-A6 use | ZEMA nomination |
| ITMO NOMINATED | RETIRED: A6 | Operational: Extinguished; Replay: Permanent | UNFCCC/registry retirement |
| ACTIVE/HELD | RETIRED | Operational: Extinguished; Replay: Permanent | Account holder retirement instruction |
| ACTIVE/HELD | CBAM LODGED | Operational: Suspended pending CBAM | CBAM declarant lodgement |
| CBAM LODGED | RETIRED: CBAM | Operational: Extinguished; Replay: Permanent | EU CBAM authority confirmation |
| ANY ACTIVE | REVERSAL PENDING | Operational: Suspended | Certification authority determination |
| REVERSAL PENDING | REVERSED | Operational: Extinguished; Historical record: Preserved | Certification authority final determination |
| ANY STATE | DISPUTED | Operational: Suspended (overlay) | Regulator investigation initiation |
| ANY STATE | INVALIDATED | Operational: Extinguished; Historical record: Preserved | Competent invalidation authority |
| ANY TERMINAL | REPLAY ONLY | Replay: Permanent; All others: Extinguished | Automatic upon retirement/reversal/invalidation |

---

## 13. Historical Audit Survivability

### 13.1 Guarantee

Symphony guarantees that for any carbon asset whose lifecycle records were created within Symphony, the complete lifecycle record from origination through final disposition is reconstructible from Symphony's durable evidentiary store at any future point, without dependency on:

- Symphony's operational runtime availability;
- The continued existence of the issuing registry's operational systems;
- The continued operation of ZEMA, Gold Standard, Verra, or any other certification authority's operational infrastructure;
- The continued tenure of any staff, official, or entity involved in the original lifecycle events.

### 13.2 Survivability Mechanisms

Historical audit survivability is maintained through:

- **Regulator escrow partitions** (Section 8 of DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md): Each regulator domain holds an independently accessible partition of the asset's lifecycle records;
- **Replay anchor continuity** (Section 10 of this document): Each transition is anchored in durable storage;
- **Cryptographic lineage preservation**: The hash chain from originating event to terminal state is maintained across all storage migrations;
- **External verifier escrow access**: External verifiers hold or can access sufficient replay data to independently reconstruct any asset's lifecycle without Symphony mediation;
- **Methodology lineage archival**: Methodology documents referenced by provenance records are archived in Symphony's evidentiary store, not merely referenced by external URL.

### 13.3 Audit Survivability Time Horizon

Historical audit survivability obligations extend:
- For Article 6 ITMO records: permanently, without expiry;
- For Gold Standard and Verra records: for the duration applicable under each registry's governance rules, not less than the project crediting period plus 10 years;
- For ZEMA domestic records: as mandated by ZEMA regulations and SI 5 of 2026;
- For EU CBAM records: as mandated by EU CBAM Regulation;
- For BoZ-linked records: as mandated by BoZ prudential retention regulations.

Where retention periods differ across domains for the same asset, the longest applicable period governs, consistent with the Data Sovereignty and Retention Doctrine.

---

## 14. Constitutional Glossary References

- **Carbon Asset:** The composite evidentiary record defined in Section 3, comprising originating mitigation evidence, certification provenance, issuance record, custody chain, disposition record, and cryptographic lineage.
- **Compositional Validation:** The complete set of validation components that must be satisfied before a lifecycle state transition is constitutionally recorded (Section 6).
- **Corresponding Adjustment:** The accounting entry made by Zambia (as host country) in its national determined contribution accounting to reflect the transfer of mitigation outcomes to another country under Article 6, ensuring no double-counting of the same mitigation outcome.
- **Cross-Registry Transfer:** A transfer of a carbon asset between two operationally distinct registry domains, requiring cryptographic linkage between the cancellation record in the source registry and the issuance record in the destination registry.
- **Cryptographic Lineage:** The unbroken chain of cryptographic signatures, hashes, and attestations establishing the origin, custody, and integrity of a carbon asset's evidentiary record from originating mitigation event to current constitutional state.
- **Historical Audit Survivability:** The guaranteed capacity to reconstruct any carbon asset's complete lifecycle record at any future point, independently of Symphony's operational runtime availability (Section 13).
- **ITMO:** International Transfer of Mitigation Outcomes under Paris Agreement Article 6.2.
- **Methodology Lineage:** The immutable record of the specific approved methodology, version, tools, and modules under which a carbon asset's originating mitigation evidence was quantified and verified (Section 9).
- **Provenance Validity:** The admissibility domain establishing that a carbon asset's originating mitigation evidence, methodology compliance, and certification lineage satisfy the requirements of the issuing certification authority (Section 4.1).
- **Replay Anchor:** A durable, cryptographically signed record created at each lifecycle transition, sufficient to reconstruct the asset's state at that transition point without dependency on operational runtime.
- **Replay Lineage Continuity:** The unbroken capacity of Symphony's evidentiary store to reconstruct any prior constitutional state of a carbon asset from replay anchor records (Section 10).
- **Replay Only State:** The terminal lifecycle state of a carbon asset in which operational admissibility is extinguished but the complete evidentiary record remains permanently preserved and replayable (Section 5.13).
- **Reversal:** An exceptional lifecycle event in which a certification authority formally determines that a previously issued carbon asset must be revoked due to a material defect, subject to the constitutional constraints of Section 5.11.
- **Runtime / Provenance Orthogonality:** The constitutional principle that operational runtime state has no authority over provenance records and that provenance records derive their constitutional status from certification authority attestation rather than runtime system availability (Section 7).
- **Sovereign Evidentiary Asset:** A carbon asset treated as a constitutional record whose integrity, admissibility, and lifecycle state derive from evidentiary provenance and regulatory authority, not from database record status.

---

# Constitutional Self-Validation

## Sovereignty Domains Governed

This constitution governs:

- The complete lifecycle of carbon assets within Symphony across all six regulator sovereign domains enumerated in Section 1;
- The admissibility conditions across provenance, operational, market, jurisdictional, and replay validity domains;
- The compositional validation requirements binding all lifecycle state transitions;
- The methodology lineage obligations applicable to Verra VCS and Gold Standard assets;
- The Article 6 cross-border trust transfer architecture including ITMO nomination, authorisation, corresponding adjustment, and retirement;
- The replay lineage continuity obligations binding all lifecycle transition records;
- The historical audit survivability guarantees extending beyond Symphony operational continuity.

## Sovereignty Domains This Constitution Must NOT Redefine

This constitution must not redefine:

- ZEMA's sovereign authority over the Zambian domestic carbon registry or NDC accounting framework;
- The UNFCCC supervisory body's methodological and accounting authority under Article 6;
- Gold Standard's certification programme governance authority;
- Verra's methodology approval and reversal authority;
- The EU CBAM competent authority's admissibility determination authority;
- BoZ's prudential classification authority over regulated financial instruments;
- The data class classification rules and retention obligations of the Data Sovereignty and Retention Doctrine.

## Replay Obligations Preserved

This constitution preserves the following replay obligations:

- Permanent replay preservation of all lifecycle transition records for Article 6 ITMO assets;
- Permanent replay preservation of all origination, attestation, verification, issuance, and disposition records as evidentiary data;
- Methodology lineage record permanence across all lifecycle states including REPLAY ONLY;
- Replay anchor creation at each lifecycle transition;
- Cross-domain replay reconstruction capability from each regulator's escrow partition independently;
- Tombstone record replay integrity for identity-redacted evidentiary records.

## Regulator Boundaries That Constrain This Constitution

- ZEMA determines host-country authorisation for ITMO transfers; this constitution records but does not substitute for that determination;
- Gold Standard determines reversal of its certified credits; this constitution preserves but does not override those determinations;
- Verra determines methodology lineage validity for VCS assets; this constitution records but does not alter those determinations;
- EU CBAM competent authority determines CBAM admissibility; this constitution supports but does not substitute for that determination;
- BoZ determines ZGFT taxonomy classification for linked instruments; this constitution preserves but does not override those determinations.

## Phases to Which This Constitution Applies

This constitution applies globally across all Symphony phases. Phase completion does not extinguish the lifecycle, replay, or admissibility obligations applicable to carbon assets created or processed within that phase.

## Constitutional Layers Possessing Override Authority

Override authority over this constitution is restricted to:

- Root Interpretation Authority, upon formal constitutional determination;
- Treaty-level obligations (Paris Agreement Article 6, EU CBAM Regulation) that impose stricter requirements, which automatically supersede this constitution to the extent of the stricter requirement;
- DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md at Authority-Rank 9 for all data class and retention rule conflicts.

## Lower-Layer Documents Prohibited From Reinterpretation

The following are prohibited from reinterpreting any provision of this constitution:

- Registry integration operational specifications;
- MRV workflow implementation guides;
- Carbon market participation procedures;
- Phase-specific operational runbooks;
- Runtime data model documentation;
- Any document below Authority-Rank 9 addressing carbon asset state, lifecycle, or admissibility.

---

# Prohibited Misinterpretations

## Invalid Simplifications

1. **"Carbon credits are database records":** Carbon assets within Symphony are sovereign evidentiary assets. Their constitutional state derives from certification authority attestation, regulatory authorisation, and cryptographic lineage — not from database record status, operational system availability, or runtime configuration.

2. **"Lifecycle management is a workflow engine function":** The carbon asset lifecycle is constitutionally defined. State transitions are governed by compositional validation requirements and regulator sovereign determinations. They are not outputs of a workflow engine configuration.

3. **"Retired assets can be ignored":** Assets in the REPLAY ONLY state carry permanent replay obligations and must remain accessible to all regulator domains with historical audit rights. REPLAY ONLY is constitutional permanence, not archival dormancy.

4. **"One admissibility standard applies to all uses":** The four admissibility domains (provenance, operational, market, jurisdictional) are constitutionally independent. Admissibility in one domain does not imply admissibility in another. Each domain's assessment is sovereign.

## Forbidden Authority Collapses

5. **"ZEMA approval implies Article 6 admissibility":** ZEMA's domestic registry authority and its host-country authorisation authority under Article 6 are distinct. ZEMA domestic registry issuance does not automatically establish Article 6 ITMO admissibility. The ITMO nomination and authorisation process is a distinct lifecycle sub-state requiring explicit determination.

6. **"Gold Standard certification implies CBAM admissibility":** EU CBAM admissibility is determined by the EU CBAM competent authority under the CBAM Regulation. Gold Standard certification does not automatically establish CBAM admissibility. These are sovereign and independent determinations.

7. **"BoZ linkage transfers BoZ's authority to the carbon asset lifecycle":** BoZ's authority over a carbon asset is limited to its green finance linkage dimension. BoZ does not acquire certification authority, registry authority, or ITMO authorisation authority by virtue of linking a carbon asset to a regulated financial instrument.

8. **"Runtime system state defines asset lifecycle state":** The asset's constitutional lifecycle state is defined by its evidentiary record. A runtime system outage, data migration, or configuration change that alters the operational presentation of an asset does not alter the asset's constitutional lifecycle state.

## Replay-Destructive Interpretations

9. **"Reversal erases prior records":** A reversal determination does not authorise deletion of any prior lifecycle record. Reversal records supplement the historical evidentiary record. All prior attestations, verifications, and issuance records remain permanently preserved alongside the reversal record.

10. **"Retired assets do not need replay infrastructure":** Retirement transitions an asset to REPLAY ONLY state, which carries the strongest replay preservation obligations. Retirement extinguishes operational admissibility; it does not reduce replay obligations.

11. **"Methodology document URLs are sufficient for lineage":** Methodology lineage requires archival of the methodology document content within Symphony's evidentiary store, not merely a URL reference. External URL references are not replay-survivable. A URL that resolves to a changed or removed document destroys methodology lineage.

## Regulator-Flattening Interpretations

12. **"A single invalidation order invalidates the asset in all domains":** An invalidation order from one regulator domain does not automatically effect invalidation in other domains. Each domain's invalidation authority is sovereign and independent. Cross-domain invalidation requires separate determinations from each competent authority.

13. **"The most recent registry record supersedes all others":** No registry's current operational record supersedes Symphony's evidentiary record. Symphony's evidentiary record is the constitutional record. Registry records are inputs to and outputs from Symphony's lifecycle management; they are not superior authorities over Symphony's evidentiary determinations.

14. **"Regulator escrow partitions can be merged for efficiency":** Regulator escrow partitions are sovereign and independent. Merging partitions collapses regulator sovereignty and violates the regulator partitioning doctrine. Each domain must retain independent, separately accessible partition records.

## Phase-Illegality Misreadings

15. **"Phase completion allows carbon asset records to be archived or purged":** Phase completion does not affect carbon asset lifecycle obligations. Evidentiary records created in any phase are subject to their constitutional data class rules indefinitely. Phase archival procedures may not be applied to carbon asset evidentiary data.

## Provenance / Runtime Collapse Interpretations

16. **"Provenance validity is maintained by the runtime system":** Provenance validity derives from certification authority attestation and cryptographic lineage. It is not a runtime system property. A runtime system may present provenance data but it cannot create, modify, or certify provenance validity. Wave 4 operational sovereignty has no authority over Wave 8 provenance sovereignty.

17. **"A methodology's retirement retroactively impairs previously verified credits":** A methodology retirement or revision does not retroactively alter the provenance validity of credits verified under that methodology while it was approved. Methodology lineage is captured at the moment of verification and is permanently preserved in its historical form.

18. **"External verifiers must access Symphony runtime to verify provenance":** External verifier independence requires that verifiers can reconstruct the complete provenance chain from regulator escrow alone, without accessing Symphony's operational runtime. Any architecture that makes external verification dependent on Symphony runtime availability violates the provenance independence doctrine.

---

*End of CARBON_ASSET_LIFECYCLE_CONSTITUTION.md*
