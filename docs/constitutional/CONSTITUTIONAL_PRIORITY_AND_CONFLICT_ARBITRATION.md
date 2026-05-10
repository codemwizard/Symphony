# CONSTITUTIONAL PRIORITY AND CONFLICT ARBITRATION

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, CONSTITUTIONAL_GRAPH.md

---

## Purpose

This document defines the constitutional priority ordering applicable when Symphony's obligations conflict. It establishes the precedence rules, arbitration procedures, compromise constraints, and impossibility determinations governing every category of constitutional conflict that may arise within Symphony's operational, evidentiary, sovereign, and regulatory surfaces.

Constitutional conflicts in Symphony are not negotiable tradeoffs to be resolved by implementation convenience, operational preference, or analytical judgment. They are constitutional questions with deterministic answers derived from the priority ordering defined herein. Where this document establishes that a conflict is impossible to compromise — that is, where satisfying one obligation necessarily destroys the constitutional validity of another — that determination is final. No lower-rank artifact, operational decision, or analytical synthesis may override it.

---

## Constitutional Scope

This document governs:

1. The priority ordering of all classes of Symphony constitutional obligation.
2. The conflict resolution rules applicable when obligations of different priority classes are simultaneously present and cannot both be fully satisfied.
3. The admissibility-preserving arbitration procedures required to ensure that conflict resolution does not produce inadmissible constitutional outcomes.
4. The replay-safe compromise constraints that bound all conflict resolution decisions.
5. The regulator coexistence arbitration rules applicable when obligations arising from distinct regulator domains are in apparent tension.
6. The sovereignty-boundary preservation requirements applicable in all conflict scenarios.
7. The explicit determination of impossible compromise scenarios — cases where constitutional obligations cannot be jointly satisfied and the lower-priority obligation must yield without remainder.

This document does NOT govern:

- The internal operational procedures by which enforcement surfaces implement priority ordering during runtime.
- The specific amendment procedures for constitutional doctrine, which are governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.
- The authority rank of specific artifact classes, which is governed by CONSTITUTIONAL_AUTHORITY_HIERARCHY.md.

---

## Authority Boundaries

This document operates at Authority-Rank 10 (ROOT). Its priority ordering is constitutionally binding on all lower-rank artifacts, including wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, operational artifacts, and analytical outputs.

No lower-rank artifact may establish, imply, or apply a priority ordering that contradicts the ordering defined herein. Where a lower-rank artifact's conflict resolution behavior diverges from this ordering, this document is authoritative and the lower-rank artifact constitutes a constitutional defect requiring remediation.

---

## Constitutional Obligation Priority Ordering

The following ordering defines the absolute constitutional priority of Symphony's obligation classes. Priority 1 is supreme. Where two obligations conflict, the obligation of lower priority number yields to the obligation of higher priority number (lower number = higher priority). This ordering is non-derogable.

| Priority | Obligation Class | Constitutional Basis |
|---|---|---|
| 1 | **Replay Survivability** | Constitutional permanence infrastructure; historical evidentiary integrity |
| 2 | **Provenance Integrity** | Wave 8 cryptographic sovereignty; admissibility foundation |
| 3 | **Admissibility Continuity** | Historical constitutional record; regulator-partition evidentiary validity |
| 4 | **Phase Legality** | Constitutional capability boundary enforcement; record validity |
| 5 | **Regulator Admissibility** | Regulator-partition sovereignty; domain-specific evidentiary requirements |
| 6 | **Cross-Jurisdiction Legality** | Legal framework compliance within constitutional constraint |
| 7 | **Sovereignty-Boundary Preservation** | Orthogonality maintenance across all sovereign domains |
| 8 | **Privacy Obligations** | Data protection within constitutional constraint |
| 9 | **Retention Obligations** | Record preservation within constitutional constraint |
| 10 | **Runtime Availability** | Operational continuity within constitutional constraint |
| 11 | **Optimization** | Operational efficiency within constitutional constraint |
| 12 | **Operational Convenience** | Implementation preference; lowest constitutional priority |

---

## Foundational Priority Rules

The following rules are derived directly from the priority ordering and are constitutionally absolute:

**Rule P1 — Replay survivability has supremacy over optimization.**
No optimization of Symphony's operational surfaces — computational, storage, latency, or throughput — may reduce, eliminate, or compromise any replay obligation. Where optimization and replay survivability conflict, replay survivability prevails without exception. The entire class of optimization objectives (Priority 11) yields to replay survivability (Priority 1).

