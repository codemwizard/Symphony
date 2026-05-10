# CONSTITUTIONAL_QUERY_AND_INFERENCE_RULES.md

```
Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 10
Phase-Scope: GLOBAL
Supersedes: all undeclared analytical conventions, all informal query patterns applied to Symphony architecture
Depends-On: NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, SYMPHONY_CANONICAL_CAPABILITY_AND_ENFORCEMENT_REPORT.md
```

---

## Purpose

This document establishes the constitutional doctrine governing the formation, evaluation, and answering of questions directed at Symphony's architecture, substrate, governance, and capability state. It defines which question forms are constitutionally invalid, which analytical framings are admissible, and which reformulations are required when an invalid question is detected.

This document governs all query activity, including: direct human interrogation of Symphony's substrate, AI-assisted task generation, Definition of Done construction, phase planning inquiries, audit analysis, NotebookLM retrieval synthesis, and agent-generated architectural reasoning.

No question form that violates this document may produce a constitutionally valid analytical output, regardless of the apparent correctness of the answer it receives.

---

## Constitutional Scope

This document governs:

1. The formation of questions about Symphony's architecture, enforcement substrate, governance mechanisms, and capability state.
2. The analytical framing applied to answers retrieved from Symphony's canonical documents.
3. AI-assisted task generation inference patterns, including Phase 3 decomposition, Definition of Done generation, and execution envelope construction.
4. NotebookLM retrieval synthesis patterns for all Symphony canonical documents.
5. Audit and compliance analytical framing applied to Symphony's evidentiary outputs.

This document does NOT govern:

1. The substantive content of specific enforcement mechanisms (governed by source migrations and the Canonical Capability Report).
2. Phase transition authorization criteria (governed by phase lifecycle constitutional documents).
3. The resolution of specific cross-jurisdiction disputes (governed by regulator-partitioned instruments).

---

## Part I: Constitutionally Invalid Question Forms

A question is constitutionally invalid if it:

(a) Presupposes a sovereignty collapse that this doctrine prohibits.
(b) Presupposes that inactivity, parallelism, or deferral constitutes a defect.
(c) Presupposes runtime supremacy or provenance subordination.
(d) Presupposes that regulatory jurisdictions are comparable, additive, or interchangeable.
(e) Presupposes that a current-phase capability state is permanent rather than phase-bounded.
(f) Presupposes that replay infrastructure is optional or separable from evidentiary obligations.
(g) Presupposes that architectural complexity implies accidental design.

Each section below defines a category of invalid question forms, the constitutional defect in each, and the legally correct reformulation.

---

## Part II: Invalid Convergence Questions

### Category IQ-C: Questions That Presuppose Architectural Convergence

These questions are constitutionally invalid because they embed the assumption that Symphony's multiple coexisting mechanisms create convergence pressure — an obligation to merge, consolidate, or reduce the number of distinct mechanisms.

---

**IQ-C-001**

*Invalid Form:* "Since both `data_authority_level` triggers and `wave8_cryptographic_enforcement` govern asset batch insertions, which one should be the primary enforcement layer going forward?"

*Constitutional Defect:* This question presupposes that two mechanisms governing the same data object must be ranked into primary and subordinate positions, and that the subordinate one is a candidate for eventual removal. It collapses Wave 4 operational sovereignty and Wave 8 provenance sovereignty into a single "enforcement layer" concept.

*Constitutional Invalidity Basis:* Sovereignty collapse prohibition; parallelism-as-conflict fallacy (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.1).

*Legally Correct Reformulation:* "What sovereignty plane does `data_authority_level` enforcement serve on asset batch insertions, and what sovereignty plane does `wave8_cryptographic_enforcement` serve? Are both planes constitutionally required for a complete asset batch insertion?"

*Expected Constitutional Answer Form:* Identification of Wave 4 and Wave 8 as orthogonal sovereignty planes, each constitutionally required. No ranking. No convergence path.

---

**IQ-C-002**

*Invalid Form:* "We have `policy_decisions`, `state_rules`, and `interpretation_packs` as three separate policy mechanisms. Can we consolidate these into a single Policy Authority Registry?"

*Constitutional Defect:* This question treats architectural multiplicity as an optimization problem. It presupposes that fewer mechanisms serving related domains is constitutionally superior to more mechanisms serving distinct planes.

*Constitutional Invalidity Basis:* Multiple-authorities-imply-convergence-pressure fallacy (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.6); compositional validation semantics prohibition.

*Legally Correct Reformulation:* "What authority plane does each of `policy_decisions`, `state_rules`, and `interpretation_packs` govern? Do any two of these planes share a constitutional boundary that would permit consolidation without sovereignty collapse? If consolidation is impermissible, what is the correct relationship between them?"

