# DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md

---

**Constitutional-Status:** AUTHORITATIVE  
**Interpretation-Authority:** ROOT  
**NotebookLM-Ingestion:** CANONICAL  
**Authority-Rank:** 9  
**Phase-Scope:** GLOBAL  
**Supersedes:** Any operational data retention policy, SaaS-tier retention configuration, or runtime-layer deletion rule that purports to govern evidentiary or provenance data classes within Symphony.  
**Depends-On:**  
- `SOVEREIGNTY_ARCHITECTURE_DOCTRINE.md`  
- `REPLAY_SURVIVABILITY_DOCTRINE.md`  
- `REGULATOR_PARTITIONING_DOCTRINE.md`  
- `PROVENANCE_INDEPENDENCE_DOCTRINE.md`  
- `PHASE_LEGALITY_DOCTRINE.md`  
- `CRYPTOGRAPHIC_LINEAGE_DOCTRINE.md`

---

## 1. Purpose

This document establishes the constitutional doctrine governing data sovereignty, evidentiary retention, right-to-forget legality, immutable evidence carve-outs, regulator escrow retention, cryptographic tombstoning, redactable identity models, replay survivability, and jurisdictional retention conflict resolution within Symphony.

Symphony is a sovereign constitutional trust coordination platform serving the following regulatory and treaty domains:

- **Zambia SI 5 of 2026** — domestic statutory instrument establishing digital financial infrastructure obligations;
- **ZGFT** (Zambia Green Finance Taxonomy) — sovereign green finance classification authority;
- **BoZ** (Bank of Zambia) — central bank prudential and green finance supervisory authority;
- **ZEMA** (Zambia Environmental Management Agency) — national carbon market and environmental credit authority;
- **Paris Agreement Article 6 ITMOs** — international transfer of mitigation outcomes under UNFCCC treaty obligations;
- **Gold Standard** — independent carbon credit certification and registry authority;
- **Verra / VCS** — independent carbon credit verification and registry authority;
- **EU CBAM** (Carbon Border Adjustment Mechanism) — European Union carbon tariff and admissibility authority.

Retention within Symphony is not a data management policy. It is sovereign evidentiary continuity infrastructure. Deletion decisions within Symphony carry constitutional-grade consequences for admissibility, replay integrity, regulator audit survivability, and treaty compliance.

---

## 2. Constitutional Scope

This doctrine governs:

1. The classification of all data types within Symphony according to constitutional retention categories.
2. The legal boundaries of erasure, redaction, tombstoning, and immutable preservation for each data class.
3. The resolution hierarchy for conflicts between Zambia Data Protection Act erasure rights and evidentiary replay obligations.
4. The preservation obligations owed to each regulator sovereign domain.
5. The conditions under which cryptographic lineage may not be altered, even upon lawful identity deletion.
6. The replay obligations that survive all deletion events without exception.
7. The admissibility continuity requirements binding all retention decisions across all phases.

---

## 3. Constitutional Data Classification

Symphony recognises six constitutionally distinct data classes. Each class carries independent retention rules, deletion permissions, and replay obligations. These classes are not interchangeable and must not be collapsed.

### 3.1 Identity Data

**Definition:** Personal or organisational identifiers that establish the acting party within a transaction or event record, including names, registration numbers, wallet addresses linked to natural persons, KYC artefacts, and authentication credentials.

**Governed by:** Zambia Data Protection Act; BoZ KYC/AML obligations; SI 5 of 2026 participant registration requirements.

**Deletion permission:** Conditionally permitted subject to Section 6 conflict resolution rules.

**Redaction permission:** Permitted under cryptographic tombstoning protocol (see Section 7).

**Replay obligation:** Identity data is NOT independently replayable. Replay of evidentiary and provenance records must survive identity deletion through tombstone substitution without loss of structural integrity.

**Retention floor:** Identity data must be retained for the minimum period required by BoZ AML regulations and SI 5 of 2026, irrespective of Data Protection Act erasure requests received prior to expiry of that floor.

---

### 3.2 Evidentiary Data

**Definition:** Records that constitute proof of a regulated event, transaction, credit issuance, retirement, transfer, or compliance assertion, including signed transaction logs, credit issuance certificates, retirement confirmations, ITMO transfer records, CBAM declarations, and audit attestations.

