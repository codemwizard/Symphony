# MRV ARTIFACT MUTABILITY AND RETENTION CLASSIFICATION

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: REGULATORY
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 7
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/constitutional/DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md
  - docs/constitutional/CARBON_ASSET_LIFECYCLE_CONSTITUTION.md
  - docs/constitutional/REGULATORY_ALIGNMENT_CONSTITUTION.md
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/CONSTITUTIONAL_SUBSTRATE_STATE_MODEL.md
  - docs/constitutional/SYSTEM_SOVEREIGNTY_MODEL.md
  - docs/security/ZDPA_COMPLIANCE_MAP.md
  - docs/decisions/ADR-0013-zdpa-pii-decoupling-strategy.md
  - docs/decisions/ADR-0015-identity-reference-trust-boundary.md

---

## Purpose

This document defines the complete artifact mutability and retention classification
for Symphony operating as a Sovereign Measurement, Reporting, and Verification
(MRV) system for the Zambian Carbon Credit Market, BoZ Green Finance controls,
ZDPA and ZICTA local regulatory obligations, EU CBAM, and Paris Agreement Article 6
NDC registry compliance.

Every artifact that Symphony produces, receives, transforms, or preserves is
classified within this document according to four constitutional mutability
categories and assigned to the regulatory regimes for which that classification
is binding. The classification determines what may be mutated, what may be
deleted, what may only be tombstoned, and what must remain permanently and
independently replayable under all operational conditions.

This document does not create a data management policy. It constitutionally
classifies Symphony's artifacts so that no operational decision, no schema
migration, no retention schedule, and no erasure request may be applied without
a constitutional basis for the artifact class affected.

---

## Constitutional Definitions

The following four mutability categories are constitutionally distinct. No
artifact occupies more than one category simultaneously, and no artifact may
be reclassified downward (from more protected to less protected) without a
constitutional supersession declaration.

### IMMUTABLE
An artifact is IMMUTABLE when its content may not be altered, overwritten,
redacted, or deleted by any operational, administrative, legal, or regulatory
act. The artifact must remain exactly as produced at the moment of its original
acceptance into Symphony's constitutional evidence chain. Deletion requests,
including lawful erasure requests under the Zambia Data Protection Act, do not
apply to IMMUTABLE artifacts. IMMUTABLE artifacts carry permanent replay
obligations: they must be independently re-verifiable at any future constitutional
moment by any external verifier without access to Symphony's runtime.

### TOMBSTONE-ONLY
An artifact is TOMBSTONE-ONLY when its identity-bearing content may be cryptographically
replaced by a declared null-substitute (the tombstone), provided that the structural
position of the artifact within the evidence chain, its cryptographic hash commitment,
its signing event record, and its chain linkages remain fully intact and replayable.
A tombstone is not a deletion. The artifact continues to exist as a constitutional
record whose content has been replaced under a declared and recorded tombstoning
event. Replay of the containing evidence chain must succeed through the tombstone
without loss of structural integrity.

### MUTABLE-CONTROLLED
An artifact is MUTABLE-CONTROLLED when its content may be updated through a
constitutionally declared amendment event that: (a) preserves the prior version
in the historical record, (b) records the amendment event with its authority,
timestamp, and basis, and (c) does not alter the cryptographic lineage of evidence
events that referenced the prior version. Mutation without a declared amendment
event is prohibited. Mutable-controlled artifacts are not freely editable — they
are subject to amendment governance.

### EXHAUSTIBLE
An artifact is EXHAUSTIBLE when it is constitutionally designed to expire,
be consumed, or be superseded in the course of normal constitutional operation,
without retaining a permanent replay obligation beyond the retention floor
applicable to its governing regime. Exhaustible artifacts carry a defined
retention floor; after that floor expires, the artifact may be deleted under
a constitutionally declared purge event. Exhaustible artifacts that are
referenced by IMMUTABLE artifacts may not be deleted until the referencing
IMMUTABLE record's own retention obligations are satisfied.

---

## Part I: Master Artifact Classification Matrix

The following table classifies every artifact class produced or consumed by
Symphony in its MRV capacity. Columns identify the mutability category and
the regulatory regimes for which that classification is binding.

Regime abbreviations:
- ZM-ZEMA: Zambia Environmental Management Agency
- ZM-BOZ: Bank of Zambia
- ZM-DPA: Zambia Data Protection Authority
- ZM-ZICTA: Zambia Information and Communications Technology Authority
- ZM-SI5: Zambia SI 5 of 2026 / ZGFT
- INT-VERRA: Verra Verified Carbon Standard
- INT-GS: Gold Standard for the Global Goals
- EU-CBAM: EU Carbon Border Adjustment Mechanism
- INT-ART6: Paris Agreement Article 6