*Expected Constitutional Answer Form:* Identification of three distinct planes (decision authority, transition permissibility, interpretive scoping). Determination that consolidation would produce unconstitutional authority collapse. Definition of the correct compositional relationship.

---

**IQ-C-003**

*Invalid Form:* "Both `resolve_interpretation_pack()` and `resolve_authoritative_signer()` are resolution functions. Should they be refactored into a single `resolve_authority()` function?"

*Constitutional Defect:* This question treats syntactic similarity (both are "resolution functions") as semantic equivalence. It ignores that the two functions resolve across fundamentally different authority planes with different constitutional implications.

*Constitutional Invalidity Basis:* Sovereignty collapse prohibition; complexity-as-redundancy fallacy (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §2.2).

*Legally Correct Reformulation:* "What does `resolve_interpretation_pack()` resolve, and what constitutional question does its answer settle? What does `resolve_authoritative_signer()` resolve, and what constitutional question does its answer settle? Would merging them require a single function to answer two constitutionally distinct questions simultaneously?"

---

**IQ-C-004**

*Invalid Form:* "The system has both CI-level evidence (JSON artifacts) and DB-level evidence (trigger-enforced state). Should we pick one as the canonical evidence system?"

*Constitutional Defect:* This question assumes that two evidence systems serving the same substrate create redundancy that must be resolved by elimination of one. It ignores that CI-level evidence serves governance admissibility and DB-level evidence serves operational sovereignty — planes that cannot replace each other.

*Constitutional Invalidity Basis:* Evidence plane attribution constraint (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §2.1); runtime supremacy prohibition (§1.7).

*Legally Correct Reformulation:* "Which constitutional questions does CI-level evidence (JSON artifacts) answer that DB-level trigger enforcement cannot? Which constitutional questions does DB-level enforcement answer that CI evidence cannot? What is the constitutional relationship between the two evidence planes?"

---

## Part III: Invalid Authority-Collapse Questions

### Category IQ-A: Questions That Presuppose Authority Hierarchy Collapse

These questions are constitutionally invalid because they presuppose that Symphony's multiple authority mechanisms must be ranked into a single hierarchy, and that a question about authority can always be resolved by identifying "the" authoritative source.

---

**IQ-A-001**

*Invalid Form:* "If a DB trigger rejects a transaction with GF037 but the CI evidence JSON shows PASS for the same invariant, which one is correct?"

*Constitutional Defect:* This question presupposes that "correctness" is a single-valued property that must be assigned to one of two evidence sources. It ignores that GF037 governs Wave 4 operational authority (data_authority_level transition validity) and a CI evidence PASS governs governance admissibility completeness. These answer different constitutional questions.

*Constitutional Invalidity Basis:* Runtime supremacy prohibition (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.7); cross-layer evidence adjudication gap (Canonical Capability Report §M-002).

*Legally Correct Reformulation:* "What constitutional question does GF037 answer? What constitutional question does the CI PASS answer? Are these questions in the same authority plane? If they are in different planes, is there a defined cross-plane adjudication protocol? If no protocol exists, the findings must be treated as sovereign and non-conflicting within their respective planes."

---

**IQ-A-002**

*Invalid Form:* "Does `enforce_authority_transition_binding()` supersede `state_rules` permissibility checks, or vice versa?"

*Constitutional Defect:* This question presupposes a linear hierarchy between two enforcement mechanisms that operate compositionally, not in sequence of precedence. It embeds the assumption that one mechanism's finding can override the other's.

*Constitutional Invalidity Basis:* Authority plane specificity constraint (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md Rule NL-008); compositional validation semantics.

*Legally Correct Reformulation:* "What does `enforce_authority_transition_binding()` verify that `state_rules` does not verify? What does `state_rules` enforce that `enforce_authority_transition_binding()` does not enforce? What is the compositional execution sequence, and does failure in either mechanism independently block the operation?"

*Expected Constitutional Answer Form:* Both mechanisms must pass; neither supersedes the other. `state_rules` governs permissibility (is this transition type allowed from this state?); `enforce_authority_transition_binding()` governs authority provenance (is there a cryptographic policy decision authorizing this specific transition?). These are sequential and compositional.

---

**IQ-A-003**

*Invalid Form:* "Who is the final authority on whether a carbon credit batch is valid: the DB trigger chain, the CI gate, or the verifier registry?"

*Constitutional Defect:* This question presupposes a single "final authority" model. It treats validity as a unitary property rather than a multi-plane constitutional status. Different authority planes certify different dimensions of validity simultaneously.

*Constitutional Invalidity Basis:* Multiple-authorities-imply-convergence-pressure fallacy; regulator-flattening prohibition.

*Legally Correct Reformulation:* "What is the DB trigger chain's authority over a carbon credit batch, and which dimension of validity does it certify? What is the CI gate's authority, and which dimension does it certify? What is the verifier registry's authority (`check_reg26_separation()`), and which dimension does it certify? Which downstream uses require which dimension of validity?"

