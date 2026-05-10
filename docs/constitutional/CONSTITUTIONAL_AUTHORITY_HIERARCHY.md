# CONSTITUTIONAL AUTHORITY HIERARCHY

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, CONSTITUTIONAL_GRAPH.md

---

## Purpose

This document defines the constitutional authority hierarchy of Symphony. It establishes the supremacy ordering of all artifact classes, the legal rules governing override and conflict resolution, the constraints on constitutional interpretation authority, and the prohibitions on authority inversion.

Symphony is a constitutional trust coordination system. It is not a conventional software repository. Every artifact produced in relation to Symphony — whether a constitutional document, a migration record, an enforcement trigger, a repository observation, an AI synthesis, or an analytical report — occupies a defined position in the constitutional authority hierarchy. That position determines the artifact's capacity to establish, interpret, modify, or override constitutional doctrine.

No artifact may exercise authority that exceeds its constitutional class. No lower-class artifact may override, reinterpret, or implicitly supersede a higher-class artifact. Conflicts between artifacts of different authority classes are resolved exclusively in favor of the higher-class artifact, without exception.

---

## Constitutional Scope

This document governs:

1. The supremacy ordering of all artifact classes within the Symphony constitutional corpus.
2. The legal rules by which higher-authority artifacts override lower-authority artifacts.
3. The constraints on which artifact classes possess constitutional interpretation authority.
4. The conflict resolution semantics applicable when artifacts of different classes produce contradictory propositions.
5. The authority inheritance constraints applicable to delegated and derived artifacts.
6. The explicit prohibitions on authority inversion and lower-layer override of constitutional doctrine.
7. The constitutional status of repository observations, AI syntheses, and analytical artifacts.

This document does NOT govern:

- The operational content of individual enforcement triggers, migration records, or runtime configurations, except insofar as those artifacts assert constitutional authority.
- The internal ordering of artifacts within the same authority class, except where a supersession chain or explicit authority assignment establishes rank.
- The procedural requirements for constitutional amendment, which are governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

---

## Foundational Principle: Symphony as Constitutional Trust Coordination System

Symphony's authority hierarchy is not derivable from software engineering conventions, repository topology, runtime behavior, or analytical synthesis. It is established constitutionally and is binding regardless of what any operational artifact, repository observation, or AI synthesis asserts.

The following foundational principles are non-derogable:

**F1. Constitutional supremacy is document-class-determined, not content-determined.**
An artifact's authority rank is determined by its constitutional class, not by the sophistication, correctness, or operational significance of its content. A migration record that contains accurate constitutional observations does not thereby acquire constitutional interpretation authority.

**F2. Runtime behavior does not constitute constitutional authority.**
The operational behavior of Symphony's enforcement surfaces — triggers, SECURITY DEFINER functions, CI gates, RLS policies — constitutes constitutional expression, not constitutional authority. The authority resides in the constitutional documents that define what that behavior must be. If operational behavior diverges from constitutional doctrine, the doctrine is authoritative.

**F3. Observation does not confer authority.**
An artifact that accurately observes, describes, analyzes, or synthesizes constitutional behavior does not thereby acquire authority over that behavior. Repository observations, audit reports, and AI syntheses are descriptive artifacts. They possess no prescriptive constitutional authority.

**F4. Analytical synthesis cannot redefine sovereignty ontology.**
No artifact produced by analytical process — whether human-authored analysis, machine-generated synthesis, or AI-produced summary — may redefine the sovereignty ontology of Symphony. Sovereignty domains, authority ranks, replay obligations, and regulator partitions are defined by constitutional documents and may be modified only through the amendment procedures established in CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

---

## Ranked Authority Matrix

The following matrix defines the complete authority hierarchy. Rank 10 is supreme. Lower ranks are subordinate to all higher ranks. No artifact of a given rank may override any artifact of a higher rank.