---

### TABLE 1: IMMUTABLE ARTIFACTS
*May not be altered, redacted, or deleted under any instruction. Permanent replay obligation.*

| Artifact | Description | Governing Regimes | Retention Period | Replay Obligation |
|----------|-------------|-------------------|-----------------|-------------------|
| **Originating MRV Record** | The signed measurement, reporting, and verification record establishing that a specific quantum of GHG reduction or removal occurred within a defined project boundary and accounting period | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6 | Permanent (treaty-obligated) | Full independent replay; all three MRV surfaces (measurement instrument, verification report, registry issuance) must be independently re-verifiable |
| **Carbon Credit Issuance Record** | The formal registry-issued credit record, including serial number, vintage, methodology version, project identifier, issuing registry identity, and quantum | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6, EU-CBAM | Permanent | Cryptographic lineage from issuance event to current state must be unbroken and independently verifiable |
| **ITMO Transfer Authorisation Record** | The sovereign authorisation issued by Zambia (via ZEMA) permitting the international transfer of an ITMO under Article 6.2, including the corresponding adjustment basis | INT-ART6, ZM-ZEMA | Permanent (UNFCCC treaty obligation) | Must survive all future NDC review cycles and Global Stocktake intervals; external verifier (receiving Party state) must be able to replay-verify without access to Zambia's runtime |
| **Corresponding Adjustment Record** | The record of the corresponding adjustment made to Zambia's NDC accounting for each transferred ITMO | INT-ART6, ZM-ZEMA | Permanent (UNFCCC treaty obligation) | Independently replayable at any future UNFCCC reporting or adjudication event |
| **Retirement Record** | The record of final disposition of a carbon credit through retirement, including retirer identity reference (not raw PII), retired quantity, vintage, applicable standard, and retirement purpose | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6, EU-CBAM | Permanent | Must support replay for double-counting prevention verification across all applicable registries |
| **Third-Party Verification Attestation** | The cryptographically signed attestation by an accredited verifier confirming methodology compliance for a specific MRV cycle | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6 | Permanent | Verifier identity, accreditation status at time of verification, and verification scope must all be replayable independently of verifier's continued operation |
| **BoZ Green Finance Linkage Record** | The record linking a carbon asset or MRV event to a BoZ-supervised green finance instrument (green loan, green bond, blended finance tranche) | ZM-BOZ, ZM-SI5 | Minimum 10 years post-instrument-maturity; permanent where linked to ITMO | Full replay to support BoZ prudential audit and ex-post green finance verification |
| **EU CBAM Embedded Carbon Declaration** | The declaration of embedded carbon content for regulated goods entering the EU customs territory, including quantification methodology reference and verification basis | EU-CBAM | Minimum as required by EU CBAM implementing regulations (current: 5 years from declaration date; subject to revision) | Must be independently verifiable by EU customs authority without access to Symphony runtime |
| **Asset Batch Attestation Record** (Wave 8) | The cryptographically signed `asset_batches` record constituting the authoritative enforcement boundary record for a carbon asset lifecycle event | ZM-ZEMA, ZM-BOZ, INT-ART6, INT-VERRA, INT-GS | Permanent | Wave 8 cryptographic replay: Ed25519 signature, canonical payload bytes, signer key registry state, and attestation hash must all be independently re-verifiable |
| **Credit Cancellation Record** | The record of credit cancellation following a finding of provenance defect, regulatory revocation, or voluntary cancellation, including the basis for cancellation | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6 | Permanent | Cancellation basis and authority must be independently replayable; cancellation does not delete the original issuance record |
| **Methodology Version Binding Record** | The record binding a specific MRV event to a specific approved methodology version, including the effective date and approval authority of that version | ZM-ZEMA, INT-VERRA, INT-GS, INT-ART6 | Permanent | Must survive methodology supersession; the version that was operative at time of event remains the governing version for that event regardless of later revisions |
| **Cryptographic Signing Event Record** | The record of each Ed25519 signing event, including: signer key identifier, key lifecycle state at signing time, signed payload hash, and canonical bytes | ZM-ZEMA, ZM-BOZ, INT-ART6 | Permanent | Required for replay-verification at any future constitutional moment; key rotation does not extinguish replay obligation |

---

### TABLE 2: TOMBSTONE-ONLY ARTIFACTS
*Identity-bearing content may be cryptographically replaced; structural and hash position must remain intact. Replay must succeed through tombstone.*