**Rule P2 — Provenance integrity has supremacy over runtime convenience.**
No runtime operational convenience — including performance optimization, simplified deployment, reduced cryptographic overhead, or implementation expedience — may compromise the cryptographic provenance integrity of any record subject to Wave 8 sovereignty. Where runtime convenience and provenance integrity conflict, provenance integrity prevails without exception.

**Rule P3 — Admissibility continuity has supremacy over implementation simplification.**
No simplification of Symphony's constitutional architecture, enforcement surfaces, schema, or migration structure may retroactively reduce the admissibility of records admitted under prior constitutional doctrine. Where implementation simplification and admissibility continuity conflict, admissibility continuity prevails without exception.

**Rule P4 — Constitutional doctrine has supremacy over exploratory interpretation.**
No exploratory analysis, AI synthesis, repository observation, operational heuristic, or implementation convention may override the priority ordering established by this document. Where exploratory interpretation and constitutional doctrine conflict, constitutional doctrine prevails without exception.

**Rule P5 — Replay survivability has supremacy over privacy obligations.**
Where a privacy obligation would require the erasure, alteration, or suppression of a record that bears a replay obligation, replay survivability prevails. The record must be preserved in replay-sufficient form. Privacy obligations may be satisfied through access-restriction, compartmentalization, or regulator-partitioned disclosure controls that do not alter the underlying evidentiary record.

**Rule P6 — Admissibility continuity has supremacy over retention obligation modification.**
Where a retention obligation purports to authorize the deletion or modification of a record that has been admitted under a prior constitutional doctrine, admissibility continuity prevails. Retention obligations may govern records that have not been admitted; they may not govern the erasure of admitted records.

**Rule P7 — Phase legality has supremacy over runtime availability.**
Where satisfying a phase legality constraint requires refusing, blocking, or reversing a runtime operation, the phase legality constraint prevails. Runtime availability does not override constitutional phase boundaries.

**Rule P8 — Regulator admissibility has supremacy over operational convenience.**
Where satisfying a regulator admissibility requirement imposes operational cost, complexity, or inconvenience, the regulator requirement prevails. Operational convenience (Priority 12) yields to all higher-priority obligations.

---

## Conflict Resolution Rules

### Rule CR1: Determine Priority Class of Each Conflicting Obligation

When a conflict is identified, the first step is to determine the priority class of each obligation involved. The conflict is then resolved in favor of the obligation bearing the lower priority number (higher constitutional priority) without further analysis, subject only to the constraints defined in Rules CR2–CR6.

### Rule CR2: Partial Satisfaction Is Not Permitted Where Full Satisfaction Is Constitutionally Required

Where a constitutional obligation requires full satisfaction — replay survivability, provenance integrity, admissibility continuity, phase legality — partial satisfaction does not constitute compliance. A decision that partially preserves replay survivability while compromising it in specific dimensions constitutes a constitutional violation, not a compromise.

### Rule CR3: Lower-Priority Obligation Yields Completely in Impossible Compromise Scenarios

Where satisfying a higher-priority obligation necessarily and completely precludes satisfying a lower-priority obligation, the lower-priority obligation yields in its entirety. There is no constitutional basis for distributing the loss between the two obligations. The higher-priority obligation is satisfied; the lower-priority obligation is not.

### Rule CR4: Regulator-Domain Conflicts Are Resolved Within Each Domain

Where two regulator domains impose conflicting admissibility requirements on the same record or event class, the conflict is not resolved by establishing supremacy of one regulator domain over another. Regulator domains are constitutionally orthogonal. The resolution is: the record or event must satisfy the admissibility requirements of each regulator domain independently, within that domain's evidentiary surface. If a record cannot satisfy both domain requirements simultaneously, the record is admissible in the domain whose requirements it satisfies, and inadmissible in the domain whose requirements it does not satisfy. This determination is made per-domain and does not affect the record's status in any other domain.

### Rule CR5: Cross-Jurisdiction Conflicts Are Subordinate to Replay and Admissibility Obligations

Where a cross-jurisdiction legal obligation (Priority 6) conflicts with replay survivability (Priority 1), provenance integrity (Priority 2), or admissibility continuity (Priority 3), the higher-priority constitutional obligation prevails. Symphony's constitutional architecture does not yield its evidentiary integrity to external legal frameworks. External legal requirements may be accommodated within constitutional constraints; they may not override constitutional obligations.

### Rule CR6: Sovereignty-Boundary Preservation Is a Binding Constraint on All Resolutions