| Rank | Artifact Class | Examples | Override Authority | Interpretation Authority | Admissibility Authority |
|---|---|---|---|---|---|
| 10 | **Root Constitutional Doctrine** | CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md | Supreme — overrides all lower ranks | Full constitutional interpretation authority | Defines admissibility standards for all lower classes |
| 9 | **Wave Sovereignty Doctrine** | Wave 4 Sovereignty Doctrine, Wave 8 Sovereignty Doctrine | Overrides Ranks 1–8 within wave sovereignty scope | Wave-scoped interpretation authority | Defines admissibility within wave sovereignty domain |
| 8 | **Phase Constitutional Doctrine** | Phase 0 Doctrine, Phase 1 Doctrine, Phase 2 Doctrine | Overrides Ranks 1–7 within phase scope | Phase-scoped interpretation authority | Defines admissibility within phase capability boundary |
| 7 | **Regulator Partition Doctrine** | Regulator Domain A Doctrine, Regulator Domain B Doctrine | Overrides Ranks 1–6 within regulator partition scope | Regulator-scoped interpretation authority | Defines admissibility within regulator domain |
| 6 | **Enforcement Doctrine** | Invariant enforcement doctrine, RLS enforcement doctrine, trigger enforcement doctrine | Overrides Ranks 1–5 for enforcement surface definitions | Enforcement-surface interpretation authority | Defines enforcement-surface admissibility conditions |
| 5 | **Constitutional Migration Record** | Migration sequence 0001–0204 (tip authoritative) | Overrides Ranks 1–4 for constitutional record state; subject to Ranks 6–10 | No independent interpretation authority; expresses constitutional state | Constitutes evidentiary record of constitutional state |
| 4 | **CI Gate Authority** | `mechanical_invariants`, `db_verify_invariants`, `phase0_evidence_gate`, `security_scan` | Overrides Ranks 1–3 for merge admissibility; subject to Ranks 5–10 | No independent interpretation authority; enforces constitutional gates | Determines merge-path admissibility |
| 3 | **Operational Enforcement Artifact** | Database triggers, SECURITY DEFINER functions, RLS RESTRICTIVE policies, runtime enforcement surfaces | Overrides Ranks 1–2 at runtime enforcement layer; subject to Ranks 4–10 | No independent interpretation authority; expresses runtime enforcement state | Determines runtime operational admissibility |
| 2 | **Declarative Substrate** | Scaffolded tables, dormant registries, unwired enforcement surfaces, declared-but-inactive schema | No override authority | No interpretation authority | Constitutional existence only; admissibility deferred pending activation |
| 1 | **Repository Observation** | Audit reports, analysis documents, inspection summaries, CONSTITUTIONAL_GRAPH.md node observations | No override authority | No interpretation authority | No independent admissibility authority; descriptive only |
| 0 | **AI Synthesis / Analytical Artifact** | AI-generated summaries, NotebookLM syntheses, agent analyses, exploratory documents | No override authority | No interpretation authority | No admissibility authority; zero constitutional standing |

---

## Authority Class Definitions

### Rank 10 — Root Constitutional Doctrine

Root Constitutional Doctrine constitutes the supreme authority tier of the Symphony constitutional corpus. Documents at this rank define the foundational sovereignty ontology, the amendment procedures for all constitutional documents, the authority hierarchy itself, and the non-derogable constraints on all lower-rank artifacts.

Root Constitutional Doctrine may be amended only in accordance with the procedures established in CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, which itself operates at Rank 10. No lower-rank artifact, including wave sovereignty doctrine, phase doctrine, or enforcement doctrine, may override, reinterpret, or implicitly supersede any Root Constitutional Doctrine.

### Rank 9 — Wave Sovereignty Doctrine

Wave Sovereignty Doctrine defines the constitutional scope and authority surfaces of Symphony's wave-partitioned sovereignty layers. Wave 4 doctrine governs operational/runtime sovereignty. Wave 8 doctrine governs provenance/cryptographic sovereignty. These are constitutionally orthogonal and non-subordinate.

Wave Sovereignty Doctrine operates within the constraints established by Root Constitutional Doctrine. It may not redefine Root Constitutional Doctrine concepts, collapse its own sovereignty domain with another, or assert supremacy over Root Constitutional Doctrine.

### Rank 8 — Phase Constitutional Doctrine