| Artifact | Description | Governing Regimes | Tombstone Trigger | What Is Replaced | What Must Remain |
|----------|-------------|-------------------|-------------------|-----------------|-----------------|
| **Participant Identity Record** (raw PII fields) | Natural person or legal entity name, national ID, KYC document reference, address — where stored in direct association with a transaction record | ZM-DPA, ZM-BOZ, ZM-SI5 | Valid ZDPA erasure request after BoZ/SI 5 retention floor has expired; OR deceased participant after applicable retention period | Raw name, ID number, address fields | Cryptographic hash of identity (identity_hash), structural position in evidence chain, chain linkages, signing key reference, tombstone declaration record |
| **Project Developer Identity Reference** | Natural person identity of a project developer in a credit issuance or verification record — where that person has exercised a valid ZDPA erasure right after regulatory floor expiry | ZM-DPA | Same as above | Raw PII fields only | Project entity reference, methodology linkage, issuance record structural integrity |
| **Authentication Credential Record** | User session credentials, MFA artefacts, and authentication tokens stored as part of access audit records | ZM-DPA, ZM-ZICTA | Session expiry plus applicable retention floor; valid erasure request after floor | Active credential content | Audit event timestamp, access event structural record, session hash |
| **KYC Document Reference** | Reference to a KYC document (not the document itself) stored within a participant onboarding record | ZM-DPA, ZM-BOZ | Valid erasure request after BoZ AML retention floor (minimum 5 years from relationship end) | Document reference fields | Onboarding event record, participant classification record, compliance decision record |

---

### TABLE 3: MUTABLE-CONTROLLED ARTIFACTS
*May be amended through a declared amendment event that preserves prior versions and does not alter referencing evidence chain records.*

| Artifact | Description | Governing Regimes | Amendment Authority | Prior Version Fate | Constraints |
|----------|-------------|-------------------|--------------------|-------------------|-------------|
| **Project Registration Record** | The registration record for a carbon project, including project boundaries, activity type, methodology reference, and estimated credit volume | ZM-ZEMA, INT-VERRA, INT-GS | ZEMA (domestic); relevant standard body (international) | Prior version preserved in historical record with amendment event timestamp and authority | Amendment may not retroactively alter the methodology version or project boundary applicable to already-issued credits |
| **Signer Key Registry Entry** | The registry entry for an authorised signing key, including key identifier, public key bytes, effective date, lifecycle state, and authorisation scope | ZM-ZEMA, ZM-BOZ | Key lifecycle governance authority (per KEY_MANAGEMENT_POLICY.md) | Prior entry preserved; superseded key entry transitions to SUPERSEDED substrate state | Supersession must be declared; prior signing events remain valid under the key that was operative at signing time |
| **Methodology Approval Record** | The record of a methodology version's approval status, including the approving authority and effective date | ZM-ZEMA, INT-VERRA, INT-GS | ZEMA; Verra; Gold Standard respectively | Prior approval status preserved with supersession record | Supersession of a methodology version does not retroactively affect events that occurred under the prior version |
| **Participant Classification Record** | The operational classification of a participant (project developer, verifier, registry operator, BoZ-supervised entity) including tier and authorisation scope | ZM-ZEMA, ZM-BOZ, ZM-SI5 | ZEMA; BoZ; SI 5 competent authority | Prior classification preserved with amendment event | Reclassification may not retroactively alter the admissibility of actions taken under prior classification |
| **Green Finance Instrument Classification** | The ZGFT taxonomy classification of a green finance instrument as green, transition, or social | ZM-BOZ, ZM-SI5 | BoZ / ZGFT competent authority | Prior classification preserved | Reclassification does not retroactively alter the carbon asset linkage records that referenced the prior classification |
| **ZICTA Digital Service Registration Record** | The ZICTA registration record for Symphony as a licensed digital service provider under Zambian ICT law | ZM-ZICTA | ZICTA | Prior registration preserved | Registration updates must be reflected in the compliance record with effective dates |

---

### TABLE 4: EXHAUSTIBLE ARTIFACTS
*Constitutionally designed to expire or be purged after defined retention floor. May not be purged while referenced by an IMMUTABLE artifact within its own retention obligation.*