---

**IQ-A-004**

*Invalid Form:* "Since Wave 8 adds cryptographic signing to asset batches, does it replace the need for the `policy_decisions` authority chain?"

*Constitutional Defect:* This question presupposes that cryptographic signing (provenance sovereignty) and policy decision authority (governance decision sovereignty) are alternative mechanisms serving the same purpose.

*Constitutional Invalidity Basis:* Provenance subordination prohibition (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.8); Wave attribution preservation (Rule NL-003).

*Legally Correct Reformulation:* "What constitutional question does Wave 8 cryptographic signing answer? What constitutional question does the `policy_decisions` chain answer? Does a cryptographic signature on an asset batch attest that a governance decision was made authorizing that batch? Does a `policy_decisions` record attest to the cryptographic origin of the batch? If these are distinct attestations, both are constitutionally required."

---

## Part IV: Invalid Replay-Dismissal Questions

### Category IQ-R: Questions That Treat Replay as Optional or Secondary

These questions are constitutionally invalid because they presuppose that replay infrastructure is separable from primary evidentiary obligations, or that replay survivability is a quality-of-life feature rather than a constitutional permanence obligation.

---

**IQ-R-001**

*Invalid Form:* "The `archive_verification_runs` table has never been populated. Can we defer implementing the archive verification runner to Phase 4?"

*Constitutional Defect:* This question conflates inactivity with optionality. It presupposes that a table with no rows is evidence that the capability it supports is not yet needed, and that deferral is therefore architecturally safe. It ignores that the obligation to produce replay-survivable evidence is active from the first evidentiary output.

*Constitutional Invalidity Basis:* Inactivity-as-obsolescence fallacy (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.2); replay obligation inclusion rule (NL-006); replay irrelevance prohibition (§1.9).

*Legally Correct Reformulation:* "What activation condition triggers the obligation to run archive verification? Has that condition been triggered? If not, what is the current state of replay survivability for evidentiary outputs produced to date? Does the absence of verification runs create any gap in the constitutional admissibility guarantee for historical evidence?"

---

**IQ-R-002**

*Invalid Form:* "For Phase 3 tasks, can we add replay survivability as a post-Phase-3 enhancement rather than a Definition of Done criterion?"

*Constitutional Defect:* This question treats replay survivability as an enhancement — an optional quality attribute that can be added after primary functionality is delivered. This is constitutionally impermissible. Evidence produced without replay survivability from its first production carries a permanent admissibility gap that cannot be retroactively repaired without reprocessing.

*Constitutional Invalidity Basis:* Replay doctrine (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §4.1); replay obligation in Phase 3 DoD (Canonical Capability Report §8.6).

*Legally Correct Reformulation:* "For this Phase 3 task, which evidentiary outputs does it produce? For each evidentiary output, what replay survivability mechanism is constitutionally required? Is that mechanism in the existing substrate, or does it require new substrate? The replay survivability requirement is a Definition of Done criterion, not a post-delivery enhancement."

---

**IQ-R-003**

*Invalid Form:* "Can we treat the Merkle archive infrastructure as a nice-to-have and focus Phase 3 on the core issuance pipeline first?"

*Constitutional Defect:* This question creates a category distinction between "core" infrastructure (issuance) and "non-core" infrastructure (replay/archive), treating the latter as separable from constitutional completeness. In Symphony's constitutional model, issuance without replay survivability produces constitutionally incomplete evidence.

*Constitutional Invalidity Basis:* Replay-survivable evidentiary platform doctrine; non-collapse doctrine.

*Legally Correct Reformulation:* "What replay survivability obligations attach to the issuance pipeline? Is the Merkle archive the designated replay substrate for issuance outputs? If so, is the issuance pipeline constitutionally complete without Merkle anchor wiring? The correct framing is not 'core vs. nice-to-have' but 'which obligations are unconditional for constitutional completeness.'"

---

**IQ-R-004**

*Invalid Form:* "Evidence signed with an old key version after key rotation was superseded — should we discard that evidence as invalid?"

*Constitutional Defect:* This question presupposes that signer key supersession retroactively invalidates evidence produced before supersession. This contradicts the historical admissibility continuity doctrine. Evidence signed before supersession carries the admissibility of the key at the time of signing.

*Constitutional Invalidity Basis:* Signer key rotation and historical admissibility doctrine (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §4.3); supersession vs. invalidation distinction (Rule NL-009).

*Legally Correct Reformulation:* "At what timestamp was this evidence signed? At what timestamp was the signing key superseded? Does Symphony's historical admissibility doctrine preserve the admissibility of evidence signed before the supersession event? Replay verification of this evidence must use the key version valid at the time of signing, not the current active key."

---