**Governed by:** All regulator sovereign domains enumerated in Section 1; Paris Article 6 treaty obligations; UNFCCC reporting standards; EU CBAM Regulation.

**Deletion permission:** **Prohibited.** Evidentiary data is constitutionally immutable within Symphony. No deletion, overwrite, or expiry mechanism may be applied to evidentiary data regardless of the source of the deletion instruction.

**Redaction permission:** Prohibited as to substantive content. Permitted only as to identity linkage fields subject to tombstoning protocol (Section 7), provided the evidentiary record remains structurally and cryptographically intact.

**Replay obligation:** All evidentiary data must remain permanently replayable across all phases and all regulatory time horizons, including post-operational phases and external verifier reconstruction scenarios.

**Admissibility obligation:** Evidentiary data must maintain unbroken cryptographic lineage from originating event to current state, across all substrate generations, wave transitions, and runtime migrations.

---

### 3.3 Provenance Data

**Definition:** Records that establish the origin, custody chain, transformation history, and certification lineage of evidentiary data, including issuer signatures, methodology version records, validation attestations, inter-registry transfer proofs, and cryptographic hash chains linking successive states.

**Governed by:** Wave 8 provenance sovereignty; Gold Standard, Verra, and Article 6 certification requirements; BoZ audit trail obligations.

**Deletion permission:** **Prohibited.** Provenance data constitutes the constitutional lineage of evidentiary records. Its destruction renders evidentiary data inadmissible.

**Redaction permission:** Prohibited. Provenance data must remain fully intact. No element of a provenance chain may be selectively removed without rendering the chain invalid.

**Replay obligation:** Provenance data must be reconstructible from regulator-side escrow in the event of Symphony operational substrate failure or wave transition. External verifier independence must be preserved across all provenance records.

---

### 3.4 Replay Data

**Definition:** The structured dataset required to reconstruct any prior constitutional state of Symphony from durable storage, including event sequence logs, state transition records, cryptographic anchors, and regulator partition snapshots sufficient to satisfy replay survivability obligations.

**Governed by:** Replay Survivability Doctrine; all regulator domains with historical audit rights.

**Deletion permission:** **Prohibited.** Replay data is constitutional permanence infrastructure. Its deletion constitutes destruction of Symphony's capacity to satisfy treaty-level and regulatory audit obligations.

**Redaction permission:** Prohibited as to structural content. Identity-linked fields within replay data must be tombstoned rather than deleted (Section 7), preserving replay structural integrity.

**Replay obligation:** Replay data must be maintained in a state from which any designated prior constitutional moment can be fully reconstructed without dependency on runtime substrate availability.

---

### 3.5 Regulator-Preserved Data

**Definition:** Data classes designated by individual regulator sovereign domains for mandatory retention under their jurisdictional authority, including BoZ prudential records, ZEMA environmental credit ledgers, Article 6 ITMO transfer registers, CBAM declaration archives, and Gold Standard/Verra registry synchronisation records.

**Governed by:** Each regulator's sovereign retention mandate. Regulator-preserved data is partitioned; one regulator's retention authority does not override another regulator's retention authority.

**Deletion permission:** **Prohibited** as to any data within an active regulator retention mandate. Deletion may only occur after unanimous expiry of all applicable regulator retention periods, subject to evidentiary and provenance class rules which independently prohibit deletion regardless of regulator period expiry.

**Redaction permission:** Governed by regulator-specific protocol. Cross-regulator redaction decisions are prohibited without bilateral consent of all affected regulators.

**Replay obligation:** Each regulator sovereign domain must possess the capacity to replay its designated data partition independently of other regulator domains and independently of Symphony operational runtime.

---

### 3.6 Operational Runtime Data

**Definition:** Transient processing state, session context, queue intermediaries, and computational artefacts generated during Symphony operation that do not constitute evidentiary, provenance, replay, or regulator-preserved records.

**Governed by:** Operational sovereignty of Wave 4; SI 5 of 2026 operational compliance standards.

**Deletion permission:** Permitted, subject to confirmation that the data does not contain or reference evidentiary, provenance, replay, or regulator-preserved content. Deletion of operational runtime data that encapsulates or derives from protected data classes is prohibited.

**Redaction permission:** Permitted within operational scope.

**Replay obligation:** None, unless operational runtime data has been designated as replay anchor material by the Replay Survivability Doctrine.

---

## 4. Authority Boundaries

### 4.1 Wave Sovereignty Over Retention