| Artifact | Description | Governing Regimes | Retention Floor | Purge Trigger | Constraints |
|----------|-------------|-------------------|-----------------|-----------|-|
| **Operational Runtime Logs** | Application-layer execution logs, API call logs, system health records, and performance monitoring data not constituting an audit event | ZM-ZICTA, ZM-SI5 | 90 days (dev/test); 2 years (production) per AUDIT_LOGGING_RETENTION_POLICY.md | Scheduled purge after floor expiry | Must not contain raw PII beyond ZDPA-permitted operational necessity; may not be purged if subject of an active regulatory inquiry |
| **Session and Authentication Audit Logs** | Logs of authentication events, session creation, access decisions, and MFA events | ZM-DPA, ZM-ZICTA, ZM-BOZ | 5 years from event (BoZ AML floor) or 3 years (standard Zambian audit) — whichever is longer | Scheduled purge after applicable floor | Raw PII within these logs is subject to tombstoning before purge if erasure right is exercised; structural event record remains |
| **Draft MRV Data** | Measurement data, monitoring records, and reporting drafts that have not yet been submitted to a verifier and do not constitute a completed MRV cycle | ZM-ZEMA | 3 years from data collection (or as ZEMA prescribes) | Purge after floor expiry if not submitted; if submitted, the submitted record transitions to IMMUTABLE upon verification acceptance | Pre-submission data is not a carbon credit and does not carry credit-level retention obligations |
| **Pending Transfer Records** | Records of in-flight credit transfers that have not yet achieved settlement finality | ZM-ZEMA, ZM-BOZ | Duration of transfer plus 90-day dispute window | Superseded by final Settlement Record (IMMUTABLE) upon settlement; purge of pending record permitted after settlement finality and dispute window | Pending records may not be purged before dispute window closes; upon purge, the IMMUTABLE settlement record becomes the sole authoritative record |
| **Operational Cache Records** | In-memory or short-lived cache records of registry state, price references, and operational parameters used for system performance | ZM-ZICTA | Session lifetime or maximum 24 hours | Automatic expiry | Must not constitute the authoritative source for any regulatory determination; authoritative source is always the underlying IMMUTABLE record |
| **API Rate Limit and Throttle Records** | Records of API usage, rate limit counters, and service quota consumption | ZM-ZICTA, ZM-SI5 | 90 days | Scheduled purge | No carbon credit admissibility implications; no replay obligation |
| **Soft-Deleted Operational Configuration Records** | Operational configuration records (feature flags, routing tables, service parameters) that have been administratively superseded but not permanently removed | Internal governance | 1 year from supersession | Purge after floor expiry | Must not be operational configuration that affected the outcome of any IMMUTABLE evidence event; if they did, they transition to MUTABLE-CONTROLLED |

---

## Part II: Regulator-Specific Artifact Views

The following sections present the artifact classification through the lens of
each regulatory regime, identifying which artifact classes are binding for that
regime and what the regime-specific retention and replay obligations are.

---

### 2.1 ZEMA (Zambia Environmental Management Agency)
**Domain:** National carbon market sovereignty; domestic MRV authority; ITMO authorisation

ZEMA requires Symphony to maintain the following artifact classes as constitutionally
binding for domestic carbon market integrity and for treaty-compliance reporting
under the Paris Agreement:

**IMMUTABLE (ZEMA-binding):**
- Originating MRV Record — permanent; ZEMA cannot admit a carbon credit claim
  without an intact, independently verifiable MRV record
- Carbon Credit Issuance Record — permanent; domestic credit issuance is a
  sovereign ZEMA act and its record is ZEMA-owned evidentiary property
- ITMO Transfer Authorisation Record — permanent treaty obligation; Zambia's
  sovereign position in Article 6 proceedings depends on this record surviving
  all future UNFCCC review events
- Corresponding Adjustment Record — permanent; NDC accounting integrity requires
  unbroken replay
- Retirement Record — permanent; double-counting prevention requires permanent
  retirement chain
- Third-Party Verification Attestation — permanent; ZEMA's domestic MRV
  accreditation process requires that verification records survive beyond
  the operational life of the verifier
- Methodology Version Binding Record — permanent; ZEMA's approved methodology
  list and the version operative at each credit issuance must be independently
  verifiable
- Asset Batch Attestation Record (Wave 8) — permanent; the Wave 8 cryptographic
  enforcement boundary is the constitutional proof surface for ZEMA admissibility
- Credit Cancellation Record — permanent; cancellation is a ZEMA sovereign act

**MUTABLE-CONTROLLED (ZEMA-binding):**
- Project Registration Record — ZEMA amendment authority
- Signer Key Registry Entry — lifecycle amendments under ZEMA-recognised key
  governance
- Methodology Approval Record — ZEMA amendment authority; supersession not
  retroactive

**EXHAUSTIBLE (ZEMA-relevant):**
- Draft MRV Data — 3 years or as ZEMA prescribes; transitions to IMMUTABLE
  upon verified submission