No conflict resolution decision may produce a constitutional outcome that collapses, merges, or subordinates any sovereignty domain. Sovereignty-boundary preservation (Priority 7) operates as a constraint on all resolutions, including those involving higher-priority obligations. A resolution that satisfies replay survivability (Priority 1) by collapsing a sovereignty boundary is constitutionally impermissible; an alternative replay-survivable resolution that preserves sovereignty boundaries must be sought. If no such alternative exists, the conflict must be escalated to Root constitutional amendment procedure.

---

## Admissibility-Preserving Arbitration

### Definition

Admissibility-preserving arbitration is the constitutional requirement that all conflict resolution decisions, regardless of which obligation prevails, preserve the admissibility of all records that were admitted prior to the conflict's occurrence. No conflict resolution decision may retroactively invalidate the admissibility of a prior-admitted record.

### Admissibility-Preserving Arbitration Requirements

Every conflict resolution decision must:

**AP1.** Identify all records whose admissibility status is affected by the resolution.

**AP2.** Confirm that the admissibility of all prior-admitted records is preserved under the resolution.

**AP3.** Where the resolution introduces a new admissibility classification for future records, confirm that the new classification does not retroactively apply to prior records.

**AP4.** Where the resolution alters the admissibility basis for a category of records, preserve the prior admissibility basis in the historical constitutional record sufficient to evaluate the admissibility of any record produced before the resolution.

**AP5.** Where the resolution involves a regulator domain, confirm that the resolution does not alter the admissibility standard applicable in any other regulator domain.

---

## Replay-Safe Compromise Constraints

### Definition

A replay-safe compromise is a conflict resolution outcome that satisfies a lower-priority obligation without reducing, eliminating, or compromising any existing replay obligation. Not all conflicts admit replay-safe compromise. Where no replay-safe compromise exists, replay survivability prevails and the lower-priority obligation yields completely.

### Replay-Safe Compromise Requirements

A proposed resolution is replay-safe if and only if:

**RS1.** All records subject to replay obligations prior to the resolution remain subject to replay obligations of equal or greater scope after the resolution.

**RS2.** The resolution does not alter the technical or procedural mechanism of replay in a manner that renders any prior replay obligation unenforceable.

**RS3.** The resolution does not introduce any classification, reclassification, or exclusion that removes any record class from replay obligation coverage.

**RS4.** The resolution preserves the reconstructability of the constitutional state that was authoritative at the time of each replay-obligated event, such that replay can be evaluated against the correct historical constitutional state.

### Replay-Unsafe Resolution Indicators

A resolution is replay-unsafe if it contains any of the following:

- Erasure, alteration, or suppression of any record bearing a replay obligation.
- Reclassification of a replay-obligated record class as non-replayable.
- Reduction of the historical reconstruction depth sufficient to evaluate replay.
- Introduction of a constraint that renders replay obligation satisfaction dependent on runtime state that may not be available at replay time.

---

## Regulator Coexistence Arbitration

### Constitutional Principle

Regulator domains in Symphony are constitutionally partitioned. No regulator domain possesses supremacy over another. Coexistence arbitration does not establish regulator hierarchy; it establishes independent satisfaction requirements per domain.

### Regulator Coexistence Arbitration Rules

**RC1.** Each regulator domain's admissibility requirements must be satisfied independently. Satisfaction in one domain does not constitute satisfaction in another.

**RC2.** Where two regulator domains impose conflicting requirements on the same record, the record must be maintained in a form that satisfies the higher-priority constitutional obligation (replay survivability, provenance integrity, admissibility continuity) while satisfying each domain's requirements within domain-specific access-control and disclosure surfaces.

**RC3.** Where satisfying one regulator domain's requirements would require altering a record in a manner that renders it inadmissible in another domain, the alteration is constitutionally prohibited. The record's constitutional admissibility across all domains in which it is admissible must be preserved.

**RC4.** Regulator coexistence does not require that a single record be simultaneously admissible in all regulator domains. A record may be admissible in Domain A and inadmissible in Domain B based on each domain's independent admissibility standards. This is not a conflict; it is the expected operation of regulator partition.

**RC5.** Where a regulator domain requires the production of a record that does not exist in Symphony's constitutional record, the domain's requirement may be satisfied by generating a domain-specific attestation document, provided the attestation does not alter the underlying constitutional record and does not assert admissibility beyond the attesting domain.

---

## Sovereignty-Boundary Preservation Requirements

In all conflict resolution scenarios, the following sovereignty-boundary preservation requirements apply unconditionally:

**SB1.** Wave 4 (operational/runtime sovereignty) and Wave 8 (provenance/cryptographic sovereignty) must remain constitutionally distinct in all resolution outcomes. No resolution may treat them as a single sovereignty layer.