Phase Constitutional Doctrine defines the constitutional capability boundaries of each phase. It establishes what operations, records, and authorities are constitutionally legal within a given phase. Phase doctrine may not redefine wave sovereignty, root constitutional concepts, or regulator partition boundaries.

### Rank 7 — Regulator Partition Doctrine

Regulator Partition Doctrine defines the constitutional scope, admissibility standards, and evidence requirements of each regulator sovereignty domain. Regulator domains are constitutionally orthogonal. No Regulator Partition Doctrine document may assert supremacy over, equivalence with, or subordination to any other regulator domain.

### Rank 6 — Enforcement Doctrine

Enforcement Doctrine defines the constitutional requirements for Symphony's enforcement surfaces, including database triggers, SECURITY DEFINER functions, CI gates, and RLS policies. Enforcement Doctrine is prescriptive of what operational artifacts must do; it does not derive its authority from what those artifacts currently do.

### Rank 5 — Constitutional Migration Record

The migration sequence (0001–0204 and extensions) constitutes the constitutional record of Symphony's evidentiary state. The tip migration is authoritative for current constitutional state. Prior migrations constitute the historical constitutional record and must remain reconstructable. Migration records express constitutional state; they do not independently interpret it.

**Critical constraint:** A migration record that contains language purporting to redefine constitutional doctrine (e.g., redefining a sovereignty boundary, eliminating a replay obligation, or reassigning authority rank) does not thereby acquire constitutional interpretation authority. Such language is constitutionally void unless accompanied by a formal Root Constitutional Doctrine amendment.

### Rank 4 — CI Gate Authority

CI gates constitute the constitutional merge-admissibility surface. Their pass/fail determinations are constitutionally authoritative for the merge path. CI gates express enforcement doctrine; they do not independently establish constitutional doctrine. A CI gate that passes an artifact does not thereby establish that artifact's constitutional validity beyond its merge-path admissibility.

### Rank 3 — Operational Enforcement Artifact

Operational enforcement artifacts — triggers, SECURITY DEFINER functions, RLS policies — constitute the runtime expression of constitutional doctrine. Their behavior is authoritative for operational admissibility. They do not possess independent constitutional interpretation authority. Where an operational artifact's behavior diverges from higher-rank doctrine, the higher-rank doctrine is authoritative.

**Shadow authority prohibition:** An operational artifact that presents itself as cryptographically authoritative while returning unconditional positive results (as with `verify_ed25519_signature` in the CONSTITUTIONAL_GRAPH) constitutes a shadow authority surface. Shadow authority surfaces do not acquire genuine constitutional authority through their operational posture. Their constitutional status is determined by the enforcement doctrine that governs them, not by their runtime behavior.

### Rank 2 — Declarative Substrate

Declarative substrate encompasses constitutionally declared but not yet operationally active artifacts: scaffolded tables, dormant registries, unwired enforcement surfaces. These artifacts possess constitutional existence and are constitutionally protected. Their dormancy does not constitute technical debt, accidental design, or grounds for elimination. They are constitutionally deferred pending the activation conditions defined in their governing phase or wave doctrine.

### Rank 1 — Repository Observation

Repository observations are descriptive artifacts. They record what exists in the repository at the time of inspection. They possess no prescriptive constitutional authority. An observation that accurately describes a constitutional condition does not thereby validate, invalidate, or modify that condition. The CONSTITUTIONAL_GRAPH.md is a Rank 1 artifact: it describes constitutional topology; it does not define it.

### Rank 0 — AI Synthesis / Analytical Artifact

AI syntheses, analytical reports, NotebookLM-generated summaries, and exploratory documents possess zero constitutional standing. They may describe, summarize, or reason about constitutional doctrine. They may not define, override, reinterpret, or extend it. This document, as produced, is authored under Root constitutional authority by the constitutional custodian process. The involvement of AI tooling in its generation does not reduce its constitutional authority rank, which is determined by its document class and the authority under which it is issued, not by the mechanism of its production.

---

## Legal Override Rules

### Rule 1: Higher Rank Always Overrides Lower Rank