- **Wave 4 (Operational/Runtime Sovereignty):** Governs operational runtime data retention. Wave 4 possesses no authority to delete, redact, or modify evidentiary, provenance, replay, or regulator-preserved data.
- **Wave 8 (Provenance/Cryptographic Sovereignty):** Governs the cryptographic integrity of provenance chains and replay anchors. Wave 8 deletion authority is constitutionally prohibited. Wave 8 defines tombstoning protocol semantics.

### 4.2 Phase Authority Over Retention

Each phase operates within constitutionally defined capability boundaries. No phase possesses authority to:

- Delete evidentiary data on behalf of a subsequent phase;
- Retroactively reclassify evidentiary or provenance data as operational runtime data;
- Transfer deletion authority across phase boundaries;
- Assert that phase completion terminates retention obligations for records created within that phase.

Phase completion does not extinguish retention obligations. Records created within any phase remain subject to their constitutional data class rules for the full duration of those rules, irrespective of phase lifecycle status.

### 4.3 Regulator Authority Over Retention

Each regulator sovereign domain exercises independent retention authority over its designated data partition. No regulator possesses authority to:

- Order deletion of another regulator's partition;
- Override evidentiary or provenance class immutability rules;
- Assert erasure rights on behalf of data subjects against regulator-preserved data without bilateral consent of all affected regulators and compliance with the conflict resolution rules of Section 6.

---

## 5. Veto Semantics

The following veto hierarchy governs all retention decisions:

| Veto Level | Authority | Scope |
|---|---|---|
| Level 1 (Absolute) | Evidentiary Immutability | Prohibits deletion or substantive redaction of evidentiary data under any instruction |
| Level 2 (Absolute) | Provenance Immutability | Prohibits any modification to provenance chains |
| Level 3 (Absolute) | Replay Preservation | Prohibits deletion of replay data or replay anchor material |
| Level 4 (Jurisdictional) | Regulator Partition Authority | Prohibits cross-regulator deletion without bilateral consent |
| Level 5 (Conditional) | Retention Floor Compliance | Prohibits identity data deletion prior to expiry of mandatory retention floors |
| Level 6 (Permitted) | Operational Runtime Management | Permits operational data deletion subject to Levels 1–5 |

No instruction, order, or process may override a higher-level veto. Data Protection Act erasure requests operate at Level 5 or below and are constitutionally incapable of overriding Levels 1–4.

---

## 6. Constitutional Conflict Resolution: Erasure Rights vs. Evidentiary Replay Obligations

### 6.1 The Constitutional Conflict

The Zambia Data Protection Act confers upon data subjects the right to request erasure of personal data held by a data processor. Symphony, as a sovereign evidentiary platform, holds identity data linked to evidentiary, provenance, and replay records that are constitutionally immutable.

This creates a direct constitutional conflict between:

- **Erasure right:** The data subject's right to deletion of personal identity data; and
- **Evidentiary replay obligation:** Symphony's constitutional obligation to maintain permanently replayable, cryptographically intact records for regulatory and treaty admissibility.

### 6.2 Resolution Doctrine

This conflict is resolved as follows:

**Rule 6.2.1 — Identity-Evidentiary Separation Principle:**  
Identity data and evidentiary data are constitutionally distinct. An erasure right applies to identity data. It does not apply to, and cannot be extended to affect, evidentiary data, provenance data, replay data, or regulator-preserved data.

**Rule 6.2.2 — Tombstone Substitution Mandate:**  
Upon a lawful and procedurally valid erasure request, Symphony shall apply cryptographic tombstoning (Section 7) to identity-linked fields within evidentiary and provenance records. The evidentiary record survives intact. The identity linkage is replaced with a cryptographically sealed tombstone reference. The evidentiary record remains admissible, replayable, and structurally complete.

**Rule 6.2.3 — Retention Floor Supremacy:**  
Where BoZ AML regulations, SI 5 of 2026, or other statutory instruments impose a mandatory minimum retention period on identity data, erasure requests received prior to expiry of that period are not actionable during the retention floor period. Processing of the erasure request is suspended until the retention floor expires, at which point tombstoning is applied.

**Rule 6.2.4 — Regulator Consent Requirement:**  
Where identity data forms part of a regulator-preserved data partition, erasure by tombstoning requires the consent of the relevant regulator sovereign domain before tombstoning is applied to that partition. Absence of consent suspends the erasure pending regulator determination.