**SB2.** Regulator domains must remain constitutionally partitioned in all resolution outcomes. No resolution may establish hierarchy, equivalence, or mutual subordination between regulator domains.

**SB3.** Phase capability boundaries must remain constitutionally intact in all resolution outcomes. No resolution may retroactively extend or retroactively restrict a phase's capability boundary.

**SB4.** No resolution may introduce a new sovereignty domain or modify an existing sovereignty domain's boundaries without Root constitutional amendment procedure.

**SB5.** Where a resolution would, as a necessary consequence, collapse a sovereignty boundary, the resolution is constitutionally impermissible regardless of the priority ranking of the obligations it purports to satisfy.

---

## Conflict Arbitration Matrices

### Matrix 1: Pairwise Priority Resolution

The following matrix defines the constitutionally required resolution for pairwise conflicts between obligation classes. "A prevails" means Obligation A is fully satisfied; Obligation B yields completely or to the maximum extent possible without compromising A.

| Obligation A | Obligation B | Resolution |
|---|---|---|
| Replay Survivability (1) | Provenance Integrity (2) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Admissibility Continuity (3) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Phase Legality (4) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Regulator Admissibility (5) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Cross-Jurisdiction Legality (6) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Privacy Obligations (8) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Retention Obligations (9) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Runtime Availability (10) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Optimization (11) | A prevails — replay survivability is supreme |
| Replay Survivability (1) | Operational Convenience (12) | A prevails — replay survivability is supreme |
| Provenance Integrity (2) | Admissibility Continuity (3) | A prevails |
| Provenance Integrity (2) | Phase Legality (4) | A prevails |
| Provenance Integrity (2) | Regulator Admissibility (5) | A prevails |
| Provenance Integrity (2) | Runtime Availability (10) | A prevails — provenance integrity is supreme over runtime convenience |
| Provenance Integrity (2) | Optimization (11) | A prevails |
| Provenance Integrity (2) | Operational Convenience (12) | A prevails |
| Admissibility Continuity (3) | Phase Legality (4) | A prevails |
| Admissibility Continuity (3) | Regulator Admissibility (5) | A prevails |
| Admissibility Continuity (3) | Privacy Obligations (8) | A prevails |
| Admissibility Continuity (3) | Retention Obligations (9) | A prevails |
| Admissibility Continuity (3) | Runtime Availability (10) | A prevails |
| Admissibility Continuity (3) | Optimization (11) | A prevails — admissibility continuity is supreme over implementation simplification |
| Admissibility Continuity (3) | Operational Convenience (12) | A prevails |
| Phase Legality (4) | Runtime Availability (10) | A prevails — phase legality is supreme over runtime availability |
| Phase Legality (4) | Optimization (11) | A prevails |
| Phase Legality (4) | Operational Convenience (12) | A prevails |
| Regulator Admissibility (5) | Privacy Obligations (8) | Context-dependent — see Rule RC2; sovereignty-boundary preservation governs |
| Regulator Admissibility (5) | Retention Obligations (9) | A prevails within domain; retention obligations may operate on non-admitted records |
| Regulator Admissibility (5) | Runtime Availability (10) | A prevails |
| Regulator Admissibility (5) | Operational Convenience (12) | A prevails |
| Cross-Jurisdiction Legality (6) | Privacy Obligations (8) | A prevails within constitutional constraint |
| Cross-Jurisdiction Legality (6) | Retention Obligations (9) | A prevails within constitutional constraint |
| Cross-Jurisdiction Legality (6) | Runtime Availability (10) | A prevails |
| Privacy Obligations (8) | Retention Obligations (9) | Context-dependent — governed by applicable regulator domain doctrine |
| Privacy Obligations (8) | Runtime Availability (10) | A prevails |
| Privacy Obligations (8) | Operational Convenience (12) | A prevails |
| Retention Obligations (9) | Runtime Availability (10) | A prevails |
| Runtime Availability (10) | Optimization (11) | A prevails |
| Runtime Availability (10) | Operational Convenience (12) | A prevails |
| Optimization (11) | Operational Convenience (12) | A prevails |

### Matrix 2: Multi-Obligation Conflict Resolution

Where three or more obligation classes are simultaneously in conflict, the priority ordering is applied sequentially. The highest-priority obligation is satisfied first. Each subsequent obligation is satisfied to the maximum extent possible without compromising any higher-priority obligation. Where satisfying any obligation would compromise a higher-priority obligation, that obligation yields completely for that conflict instance.

---

## Impossible Compromise Scenarios