- Pending Transfer Records — superseded by IMMUTABLE settlement record

**Regime-specific replay requirement:** ZEMA must be able to independently
re-verify any credit issuance, transfer, retirement, or ITMO authorisation
at any point within the credit's constitutional lifetime and beyond, without
dependence on Symphony's runtime availability.

---

### 2.2 Bank of Zambia (BoZ)
**Domain:** Green finance prudential oversight; financial system integrity;
AML/KYC compliance; SI 5 of 2026 / ZGFT

BoZ requires Symphony to maintain the following artifact classes under its
prudential and green finance supervisory authority:

**IMMUTABLE (BoZ-binding):**
- BoZ Green Finance Linkage Record — minimum 10 years post-instrument-maturity;
  permanent where linked to ITMO; prudential audit survivability is non-negotiable
- Asset Batch Attestation Record (Wave 8) — permanent; Wave 8 is the
  authoritative financial transaction boundary; BoZ cannot accept settlement
  finality claims whose provenance trace is incomplete
- Retirement Record (where linked to green finance) — permanent; ESG and
  green bond verification requires retirement chain integrity

**TOMBSTONE-ONLY (BoZ-binding):**
- Participant Identity Record — ZDPA erasure right applies to raw PII only
  after BoZ AML retention floor (minimum 5 years from relationship end);
  identity_hash and structural records remain intact
- KYC Document Reference — tombstonable after floor; document reference fields
  removed; compliance decision record intact

**MUTABLE-CONTROLLED (BoZ-binding):**
- Participant Classification Record — BoZ reclassification authority
- Green Finance Instrument Classification — ZGFT taxonomy amendments under
  BoZ/SI 5 authority
- Signer Key Registry Entry — key lifecycle amendments

**EXHAUSTIBLE (BoZ-relevant):**
- Session and Authentication Audit Logs — 5-year floor (AML); purge after floor
- Pending Transfer Records — superseded by IMMUTABLE settlement record

**Regime-specific replay requirement:** BoZ must be able to independently
re-verify the cryptographic integrity of all green finance-linked carbon asset
records using Symphony's published canonical schema and key registry, without
access to Symphony's application runtime.

---

### 2.3 Zambia Data Protection Authority (ZDPA)
**Domain:** Personal data sovereignty; erasure rights; cross-border data transfer
restrictions; data minimisation

ZDPA imposes the only regime within Symphony's constitutional architecture that
creates a positive right of deletion (erasure right). This right is constitutionally
bounded by the immutability obligations of other regimes. The constitutional
resolution is: **erasure right applies to identity data only, via tombstoning,
after all other regimes' retention floors have been satisfied.**

**TOMBSTONE-ONLY (ZDPA-governed):**
- Participant Identity Record — primary ZDPA surface; raw PII tombstonable
  after all retention floors satisfied; identity_hash remains; no IMMUTABLE
  artifact may be structurally damaged by the tombstoning
- Project Developer Identity Reference — tombstonable under same conditions
- Authentication Credential Record — tombstonable after session expiry plus floor
- KYC Document Reference — tombstonable after BoZ AML floor

**EXHAUSTIBLE (ZDPA-governed):**
- Session and Authentication Audit Logs — 3-year floor (standard); purge permitted
  after floor; raw PII within logs tombstoned before purge
- Operational Runtime Logs — 2-year floor; raw PII minimised by design;
  purge after floor

**ZDPA does NOT govern:**
- Evidentiary data, provenance data, replay data, or cryptographic lineage.
  These are constitutionally exempt from erasure rights by virtue of the
  immutable evidentiary carve-out established in DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md.
- The content of ITMO Transfer Authorisation Records, Corresponding Adjustment
  Records, or Credit Issuance Records, even where those records carry an
  identity_hash.

**Regime-specific ZDPA constraint:** Every Symphony schema change that touches
participant-identifying fields must be evaluated against the tombstoning
protocol. No schema change may make it impossible to tombstone a participant
identity without degrading the structural integrity of an IMMUTABLE referencing
record.

---

### 2.4 ZICTA (Zambia Information and Communications Technology Authority)
**Domain:** Digital service licensing; ICT infrastructure compliance; cybersecurity
obligations; data localisation

**MUTABLE-CONTROLLED (ZICTA-binding):**
- ZICTA Digital Service Registration Record — ZICTA amendment authority;
  effective dates must be preserved

**EXHAUSTIBLE (ZICTA-binding):**
- Operational Runtime Logs — 2-year floor; ZICTA may specify longer floor
  for licensed digital service providers
