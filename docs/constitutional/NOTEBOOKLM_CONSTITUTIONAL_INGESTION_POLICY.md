# NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 10
Phase-Scope: GLOBAL
Supersedes: all informal document inclusion conventions, all undeclared corpus management practices
Depends-On: CONSTITUTIONAL_GLOSSARY.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md, CONSTITUTIONAL_ARTIFACT_STATUS_STANDARD.md
```

---

## Purpose

This document defines the constitutional policy governing the ingestion, ranking, weighting, synthesis, and quarantine of all documents and sources within the Symphony NotebookLM corpus. It establishes which sources may be ingested, at which trust level, under which constraints, and with which synthesis restrictions. It further defines the contamination prevention regime, ontology drift prevention controls, and sovereignty preservation requirements that govern all NotebookLM retrieval and synthesis activity.

This policy is binding on all NotebookLM corpus management operations. No source may be added to, retained in, or removed from the Symphony NotebookLM corpus in a manner that contradicts this policy. No synthesis output produced by NotebookLM operating on the Symphony corpus is constitutionally valid if it violates the synthesis restrictions defined herein.

---

## Constitutional Scope

This document governs:

1. The classification of all documents and sources as members of a defined ingestion class.
2. The admissibility weighting applied to each ingestion class during NotebookLM retrieval and synthesis.
3. The quarantine requirements for sources that carry contamination risk.
4. The segregation requirements for archaeological sources.
5. The synthesis restrictions applicable to each ingestion class.
6. The contamination prevention, ontology drift prevention, replay doctrine preservation, and sovereignty-domain preservation controls applied to all corpus management and synthesis operations.

This document does NOT govern:

1. The substantive content of documents classified as CANONICAL (governed by their own constitutional authority).
2. The specific enforcement mechanisms of Symphony's DB or CI substrate (governed by source migrations and the Canonical Capability Report).
3. The process for generating new canonical documents (governed by the GOV-CONV ratification sequence).

---

## Part I: Ingestion Classes

All sources ingested into or referenced by the Symphony NotebookLM corpus MUST be assigned to exactly one of the following ingestion classes. A source without an assigned ingestion class MUST be treated as EXPLORATORY pending classification review.

---

### Class 1: CANONICAL

**Definition:**
Sources that carry `Constitutional-Status: AUTHORITATIVE` and `NotebookLM-Ingestion: CANONICAL` in their constitutional metadata block. These sources constitute the authoritative evidentiary and doctrinal foundation of the Symphony corpus. Their definitions, prohibitions, and doctrines are binding on all synthesis activity.

**Ingestion authorization:** Unconditional. All CANONICAL sources MUST be ingested.

**Admissibility weighting:** Maximum. In any synthesis conflict between a CANONICAL source and any lower-class source, the CANONICAL source governs without exception.

**Synthesis restrictions:**
- NotebookLM MUST NOT produce synthesis outputs that contradict CANONICAL sources.
- NotebookLM MUST NOT synthesize "balanced perspectives" between CANONICAL doctrine and lower-class source material when those perspectives are constitutionally incompatible.
- NotebookLM MUST cite the CANONICAL source when its doctrine governs the response.
- NotebookLM MUST qualify any response that touches CANONICAL subject matter by referencing the governing CANONICAL document.

**Current corpus members:**
CONSTITUTIONAL_GLOSSARY.md; NON_INFERENCE_AND_INTERPRETATION_LIMITS.md; CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md; NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md; CONSTITUTIONAL_ARTIFACT_STATUS_STANDARD.md; SYMPHONY_CANONICAL_CAPABILITY_AND_ENFORCEMENT_REPORT.md; and all documents bearing `Constitutional-Status: AUTHORITATIVE` and `NotebookLM-Ingestion: CANONICAL` after ratification through the GOV-CONV sequence.

---

### Class 2: INTERPRETIVE

**Definition:**
Sources that provide constitutionally grounded interpretation of CANONICAL doctrine without themselves possessing root constitutional authority. INTERPRETIVE sources elaborate, apply, or extend CANONICAL definitions to specific domains, phases, or use cases. They MUST NOT contradict CANONICAL sources.

**Ingestion authorization:** Conditional. INTERPRETIVE sources may be ingested only after confirming they do not contradict any CANONICAL source.

**Admissibility weighting:** Secondary. INTERPRETIVE sources govern where CANONICAL sources are silent on a specific question. Where CANONICAL sources address the question, CANONICAL governs.

**Synthesis restrictions:**
- NotebookLM MAY use INTERPRETIVE sources to elaborate on CANONICAL doctrine.
- NotebookLM MUST NOT use INTERPRETIVE sources to qualify, narrow, or override CANONICAL doctrine.
- NotebookLM MUST flag apparent contradictions between INTERPRETIVE and CANONICAL sources rather than resolving them by synthesis.

**Typical sources:** Phase-specific execution envelopes; wave-specific implementation guides; agent authority documents; Definition of Done templates; ratified governance convergence documents (GOV-CONV series).

---

### Class 3: ADVISORY

**Definition:**
Sources that provide context, background, analysis, or recommendations relevant to Symphony's architecture or governance, without asserting constitutional authority and without carrying a `Constitutional-Status: AUTHORITATIVE` declaration. ADVISORY sources may contain accurate information but are not constitutionally binding.

**Ingestion authorization:** Permitted with explicit ADVISORY classification applied.

**Admissibility weighting:** Tertiary. ADVISORY sources inform context but do not govern synthesis. They are subordinate to both CANONICAL and INTERPRETIVE sources.

**Synthesis restrictions:**
- NotebookLM MAY use ADVISORY sources to provide background and context.
- NotebookLM MUST NOT use ADVISORY sources to fill gaps in CANONICAL doctrine. Gaps MUST be acknowledged as gaps, not filled by ADVISORY material.
- NotebookLM MUST identify ADVISORY source material as advisory when using it.
- NotebookLM MUST NOT treat ADVISORY analysis as architectural determination.

**Typical sources:** Research reports; design documents without constitutional authority declarations; formally preserved meeting notes; comparative analysis documents; technology assessments.

---

### Class 4: EXPLORATORY

**Definition:**
Sources that represent preliminary thinking, draft analysis, speculative design, or exploratory investigation. EXPLORATORY sources have not been reviewed for constitutional consistency and may contain assumptions that violate Symphony's constitutional doctrine.

**Ingestion authorization:** Restricted. EXPLORATORY sources MUST be ingested with an explicit contamination quarantine declaration attached and MUST be segregated from CANONICAL and INTERPRETIVE sources.

**Admissibility weighting:** None for doctrinal questions. EXPLORATORY sources carry zero admissibility weight for any question addressed by CANONICAL or INTERPRETIVE sources.

**Synthesis restrictions:**
- NotebookLM MUST NOT derive constitutional doctrine from EXPLORATORY sources.
- NotebookLM MUST NOT use EXPLORATORY sources to infer architectural intent, fill architectural gaps, or confirm or deny CANONICAL findings.
- If an EXPLORATORY source is the only source on a topic, NotebookLM MUST acknowledge that no constitutionally grounded source exists on that topic.
- NotebookLM MUST label all EXPLORATORY-sourced content explicitly.

**Typical sources:** Brainstorming documents; pre-ratification draft governance documents; speculative architecture proposals; informally circulated design notes.

---

### Class 5: SUPERSEDED

**Definition:**
Sources that previously held CANONICAL or INTERPRETIVE status but have been formally superseded by a newer document that explicitly names the superseded source in its `Supersedes:` metadata field. SUPERSEDED sources retain historical validity as records of the constitutional state during their active period but MUST NOT govern current doctrine.

**Ingestion authorization:** Historical only. SUPERSEDED sources MUST remain in the corpus but MUST be tagged with their SUPERSEDED status and the identity of their successor.

**Admissibility weighting:** For current-state questions: zero. For historical-state questions about the period of their authority: qualified historical weight.

**Synthesis restrictions:**
- NotebookLM MUST NOT present superseded doctrine as current doctrine under any circumstances.
- NotebookLM MUST explicitly qualify any use of SUPERSEDED material with the statement that the source has been superseded and identify the superseding document.
- NotebookLM MUST NOT synthesize between current CANONICAL doctrine and SUPERSEDED doctrine as though both represent current valid positions.

---

### Class 6: ARCHAEOLOGICAL

**Definition:**
Sources from an earlier phase, wave, or architectural period of Symphony that predate the constitutional ratification framework. Their content may reflect historically valid decisions, accurate descriptions of prior state, or exploratory thinking that was never constitutionally ratified. They cannot be assessed for constitutional consistency without individual review, because the framework under which they would be assessed did not exist when they were produced.

**Ingestion authorization:** Segregated. ARCHAEOLOGICAL sources MUST be maintained in a constitutionally isolated segment clearly labeled as pre-constitutional.

**Admissibility weighting:** Zero for current doctrine questions. For historical reconstruction queries, qualified historical weight with explicit pre-constitutional caveat.

**Synthesis restrictions:**
- NotebookLM MUST NOT use ARCHAEOLOGICAL sources in synthesis about current Symphony architecture, governance, or doctrine.
- NotebookLM MAY reference ARCHAEOLOGICAL sources when explicitly asked about Symphony's pre-constitutional history, with explicit qualification.
- NotebookLM MUST NOT allow ARCHAEOLOGICAL content to migrate into doctrinal synthesis through indirect reference chains.

**Typical sources:** Pre-constitutional architecture documents; early wave implementation notes from before Wave 4 governance was established; informal design records from Symphony's pre-ratification period.

---

## Part II: Constitutional Source Trust Hierarchy

When sources in different classes produce conflicting findings on the same question, the higher-class source governs without exception:

```
CANONICAL         [Class 1] — Governs all doctrinal questions
    |