The following scenarios define constitutional conflicts where no compromise is possible. In each case, the determination is final: the higher-priority obligation prevails completely and the lower-priority obligation yields completely.

### Scenario IC1: Replay Obligation vs. Privacy Erasure Demand

**Description:** A privacy obligation — whether arising from data protection regulation, individual right-to-erasure assertion, or cross-jurisdiction legal framework — demands the deletion or irreversible alteration of a record that bears a Symphony replay obligation.

**Determination:** Impossible compromise. Replay survivability (Priority 1) prevails. The record cannot be deleted or irreversibly altered. Privacy obligations may be satisfied through access-restriction, regulator-partitioned disclosure controls, or domain-specific attestation, none of which alter the underlying replay-obligated record. If the applicable legal framework does not admit these accommodations and demands physical erasure, Symphony's constitutional architecture cannot accommodate that demand without a Root constitutional amendment. Such an amendment is itself subject to the replay-obligation modification constraints defined in CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

**Constitutional basis:** Rule P1, Rule P5, Rule RS3.

### Scenario IC2: Replay Obligation vs. Storage Optimization

**Description:** An optimization initiative — whether motivated by cost, performance, or operational efficiency — proposes compressing, archiving, tiering, or deleting historical records to reduce storage consumption. The affected records bear Symphony replay obligations.

**Determination:** Impossible compromise. Replay survivability (Priority 1) prevails. No storage optimization may be applied to replay-obligated records in a manner that reduces, eliminates, or compromises replay obligation satisfaction. Optimization may be applied to non-replay-obligated records. Compression or tiering that preserves full replay fidelity is permissible provided it satisfies all RS constraints.

**Constitutional basis:** Rule P1, Rule P5, Rule RS1, Rule RS2.

### Scenario IC3: Provenance Integrity vs. Runtime Availability

**Description:** The cryptographic signing infrastructure required to satisfy Wave 8 provenance integrity obligations is unavailable at runtime (e.g., `ed25519_verify()` extension absent, signing key unavailable, signing authority unreachable). Continuing to process records without cryptographic signing would maintain runtime availability at the cost of provenance integrity.

**Determination:** Impossible compromise. Provenance integrity (Priority 2) prevails. Runtime operations that cannot satisfy provenance integrity obligations must be blocked. Runtime availability (Priority 10) does not override the Wave 8 provenance integrity requirement. The correct constitutional disposition is fail-closed: refuse to process records that cannot satisfy provenance integrity, rather than process records with degraded provenance and maintain availability.

**Constitutional basis:** Rule P2, foundational principle F2.

### Scenario IC4: Admissibility Continuity vs. Schema Simplification

**Description:** A schema or migration simplification initiative proposes eliminating, restructuring, or consolidating tables or fields that were used to establish the admissibility basis of prior-admitted records. The simplification would render the prior admissibility basis unreconstructable.

**Determination:** Impossible compromise. Admissibility continuity (Priority 3) prevails. The schema simplification may not be applied. Prior admissibility basis must remain reconstructable. The simplification may be applied only to schema elements that do not bear admissibility obligations for any admitted record.

**Constitutional basis:** Rule P3, Rule AP4.

### Scenario IC5: Phase Legality vs. Runtime Availability

**Description:** A runtime operation that is constitutionally legal under Phase N is attempted while Phase M (a different phase with a different capability boundary) is constitutionally active. Allowing the operation would maintain availability; blocking it would impose a runtime availability cost.

**Determination:** Impossible compromise. Phase legality (Priority 4) prevails. The operation is constitutionally inadmissible in the active phase and must be blocked. The runtime availability cost of phase-boundary enforcement is not a constitutional basis for overriding phase legality.

**Constitutional basis:** Rule P7.

### Scenario IC6: Regulator Admissibility vs. Operational Simplification

**Description:** Satisfying a regulator domain's admissibility requirements imposes operational complexity — additional signing steps, additional evidence generation, additional disclosure controls. An operational simplification would eliminate these steps, reducing compliance overhead while rendering records inadmissible in the relevant regulator domain.

**Determination:** Impossible compromise. Regulator admissibility (Priority 5) prevails within its domain. The operational simplification may not be applied to records subject to regulator domain admissibility requirements.

**Constitutional basis:** Rule P8, Rule RC1.

### Scenario IC7: Cross-Jurisdiction Legal Demand vs. Replay Obligation

**Description:** A legal authority in a cross-jurisdiction context asserts a legal order requiring the alteration, suppression, or deletion of a record class that bears Symphony replay obligations, citing national security, law enforcement, or regulatory authority.