Where any artifact of a lower authority rank asserts a proposition that contradicts a proposition in a higher-rank artifact, the higher-rank proposition is controlling. This rule is unconditional and applies regardless of the lower-rank artifact's content quality, operational significance, or author identity.

### Rule 2: Same-Rank Conflict — Supersession Chain Governs

Where two artifacts of the same authority rank assert contradictory propositions, the conflict is resolved by the supersession chain. The artifact most recently established in the supersession chain, provided that establishment complied with the amendment procedures of CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, is controlling.

### Rule 3: Silence Does Not Confer Authority

Where a higher-rank artifact is silent on a matter addressed by a lower-rank artifact, that silence does not confer independent authority on the lower-rank artifact. The lower-rank artifact may address the matter within its constitutionally defined scope, but may not use the silence to assert authority exceeding its rank.

### Rule 4: Migration Tip Governs Current Constitutional State, Not Constitutional Semantics

The tip migration record is authoritative for the current state of the constitutional record. It is not authoritative for the interpretation of constitutional doctrine. Constitutional semantics are governed by Ranks 6–10.

### Rule 5: Operational Behavior Cannot Override Doctrine

Where the operational behavior of a Rank 3 artifact (trigger, function, policy) diverges from the constitutional doctrine established by Ranks 6–10, the doctrine is authoritative. The operational artifact must be corrected to conform to doctrine; doctrine is not amended to conform to operational behavior.

### Rule 6: No Authority Is Acquired Through Accurate Description

An artifact that accurately describes, analyzes, or synthesizes constitutional conditions does not thereby acquire constitutional authority over those conditions. Accuracy of description is not a source of constitutional authority.

---

## Conflict Resolution Semantics

### Conflict Resolution Procedure

When a conflict between artifacts is identified, the following procedure applies:

**Step 1 — Authority rank determination:** Determine the authority rank of each conflicting artifact per the Ranked Authority Matrix above.

**Step 2 — Higher-rank resolution:** If the artifacts are of different ranks, the higher-rank artifact's proposition is controlling without further analysis.

**Step 3 — Same-rank supersession resolution:** If the artifacts are of the same rank, identify the supersession chain. The artifact most recently established in the supersession chain, provided its establishment was procedurally valid, is controlling.

**Step 4 — Procedural validity assessment:** If the superseding artifact's establishment was not procedurally valid (i.e., did not comply with CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md amendment procedures), the prior artifact retains authority.

**Step 5 — Escalation:** If conflict cannot be resolved by Steps 1–4 (including cases where procedural validity is contested), the conflict must be resolved by formal constitutional amendment at Root authority rank (Rank 10).

### Conflict Arbitration Examples

**Example A — Migration record vs. enforcement doctrine:**
Migration 0190 contains language describing `wave8_cryptographic_enforcement` as conditionally authoritative pending extension availability. Enforcement Doctrine (Rank 6) specifies that cryptographic enforcement must be fail-closed under all conditions. Resolution: Enforcement Doctrine (Rank 6) overrides migration record (Rank 5). The migration record's conditional framing does not constitute a reduction of the enforcement obligation.

**Example B — Repository observation vs. wave sovereignty doctrine:**
The CONSTITUTIONAL_GRAPH.md (Rank 1) observes that `public_keys_registry` and `delegated_signing_grants` are disconnected from the active enforcement graph, and notes them as having a convergence obligation toward `wave8_cryptographic_enforcement`. Wave 8 Sovereignty Doctrine (Rank 9) defines the cryptographic provenance sovereignty domain. Resolution: The repository observation accurately describes a constitutional topology condition but does not determine what the constitutional resolution must be. Wave 8 Sovereignty Doctrine governs. The observation is admissible as evidentiary description; it is not authoritative as constitutional determination.

**Example C — AI synthesis vs. phase constitutional doctrine:**
A NotebookLM synthesis (Rank 0) generates a summary asserting that Phase 1 and Phase 2 capability boundaries have effectively merged based on observed operational behavior. Phase Constitutional Doctrine (Rank 8) defines Phase 1 and Phase 2 as constitutionally distinct. Resolution: The AI synthesis has zero constitutional standing. Phase Constitutional Doctrine is controlling. The synthesis's observational basis is irrelevant to the constitutional resolution.