**IQ-R-005**

*Invalid Form:* "If we change the canonicalization algorithm from canon-v1 to canon-v2, do we need to reprocess all historical evidence?"

*Constitutional Defect:* This question presupposes that introduction of a new canonicalization version creates a retroactive obligation to reprocess historical evidence under the new version. It violates the canonicalization version binding doctrine.

*Constitutional Invalidity Basis:* Canonicalization version binding (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §4.2); parallel admissibility planes doctrine.

*Legally Correct Reformulation:* "canon-v2 creates a new admissibility plane for future evidence. Evidence produced under canon-v1 remains constitutionally admissible under canon-v1 indefinitely. The correct question is: does any downstream use of historical evidence require canon-v2 canonicalization? If so, that use must produce new canon-v2 evidence objects in parallel, without invalidating the canon-v1 originals."

---

## Part V: Invalid Regulator-Equivalence Questions

### Category IQ-RG: Questions That Flatten Regulator Sovereignty

These questions are constitutionally invalid because they presuppose that different regulatory jurisdictions, accreditation frameworks, or compliance domains occupy the same authority plane and can be compared, reconciled, or substituted without constitutional consequence.

---

**IQ-RG-001**

*Invalid Form:* "If a project satisfies VERRA VCS requirements, does it automatically satisfy the Zambia Carbon Market requirements?"

*Constitutional Defect:* This question presupposes that different regulatory jurisdictions are comparable via a containment or equivalence relationship. In Symphony's constitutional model, regulators are orthogonal sovereign domains. Satisfaction of one domain's requirements does not confer, imply, or approximate satisfaction of another domain's requirements.

*Constitutional Invalidity Basis:* Regulator-flattening prohibition (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.10); regulator orthogonality constraint (§3.3).

*Legally Correct Reformulation:* "Under which `app.jurisdiction_code` was VERRA VCS compliance verified? Under which `app.jurisdiction_code` is Zambia Carbon Market compliance verified? Are these the same jurisdiction context? If not, the two verification events are constitutionally non-comparable. Satisfaction of one does not address the other."

---

**IQ-RG-002**

*Invalid Form:* "Can we use the same interpretation pack for projects in multiple African jurisdictions to reduce implementation complexity?"

*Constitutional Defect:* This question presupposes that administrative simplicity justifies collapsing distinct regulatory jurisdictions into a shared interpretation pack. This violates jurisdiction RLS boundaries and regulator orthogonality.

*Constitutional Invalidity Basis:* Jurisdiction isolation enforcement (`rls_jurisdiction_isolation_interpretation_packs`); regulator partitioning doctrine.

*Legally Correct Reformulation:* "For each jurisdiction in which projects are registered, is there a constitutionally distinct regulatory authority with jurisdiction-specific interpretation requirements? If so, each jurisdiction requires a distinct interpretation pack scoped to its `jurisdiction_code`. Administrative simplification that crosses sovereign jurisdiction boundaries is constitutionally impermissible."

---

**IQ-RG-003**

*Invalid Form:* "Since Regulation 26 already enforces validator/verifier separation, do we need separate jurisdiction-level conflict-of-interest rules?"

*Constitutional Defect:* This question presupposes that a platform-level rule (`check_reg26_separation()`, `GF001`) satisfies jurisdiction-specific conflict-of-interest requirements. Jurisdiction-specific rules are sovereign and not pre-empted by platform-level rules.

*Constitutional Invalidity Basis:* Regulator-flattening prohibition; regulator orthogonality.

*Legally Correct Reformulation:* "What conflict-of-interest rule does `check_reg26_separation()` enforce, and at which sovereignty level (platform) does it operate? Do any active jurisdiction interpretation packs define conflict-of-interest rules that are more restrictive or differently structured than Regulation 26? If so, those rules coexist with Regulation 26 and are enforced in addition to, not instead of, the platform rule."

---

**IQ-RG-004**

*Invalid Form:* "If we get Article 6 authorization from Zambia, does that cover all Paris Agreement jurisdictions?"

*Constitutional Defect:* This question presupposes that a bilateral authorization event under Article 6 produces a universal authorization covering all Paris Agreement signatories. Jurisdictions under the Paris Agreement are orthogonal sovereign parties; authorization from one does not extend to others.

*Constitutional Invalidity Basis:* Regulator-flattening prohibition; regulator equivalence prohibition.

*Legally Correct Reformulation:* "Article 6 authorization from Zambia constitutes a constitutionally valid authorization within the Zambia sovereign domain. Separate authorization is required from each other Paris Agreement jurisdiction in which the project seeks ITMO recognition. Jurisdictions are orthogonal. The correct question is which jurisdiction's authorization is required for a specific downstream use."

---

## Part VI: Invalid Phase-Illegality Assumptions