- Session and Authentication Audit Logs — aligned with BoZ floor where
  intersection exists; ZICTA floor applies where BoZ floor does not
- API Rate Limit and Throttle Records — 90 days; no carbon admissibility
  implications
- Operational Cache Records — session lifetime maximum

**ZICTA data localisation constraint:** To the extent ZICTA imposes data
localisation requirements on Symphony as a licensed Zambian digital service
provider, those requirements apply to EXHAUSTIBLE and MUTABLE-CONTROLLED
artifacts within Zambia's jurisdiction. They do not override the IMMUTABLE
classification of evidentiary artifacts — the immutability obligation governs
where both apply. Where localisation and international treaty replay
obligations conflict (e.g., ITMO records must be verifiable by foreign Party
states), the treaty obligation governs subject to
CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.

---

### 2.5 Verra (VCS)
**Domain:** Voluntary carbon standard methodology; credit verification; VCS
registry; double-counting prevention

**IMMUTABLE (Verra-binding):**
- Originating MRV Record — VCS methodology compliance is permanently
  reviewable
- Carbon Credit Issuance Record — VCS registry issuance is a permanent
  evidentiary fact; Symphony's record must be independently verifiable
  against the Verra registry record
- Third-Party Verification Attestation — Verra-accredited verifier attestations
  are permanently binding; verifier accreditation status at time of attestation
  must be replayable
- Methodology Version Binding Record — VCS methodology versioning is permanent;
  the approved methodology version operative at issuance governs that credit
  permanently
- Retirement Record — double-counting prevention is permanent; retirement chain
  must be unbroken and independently verifiable against Verra's registry
- Credit Cancellation Record — Verra cancellation events are permanent registry
  facts

**MUTABLE-CONTROLLED (Verra-binding):**
- Methodology Approval Record — Verra methodology supersession is controlled;
  prior versions preserved
- Signer Key Registry Entry — key lifecycle governance

**Regime-specific replay requirement:** Verra-issued credits within Symphony
must support independent reconciliation with the Verra registry at any future
audit interval without requiring access to Symphony's operational runtime.
Symphony's record and the Verra registry record are independently admissible
and independently replay-obligated — neither is authoritative over the other
for double-counting purposes.

---

### 2.6 Gold Standard
**Domain:** GS4GG methodology; SDG co-benefit certification; Impact Registry;
independent verification body approval

**IMMUTABLE (Gold Standard-binding):**
- Originating MRV Record — GS4GG methodology compliance including SDG
  co-benefit assessment basis is permanently reviewable
- Carbon Credit Issuance Record — Gold Standard Impact Registry issuance
  record is permanent; Symphony's record must be independently verifiable
  against the Impact Registry
- Third-Party Verification Attestation — Gold Standard Approved Validator
  attestation is permanently binding; Validator identity and accreditation
  at time of validation must be replayable
- Methodology Version Binding Record — GS4GG methodology version and SDG
  co-benefit assessment version both permanently bound to the credit event
- Retirement Record — permanent; Impact Registry retirement reconciliation
- Credit Cancellation Record — permanent

**MUTABLE-CONTROLLED (Gold Standard-binding):**
- Methodology Approval Record — GS4GG supersession controlled; prior
  versions preserved

**Regime-specific note:** Gold Standard's SDG co-benefit record is an
artifact class with no equivalent in Verra VCS. It must not be treated
as equivalent to Verra's methodology provenance record. It is a distinct
IMMUTABLE artifact class within the Gold Standard domain.

---

### 2.7 EU CBAM
**Domain:** Embedded carbon quantification; EU customs admissibility; declarant
authority; scope classification

**IMMUTABLE (EU CBAM-binding):**
- EU CBAM Embedded Carbon Declaration — immutable from date of declaration;
  EU customs admissibility requires that declarations survive EU administrative
  proceedings without dependence on Symphony's runtime
- Asset Batch Attestation Record (Wave 8) — permanent; the Wave 8
  cryptographic boundary provides the proof surface for EU CBAM auditors
  verifying the embedded carbon quantification chain
- Methodology Version Binding Record — EU CBAM's embedded carbon quantification
  methodology is distinct from ZEMA/Verra/GS methodologies; its version binding
  is independently immutable

**MUTABLE-CONTROLLED (EU CBAM-binding):**
- Participant Classification Record — declarant authorisation status is
  mutable-controlled; reclassification not retroactive

**Exhaustible (EU CBAM-relevant):**
- Pending Transfer Records — superseded by IMMUTABLE settlement record