**Rule 6.2.5 — Treaty Obligation Supremacy:**  
Where identity data is embedded in Article 6 ITMO transfer records, EU CBAM declarations, or other treaty-level instruments, erasure of identity data is permissible only through tombstoning, and only where tombstoning can be demonstrated not to impair the admissibility of the underlying instrument under the applicable treaty or regulatory framework. Where such demonstration cannot be made, erasure is suspended pending resolution.

**Rule 6.2.6 — Non-Retroactivity:**  
Erasure applied through tombstoning operates prospectively on the identity linkage. It does not alter, invalidate, or retroactively modify the evidentiary content of any record created prior to the tombstoning event.

---

## 7. Cryptographic Tombstoning Protocol

### 7.1 Definition

Cryptographic tombstoning is the constitutionally authorised mechanism for satisfying identity erasure obligations within Symphony without destroying evidentiary, provenance, or replay integrity.

### 7.2 Tombstoning Operation

A tombstoning operation:

1. Identifies all identity-linked fields within affected records across all constitutional data classes;
2. Replaces the identity data with a cryptographically sealed tombstone marker containing: (a) a hash of the deleted identity data, (b) the timestamp of tombstoning, (c) the legal authority citation for the tombstoning event, and (d) the tombstoning authority identifier;
3. Appends a tombstone event record to the evidentiary audit log, constituting an immutable record of the erasure event itself;
4. Preserves all non-identity fields of the affected records without modification;
5. Recomputes and updates all cryptographic signatures and hash chains to reflect the tombstoned state, maintaining lineage integrity through the tombstoning event.

### 7.3 Tombstoning Constraints

- Tombstoning is not deletion. The evidentiary record survives.
- Tombstoning is irreversible. The tombstone marker cannot be used to reconstruct the deleted identity data.
- Tombstoning does not affect replay obligations. Records containing tombstone markers remain fully replayable.
- Tombstoning events are themselves evidentiary data and are permanently retained.
- Tombstoning cannot be applied to provenance chain structural fields. It may only be applied to identity-linked metadata fields that do not form part of the cryptographic lineage structure itself.

### 7.4 Redactable Identity Model

Symphony implements a redactable identity model in which:

- Identity layer fields are architecturally separated from evidentiary and provenance layer fields at the record structure level;
- This separation is enforced at the data schema layer across all waves and phases;
- Redaction of the identity layer does not propagate to the evidentiary or provenance layers;
- All regulator sovereign domains receive evidentiary and provenance data in a form that does not require identity data to establish admissibility.

---

## 8. Regulator Escrow Retention

### 8.1 Escrow Obligation

Each regulator sovereign domain enumerated in Section 1 is entitled to a designated escrow retention partition containing:

- All evidentiary data within that regulator's jurisdictional scope;
- All provenance data supporting that evidentiary data;
- All replay anchor data sufficient to reconstruct the regulator's evidentiary view at any designated prior constitutional moment;
- Tombstone event records affecting records within the regulator's partition.

### 8.2 Escrow Independence

Regulator escrow partitions are operationally independent of Symphony's runtime substrate. Escrow retention is not contingent on Symphony operational availability. Regulator-side replay reconstruction must be achievable from escrow alone.

### 8.3 Escrow Retention Periods

| Regulator Domain | Minimum Escrow Retention Period |
|---|---|
| BoZ | As mandated by current BoZ prudential regulations, not less than 7 years |
| ZEMA | As mandated by current ZEMA environmental credit regulations |
| Article 6 / ITMO | Permanently, subject to UNFCCC treaty obligations |
| Gold Standard | As mandated by Gold Standard registry rules |
| Verra / VCS | As mandated by Verra registry rules |
| EU CBAM | As mandated by EU CBAM Regulation |
| SI 5 of 2026 | As mandated by current statutory instrument provisions |
| ZGFT | As mandated by current ZGFT taxonomy governance rules |

No regulator escrow partition may be purged, archived offline without retrieval capability, or rendered inaccessible without the explicit constitutional authorisation of the applicable regulator sovereign domain.

---

## 9. Article 6 Historical Replay Obligations

### 9.1 Permanent Replayability Mandate

All records relating to Article 6 ITMO issuance, transfer, cancellation, retirement, or corresponding adjustment are subject to permanent replayability obligations. There is no expiry of this obligation.