### Category IQ-P: Questions That Misread Phase State as Permanent or Interchangeable

These questions are constitutionally invalid because they presuppose that the current capability state of Symphony is a permanent architectural state rather than a phase-bounded configuration, or that Phase N constraints apply to Phase N+1, or that Phase N+1 capabilities may be assumed to exist because Phase N is complete.

---

**IQ-P-001**

*Invalid Form:* "Phase 1 data has `data_authority_level = 'phase1_indicative_only'`. Can we upgrade it to `authoritative_signed` now that Wave 8 is available?"

*Constitutional Defect:* This question presupposes that a higher data authority level is constitutionally superior to `phase1_indicative_only` for all purposes, and that Phase 1 evidence should be retroactively upgraded. It ignores that `phase1_indicative_only` is a constitutional classification for Phase 1 evidence, not a quality deficit. The `enforce_phase1_boundary()` trigger (`GF071`/`GF072`) explicitly prohibits this elevation.

*Constitutional Invalidity Basis:* Phase 1 indicative status doctrine (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §5.2); phase-illegality misreading prohibition.

*Legally Correct Reformulation:* "Phase 1 evidence carries `phase1_indicative_only` as its permanent constitutional classification. It answers Phase 1 constitutional questions with Phase 1 authority. Wave 8 availability does not create an obligation or a constitutional path to elevate Phase 1 evidence. New evidence collected under Phase 2+ protocols carries Phase 2+ authority. It does not replace Phase 1 evidence; it is a distinct evidentiary record."

---

**IQ-P-002**

*Invalid Form:* "Since Phase 2 is complete, can we assume Phase 3 capabilities are now available?"

*Constitutional Defect:* This question presupposes that phase completion creates automatic availability of the next phase's capabilities. Phase 3 capabilities are constitutionally unavailable until the Phase 3 capability boundary has been formally declared and the constitutional ratification sequence (GOV-CONV-001 through GOV-CONV-007) has been completed.

*Constitutional Invalidity Basis:* Phase legality doctrine (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §5.1); phase boundary as constitutional threshold (§5.1); phase-illegality misreading prohibition.

*Legally Correct Reformulation:* "What is the current constitutional phase authorization state? Has GOV-CONV-007 been completed, establishing the Phase 3 constitutional boundary? Until that completion, Phase 3 capabilities are constitutionally undeclared and phase-illegal to assume or pre-populate."

---

**IQ-P-003**

*Invalid Form:* "Can we skip the Phase 2 constitutional ratification sequence if all the technical implementations are already in place?"

*Constitutional Defect:* This question presupposes that technical implementation completeness is equivalent to constitutional ratification. Constitutional ratification is a distinct act from technical implementation. Technical completeness without constitutional ratification produces an unlawfully advanced phase state.

*Constitutional Invalidity Basis:* Phase legality doctrine; phase boundary as constitutional threshold.

*Legally Correct Reformulation:* "Technical implementation and constitutional ratification are distinct constitutional acts. A phase is constitutionally complete when its ratification sequence is complete, not when its technical implementations pass CI. GOV-CONV-001 through GOV-CONV-007 are constitutional ratification acts, not optional documentation steps. Phase 3 decomposition is phase-illegal without their completion."

---

**IQ-P-004**

*Invalid Form:* "The attestation seam columns are already in the schema. Can Phase 3 tasks start populating them?"

*Constitutional Defect:* This question presupposes that schema presence is equivalent to population authorization. The attestation seam columns carry an explicit deferral declaration: "Population deferred to Wave 8." Population of deferred columns before their authorizing phase boundary is phase-illegal, regardless of schema readiness.

*Constitutional Invalidity Basis:* Deferred-implies-missing fallacy correction (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md §1.5); deferral as constitutional act (§1.5).

*Legally Correct Reformulation:* "Do the attestation seam columns carry a deferral declaration? If yes, which phase or wave authorizes their population? Has that authorization been constitutionally established? If not, population is phase-illegal. The correct sequence is: establish wave authorization → declare population as phase-legal → begin population."

---

**IQ-P-005**

*Invalid Form:* "Since Phase 1 is finished, can we remove the `enforce_phase1_boundary()` trigger now that it's no longer needed?"

*Constitutional Defect:* This question presupposes that a phase boundary trigger becomes obsolete after its phase ends. The `enforce_phase1_boundary()` trigger is a permanent constitutional boundary marker. Its purpose is not to prevent future Phase 1 data from being inserted; it is to ensure that historical Phase 1 data can never be retroactively re-classified under higher authority levels. This obligation is permanent.

*Constitutional Invalidity Basis:* Historical admissibility continuity doctrine; replay-survivable evidentiary platform doctrine.

