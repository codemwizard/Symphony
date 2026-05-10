# CONSTITUTIONAL_ARTIFACT_STATUS_STANDARD.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 10
Phase-Scope: GLOBAL
Supersedes: all informal document header conventions, all undeclared metadata standards applied to Symphony artifacts
Depends-On: CONSTITUTIONAL_GLOSSARY.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
```

---

## Purpose

This document defines the machine-readable constitutional metadata standard for all Symphony constitutional artifacts. It establishes the legal values for each metadata field, the semantics of those values, the rules governing metadata inheritance, supersession, ingestion legality, and constitutional precedence. It constitutes the formal schema by which Symphony artifacts declare their authority, scope, and relationship to the constitutional hierarchy.

Every Symphony artifact that is intended for NotebookLM ingestion, governance enforcement, agent reasoning, or audit reference MUST carry a conformant metadata block. An artifact lacking a conformant metadata block MUST be treated as EXPLORATORY by default, regardless of its content.

---

## Constitutional Scope

This document governs the structural and semantic specification of constitutional metadata for Symphony artifacts. It does not govern the content of those artifacts. It governs:

1. The required metadata fields for all constitutional artifacts.
2. The legal values for each field and their semantic meaning.
3. The inheritance rules by which dependent artifacts derive or override metadata from their dependencies.
4. The supersession semantics governing the transition from one artifact version to its successor.
5. The ingestion legality implications of each metadata value combination.
6. The constitutional precedence implications of each metadata configuration.

---

## Part I: Required Metadata Block

All constitutional artifacts MUST open with a conformant metadata block in the following format:

```
Constitutional-Status: [legal value]
Interpretation-Authority: [legal value]
NotebookLM-Ingestion: [legal value]
Authority-Rank: [integer 0–10]
Phase-Scope: [legal value]
Supersedes: [document name(s) or NONE]
Depends-On: [document name(s) or NONE]
```

All seven fields are mandatory. An artifact that omits any field is metadata-nonconformant and MUST be treated as EXPLORATORY regardless of its content.

Optional extension fields:

```
Superseded-By: [document name] — populated when this artifact has been superseded
Effective-From: [ISO 8601 date] — the date from which this artifact's authority is effective
Superseded-At: [ISO 8601 date] — the date at which this artifact was superseded
Jurisdiction-Scope: [jurisdiction code(s) or GLOBAL] — for jurisdiction-scoped artifacts
```

---

## Part II: Field Definitions and Legal Values

---

### Field 1: Constitutional-Status

**Purpose:** Declares the constitutional authority standing of the artifact.

**Legal values:**

**AUTHORITATIVE**
The artifact carries root or enforcement-layer constitutional authority. Its definitions, prohibitions, and doctrine are binding on all lower-ranked artifacts. An AUTHORITATIVE artifact may only be overridden by another AUTHORITATIVE artifact of equal or higher Authority-Rank that explicitly names it in its `Supersedes:` field.

*Eligibility:* Documents produced through the GOV-CONV constitutional ratification sequence, or documents generated under ROOT Interpretation-Authority by a constitutionally authorized generation process. Not self-assignable without ratification.

*Ingestion implication:* CANONICAL ingestion class (subject to `NotebookLM-Ingestion: CANONICAL` confirmation).

---

**INTERPRETIVE**
The artifact provides constitutionally grounded elaboration, application, or extension of AUTHORITATIVE doctrine without itself carrying root authority. An INTERPRETIVE artifact MUST NOT contradict any AUTHORITATIVE artifact. Where it does, the AUTHORITATIVE artifact governs and the contradiction constitutes an INTERPRETIVE artifact defect requiring correction.

*Eligibility:* Phase execution envelopes, wave implementation guides, ratified GOV-CONV outputs, Definition of Done templates, agent authority documents.

*Ingestion implication:* INTERPRETIVE ingestion class.

---

**ADVISORY**
The artifact provides context, background, analysis, or recommendations without constitutional authority. An ADVISORY artifact may contain accurate information but is not binding on any governance, enforcement, or synthesis activity.

*Eligibility:* Research documents, design analyses, comparative assessments, formally preserved meeting notes.

*Ingestion implication:* ADVISORY ingestion class.

---

**EXPLORATORY**
The artifact represents preliminary, speculative, or unreviewed thinking. An EXPLORATORY artifact has not been assessed for constitutional consistency and may contain assumptions that violate Symphony's constitutional doctrine.

*Eligibility:* Any document not yet reviewed for constitutional consistency. Default assignment for unclassified artifacts.

*Ingestion implication:* EXPLORATORY ingestion class with quarantine declaration required.

---

**SUPERSEDED**
The artifact previously held AUTHORITATIVE or INTERPRETIVE status but has been formally superseded by a successor artifact. An SUPERSEDED artifact retains historical authority for the period during which it was active but does not govern current constitutional questions.

*Assignment:* Assigned by the corpus management process upon supersession declaration by a successor artifact. Not self-assignable.

*Required companion field:* `Superseded-By:` naming the successor document; `Superseded-At:` recording the supersession date.

*Ingestion implication:* SUPERSEDED ingestion class; retained in corpus; zero admissibility weight for current-state questions.

---

**ARCHAEOLOGICAL**
The artifact predates the Symphony constitutional framework and cannot be assessed for constitutional consistency without individual review against the current CANONICAL corpus.

*Assignment:* Assigned by the corpus management process upon identification of pre-constitutional origin.

*Ingestion implication:* ARCHAEOLOGICAL ingestion class; segregated corpus; zero admissibility weight for current-state synthesis.

---

**RESERVED**
The artifact's constitutional status has been reserved for a future determination. The artifact exists in the constitutional record but has not yet been assigned active authority. RESERVED artifacts are treated as EXPLORATORY for synthesis purposes until formally promoted.

*Eligibility:* Artifacts designated for future phases that require advance corpus registration; constitutional instruments whose ratification is pending.

*Ingestion implication:* Treated as EXPLORATORY pending promotion.

---

**PHASE-DEFERRED**
The artifact's constitutional authority is phase-gated. It has been constitutionally declared for a future phase and carries no operative authority in the current phase. It is present in the corpus as a constitutional advance declaration.

*Eligibility:* Constitutional instruments whose scope is explicitly confined to a future phase that has not yet been ratified.

*Ingestion implication:* Ingested with explicit phase-deferral annotation. Zero admissibility weight for current-phase queries. Full ingestion class assigned for queries specifically about the future phase it governs.

---

**RUNTIME-SCAFFOLD**
The artifact describes runtime-enforced constraints, trigger behavior, or DB-layer enforcement mechanisms without itself carrying constitutional text-level authority. It is a structural description of existing mechanical enforcement.

*Eligibility:* Migration documentation, trigger specification documents, SQLSTATE reference documents, CI gate specification documents.

*Ingestion implication:* INTERPRETIVE ingestion class for current enforcement state; ARCHAEOLOGICAL class for historical enforcement state no longer in effect.

---

### Field 2: Interpretation-Authority

**Purpose:** Declares the authority tier from which the artifact's interpretive force derives.

**Legal values:**

**ROOT**
The artifact derives its interpretive authority from the root constitutional layer — the highest level of Symphony's constitutional hierarchy. ROOT authority is not derived from any other document; it is self-grounding within Symphony's constitutional framework. ROOT artifacts establish the definitions, prohibitions, and doctrine that all other artifacts must conform to.

*Current ROOT artifacts:* CONSTITUTIONAL_GLOSSARY.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md, NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md, CONSTITUTIONAL_ARTIFACT_STATUS_STANDARD.md.

---

**REGULATORY**
The artifact derives its interpretive authority from a specific regulatory jurisdiction's sovereign domain. REGULATORY authority is orthogonal to ROOT authority and governs within its jurisdiction's sovereignty plane. REGULATORY artifacts do not supersede ROOT artifacts; they govern jurisdiction-specific questions within the framework ROOT artifacts establish.

*Typical sources:* Jurisdiction-specific interpretation packs; regulatory authority declarations.

---

**PHASE**
The artifact derives its interpretive authority from a specific constitutional phase boundary declaration. PHASE authority governs capability legality within the declared phase and is constrained by the phase lifecycle constitutional documents.

*Typical sources:* Phase execution envelopes; phase-specific Definition of Done templates; phase capability boundary declarations.

---

**ENFORCEMENT**
The artifact derives its interpretive authority from Symphony's mechanical enforcement substrate — DB triggers, CI gates, SQLSTATE codes, security definer functions. ENFORCEMENT authority describes what is mechanically compelled, not what is constitutionally declared. ENFORCEMENT artifacts are constitutionally grounded in the substrate they describe.

*Typical sources:* Trigger specification documents; CI gate documentation; SQLSTATE reference maps; RUNTIME-SCAFFOLD documents.

---

### Field 3: NotebookLM-Ingestion

**Purpose:** Declares whether the artifact is authorized for ingestion into the Symphony NotebookLM canonical corpus and at which ingestion class.

**Legal values:**

**CANONICAL** — Authorized for ingestion as a CANONICAL source (Class 1). Requires `Constitutional-Status: AUTHORITATIVE`.

**INTERPRETIVE** — Authorized for ingestion as an INTERPRETIVE source (Class 2). Requires `Constitutional-Status: INTERPRETIVE` or `AUTHORITATIVE` with PHASE scope.

**ADVISORY** — Authorized for ingestion as an ADVISORY source (Class 3).

**RESTRICTED** — The artifact is restricted from NotebookLM ingestion. It exists in the constitutional record but MUST NOT be ingested into the synthesis corpus. Used for: artifacts containing sensitive implementation details, jurisdiction-restricted artifacts, or artifacts whose ingestion would create contamination risk without quarantine infrastructure.

**QUARANTINE** — The artifact requires quarantine review before ingestion. It MUST be treated as EXPLORATORY during review.

**HISTORICAL-ONLY** — The artifact is authorized for ingestion solely for historical corpus purposes. It carries SUPERSEDED or ARCHAEOLOGICAL status and MUST be marked accordingly.

---

### Field 4: Authority-Rank

**Purpose:** Provides a numeric precedence value (0–10) for resolving intra-class conflicts between artifacts of the same `Constitutional-Status`.

**Legal range:** Integer from 0 (lowest) to 10 (highest).

**Precedence rule:** When two artifacts of the same Constitutional-Status produce conflicting findings on the same question, the artifact with the higher Authority-Rank governs. Equal Authority-Rank conflict constitutes a constitutional ambiguity requiring corpus management review.

**Assignment conventions:**

| Rank | Typical Assignment |
|---|---|
| 10 | Root constitutional documents (glossary, inference limits, query rules, this standard) |
| 9 | Canonical capability reports; constitutional framework documents |
| 8 | Phase lifecycle constitutional documents; wave sovereignty declarations |
| 7 | Ratified governance convergence documents (GOV-CONV series) |
| 6 | Phase execution envelopes; wave implementation guides |
| 5 | Agent authority documents; Definition of Done templates |
| 4 | Evidence schema documents; invariant manifests |
| 3 | Migration metadata; sidecar `.meta.yml` files |
| 2 | CI gate specification documents |
| 1 | Advisory research and analysis |
| 0 | Exploratory and unclassified |

---

### Field 5: Phase-Scope

**Purpose:** Declares the constitutional phase(s) during which the artifact's authority is operative.

**Legal values:**

**GLOBAL** — The artifact's authority is operative across all phases, both current and future.

**PHASE-1** — The artifact's authority is operative only within Phase 1.

**PHASE-2** — The artifact's authority is operative only within Phase 2.

**PHASE-N** — Pattern for any specific phase declaration. N must be a defined constitutional phase number.

**PHASE-N-AND-BEYOND** — The artifact's authority begins at Phase N and continues indefinitely unless explicitly superseded.

**PRE-CONSTITUTIONAL** — The artifact predates the constitutional phase framework. Used for ARCHAEOLOGICAL artifacts.

**Phase-Scope enforcement implication:**
An artifact with `Phase-Scope: PHASE-1` carries zero authority for Phase 2+ questions. An artifact with `Phase-Scope: GLOBAL` carries authority across all phases. Phase-Scope is the constitutional mechanism by which phase legality is encoded in artifact metadata.

---

### Field 6: Supersedes

**Purpose:** Declares which artifacts this artifact formally supersedes. The declaration of supersession is the constitutional act that changes the superseded artifact's Constitutional-Status to SUPERSEDED.

**Legal values:**

**NONE** — This artifact does not supersede any prior artifact.

**[Document name(s)]** — Comma-separated list of artifact names that this artifact formally supersedes. Each named artifact MUST have its Constitutional-Status updated to SUPERSEDED upon this artifact's ratification. The named artifacts MUST be retained in the corpus with HISTORICAL-ONLY ingestion status.

**Supersession chain rule:**
Supersession is linear. Artifact A supersedes Artifact B, which superseded Artifact C. The chain A → B → C constitutes the constitutional lineage. No artifact may supersede an artifact that has already been superseded by another artifact currently in effect — this would create a forked supersession chain, which is constitutionally impermissible (analogous to `idx_unique_superseded_by` at the DB layer).

---

### Field 7: Depends-On

**Purpose:** Declares which artifacts this artifact depends on for its constitutional grounding. A `Depends-On` relationship means that: (a) the referenced artifact must be in the corpus for this artifact to be constitutionally operative, and (b) if the referenced artifact is superseded, this artifact must be reviewed for currency before continuing to carry its current Constitutional-Status.

**Legal values:**

**NONE** — This artifact has no constitutional dependencies.

**[Document name(s)]** — Comma-separated list of artifacts this artifact depends on.

**Dependency chain implications:**
If Artifact X depends on Artifact Y, and Artifact Y is superseded by Artifact Z, then:
1. Artifact X's `Depends-On` field MUST be reviewed.
2. If Artifact Z changes the doctrine that Artifact X relies on from Artifact Y, Artifact X MUST be updated to reflect the new doctrine or explicitly declare its continued reliance on the superseded doctrine with a constitutional justification.
3. Artifact X MUST NOT silently inherit outdated doctrine through a superseded dependency.

---

## Part III: Metadata Inheritance Rules

When a new artifact is derived from, extends, or applies an existing artifact, the following inheritance rules govern its metadata:

**Rule MI-001 — Authority Inheritance Ceiling:**
A derived artifact MUST NOT carry an Authority-Rank higher than the artifact it primarily derives from, unless it has undergone independent constitutional ratification that justifies a higher rank.

**Rule MI-002 — Constitutional-Status Non-Elevation:**
A derived artifact MUST NOT carry a Constitutional-Status of higher authority than the artifact it derives from, unless independently ratified. An artifact that applies INTERPRETIVE doctrine MUST be classified as INTERPRETIVE or lower, not AUTHORITATIVE.

**Rule MI-003 — Phase-Scope Narrowing:**
A derived artifact MAY narrow its Phase-Scope relative to its dependency (GLOBAL → PHASE-2), but MUST NOT widen it (PHASE-2 → GLOBAL) without independent authority establishing the wider scope.

**Rule MI-004 — Depends-On Propagation:**
A derived artifact's `Depends-On` field MUST include all artifacts that its dependencies depend on that are materially relevant to its content. Dependency chains MUST NOT be silently broken.

**Rule MI-005 — Ingestion Class Inheritance:**
A derived artifact's NotebookLM ingestion class MUST be equal to or lower than the ingestion class of the artifact it primarily derives from. An artifact derived from a CANONICAL source may be CANONICAL (if independently ratified), INTERPRETIVE, ADVISORY, or EXPLORATORY — but not higher than CANONICAL.

---

## Part IV: Supersession Semantics

The constitutional act of supersession occurs at the moment a new artifact carrying a `Supersedes:` field naming a prior artifact is ratified into the corpus. The following consequences are constitutionally required:

**SS-001 — Immediate Status Transition:**
The superseded artifact's `Constitutional-Status` MUST be updated to `SUPERSEDED` at the moment of the superseding artifact's ratification. No grace period exists during which both artifacts carry active status simultaneously.

**SS-002 — Superseded-By Population:**
The superseded artifact's `Superseded-By:` field MUST be populated with the name of the superseding artifact. If the superseded artifact has no `Superseded-By:` field in its current format, the corpus management record MUST carry this information.

**SS-003 — Authority Transfer:**
All authority previously carried by the superseded artifact is transferred to the superseding artifact at the moment of supersession. The superseded artifact retains no operative authority for current-state questions.

**SS-004 — Corpus Retention:**
The superseded artifact MUST be retained in the corpus with `NotebookLM-Ingestion: HISTORICAL-ONLY`. Deletion is constitutionally prohibited.

**SS-005 — Dependency Review Trigger:**
All artifacts carrying the superseded artifact in their `Depends-On:` field MUST undergo a dependency review to confirm they remain constitutionally grounded under the superseding artifact's doctrine.

**SS-006 — Partial Supersession:**
An artifact may be partially superseded — only specific sections may be superseded by a newer instrument while others remain operative. Partial supersession MUST be explicitly declared: `Supersedes: [Document Name] §[Section(s)]`. Sections not named in the supersession declaration retain their operative authority.

---

## Part V: Ingestion Legality Implications

The combination of `Constitutional-Status` and `NotebookLM-Ingestion` values determines the full ingestion legality posture of an artifact:

| Constitutional-Status | NotebookLM-Ingestion | Ingestion Class | Synthesis Authority |
|---|---|---|---|
| AUTHORITATIVE | CANONICAL | Class 1: CANONICAL | Maximum — governs all doctrinal questions |
| AUTHORITATIVE | INTERPRETIVE | Class 2: INTERPRETIVE | Secondary — note: AUTHORITATIVE with non-CANONICAL ingestion may reflect jurisdiction-scope restriction |
| INTERPRETIVE | INTERPRETIVE | Class 2: INTERPRETIVE | Secondary |
| INTERPRETIVE | ADVISORY | Class 3: ADVISORY | Tertiary |
| ADVISORY | ADVISORY | Class 3: ADVISORY | Tertiary |
| EXPLORATORY | QUARANTINE | QUARANTINE-PENDING | Zero until classified |
| SUPERSEDED | HISTORICAL-ONLY | Class 5: SUPERSEDED | Historical reference only |
| ARCHAEOLOGICAL | HISTORICAL-ONLY | Class 6: ARCHAEOLOGICAL | Pre-constitutional reference only |
| RESERVED | QUARANTINE | QUARANTINE-PENDING | Zero until promoted |
| PHASE-DEFERRED | INTERPRETIVE | Phase-gated Class 2 | Zero for current phase; full Class 2 for target phase |
| RUNTIME-SCAFFOLD | INTERPRETIVE | Class 2: INTERPRETIVE | Current enforcement state only |
| AUTHORITATIVE | RESTRICTED | Not ingested | Exists in constitutional record only |

**Ingestion conflict rule:**
If `Constitutional-Status` and `NotebookLM-Ingestion` values are inconsistent (e.g., `Constitutional-Status: EXPLORATORY` with `NotebookLM-Ingestion: CANONICAL`), the lower authority value governs. The artifact is treated at the lower class until the inconsistency is resolved by corpus management review.

---

## Part VI: Constitutional Precedence Implications

**Precedence Rule P-001 — Rank Governs Within Class:**
When two artifacts of the same Constitutional-Status address the same question, the artifact with the higher Authority-Rank governs.

**Precedence Rule P-002 — Status Governs Across Classes:**
When two artifacts of different Constitutional-Status values address the same question, the higher Constitutional-Status governs, regardless of Authority-Rank. An Authority-Rank 10 INTERPRETIVE artifact does not outrank an Authority-Rank 1 AUTHORITATIVE artifact.

**Precedence Rule P-003 — Phase Scope Constrains Application:**
An artifact with a specific Phase-Scope only carries precedence for questions that arise within its declared phase. An AUTHORITATIVE artifact with `Phase-Scope: PHASE-1` does not carry precedence over an INTERPRETIVE artifact with `Phase-Scope: GLOBAL` for Phase 2+ questions.

**Precedence Rule P-004 — Supersession Extinguishes Prior Precedence:**
A superseded artifact carries no precedence for current-state questions, regardless of its prior Authority-Rank or Constitutional-Status.

**Precedence Rule P-005 — Jurisdiction Scoping Is Orthogonal:**
A REGULATORY-authority artifact carries precedence for questions within its jurisdiction, regardless of the Authority-Rank of competing GLOBAL artifacts, for those jurisdiction-specific questions. Jurisdiction scope does not override ROOT authority for foundational constitutional questions — it governs the jurisdiction-specific application of ROOT doctrine.

**Precedence Rule P-006 — Dependency Non-Circularity:**
Constitutional precedence MUST NOT be established through circular dependency chains. Artifact A cannot depend on Artifact B which depends on Artifact A. Circular dependencies are constitutionally invalid and constitute a metadata integrity defect requiring corpus management resolution.

---

## Part VII: Metadata Conformance Validation

All artifacts submitted to the Symphony constitutional corpus MUST pass the following conformance checks before ingestion:

**Conformance Check MC-001 — Field Completeness:**
All seven required metadata fields are present and carry values from their defined legal value sets.

**Conformance Check MC-002 — Status-Ingestion Consistency:**
The `Constitutional-Status` and `NotebookLM-Ingestion` values are consistent per the ingestion legality table in Part V.

**Conformance Check MC-003 — Supersession Chain Integrity:**
If `Supersedes:` names prior artifacts, those artifacts exist in the corpus and can be updated to reflect their superseded status.

**Conformance Check MC-004 — Dependency Existence:**
All artifacts named in `Depends-On:` exist in the corpus with a Constitutional-Status of AUTHORITATIVE or INTERPRETIVE (or SUPERSEDED with the dependency review completed).

**Conformance Check MC-005 — Rank Consistency:**
The Authority-Rank assigned is consistent with the artifact's Constitutional-Status and Interpretation-Authority as defined in the rank assignment conventions (Part II, Field 4).

**Conformance Check MC-006 — Phase-Scope Validity:**
The Phase-Scope value is a declared constitutional phase or GLOBAL, and the artifact's content is consistent with the scope declared.

An artifact that fails any conformance check MUST be treated as EXPLORATORY until the defect is corrected.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
The structural and semantic specification of constitutional metadata for all Symphony artifacts. The determination of ingestion legality and constitutional precedence from metadata values.

**Sovereignty domains this document MUST NOT redefine:**
The substantive constitutional doctrine of any CANONICAL source; Symphony DB or CI enforcement mechanisms; jurisdiction interpretation pack content; phase transition authorization criteria; the specific ingestion class definitions (governed by NOTEBOOKLM_CONSTITUTIONAL_INGESTION_POLICY.md); the specific constitutional term definitions (governed by CONSTITUTIONAL_GLOSSARY.md).

**Replay obligations preserved:**
Supersession semantics (Part IV) require mandatory retention of superseded artifacts (SS-004), preserving the corpus replay chain. Partial supersession semantics (SS-006) preserve the historical validity of sections not named in a supersession. Dependency review triggers (SS-005) ensure superseded dependencies do not silently produce constitutional drift.

**Regulator boundaries constraining this document:**
This document defines the REGULATORY Interpretation-Authority value and its ingestion implications. It does not define the substantive content of REGULATORY artifacts — that is governed by the applicable jurisdiction interpretation packs.

**Phases this document applies to:**
GLOBAL — this metadata standard applies to all artifacts across all phases.

**Constitutional layers possessing override authority:**
No document with Authority-Rank below 10. Override requires a ROOT-level instrument explicitly superseding this document.

**Lower-layer documents prohibited from reinterpretation:**
Phase-specific execution envelopes; wave-specific implementation guides; task-level Definitions of Done; GOV-CONV documents; agent authority documents; evidence schema documents; any document with Authority-Rank < 10.

---

## Prohibited Misinterpretations

**PMI-001 — RESERVED as Inactive:**
RESERVED status indicates advance constitutional registration for a future determination. It does not mean the artifact is inactive or absent from the constitutional record. RESERVED artifacts are constitutionally present and treated as EXPLORATORY pending promotion.

**PMI-002 — PHASE-DEFERRED as Missing:**
PHASE-DEFERRED status indicates deliberate constitutional reservation for a future phase. It is constitutionally complete in its deferred state. Describing PHASE-DEFERRED artifacts as "not yet implemented" without including the authorizing phase declaration is constitutionally inaccurate (per Constitutional Glossary: Constitutional Reservation).

**PMI-003 — RUNTIME-SCAFFOLD as Descriptive Only:**
RUNTIME-SCAFFOLD artifacts carry INTERPRETIVE ingestion class for the current enforcement state. They are not merely descriptive; they are constitutionally grounded descriptions of mechanical enforcement that carry INTERPRETIVE authority for questions about what is currently enforced.

**PMI-004 — Authority-Rank 10 as Absolute:**
Authority-Rank 10 within a Constitutional-Status class does not override a lower-rank artifact of a higher Constitutional-Status class. An Authority-Rank 10 INTERPRETIVE artifact remains subordinate to an Authority-Rank 0 AUTHORITATIVE artifact on doctrinal questions.

**PMI-005 — Supersedes as Version Replacement:**
Supersession is a constitutional act with specific corpus consequences (artifact retention, status transition, dependency review). It is not equivalent to a software version replacement where old versions are discarded. Superseded artifacts are retained permanently.

**PMI-006 — Depends-On as Optional Documentation:**
The `Depends-On:` field is not documentation for human readers. It is a machine-readable constitutional dependency declaration that triggers specific actions (dependency review) when referenced artifacts are superseded.

**PMI-007 — Phase-Scope Narrowing as Limitation:**
An artifact with a narrow Phase-Scope (e.g., PHASE-2) is not constitutionally limited relative to a GLOBAL artifact. It carries full authority within its declared scope. Phase-Scope is a precision declaration, not a restriction on the artifact's constitutional completeness within its scope.

**PMI-008 — Metadata Conformance as Optional Best Practice:**
Metadata conformance is constitutionally mandatory. An artifact that fails conformance check MC-001 through MC-006 is treated as EXPLORATORY regardless of its content. Conformance is not optional and cannot be waived by team consensus or editorial judgment.