### 9.2 Corresponding Adjustment Integrity

The corresponding adjustment records of any Zambian ITMO transfer must remain replayable in a state that permits independent verification of:

- The originating mitigation outcome;
- The authorisation chain;
- The transfer chain;
- The corresponding adjustment applied to Zambia's national determined contribution accounting;
- The acquiring party's authorised use.

### 9.3 External Verifier Independence

External verifiers designated under Article 6 treaty mechanisms must be capable of reconstructing the full ITMO provenance chain from Symphony escrow without dependency on Symphony operational runtime, ZGFT operational systems, or BoZ operational systems.

---

## 10. BoZ Retention Survivability

BoZ's evidentiary and prudential retention obligations survive:

- Symphony operational substrate migration;
- Wave transitions;
- Phase completions;
- System decommissioning events;
- Ownership or governance changes to Symphony's operating entity.

BoZ retention survivability is guaranteed through the regulator escrow partition defined in Section 8. BoZ's capacity to reconstruct its regulatory view from escrow is a constitutional obligation of Symphony, not a feature contingent on operational continuity.

---

## 11. Jurisdictional Retention Conflict Resolution

Where two or more regulator sovereign domains assert conflicting retention obligations over the same data record (for example, where one domain mandates retention and another mandates deletion), the following resolution hierarchy applies:

**Rule 11.1 — Immutability Class Supremacy:**  
Evidentiary and provenance data class rules (Sections 3.2 and 3.3) override all jurisdictional retention conflicts. No jurisdictional deletion order may be applied to evidentiary or provenance data.

**Rule 11.2 — Longest Retention Period Governs Identity and Operational Data:**  
For identity and operational runtime data subject to multiple jurisdictional retention mandates, the longest mandatory retention period among all applicable jurisdictions governs. Deletion may not occur until all jurisdictional retention floors have expired.

**Rule 11.3 — Treaty Obligation Supremacy Over Domestic Orders:**  
Retention obligations arising from Paris Agreement Article 6 and EU CBAM treaty instruments take precedence over domestic deletion orders to the extent that the domestic order would impair treaty-level admissibility or compliance.

**Rule 11.4 — Bilateral Consent for Cross-Regulator Tombstoning:**  
Where tombstoning of identity data in a record that falls within multiple regulator partitions is sought, the consent of all affected regulator sovereign domains is required before tombstoning is applied.

**Rule 11.5 — Escalation to Root Authority:**  
Where jurisdictional conflict cannot be resolved by Rules 11.1–11.4, the conflict is escalated to Symphony's Root Interpretation Authority for constitutional determination. Pending determination, no deletion or tombstoning shall occur.

---

## 12. Admissibility Continuity

### 12.1 Admissibility Obligation

Every retention and deletion decision within Symphony must be assessed for its effect on admissibility continuity before execution. A decision that impairs the admissibility of any evidentiary record before any regulator sovereign domain is constitutionally prohibited.

### 12.2 Admissibility Continuity Test

A retention or deletion decision satisfies the admissibility continuity test if and only if:

1. All evidentiary records affected by the decision remain structurally intact;
2. All provenance chains affected by the decision remain cryptographically unbroken;
3. All replay anchor data sufficient to reconstruct affected records remains available;
4. All regulator sovereign domains can independently verify the affected records from their escrow partition following the decision;
5. No treaty-level admissibility obligation is impaired by the decision.

### 12.3 Pre-Execution Validation

No deletion, tombstoning, or redaction event may be executed within Symphony without a pre-execution admissibility continuity validation confirming satisfaction of the test in Section 12.2. The validation result is itself an evidentiary record subject to permanent retention.

---

## 13. Phase Interaction Rules

| Phase | Retention Authority | Prohibited Actions |
|---|---|---|
| All Phases | Evidentiary immutability applies without exception | Deletion or substantive redaction of evidentiary data |
| All Phases | Provenance immutability applies without exception | Any modification to provenance chain fields |
| Phase Completion | Phase lifecycle closure does not alter retention obligations | Purging records on phase completion without class-specific authorisation |
| Wave 4 Phases | Operational runtime data management permitted | Treating evidentiary or provenance data as operational runtime data |
| Wave 8 Phases | Cryptographic lineage maintenance mandatory | Altering hash chains, signature chains, or tombstone records |
| Post-Operational | Regulator escrow must remain independently accessible | Archiving escrow offline without retrieval capability |