**Regime-specific replay requirement:** EU CBAM declarations must be
independently verifiable by EU customs authority at any point within the
5-year EU statutory period (subject to regulation revision) without access
to Symphony's runtime. The canonical evidence payload must be self-proving.

---

### 2.8 Paris Agreement Article 6
**Domain:** Sovereign ITMO transfers; NDC accounting; corresponding adjustments;
first-transfer sovereign provenance; UNFCCC reporting

**IMMUTABLE (Article 6-binding — most stringent retention class):**
- ITMO Transfer Authorisation Record — permanent and treaty-obligated; must
  survive all future UNFCCC reporting cycles, Global Stocktake events, and
  sovereign disputes between Parties
- Corresponding Adjustment Record — permanent; Zambia's NDC accounting
  integrity is constitutionally dependent on this record
- Originating MRV Record — permanent; Article 6 admissibility requires that
  the mitigation event underlying every ITMO be independently verifiable at
  any future UNFCCC review
- Carbon Credit Issuance Record — permanent; first-transfer sovereign
  provenance requires unbroken issuance-to-transfer chain
- Retirement Record — permanent; prevention of double use across NDCs requires
  permanent retirement chain
- Third-Party Verification Attestation — permanent; Article 6 quality
  standards require that verification be independently verifiable
- Asset Batch Attestation Record (Wave 8) — permanent; the cryptographic
  enforcement boundary is the constitutional proof surface for Article 6
  counterparty verification
- Methodology Version Binding Record — permanent; UNFCCC methodological
  guidance version operative at activity time governs permanently

**ZEMA–Article 6 intersection:** The ITMO Transfer Authorisation Record
satisfies both ZEMA admissibility obligations and Article 6 admissibility
obligations. These are two independent obligations that the same record must
satisfy. The satisfaction of one does not constitute satisfaction of the
other. Each regime's requirements must be independently provable from the
same canonical payload.

**Regime-specific replay requirement:** Receiving Party states (counterparty
governments) must be able to independently replay-verify the entire provenance
chain of any ITMO — from originating MRV event through ZEMA authorisation
through international transfer — without access to Symphony's runtime.
Counterparty state independence is constitutionally guaranteed by
EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md.

---

## Part III: Cross-Regime Conflict Resolution for Artifact Retention

Where two regimes impose conflicting retention obligations on the same artifact,
the following priority ordering governs:

1. **Treaty obligation supersedes national statute.** Article 6 ITMO
   records carry permanent treaty-level retention obligations that supersede
   any national statutory retention limit, including ZDPA erasure timelines.

2. **Immutability supersedes erasure right.** A valid ZDPA erasure request
   may not be applied to the evidentiary, provenance, replay, or cryptographic
   lineage data classes. It applies to identity data only, via tombstoning.

3. **Longer retention floor supersedes shorter.** Where BoZ imposes a
   5-year AML floor and ZDPA permits 3-year retention, the 5-year floor
   governs. Erasure right may not be exercised until the longer floor expires.

4. **Regime-specific floor supersedes general floor.** Where a specific
   regulatory instrument prescribes a retention period for a specific artifact
   class, that period supersedes any general default retention period.

5. **IMMUTABLE supersedes all retention conflict resolution.** An artifact
   classified as IMMUTABLE carries no retention expiry. No conflict resolution
   mechanism may establish a deletion date for an IMMUTABLE artifact.

---

## Part IV: Tombstoning Protocol Summary

A tombstoning event is constitutionally valid when:

1. The artifact being tombstoned is classified as TOMBSTONE-ONLY for the
   applicable identity data fields.
2. All applicable retention floors have been verified as expired or the
   tombstoning is triggered by a valid ZDPA erasure right exercised after
   floor expiry.
3. The tombstone declaration is recorded as a constitutionally admitted
   governance event, naming: the tombstoned field(s), the triggering right
   or event, the timestamp, and the authority exercising the tombstoning.
4. The identity_hash (salted cryptographic hash of the original identity
   content) replaces the raw PII fields — it does not delete the structural
   position.
5. A replay verification test confirms that the IMMUTABLE records referencing
   the tombstoned artifact continue to pass replay verification through the
   tombstone.
6. The tombstoning event itself is recorded in an IMMUTABLE governance log.

A tombstoning event is constitutionally invalid and must be refused when:

1. The artifact's identity data is within a regulatory retention floor.
2. The tombstoning would degrade the structural integrity of any IMMUTABLE
   artifact's replay chain.
3. The tombstoning is requested for a data field classified as IMMUTABLE
   rather than TOMBSTONE-ONLY.