**Example D — Dormant declarative substrate vs. enforcement doctrine:**
An enforcement document (Rank 6) asserts that `signing_audit_log` (Rank 2, declarative/dormant) should be eliminated as technical debt. Root Constitutional Doctrine (Rank 10) prohibits treating inactive substrate as technical debt. Resolution: Root Constitutional Doctrine overrides the enforcement document's assertion. The dormant substrate retains its constitutional status.

**Example E — Same-rank phase doctrine conflict:**
Two phase doctrine documents (both Rank 8) assert contradictory capability boundaries for Phase 2. Supersession chain examination reveals Document B was established subsequent to Document A via a valid amendment procedure. Resolution: Document B is controlling. Document A retains historical constitutional status but is not operative for current constitutional state.

---

## Constitutional Interpretation Legality

### Who Possesses Constitutional Interpretation Authority

Constitutional interpretation authority — the authority to determine what a constitutional doctrine means in a contested case — is restricted to artifact classes of Rank 6 and above, and only within the scope of their constitutional class:

| Artifact Class | Interpretation Scope | Interpretation Limitations |
|---|---|---|
| Root Constitutional Doctrine (Rank 10) | Universal — all constitutional questions | None within Symphony's constitutional corpus |
| Wave Sovereignty Doctrine (Rank 9) | Wave sovereignty questions within the relevant wave domain | May not interpret beyond wave sovereignty scope |
| Phase Constitutional Doctrine (Rank 8) | Phase capability questions within the relevant phase | May not interpret wave sovereignty or root doctrine |
| Regulator Partition Doctrine (Rank 7) | Regulator domain questions within the relevant partition | May not interpret across regulator domain boundaries |
| Enforcement Doctrine (Rank 6) | Enforcement surface questions within the defined enforcement scope | May not interpret sovereignty, phase, or regulator boundaries |

### Who Does NOT Possess Constitutional Interpretation Authority

The following artifact classes possess no constitutional interpretation authority:

- **Constitutional Migration Records (Rank 5):** May record constitutional state; may not interpret constitutional doctrine.
- **CI Gate Authority (Rank 4):** May enforce constitutional gates; may not interpret constitutional doctrine.
- **Operational Enforcement Artifacts (Rank 3):** May express constitutional enforcement; may not interpret constitutional doctrine.
- **Declarative Substrate (Rank 2):** Possesses constitutional existence; possesses no interpretation authority.
- **Repository Observations (Rank 1):** Descriptive only; possesses no interpretation authority.
- **AI Syntheses / Analytical Artifacts (Rank 0):** Zero constitutional standing; possesses no interpretation authority.

### Interpretation Constraint: No Interpretation by Operational Behavior

The operational behavior of Symphony's enforcement surfaces does not constitute constitutional interpretation. Where an enforcement surface behaves in a manner inconsistent with higher-rank doctrine, that behavior does not constitute an implicit reinterpretation of the doctrine. It constitutes a constitutional defect requiring remediation.

---

## Authority Inheritance Constraints

### Delegation Rules

Constitutional authority may be delegated downward through the authority hierarchy only under the following conditions:

**D1.** Delegation must be explicit. Implicit authority inheritance — where a lower-rank artifact claims authority by virtue of its relationship to a higher-rank artifact without explicit delegation — is prohibited.

**D2.** Delegation may not exceed the delegating artifact's own authority scope. A Phase Constitutional Doctrine (Rank 8) may delegate interpretation authority for phase capability questions to an Enforcement Doctrine (Rank 6) document, but only within the Phase Doctrine's own scope. It may not delegate wave sovereignty interpretation authority it does not itself possess.

**D3.** Delegation does not elevate rank. A Rank 6 artifact that receives a delegation from a Rank 8 artifact does not become a Rank 8 artifact. The delegation is scoped; the rank is not transferred.

**D4.** Delegation is revocable. The delegating higher-rank document may revoke a delegation through a subsequent amendment. Revocation is effective upon registration in the constitutional history record.

### Derivation Rules