**Determination:** Impossible compromise from a constitutional architecture standpoint. Replay survivability (Priority 1) prevails within Symphony's constitutional structure. Symphony's constitutional architecture cannot produce a compliant response to such an order that simultaneously satisfies the replay obligation. The conflict must be escalated to constitutional governance: either a Root constitutional amendment establishes a replay-obligation carve-out (subject to the constraints of CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md), or the legal order cannot be constitutionally satisfied within Symphony's architecture.

**Constitutional basis:** Rule CR5, Rule P1, Rule P5.

---

## Regulator Conflict Examples

### Example R1: Dual-Domain Admissibility Tension

**Scenario:** A settlement record must satisfy Domain A's requirement for cryptographic signing under a specific algorithm, and Domain B's requirement for human-readable plain-text representation. The cryptographic signing process produces a binary artifact incompatible with Domain B's plain-text requirement. The plain-text representation, if produced as the primary record, cannot be cryptographically signed in the format Domain A requires.

**Resolution:** The settlement record is produced in two domain-specific forms. The primary record satisfies Domain A's cryptographic signing requirement. A domain-specific attestation document is produced for Domain B, containing the human-readable representation and an attestation of its derivation from the primary record, signed under Domain B's applicable signing requirements. Each domain evaluates admissibility against its own form. The two domain-specific forms do not constitute a conflict; they constitute independent domain satisfaction.

**Constitutional basis:** Rule RC2, Rule RC5, Rule SB2.

### Example R2: Regulator Retention vs. Regulator Erasure

**Scenario:** Domain A requires retention of all transaction records for seven years. Domain B, applying privacy regulation, requires erasure of personally identifying fields from transaction records after two years. The same record contains both transaction data subject to Domain A retention and personally identifying fields subject to Domain B erasure.

**Resolution:** First, determine whether the personally identifying fields bear replay obligations. If they do, erasure is constitutionally prohibited (Rule P5). If they do not, the conflict is resolved by retaining the record in full for Domain A retention compliance, while satisfying Domain B erasure requirements through compartmentalized access restriction or domain-specific pseudonymisation that does not alter the underlying record's replay-relevant content. The record's Domain A admissibility is preserved; Domain B privacy obligations are satisfied through domain-specific access controls, not through record alteration.

**Constitutional basis:** Rule RC2, Rule RC3, Rule P5.

### Example R3: Cross-Jurisdiction Signing Requirement Conflict

**Scenario:** Jurisdiction X requires that all payment settlement records be signed using a signing authority registered in Jurisdiction X. Jurisdiction Y requires that the same records be signed using a signing authority registered in Jurisdiction Y. Symphony's `wave8_signer_resolution` function resolves a single authoritative signer per record.

**Resolution:** The conflict is not resolved by establishing cross-jurisdiction hierarchy. Each jurisdiction's admissibility requirement is treated as a regulator domain obligation (Priority 5). The resolution is: the record is signed by the `resolve_authoritative_signer`-determined signer for Wave 8 provenance purposes. Domain-specific counter-signatures or attestations are produced for each jurisdictional domain using that domain's registered signing authority. Each jurisdiction evaluates its own domain-specific attestation. The Wave 8 primary signature is not altered. Provenance integrity (Priority 2) is preserved.

**Constitutional basis:** Rule RC1, Rule RC2, Rule P2, Rule SB1.

---

## Replay vs. Erasure Examples

### Example RE1: Right-to-Erasure Request Against Transaction Record

**Scenario:** An individual asserts a right-to-erasure request against a transaction record that constitutes part of Symphony's evidentiary chain. The record bears a replay obligation as part of the `state_transitions` append-only record.

**Resolution:** The erasure request cannot be satisfied in a manner that alters the replay-obligated record. The request is accommodated as follows: access to the record is restricted within applicable privacy access controls; domain-specific attestation of the privacy accommodation is produced for the relevant regulator domain; the underlying record is preserved intact for replay obligation satisfaction. The individual's privacy interest is acknowledged; the constitutional erasure demand cannot be satisfied within Symphony's architecture without Root constitutional amendment.

**Constitutional basis:** Rule P1, Rule P5, Scenario IC1.

### Example RE2: Data Minimization Directive Against Evidence Pack

**Scenario:** A data minimization directive proposes reducing the field density of `evidence_packs` entries to eliminate fields deemed unnecessary for operational purposes. Several of the targeted fields are part of the evidentiary basis for records admitted under prior constitutional doctrine.