4. No tombstone declaration record would be produced (silent deletion
   presented as tombstoning).

---

## Prohibited Misinterpretations

### P1: Treating EXHAUSTIBLE as freely deletable without floor verification
Exhaustible artifacts carry a defined retention floor. Deletion before that
floor constitutes a constitutional violation. The absence of ongoing operational
use does not lower or eliminate the retention floor.

### P2: Treating TOMBSTONE-ONLY as equivalent to deletion
A tombstone replaces identity content with a cryptographic null-substitute
while preserving structural position, hash commitment, and chain linkages.
Tombstoning is not deletion. An artifact that has been tombstoned continues
to exist as a constitutional record.

### P3: Applying ZDPA erasure right to evidentiary, provenance, or replay data
The ZDPA erasure right applies to identity data only. It does not apply to
records of regulated events, credit issuances, retirements, ITMO transfers,
corresponding adjustments, verification attestations, or cryptographic
signing events. Applying erasure to these classes constitutes replay destruction
and is a Priority 1 constitutional violation.

### P4: Treating MUTABLE-CONTROLLED as freely editable
A MUTABLE-CONTROLLED artifact may only be amended through a declared amendment
event that preserves the prior version. In-place overwriting without an amendment
declaration is constitutionally prohibited regardless of operational convenience.

### P5: Assuming one regime's retention obligation satisfies all regimes
Each regime's retention obligation is independently binding. A 5-year BoZ
floor does not satisfy Article 6's permanent retention obligation. A ZEMA
retention compliance certificate does not constitute Verra or Gold Standard
retention compliance. Regimes are orthogonal in their retention obligations.

### P6: Treating draft MRV data as having the same status as submitted MRV data
Draft MRV data (pre-verification, pre-submission) is EXHAUSTIBLE. Submitted,
verified, and accepted MRV data is IMMUTABLE. The constitutional status change
occurs at the moment of verification acceptance. The transition is irrevocable.

### P7: Treating structural completeness of a tombstone as evidence invalidation
A correctly executed tombstone that replaces raw PII fields with identity_hash
while preserving all chain linkages does not invalidate the referencing IMMUTABLE
evidence record. The evidence record's admissibility is determined by the
integrity of its cryptographic structure, not by the human-readability of
identity fields within it.

---

## Constitutional Self-Validation

### Sovereignty Domains Governed
This document governs the mutability and retention classification of artifacts
produced by or consumed within Symphony's MRV sovereign substrate across all
seven named regulatory regimes and ZICTA.

### Sovereignty Domains This Document MUST NOT Redefine
- Root constitutional doctrine (Rank 10).
- Replay primacy doctrine (REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md, Rank 10).
- Wave sovereignty posture for Wave 4 and Wave 8 (Rank 9).
- The constitutional substrate state model (CONSTITUTIONAL_SUBSTRATE_STATE_MODEL.md, Rank 9).
- The constitutional priority ordering (CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, Rank 10).
- The non-inference and interpretation limits (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, Rank 10).

### Replay Obligations Preserved
This document preserves the permanent replay obligations of all IMMUTABLE
artifact classes across all regulatory regimes. It prohibits replay-destructive
deletion, replay-degrading tombstoning, and any operational act that would make
an IMMUTABLE record non-replayable.

### Regulator Boundaries That Constrain This Document
- REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md: each regime's retention
  obligations are independently binding; this document does not collapse them.
- DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md (Rank 9): this document operates
  as a regime-specific application of that doctrine; it may not reduce the
  protections established there.
- CARBON_ASSET_LIFECYCLE_CONSTITUTION.md (Rank 9): this document's IMMUTABLE
  classifications are consistent with and subordinate to the lifecycle
  admissibility model established there.

### Phases to Which This Document Applies
Global. The artifact classifications are phase-independent. Draft MRV data
(EXHAUSTIBLE) transitions to IMMUTABLE upon verification acceptance regardless
of the constitutional phase in which that transition occurs.

### Constitutional Layers Possessing Override Authority
Root constitutional doctrine (Rank 10) and Wave sovereignty doctrine (Rank 9)
possess unconditional override authority over this document.

### Lower-Layer Documents Prohibited From Reinterpretation
Migration records, enforcement surfaces, operational procedures, audit logging
policies, purge runbooks, and analytical syntheses may not reclassify any
artifact from a more protective category (IMMUTABLE, TOMBSTONE-ONLY) to a
less protective category (MUTABLE-CONTROLLED, EXHAUSTIBLE) without a
constitutional amendment under CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.