---

## 14. Constitutional Glossary References

- **Admissibility Continuity:** The unbroken capacity of an evidentiary record to satisfy the admissibility requirements of its governing regulatory or treaty domain across all temporal and substrate transitions.
- **Constitutional Data Class:** A category of data defined by this doctrine whose retention, deletion, and replay rules derive from sovereign constitutional obligations rather than operational policy.
- **Cryptographic Lineage:** The unbroken chain of cryptographic signatures, hashes, and attestations establishing the origin, custody, and integrity of an evidentiary or provenance record from originating event to current state.
- **Cryptographic Tombstoning:** The constitutionally authorised process of replacing identity data with a sealed marker that satisfies erasure obligations without destroying evidentiary or provenance record integrity.
- **Evidentiary Replay:** The reconstruction of a prior constitutional state of Symphony's evidentiary record from durable storage, independent of operational runtime availability.
- **Non-Collapse Doctrine:** The constitutional prohibition against collapsing distinct sovereignty domains, data classes, regulator authorities, or wave authorities into a unified or simplified governance model.
- **Phase Legality:** The constitutional principle that each phase operates within defined capability boundaries and may not exercise authority beyond those boundaries.
- **Provenance Independence:** The constitutional principle that provenance records derive their authority from originating certification and cryptographic lineage, not from runtime system availability.
- **Regulator Partitioning:** The constitutional principle that each regulator sovereign domain exercises independent authority over its designated data partition without subordination to other regulator domains.
- **Replay Survivability:** The constitutional guarantee that Symphony's evidentiary and provenance records remain reconstructible across all substrate transitions, wave changes, phase completions, and operational failures.
- **Sovereign Orthogonality:** The constitutional principle that distinct sovereignty domains within Symphony operate independently and do not collapse into a hierarchical or unified authority.
- **Tombstone Event Record:** An immutable evidentiary record created by each tombstoning operation, permanently retained, documenting the fact, authority, and scope of the tombstoning event.

---

# Constitutional Self-Validation

## Sovereignty Domains Governed

This doctrine governs:

- Data sovereignty across all constitutional data classes within Symphony;
- Evidentiary retention sovereignty binding all waves, phases, and regulator partitions;
- Identity erasure sovereignty, specifically the intersection of Data Protection Act rights and evidentiary immutability obligations;
- Regulator escrow sovereignty for all domains enumerated in Section 1;
- Cryptographic lineage sovereignty as applied to tombstoning and admissibility continuity.

## Sovereignty Domains This Doctrine Must NOT Redefine

This doctrine must not redefine:

- The operational sovereignty of Wave 4 beyond its lawful authority over operational runtime data;
- The cryptographic sovereignty architecture of Wave 8 beyond tombstoning protocol semantics;
- The independent jurisdictional authority of any regulator sovereign domain;
- The phase capability boundaries defined in the Phase Legality Doctrine;
- The replay architecture defined in the Replay Survivability Doctrine.

## Replay Obligations Preserved

This doctrine preserves the following replay obligations:

- Permanent replayability of all evidentiary data across all phases and all substrate generations;
- Permanent replayability of all Article 6 ITMO records without expiry;
- Regulator-side replay reconstruction capability from escrow, independent of Symphony operational runtime;
- Replay structural integrity of records containing tombstone markers;
- Replay of tombstone event records as evidentiary data.

## Regulator Boundaries That Constrain This Doctrine

- BoZ retention mandates constrain identity data deletion floors;
- ZEMA environmental credit regulations constrain ZEMA partition escrow periods;
- UNFCCC Article 6 treaty obligations constrain ITMO record permanence;
- EU CBAM Regulation constrains CBAM declaration retention;
- Gold Standard and Verra registry rules constrain their respective partition escrow periods;
- SI 5 of 2026 constrains domestic operational retention obligations.

## Phases to Which This Doctrine Applies

This doctrine applies globally across all phases of Symphony without exception. Phase completion does not terminate the application of this doctrine to records created within that phase.

## Constitutional Layers Possessing Override Authority

Override authority over this doctrine is restricted to:

- Root Interpretation Authority, exercisable only upon formal constitutional determination;
- Treaty-level obligations that impose stricter retention requirements than those specified herein, which automatically supersede this doctrine to the extent of the stricter requirement.