INTERPRETIVE      [Class 2] — Governs where CANONICAL is silent
    |
ADVISORY          [Class 3] — Provides context; never governs doctrine
    |
EXPLORATORY       [Class 4] — Zero doctrinal weight
    |
SUPERSEDED        [Class 5] — Historical reference only
    |
ARCHAEOLOGICAL    [Class 6] — Pre-constitutional reference only
```

**Cross-class conflict resolution rule:**
A conflict between a CANONICAL source and any lower-class source is NOT a genuine conflict — the CANONICAL source governs. A genuine conflict exists only between two sources of the same class. Intra-class conflicts within the CANONICAL class are resolved by `Authority-Rank`. If two CANONICAL sources of equal Authority-Rank conflict, the conflict constitutes a constitutional ambiguity that MUST be flagged, not resolved by synthesis.

---

## Part III: Ingestion Ranking

All documents admitted to the Symphony NotebookLM corpus carry an ingestion rank derived from their ingestion class and `Authority-Rank` metadata field:

| Ingestion Class | Base Rank | Authority-Rank Modifier | Effective Rank Range |
|---|---|---|---|
| CANONICAL | 1000 | + (Authority-Rank × 10) | 1000–1100 |
| INTERPRETIVE | 500 | + (Authority-Rank × 10) | 500–600 |
| ADVISORY | 200 | + (Authority-Rank × 5) | 200–250 |
| EXPLORATORY | 50 | none | 50 |
| SUPERSEDED | 10 (historical use only) | none | 10 |
| ARCHAEOLOGICAL | 5 (pre-constitutional use only) | none | 5 |

Ingestion rank governs: conflict resolution priority in synthesis; citation precedence when multiple sources address the same question; the order in which sources are consulted during retrieval.

Ingestion rank does NOT govern: the historical validity of SUPERSEDED or ARCHAEOLOGICAL sources for historical reconstruction queries; the domain-specific authority of jurisdiction-scoped documents within their jurisdiction.

---

## Part IV: Admissibility Weighting

Admissibility weighting determines how much weight a source's content carries when NotebookLM constructs synthesis responses. It is applied per-question rather than per-source.

**Rule AW-001 — Domain Match Amplification:**
A source whose defined scope matches the domain of the question receives its full admissibility weight. A source whose scope does not match receives reduced weight proportional to scope mismatch.

**Rule AW-002 — Phase Currency:**
A source whose phase scope matches the current constitutional phase receives full admissibility weight. A source whose phase scope predates the current phase receives reduced weight unless the question concerns that prior phase.

**Rule AW-003 — Supersession Deflation:**
A SUPERSEDED source receives zero admissibility weight for current-state questions. For historical-state questions, its weight is restored but qualified by superseded status.

**Rule AW-004 — Archaeological Isolation:**
ARCHAEOLOGICAL sources receive zero admissibility weight for any synthesis operation not explicitly tagged as a historical reconstruction query. For historical reconstruction queries, weight is qualified by pre-constitutional status.

**Rule AW-005 — Contamination Quarantine:**
Any source flagged for contamination review receives zero admissibility weight until the review is complete and a formal ingestion class has been assigned.

---

## Part V: Contamination Prevention Rules

Contamination occurs when lower-class source material influences synthesis outputs on doctrinal questions without the explicit constitutional qualification this policy requires. Contamination may occur directly or indirectly through reference chains and terminology migration.

**Rule CP-001 — Zero Bleed Between Classes:**
EXPLORATORY, SUPERSEDED, and ARCHAEOLOGICAL content MUST NOT migrate into CANONICAL or INTERPRETIVE synthesis outputs through any mechanism — indirect citation, summarization, or implicit terminology incorporation.

**Rule CP-002 — Quarantine Tagging:**
Any source of uncertain ingestion class MUST be tagged as QUARANTINE-PENDING before ingestion. QUARANTINE-PENDING sources receive zero admissibility weight for all synthesis operations until formally classified.

**Rule CP-003 — Terminology Contamination Prevention:**
Where a lower-class source uses a term in a non-canonical sense, the canonical definition in CONSTITUTIONAL_GLOSSARY.md governs for synthesis purposes. Pre-constitutional or informally defined terminology MUST NOT override canonical definitions.

**Rule CP-004 — Reference Chain Quarantine:**
If a CANONICAL or INTERPRETIVE source references a lower-class source, the referenced source MUST be quarantined from influencing the synthesis of the referencing source's content. Reference to a lower-class source for the purpose of superseding or acknowledging it does not elevate that source's ingestion class.

**Rule CP-005 — Contamination Audit Trigger:**
A contamination audit MUST be triggered when synthesis output contains: (a) doctrine not traceable to a CANONICAL source, (b) constitutional terminology not defined in CONSTITUTIONAL_GLOSSARY.md, (c) architectural conclusions that violate NON_INFERENCE_AND_INTERPRETATION_LIMITS.md prohibitions, or (d) question-answer pairs that violate CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md. The contamination source MUST be identified and quarantined before further synthesis on the affected topic.

---

### Phase 3 Draft and Assessment Isolation

**Rule CP-006 - Phase 3 Draft and Assessment Isolation:**
Phase 3 draft reviews, assessment documents, archived boundary drafts, and
agent-generated comparative analyses are not governing doctrine unless they
carry `Constitutional-Status: AUTHORITATIVE` and
`NotebookLM-Ingestion: CANONICAL`. Files under `docs/PHASE3/archive/` must be
treated as EXPLORATORY or SUPERSEDED according to their metadata and must not be
used to define Phase 3 task semantics.

**Rule CP-007 - Boundary Router Preservation:**
`PHASE3_CAPABILITY_BOUNDARY.md` may route to governing doctrine, but NotebookLM
must not infer missing doctrine from the boundary document itself. If the
boundary identifies a required doctrine and that doctrine is absent, synthesis
must report a doctrine gap rather than filling the gap from draft or assessment
material.

## Part VI: Ontology Drift Prevention Controls

Ontology drift occurs when the semantic meaning of foundational Symphony concepts shifts within the corpus through accumulation of lower-class sources, imprecise synthesis reformulations, or ADVISORY sources whose analytical framing implicitly redefines constitutional concepts.

**Control OD-001 — Glossary Primacy:**
CONSTITUTIONAL_GLOSSARY.md is the terminal semantic authority for all defined terms. Any synthesis response that uses a defined term inconsistently with the Glossary constitutes an ontology drift event requiring correction.

**Control OD-002 — Prohibited Term Migration:**
The following terms carry constitutional definitions that MUST NOT be redefined by lower-class sources or synthesis drift: sovereignty, authority, admissibility, attestation, verification, dormant substrate, constitutional reservation, phase legality, replay reconstruction, verifier independence, orthogonal trust domains, provenance sovereignty, operational sovereignty, canonicalization lineage, evidence survivability, non-collapse doctrine, regulator partitioning, trust root, compositional validation, historical validity.

**Control OD-003 — Periodic Constitutional Consistency Review:**
The Symphony NotebookLM corpus MUST undergo a constitutional consistency review when: (a) a new CANONICAL document is added, (b) a document is reclassified between ingestion classes, or (c) a contamination audit identifies an ontology drift event.

**Control OD-004 — Anti-Simplification Preservation:**
Constitutional complexity of Symphony's architecture MUST NOT be simplified in synthesis outputs for accessibility. The multi-dimensional nature of admissibility, the plurality of sovereignty, and the domain-specificity of trust roots MUST be preserved in their full constitutional form. Simplifications that collapse these dimensions are ontology drift events.

---

## Part VII: Superseded Corpus Handling

**Step 1 — Supersession Declaration:** The superseding document names the superseded document in its `Supersedes:` metadata field. This is the formal constitutional act of supersession.

**Step 2 — Class Reclassification:** The superseded document is reclassified to SUPERSEDED. Its `Constitutional-Status` MUST be updated to `SUPERSEDED` with a `Superseded-By:` field identifying the successor.

**Step 3 — Historical Preservation:** The superseded document MUST be retained in the corpus. Removal is constitutionally prohibited because: (a) SUPERSEDED documents are historical admissibility records, (b) they support replay reconstruction for operations during their authority period, and (c) removal breaks the supersession chain required for constitutional lineage verification.

**Step 4 — Synthesis Isolation:** The superseded document is isolated from current-state synthesis immediately upon reclassification.

**Step 5 — Transition Period:** During the transition period following supersession, NotebookLM MUST flag any synthesis response relying on the superseded document's doctrine and direct to the superseding document.

---

## Part VIII: Archaeological Corpus Segregation

All ARCHAEOLOGICAL sources MUST be maintained in a constitutionally isolated corpus segment designated `ARCHAEOLOGICAL CORPUS — PRE-CONSTITUTIONAL`.

**SEG-001 — Physical Segregation:** ARCHAEOLOGICAL sources MUST be stored in a designated section clearly labeled with the ARCHAEOLOGICAL designation and the pre-constitutional caveat.

**SEG-002 — Synthesis Firewall:** NotebookLM MUST NOT access ARCHAEOLOGICAL sources during synthesis operations that address current constitutional questions. The synthesis firewall is unconditional for current-state queries.

**SEG-003 — Historical Access Protocol:** Access to ARCHAEOLOGICAL sources for historical reconstruction queries MUST be explicitly triggered by a query specifically tagged as historical and explicitly acknowledging the pre-constitutional period. Implicit access through reference chains is prohibited.

**SEG-004 — Archaeological Source Promotion:** An ARCHAEOLOGICAL source MUST NOT be promoted to a higher ingestion class without: (a) full review against the current CANONICAL corpus, (b) formal identification of any constitutional inconsistencies, and (c) either resolution of those inconsistencies or explicit qualification of the promoted source as INTERPRETIVE with known limitations.

---

## Part IX: Replay Doctrine Preservation Requirements

**RP-001 — Supersession Chain Preservation:** The complete supersession chain for every SUPERSEDED document MUST be preserved in the corpus and MUST NOT be broken by removal of intermediate superseded documents.

**RP-002 — Ingestion Class History:** The history of a document's ingestion class assignments MUST be preserved as part of its constitutional record.

**RP-003 — Temporal Authority Attribution:** The corpus MUST support determination of which doctrine was authoritative at any specific point in time by preserving the effective authority period (effective_from and supersession date) of each document.

**RP-004 — No Retroactive Reclassification:** A document's ingestion class MUST NOT be retroactively changed to a date before the reclassification event. A document that was CANONICAL from D1 to D2 remains CANONICAL for historical queries about D1–D2 and SUPERSEDED for queries about D2 onward.

---

## Part X: Sovereignty Domain Preservation Requirements

**SV-001 — Wave Attribution Preservation:** NotebookLM synthesis MUST preserve the distinction between Wave 4 operational sovereignty and Wave 8 provenance sovereignty in all responses.

**SV-002 — Regulator Partition Preservation:** NotebookLM synthesis MUST NOT merge findings from different regulatory jurisdictions without explicit jurisdiction context.

**SV-003 — Phase Legality Preservation:** NotebookLM synthesis MUST qualify all architectural state descriptions with the applicable phase context.

**SV-004 — Non-Collapse Preservation:** NotebookLM synthesis MUST NOT produce outputs that collapse two sovereignty planes into one. Any synthesis output producing an unconstitutional authority collapse MUST be identified as a contamination event.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
The constitution of the Symphony NotebookLM corpus itself: source admission, trust level, synthesis restrictions, and contamination prevention controls.

**Sovereignty domains this document MUST NOT redefine:**
The substantive constitutional doctrine of any CANONICAL source; Symphony DB or CI enforcement mechanisms; jurisdiction interpretation pack content; phase transition criteria.

**Replay obligations preserved:**
Mandatory retention of SUPERSEDED documents; archaeological corpus preservation; replay preservation requirements for the corpus itself (§IX); prohibition on retroactive reclassification.

**Regulator boundaries constraining this document:**
This document governs the general Symphony NotebookLM corpus. Jurisdiction-specific sub-corpora are governed by the applicable jurisdiction interpretation packs within the framework this document establishes.

**Phases this document applies to:**
GLOBAL — applies across all phases as the corpus grows with new CANONICAL documents through phase ratification.

**Constitutional layers possessing override authority:**
No document with Authority-Rank below 10. Override requires a ROOT-level instrument explicitly superseding this document by name.

**Lower-layer documents prohibited from reinterpretation:**
Phase-specific execution envelopes; wave-specific implementation guides; task-level Definitions of Done; GOV-CONV documents; agent authority documents; evidence schema documents; any document with Authority-Rank < 10.

---

## Prohibited Misinterpretations

**PMI-001 — ADVISORY Sources as Gap Fillers:**
ADVISORY sources MUST NOT be used to fill gaps in CANONICAL doctrine. Gaps are constitutional silences that MUST be acknowledged, not filled by lower-class material.

**PMI-002 — SUPERSEDED as Deleted:**
Supersession is not deletion. SUPERSEDED documents retain historical authority for historical-period queries and their role in the supersession chain. Removal from the corpus is constitutionally prohibited.

**PMI-003 — ARCHAEOLOGICAL as Irrelevant:**
ARCHAEOLOGICAL sources are not irrelevant. They are constitutionally isolated for current-doctrine purposes but valid historical records for pre-constitutional period queries. Their isolation is contamination prevention, not denial of historical legitimacy.

**PMI-004 — Synthesis Balance as Constitutional Requirement:**
NotebookLM MUST NOT interpret this policy as requiring "balanced perspectives" between CANONICAL doctrine and lower-class material. Constitutional doctrine is not subject to balance; it governs. Presenting EXPLORATORY material as a counterbalancing perspective to CANONICAL doctrine is contamination, not balance.

**PMI-005 — Ingestion Rank as Quality Judgment:**
Ingestion rank reflects constitutional authority, not document quality. An ARCHAEOLOGICAL document may be historically accurate and well-written; its rank reflects its pre-constitutional status, not its quality.

**PMI-006 — Contamination as Intentional Act:**
Contamination may occur through accumulation, reference chains, or semantic drift without intentional introduction. Prevention rules apply regardless of mechanism.

**PMI-007 — This Policy as Restricting Research:**
This policy governs NotebookLM synthesis operations. It does not prohibit human researchers from consulting EXPLORATORY, SUPERSEDED, or ARCHAEOLOGICAL sources directly. It prohibits those sources from influencing constitutional synthesis outputs.