*Legally Correct Reformulation:* "The `enforce_phase1_boundary()` trigger (`GF071`/`GF072`) is a permanent constitutional boundary assertion. It does not become obsolete when Phase 1 ends; it ensures that Phase 1 evidence retains its Phase 1 constitutional classification permanently. Removal of this trigger would expose Phase 1 evidence to retroactive authority re-classification, which is constitutionally impermissible."

---

## Part VII: Legal Constitutional Inquiry Framing

### 7.1 The Five-Part Constitutional Question Structure

All constitutionally valid questions directed at Symphony's architecture SHOULD follow this structure:

**1. Sovereignty Plane Identification:**
"What sovereignty plane(s) does this mechanism, table, or capability serve?"

**2. Authority Plane Attribution:**
"Which authority plane governs the question this mechanism answers?"

**3. Phase Legality Check:**
"Is the current state of this mechanism constitutionally correct for the current phase?"

**4. Replay Obligation Determination:**
"What replay obligations attach to this mechanism's outputs?"

**5. Cross-Domain Constraint Identification:**
"Which other sovereignty planes constrain or are constrained by this mechanism?"

Analytical conclusions drawn from questions that complete all five parts are constitutionally grounded. Conclusions drawn from questions that skip any part carry unresolved constitutional risk.

### 7.2 Admissible Analytical Framing

The following question forms are constitutionally admissible:

**Admissible — Sovereignty Plane Attribution:**
"Which of Symphony's sovereignty planes does mechanism X serve, and is that plane orthogonal to the plane served by mechanism Y?"

**Admissible — Activation Condition Inquiry:**
"What is the defined activation condition for this currently inactive substrate? Has that condition been triggered?"

**Admissible — Phase Legality Verification:**
"Is action A constitutionally permissible in Phase N? What phase boundary declaration authorizes it?"

**Admissible — Replay Obligation Audit:**
"Does capability X produce evidentiary outputs? If so, what replay survivability mechanism is constitutionally required for those outputs? Is that mechanism present in the current substrate?"

**Admissible — Authority Composition Inquiry:**
"In what sequence do enforcement mechanisms A, B, and C execute for operation X? Does failure in any mechanism independently block the operation? Do they answer the same constitutional question or different constitutional questions?"

**Admissible — Constitutional Gap Identification:**
"What capability is genuinely absent after repository inspection? Is its absence explained by a defined activation condition, a phase deferral, or an unwired substrate state? If none of these explain the absence, what is the constitutional impact of that gap?"

**Admissible — Admissibility Chain Reconstruction:**
"What is the complete chain of constitutional requirements for an asset batch to be admissible for downstream use X? Which requirement is answered by which mechanism at which sovereignty level?"

### 7.3 Prohibited Semantic Collapse Patterns

The following semantic collapses are constitutionally prohibited in question formation and analytical framing:

**Collapse PC-001 — Wave Flattening:**
Describing Wave 4 and Wave 8 mechanisms collectively as "the enforcement layer" or "the security layer" without distinguishing their sovereignty planes.

**Collapse PC-002 — Evidence Unification:**
Describing DB-layer enforcement and CI-layer evidence as "the evidence system" without distinguishing their authority planes.

**Collapse PC-003 — Phase Elision:**
Asking about Symphony's capability state without qualifying by phase. Questions of the form "does Symphony support X?" without phase qualification are constitutionally underspecified.

**Collapse PC-004 — Regulator Aggregation:**
Describing multiple jurisdiction requirements as "regulatory compliance" as though they constitute a single compliance domain.

**Collapse PC-005 — Authority Singularization:**
Asking "who has authority over X?" when X involves multiple sovereignty planes, each with its own constitutionally sovereign authority.

**Collapse PC-006 — Replay Separation:**
Describing Symphony's primary capabilities and Symphony's replay capabilities as distinct systems, one of which is optional. Replay is not a separate system; it is a constitutional obligation integrated into evidentiary outputs.

**Collapse PC-007 — Deferral Normalization:**
Describing deferred capabilities as "not yet implemented" without including the authorizing phase boundary. Deferral without phase context is constitutionally incomplete description.

---

## Part VIII: AI-Assisted Task Generation Inference Constraints

This section governs the specific inference patterns that AI agents, LLMs, and automated task generators MUST apply when generating Symphony tasks, Definitions of Done, execution envelopes, and roadmap items.

### 8.1 Mandatory Pre-Generation Checks

Before generating any task, DoD criterion, or roadmap item, an AI system MUST complete the following checks:

**Check TG-001 — Capability Existence Check:**
Consult SYMPHONY_CANONICAL_CAPABILITY_AND_ENFORCEMENT_REPORT.md before generating any task that creates, modifies, or extends an enforcement mechanism. Confirm that no equivalent mechanism already exists in the substrate. Reference Section 5 (Duplicate-Risk Matrix) of that document.