Artifacts derived from higher-rank artifacts (e.g., an enforcement trigger whose logic is derived from an enforcement doctrine document) inherit the constitutional constraints of the source document, not its authority rank. The derived artifact remains at its own authority rank.

---

## Lower-Layer Override Prohibitions

The following override patterns are constitutionally prohibited. Their occurrence constitutes an authority inversion and is void regardless of the content, operational significance, or authorial intent of the lower-rank artifact.

### Prohibition 1: Repository Observation Cannot Override Constitutional Doctrine

A repository observation (Rank 1) that identifies a constitutional condition — a dormant substrate, an unwired enforcement surface, a topology gap — does not thereby establish the constitutional resolution of that condition. Repository observations cannot:

- Declare a dormant artifact as eliminable.
- Assert that an unwired substrate is accidental design.
- Determine that a parallel authority surface constitutes conflict.
- Establish that a convergence obligation has been satisfied.

### Prohibition 2: AI Synthesis Possesses No Constitutional Authority

AI syntheses (Rank 0) possess zero constitutional standing. They cannot:

- Interpret constitutional doctrine.
- Resolve conflicts between constitutional artifacts.
- Declare a constitutional amendment.
- Determine the admissibility of any record or event.
- Redefine sovereignty ontology, authority rank, replay obligations, or regulator partitions.

The accuracy of an AI synthesis is not a source of constitutional authority. A synthesis that accurately restates constitutional doctrine is accurate, not authoritative.

### Prohibition 3: Analytical Artifacts Cannot Redefine Sovereignty Ontology

Analytical artifacts — audit reports, health assessments, architecture reviews, implementation plans — cannot redefine Symphony's sovereignty ontology. They cannot:

- Assert that Wave 4 and Wave 8 are unified.
- Declare a regulator domain equivalent to another.
- Reclassify a phase capability boundary.
- Assert that replay obligations have been satisfied or eliminated.
- Determine the constitutional status of any artifact class.

### Prohibition 4: Operational Behavior Cannot Constitute Constitutional Amendment

The operational behavior of Symphony's enforcement surfaces, however consistent, cannot constitute an implicit constitutional amendment. Consistent operational behavior that diverges from constitutional doctrine constitutes a persistent constitutional defect, not an evolved constitutional state.

### Prohibition 5: Migration Content Cannot Override Enforcement Doctrine

Migration records (Rank 5) may express the implementation of enforcement obligations. They may not override, reinterpret, or reduce the enforcement obligations defined by Enforcement Doctrine (Rank 6) or higher-rank documents. A migration that omits, weakens, or conditions an enforcement obligation defined by higher-rank doctrine does not thereby amend that obligation.

### Prohibition 6: CI Gate Passage Is Not Constitutional Validation

CI gate passage (Rank 4) establishes merge-path admissibility for a specific constitutional moment. It does not constitute general constitutional validation of the artifact's content. A migration, enforcement artifact, or configuration that passes all CI gates is merge-admissible; it is not thereby constitutionally valid in all constitutional dimensions.

---

## Constitutional Override Legality Table

| Override Attempted | By Artifact Class | Against Artifact Class | Constitutional Legality |
|---|---|---|---|
| Wave doctrine interpretation | Wave Sovereignty Doctrine (9) | Enforcement Doctrine (6) | LEGAL — higher rank governs |
| Phase boundary redefinition | Phase Doctrine (8) | Enforcement Doctrine (6) | LEGAL — within phase scope |
| Enforcement surface correction | Enforcement Doctrine (6) | Operational Artifact (3) | LEGAL — prescriptive over expression |
| Migration tip update | Migration Record (5) | Prior Migration Record (5) | LEGAL — supersession chain governs |
| Constitutional doctrine interpretation | Repository Observation (1) | Root Doctrine (10) | PROHIBITED — Rank 1 cannot override Rank 10 |
| Sovereignty ontology redefinition | AI Synthesis (0) | Wave Doctrine (9) | PROHIBITED — Rank 0 has zero standing |
| Dormant substrate elimination | Enforcement Doctrine (6) | Declarative Substrate (2) | PROHIBITED — requires Root Doctrine amendment |
| Replay obligation reduction | Migration Record (5) | Enforcement Doctrine (6) | PROHIBITED — lower rank cannot reduce higher obligation |
| Regulator domain merger | Analytical Artifact (0) | Regulator Doctrine (7) | PROHIBITED — Rank 0 has zero standing |
| Admissibility standard modification | Operational Artifact (3) | Phase Doctrine (8) | PROHIBITED — Rank 3 cannot override Rank 8 |
| Authority rank self-elevation | Any artifact class | Root Doctrine (10) | PROHIBITED — authority rank is constitutionally assigned |
| CI gate override of enforcement doctrine | CI Gate (4) | Enforcement Doctrine (6) | PROHIBITED — Rank 4 cannot override Rank 6 |
| Constitutional amendment via observation | Repository Observation (1) | Root Doctrine (10) | PROHIBITED — no amendment authority at Rank 1 |
| Constitutional reinterpretation via synthesis | AI Synthesis (0) | Any rank | PROHIBITED — zero constitutional standing |