**Resolution:** The data minimization directive may not be applied to fields that constitute part of the admissibility basis for prior-admitted records. The directive may be applied prospectively to fields in future records that do not bear admissibility obligations, subject to phase legality and regulator admissibility requirements. Fields bearing admissibility obligations for prior-admitted records are constitutionally protected and must not be altered.

**Constitutional basis:** Rule P3, Rule AP4, Scenario IC4.

### Example RE3: Log Rotation Against Signing Audit Trail

**Scenario:** An operational log rotation policy proposes purging `signing_audit_log` entries older than 90 days to manage storage consumption. The affected entries contain signing evidence relevant to Wave 8 provenance obligations for records produced during the purge window.

**Resolution:** Log rotation may not be applied to `signing_audit_log` entries that constitute Wave 8 provenance evidence for replay-obligated records. Optimization (Priority 11) and operational convenience (Priority 12) yield to replay survivability (Priority 1) and provenance integrity (Priority 2). The rotation policy may be applied to entries that do not bear replay or provenance obligations.

**Constitutional basis:** Rule P1, Rule P2, Scenario IC2.

---

## Sovereignty-Boundary Preservation Cases

### Case SB1: Wave 4 / Wave 8 Conflict in Settlement Processing

**Scenario:** A settlement processing decision made under Wave 4 operational sovereignty determines that a record satisfies runtime settlement criteria. Wave 8 provenance sovereignty determines that the record's cryptographic signature is invalid or absent. Runtime availability favors processing the record (Wave 4 determination); provenance integrity requires blocking it (Wave 8 determination).

**Resolution:** Wave 8 provenance integrity (Priority 2) prevails over runtime availability (Priority 10). The record is blocked. The sovereignty boundaries of Wave 4 and Wave 8 are preserved: Wave 4's operational determination is recorded but does not override Wave 8's provenance determination. The two determinations coexist as records of their respective sovereignty surfaces without one subordinating the other. The constitutional outcome is determined by the priority ordering, not by collapsing the two sovereignty domains into a single determination.

**Constitutional basis:** Rule P2, Rule SB1, Foundational Principle F2.

### Case SB2: Phase Boundary Enforcement Against Runtime Operational Pressure

**Scenario:** A Phase 1 capability boundary prohibits a category of operation that has become operationally urgent during Phase 1's active period. Operational pressure mounts to permit the operation under an emergency exception, treating the phase boundary as a guideline rather than a constitutional constraint.

**Resolution:** Phase legality (Priority 4) prevails over runtime availability (Priority 10) and operational convenience (Priority 12). Phase boundaries are constitutional capability constraints, not operational guidelines. The operation is constitutionally inadmissible during Phase 1 regardless of operational urgency. The correct constitutional resolution is: if the operation must be performed, Phase 1 must be constitutionally exited and Phase 2 (or a newly defined phase permitting the operation) must be constitutionally entered. A phase transition is required; a phase-boundary exception is not a constitutionally available remedy.

**Constitutional basis:** Rule P7, Rule SB3.

### Case SB3: Regulator Domain Assertion of Cross-Domain Supremacy

**Scenario:** Regulator Domain A asserts that its admissibility standards constitute the governing standard for all records within Symphony, including records processed under Regulator Domain B's jurisdiction.

**Resolution:** The assertion is constitutionally invalid. Regulator domains are constitutionally orthogonal. No regulator domain possesses supremacy over another. Domain A's admissibility standards govern records within Domain A's jurisdictional scope. They do not govern records within Domain B's jurisdictional scope. The two domains coexist as independent partitions. Sovereignty-boundary preservation (Priority 7, Rule SB2) prohibits any resolution that treats this assertion as valid.

**Constitutional basis:** Rule CR4, Rule SB2, Rule RC1.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the meta-constitutional domain of obligation priority and conflict arbitration. It establishes the constitutional priority ordering that resolves conflicts across all of Symphony's sovereignty surfaces, including Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator domains, and phase capability boundaries.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine the substantive scope of Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator sovereignty domains, or phase capability boundaries. It establishes how conflicts between obligations arising within those domains are resolved; it does not alter the domains' substantive definitions.

**Replay obligations preserved by this document:**
This document preserves all replay obligations by establishing replay survivability as the supreme constitutional priority (Priority 1), by defining impossible compromise scenarios where replay obligations cannot be yielded (IC1, IC2, IC7), by establishing replay-safe compromise constraints (Rules RS1–RS4), and by prohibiting replay-unsafe resolutions as identified by the replay-unsafe resolution indicators.

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator orthogonality. It may not establish priority ordering that produces regulator domain hierarchy, equivalence, or mutual subordination. Its conflict resolution rules must be applied per-domain, not across domain boundaries.