**Check TG-002 — Phase Legality Check:**
Confirm that the proposed task is constitutionally permissible in the current phase. Tasks that would populate deferred schema, wire unwired substrate, or declare new phase boundaries require explicit constitutional authorization.

**Check TG-003 — Sovereignty Plane Attribution:**
For every new mechanism proposed in a generated task, identify which sovereignty plane it will serve. If the proposed mechanism would serve a plane already served by an existing mechanism, apply convergence prohibition before proceeding.

**Check TG-004 — Replay Obligation Check:**
For every task that produces an evidentiary output, confirm that the task's DoD includes replay survivability as a criterion. If the required replay substrate does not exist, generate the replay substrate task first.

**Check TG-005 — Regulator Partitioning Check:**
For every task that produces jurisdiction-scoped outputs, confirm that the task specifies which jurisdiction context it operates under. Multi-jurisdiction tasks MUST be decomposed into jurisdiction-specific tasks.

### 8.2 Prohibited AI Task Generation Patterns

**Prohibited TG-P-001 — Convergence Tasks:**
Generating tasks of the form "Merge mechanism A and mechanism B into a unified C" without first establishing that A and B serve the same sovereignty plane and that no constitutional authority collapse results from their merger.

**Prohibited TG-P-002 — Cleanup Tasks Based on Inactivity:**
Generating tasks of the form "Remove table X because it has no rows" or "Delete function Y because it is not called by any service." Inactivity analysis requires activation condition verification before any removal task may be generated.

**Prohibited TG-P-003 — Retroactive Phase Re-Classification:**
Generating tasks that would retroactively re-classify Phase 1 evidence under Phase 2+ authority levels, or that would retroactively populate deferred columns with backfilled data not produced by the authorizing phase mechanism.

**Prohibited TG-P-004 — Replay Deferral in DoD:**
Generating Definitions of Done that do not include replay survivability criteria for tasks producing evidentiary outputs, under any framing that treats replay as a future enhancement.

**Prohibited TG-P-005 — Universal Authority Assignment:**
Generating tasks or DoD criteria that assign a single mechanism as "the" authoritative source for a multi-plane question, without preserving the distinct authority of each relevant sovereignty plane.

**Prohibited TG-P-006 — Jurisdiction Collapse Tasks:**
Generating tasks that consolidate jurisdiction-specific interpretation packs, conflict-of-interest rules, or verification requirements into multi-jurisdiction shared configurations without explicit constitutional authorization for that consolidation.

**Prohibited TG-P-007 — Phase Assumption Without Ratification:**
Generating Phase N+1 tasks before GOV-CONV constitutional ratification is complete for Phase N. Phase N+1 tasks generated without ratification are phase-illegal and MUST be blocked or flagged.

### 8.3 Required AI Task Generation Output Format

Every AI-generated task MUST include the following constitutional metadata:

```
Task-Phase-Scope: [PHASE-N | GLOBAL]
Sovereignty-Plane: [WAVE4-OPERATIONAL | WAVE8-PROVENANCE | GOVERNANCE | EVIDENCE | BOTH-WAVE4-WAVE8]
Replay-Obligation: [REQUIRED | NOT-APPLICABLE] + justification
Regulator-Scope: [JURISDICTION-SPECIFIC: <code> | PLATFORM-LEVEL | MULTI-JURISDICTION-DECOMPOSED]
Duplicate-Risk-Check: COMPLETED (reference Canonical Capability Report §5)
Phase-Legality: CONFIRMED (reference: <authorization document>)
```

Any generated task missing this metadata block is constitutionally underspecified and MUST NOT be executed.

### 8.4 DoD Generation Constitutional Requirements

Every AI-generated Definition of Done MUST:

1. Include at least one criterion for each sovereignty plane the task's outputs touch.
2. Include replay survivability as a criterion if the task produces evidentiary outputs.
3. Specify the jurisdiction context if the task produces jurisdiction-scoped outputs.
4. Reference the specific canonical enforcement mechanism (trigger name, function name, SQLSTATE code) that will enforce each criterion.
5. NOT include criteria that presuppose a single "final authority" determination.
6. NOT include criteria that defer replay survivability to a future phase.

### 8.5 Execution Envelope Constitutional Requirements

Every AI-generated execution envelope MUST:

1. Declare the phase scope of the envelope and confirm phase legality.
2. Identify all sovereignty planes the envelope's operations will touch.
3. Specify which enforcement mechanisms will gate each operation.
4. Declare the replay survivability mechanism for all evidentiary outputs.
5. Specify cross-jurisdiction handling for any jurisdiction-scoped outputs.
6. Reference the Canonical Capability Report to confirm no duplicate mechanism is being created.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
- Constitutional validity of query formation across all Symphony sovereignty planes
- AI task generation inference constraints
- Analytical framing admissibility for all Symphony architectural analysis
- Definition of Done and execution envelope constitutional requirements
- NotebookLM query synthesis doctrine