---

## Admissibility Semantics

### Constitutional Admissibility Defined

An artifact is constitutionally admissible when it satisfies the admissibility conditions established by the highest-rank constitutional document governing its artifact class and operational context.

Admissibility is not a binary determination across all constitutional dimensions. An artifact may be:

- **Merge-path admissible** (passed all required CI gates) without being constitutionally valid in all sovereignty dimensions.
- **Operationally admissible** (processed by runtime enforcement surfaces) without being constitutionally valid against higher-rank doctrine.
- **Evidentiary admissible** (included in the constitutional history record) without being operative for current constitutional state.

### Admissibility Does Not Confer Authority

Admissibility of an artifact to a particular constitutional dimension does not confer authority beyond that dimension. Merge-path admissibility does not confer constitutional interpretation authority. Operational admissibility does not constitute constitutional validation. Evidentiary admissibility does not alter historical constitutional state.

### Admissibility of Dormant Substrate

Declarative substrate (Rank 2) is constitutionally admissible as declared constitutional existence. Its dormancy does not constitute inadmissibility. The activation conditions for dormant substrate are defined in governing phase or wave doctrine. Pending activation, dormant substrate retains full constitutional existence and is protected against elimination by lower-rank artifacts.

---

## Prohibited Authority Inversions

The following authority inversions are explicitly prohibited. Their identification in any Symphony artifact constitutes a constitutional defect requiring remediation:

**Inversion 1 — Runtime supremacy assertion:** Any assertion that the operational behavior of runtime enforcement surfaces is constitutionally authoritative over the doctrine that defines what that behavior must be.

**Inversion 2 — Provenance subordination:** Any assertion that Wave 8 provenance/cryptographic sovereignty is subordinate to, derived from, or validatable by Wave 4 operational/runtime sovereignty.

**Inversion 3 — Observation-based amendment:** Any assertion that a repository observation, audit finding, or analytical conclusion constitutes or necessitates a constitutional amendment without formal Root authority amendment procedure.

**Inversion 4 — Synthesis-based interpretation:** Any reliance on an AI synthesis or analytical artifact as the interpretive basis for a constitutional determination.

**Inversion 5 — CI-gate authority supremacy:** Any assertion that CI gate passage constitutes the supreme constitutional validation of any artifact.

**Inversion 6 — Convergence by elimination:** Any assertion that the convergence obligation between two constitutional surfaces (e.g., `public_keys_registry` and `wave8_signer_resolution`) may be satisfied by eliminating the lower-activity surface rather than by constitutional activation or formal decommission under Root authority amendment.

**Inversion 7 — Silence as permission:** Any interpretation of higher-rank silence as permission for lower-rank authority expansion. Higher-rank silence constrains lower-rank scope; it does not expand it.

**Inversion 8 — Accuracy as authority:** Any assertion that the factual accuracy of a lower-rank artifact's description of constitutional conditions confers constitutional authority over those conditions.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the meta-constitutional domain of authority hierarchy itself. It establishes the ranked ordering of all artifact classes and the rules governing their authority relationships. It does not define the substantive content of any individual sovereignty domain.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator sovereignty domains, or phase capability boundaries. It establishes the authority rank of documents governing those domains; it does not alter their substantive definitions.