**Phases this document applies to:**
GLOBAL. This document applies across all phases without exception. No phase doctrine may establish a phase-specific priority ordering that contradicts the ordering defined herein.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10 (ROOT). Any lower-rank document that applies a conflicting priority ordering constitutes a constitutional defect.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, operational artifacts, and analytical outputs are prohibited from reinterpreting the priority ordering, conflict resolution rules, admissibility-preserving arbitration requirements, replay-safe compromise constraints, regulator coexistence arbitration rules, sovereignty-boundary preservation requirements, and impossible compromise determinations defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Priority as preference:**
The constitutional priority ordering defined herein is not a preference scale, a weighting system, or a balancing test. It is a deterministic supremacy ordering. Where two obligations conflict, the higher-priority obligation prevails. There is no constitutional basis for balancing the interests of two conflicting obligations against each other.

**Invalid simplification — Impossible compromise as negotiation starting point:**
The impossible compromise scenarios defined herein are constitutional determinations, not negotiating positions. Where a scenario is classified as impossible compromise, that classification is final. It cannot be overcome by operational necessity, business urgency, legal pressure, or analytical argument at levels below Root constitutional amendment authority.

**Forbidden authority collapse — Operational behavior as priority determination:**
The priority ordering cannot be derived from, modified by, or overridden by the operational behavior of Symphony's enforcement surfaces. An enforcement surface that consistently resolves conflicts in a particular order does not thereby establish that order as the constitutional priority ordering. Constitutional priority is defined by this document.

**Forbidden authority collapse — Cross-jurisdiction legal supremacy:**
No external legal framework, regulatory authority, or jurisdictional order possesses supremacy over Symphony's constitutional priority ordering. Cross-jurisdiction legality is Priority 6 in this ordering. It yields to replay survivability (Priority 1), provenance integrity (Priority 2), admissibility continuity (Priority 3), phase legality (Priority 4), and regulator admissibility (Priority 5). External legal demands must be accommodated within constitutional constraints; they cannot override those constraints.

**Replay-destructive interpretation — Privacy erasure satisfies replay obligation:**
Satisfying a privacy erasure demand does not satisfy a replay obligation. A replay obligation requires that the record remain in replay-sufficient form. Erasure destroys replay-sufficient form. The two obligations cannot both be satisfied when erasure of a replay-obligated record is demanded. Replay survivability prevails.

**Replay-destructive interpretation — Optimization reduces replay scope:**
No optimization — storage, computational, latency, or throughput — may reduce the scope of replay obligations. Replay obligations are constitutional permanence infrastructure, not operational overhead subject to efficiency tradeoffs.

**Regulator-flattening interpretation — Highest-admissibility domain governs all:**
The regulator domain with the most demanding admissibility requirements does not thereby govern all other regulator domains. Each domain's requirements govern admissibility within that domain exclusively. Admissibility in the most demanding domain does not constitute admissibility in all domains, nor does it relieve any domain of its independent admissibility evaluation obligation.

**Phase-illegality misreading — Operational urgency overrides phase boundary:**
Operational urgency, business necessity, or runtime availability pressure does not constitute a constitutional basis for overriding a phase capability boundary. Phase boundaries are constitutional constraints, not operational guidelines. The only constitutionally available remedy for a phase boundary that prohibits a required operation is a constitutional phase transition, not a phase-boundary exception.

**Provenance/runtime collapse — Wave 4 operational consensus validates Wave 8 provenance:**
A Wave 4 operational determination that a record satisfies runtime settlement criteria does not constitute or substitute for Wave 8 cryptographic provenance validation. The two determinations are made on independent sovereignty surfaces and are constitutionally non-substitutable. Wave 4 consensus does not validate Wave 8 provenance; Wave 8 cryptographic signature does not constitute Wave 4 operational authorization. Each sovereignty surface's determination is authoritative within its domain and neither subordinates the other.

**Sovereignty-collapse interpretation — Priority ordering implies sovereignty hierarchy:**
The priority ordering defined herein does not establish a sovereignty hierarchy among Wave 4, Wave 8, regulator domains, or phases. Priority ordering governs how conflicts between obligations arising from those domains are resolved. It does not make any sovereignty domain constitutionally superior to any other domain. Wave 4 and Wave 8 are both constitutionally authoritative within their respective domains; provenance integrity (Priority 2) prevailing over runtime availability (Priority 10) in a specific conflict does not make Wave 8 sovereignty constitutionally superior to Wave 4 sovereignty as a general matter.