No operational layer, runtime layer, wave layer, or phase layer possesses override authority over this doctrine.

## Lower-Layer Documents Prohibited From Reinterpretation

The following are prohibited from reinterpreting any provision of this doctrine:

- Operational data management policies;
- Runtime configuration documents;
- SaaS-tier retention settings or platform defaults;
- Phase-specific operational runbooks;
- Individual regulator engagement protocols that do not expressly carry Root Interpretation Authority;
- Any document below Authority-Rank 9 that addresses data retention, deletion, or erasure.

---

# Prohibited Misinterpretations

## Invalid Simplifications

1. **"Retention policy" equivalence:** This doctrine must not be interpreted as equivalent to a SaaS data retention policy, privacy policy, or data governance framework. It is sovereign evidentiary continuity infrastructure.

2. **"GDPR-style erasure applies uniformly":** The right to erasure does not apply uniformly across all data classes in Symphony. It applies only to identity data, subject to retention floors, regulator consent, and treaty obligations, and is executed exclusively through cryptographic tombstoning.

3. **"Deletion of old records is housekeeping":** No deletion of evidentiary, provenance, replay, or regulator-preserved data constitutes legitimate housekeeping. All such deletion is constitutionally prohibited.

4. **"One retention rule for all data":** Symphony's six constitutional data classes carry independent retention rules. Applying a single retention rule across all data classes violates this doctrine.

## Forbidden Authority Collapses

5. **Wave 4 authority over evidentiary data:** Wave 4 possesses no authority to delete, modify, or reclassify evidentiary, provenance, or replay data. Any assertion of such authority is constitutionally void.

6. **Single regulator retention supremacy:** No regulator sovereign domain possesses authority to order deletion of another regulator's partition or to override evidentiary immutability obligations applicable to records within another domain's jurisdiction.

7. **Data Protection Authority override of evidentiary immutability:** A Data Protection Authority erasure order does not override the evidentiary immutability rules of Sections 3.2 and 3.3. The resolution mechanism is tombstoning, not deletion.

## Replay-Destructive Interpretations

8. **"Erasure satisfies erasure rights and simplifies systems":** Full deletion of identity-linked records to satisfy erasure rights, in place of tombstoning, constitutes replay-destructive erasure and is constitutionally prohibited.

9. **"Replay is only needed during active operation":** Replay obligations persist beyond Symphony operational phases, across substrate migrations, and into post-decommissioning periods for all evidentiary, provenance, and Article 6 data.

10. **"Tombstoning breaks replay":** Tombstoning is designed to preserve replay integrity. A correctly executed tombstoning operation does not impair replay. Claims that tombstoning prevents replay are factually and constitutionally incorrect.

## Regulator-Flattening Interpretations

11. **"All regulators have the same retention rules":** Regulator sovereign domains are orthogonal. Their retention mandates are independent and their periods differ. Applying a single retention period across all regulator partitions violates regulator partitioning doctrine.

12. **"Domestic law overrides treaty obligations":** Where Article 6 ITMO or EU CBAM treaty obligations impose retention requirements that conflict with domestic deletion orders, treaty obligations take precedence to the extent of the conflict as provided in Section 11.3.

## Phase-Illegality Misreadings

13. **"Phase completion terminates retention obligations":** Phase completion is a lifecycle event in Symphony's operational architecture. It does not terminate, reduce, or modify the retention obligations applicable to records created within that phase.

14. **"Inactive phases can have their records purged":** Phase inactivity does not reclassify records created within that phase. Evidentiary records created in any phase retain their constitutional data class classification indefinitely.

## Provenance/Runtime Collapse Interpretations

15. **"Provenance records are operational data":** Provenance records are constitutionally distinct from operational runtime data. They are governed by Wave 8 sovereignty and are immutable. Any reclassification of provenance records as operational data is constitutionally prohibited.

16. **"Cryptographic lineage can be reconstructed after deletion":** Cryptographic lineage cannot be reconstructed after deletion. Lineage destruction is irreversible and permanently impairs admissibility. This is why deletion of provenance data is absolutely prohibited.

17. **"External verifiers can rely on Symphony runtime for provenance":** External verifier independence requires that verifiers can reconstruct provenance from regulator escrow alone. Runtime dependency for provenance verification violates the provenance independence doctrine.

---

*End of DATA_SOVEREIGNTY_AND_RETENTION_DOCTRINE.md*