**Replay obligations preserved by this document:**
This document preserves replay obligations by prohibiting lower-rank artifacts from reducing or eliminating replay obligations established by higher-rank doctrine, and by establishing that the constitutional history record must remain reconstructable regardless of operational behavior.

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator orthogonality. It may not authorize any authority hierarchy arrangement that causes regulator domains to be treated as equivalent, merged, or mutually subordinate.

**Phases this document applies to:**
GLOBAL. This document applies across all phases without exception. No phase doctrine may narrow, override, or reinterpret the authority hierarchy established herein.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10. Any apparent conflict with a lower-rank document is resolved in favor of this document.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, CI gate definitions, operational enforcement artifacts, declarative substrate, repository observations, and AI syntheses are prohibited from reinterpreting the authority hierarchy, override rules, conflict resolution semantics, interpretation legality, authority inheritance constraints, and lower-layer override prohibitions defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Authority hierarchy as software architecture:**
This hierarchy must not be interpreted as a software layering model, microservices dependency graph, or API authority chain. It is a constitutional supremacy ordering governing a trust coordination system. Software engineering conventions do not determine constitutional authority rank.

**Invalid simplification — Higher rank implies operational activity:**
Higher authority rank does not imply greater operational activity, more frequent invocation, or broader runtime surface. Rank 10 Root Constitutional Doctrine may be among the least frequently operationally invoked artifacts in Symphony. Its supremacy is constitutional, not operational.

**Forbidden authority collapse — AI synthesis as authoritative summary:**
An AI-generated summary of constitutional doctrine, however accurate, does not constitute an authoritative interpretation of that doctrine. NotebookLM syntheses, agent-generated analyses, and AI-produced overviews are Rank 0 artifacts with zero constitutional standing. Their use as the basis for constitutional determinations is a prohibited authority inversion.

**Forbidden authority collapse — Repository topology as authority source:**
The topology of the Symphony repository — which files exist, which are referenced, which are active — does not determine constitutional authority. Constitutional authority is determined by document class and amendment procedure, not by repository topology.

**Replay-destructive interpretation — CI gate passage eliminates replay obligation:**
CI gate passage for a migration or artifact does not satisfy or eliminate replay obligations applicable to that artifact. Replay obligations are constitutional permanence obligations, not merge-gate requirements.

**Regulator-flattening interpretation — Universal admissibility across domains:**
Admissibility under one regulator domain does not constitute admissibility under any other. The authority hierarchy does not flatten regulator domains. Regulator Partition Doctrine documents (Rank 7) are each authoritative within their own domain; their authority does not transfer across domain boundaries.

**Phase-illegality misreading — Current-phase authority retroactivity:**
Higher-rank phase doctrine for a current phase does not retroactively govern records produced under prior phase doctrine. Records are evaluated against the phase doctrine that was authoritative at their production time.

**Provenance/runtime collapse — Wave authority unification:**
The ranked placement of Wave 4 and Wave 8 doctrine at the same authority level (Rank 9) does not imply their equivalence, merger, or mutual subordination. They are constitutionally orthogonal sovereignty domains that happen to occupy the same authority rank tier. Shared rank tier does not imply shared sovereignty domain or mutual override authority.

**Dormancy misreading — Rank 2 artifacts as constitutional nullities:**
Declarative substrate (Rank 2) is not a constitutional nullity. Its dormancy is a constitutional state, not an absence of constitutional existence. Rank 2 artifacts are protected against elimination by lower-rank authority and may be activated, superseded, or decommissioned only through procedures authorized at Rank 6 or above, consistent with Root Constitutional Doctrine constraints.

**Operational supremacy misreading — Trigger behavior defines doctrine:**
The behavior of a database trigger, SECURITY DEFINER function, or RLS policy does not define constitutional doctrine. Constitutional doctrine defines what that behavior must be. Where behavior and doctrine diverge, doctrine is authoritative and behavior constitutes a defect, not an evolved constitutional state.