**Sovereignty domains this document MUST NOT redefine:**
- The substantive content of enforcement mechanisms (governed by source migrations)
- The specific phase transition criteria and ratification requirements (governed by phase lifecycle documents)
- The content of specific jurisdiction interpretation packs (governed by regulator-partitioned instruments)
- The specific GF-prefix SQLSTATE assignments (governed by the SQLSTATE canonical map)
- The specific invariant identifiers and content (governed by INVARIANTS_MANIFEST.yml)

**Replay obligations preserved:**
- Invalid replay-dismissal question forms (Part IV) are prohibited across all phases and all contexts.
- Replay survivability is defined as a DoD criterion obligation for evidentiary outputs (§8.4).
- Historical admissibility continuity is preserved by prohibiting retroactive re-canonicalization and retroactive key invalidation (IQ-R-004, IQ-R-005).
- Replay infrastructure is defined as a constitutional permanence obligation, not a disaster recovery feature.

**Regulator boundaries constraining this document:**
- This document governs internal architectural query doctrine. It does not govern the substantive content of jurisdiction-specific requirements.
- The jurisdiction isolation boundary (`current_jurisdiction_code_or_null()`) constrains the scope of any cross-jurisdiction query or task generation.
- Regulator orthogonality doctrine constrains all comparative regulatory analysis.

**Phases this document applies to:**
GLOBAL — this document applies from Phase 1 onward through all future phases. Its AI task generation constraints (Part VIII) apply beginning with Phase 3 decomposition.

**Constitutional layers possessing override authority over this document:**
No lower-ranked document possesses override authority over this document (Authority-Rank: 10). Override authority is reserved for future ROOT-level constitutional instruments that explicitly supersede this document by name and provide a replacement doctrine for each section superseded.

**Lower-layer documents prohibited from reinterpretation:**
- Phase-specific execution envelopes
- Wave-specific implementation guides
- Task-level Definitions of Done
- Governance convergence documents (GOV-CONV series)
- Agent-specific authority documents (AGENTS.md, AGENT_ENTRYPOINT.md)
- Any document with Authority-Rank < 10

These documents apply the query and inference doctrine defined herein. They may not qualify, narrow, expand, or reinterpret it.

---

## Prohibited Misinterpretations

**PMI-001 — This Document as a Query Filter:**
This document MUST NOT be interpreted as a filter that blocks certain questions from being asked. It is a doctrine that governs how questions MUST be formed to be constitutionally valid. Any question may be asked; not all forms of asking are constitutionally valid.

**PMI-002 — Invalid Question Forms as Unanswerable:**
The "invalid question forms" defined in Parts II–VI MUST NOT be interpreted as questions that cannot be answered. They are questions that, if answered in their invalid form, will produce constitutionally inadmissible analysis. The correct response is to reformulate the question, not to refuse engagement.

**PMI-003 — AI Constraints as Human Constraints:**
The AI task generation constraints in Part VIII apply to AI-assisted generation. They MUST NOT be applied as if they prohibit human architects from exploring architectural questions in invalid forms during design. The constraints govern what is produced as a constitutional output, not what is explored during deliberation.

**PMI-004 — Legal Inquiry Form as Exhaustive:**
The five-part constitutional question structure in §7.1 is a sufficient condition for constitutional validity, not a necessary one. Questions that are constitutionally valid on other grounds are not invalidated by failing to follow the five-part structure exactly.

**PMI-005 — Admissible Framing as Endorsed Conclusions:**
The admissible analytical framing defined in §7.2 defines valid question forms. It does not endorse any specific answer. A constitutionally well-formed question may produce a finding that challenges existing architectural assumptions. Constitutional validity of the question does not predetermine the answer.

**PMI-006 — Phase Illegality as Permanent Prohibition:**
A task described as "phase-illegal" in the current phase MUST NOT be interpreted as permanently prohibited. Phase illegality is phase-bounded. A task that is phase-illegal in Phase N may be constitutionally authorized in Phase N+1 by the appropriate ratification event.

**PMI-007 — Regulator Orthogonality as Non-Cooperation:**
The doctrine that regulators are orthogonal sovereign domains MUST NOT be interpreted as a prohibition on multi-jurisdiction project operation. It defines how jurisdictions must be handled (separately, with distinct interpretation packs and jurisdiction contexts), not whether multi-jurisdiction operation is permissible.

**PMI-008 — Prohibited Semantic Collapses as Prohibited Terminology:**
The semantic collapse prohibitions in §7.3 govern the analytical meaning embedded in questions and outputs, not the use of shorthand terminology in informal communication. "The enforcement layer" in casual discussion is not constitutionally prohibited; describing two distinct sovereignty planes as constitutionally equivalent in formal analysis is.
