# NON-INFERENCE AND INTERPRETATION LIMITS

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md, CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md

---

## Purpose

This document defines the boundaries of constitutional inference within Symphony. It prohibits specific patterns of architectural reasoning that, when applied to Symphony's constitutional substrate, produce conclusions that are constitutionally void, sovereignty-destructive, or admissibility-harmful — regardless of how internally coherent those conclusions may appear to a conventional software analysis framework.

Symphony's constitutional architecture contains features that are predictably misread by inference patterns borrowed from conventional software system analysis. These misreadings arise because conventional software reasoning applies assumptions about system design — that parallel systems imply conflict, that inactive components imply obsolescence, that deferred elements imply incompleteness — that are constitutionally false within Symphony's sovereign trust coordination architecture.

This document names each prohibited inference pattern with precision, defines why it is constitutionally impermissible, and provides corrected constitutional reframings. It applies to all actors performing interpretive reasoning about Symphony: human engineers, constitutional custodians, automated analysis systems, and AI synthesis tools including NotebookLM.

---

## Constitutional Scope

This document governs:

1. The prohibited inference patterns applicable to all interpretation of Symphony's constitutional architecture.
2. The constitutional inference legality rules defining what reasoning may lawfully be applied to Symphony's constitutional substrate.
3. The sovereignty-aware, replay-aware, and phase-aware interpretation constraints applicable to all interpretive acts.
4. The corrected constitutional reframings for each prohibited inference pattern.
5. The NotebookLM anti-drift interpretation rules applicable to synthesis outputs ingesting this corpus.

This document does NOT govern:

- The authority rank of specific artifact classes (governed by CONSTITUTIONAL_AUTHORITY_HIERARCHY.md).
- The priority ordering of competing constitutional obligations (governed by CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md).
- The procedures for constitutional amendment (governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md).
- The assignment of interpretation authority to document classes (governed by CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md).

---

## Authority Boundaries

This document operates at Authority-Rank 10 (ROOT). Its prohibited inference rules are constitutionally binding on all artifact classes. No lower-rank artifact, including wave sovereignty doctrine, phase doctrine, enforcement doctrine, migration records, operational artifacts, repository observations, or AI syntheses, may apply reasoning patterns that violate the inference limits defined herein. Application of a prohibited inference pattern in any constitutional artifact constitutes a constitutional defect.

---

## Foundational Principle: Symphony Is Not a Conventional Software System

The prohibited inference patterns defined in this document arise from a single foundational error: applying conventional software system reasoning to a constitutional trust coordination substrate. Conventional software reasoning treats systems as efficiency-optimized, convergence-seeking, and architecturally unified. Symphony's constitutional architecture is none of these things.

Symphony is:
- **Sovereignty-partitioned by design.** Parallel authority surfaces are not redundancies to be collapsed; they are constitutional partitions to be preserved.
- **Replay-survivable by constitution.** Inactive or deferred components are not dead weight; they may be constitutional permanence infrastructure.
- **Regulator-orthogonal by requirement.** Multiple admissibility standards are not inconsistencies to be harmonized; they are independent domain requirements to be satisfied independently.
- **Phase-bounded by legality.** Deferred capabilities are not missing features; they are constitutionally deferred to the phase in which they become legally capable.
- **Provenance-independent from runtime.** Cryptographic sovereignty does not derive its authority from operational consensus; it constitutes an independent sovereignty surface.

Every prohibited inference pattern in this document is a specific application of conventional software reasoning to a constitutional architecture for which it is not designed. Each pattern produces conclusions that are internally coherent within the conventional framework but constitutionally void within Symphony's framework.

---

## Catalogue of Prohibited Inference Patterns

### Pattern PI-1: Parallel Implies Conflict

**Statement of prohibited inference:**
When two authority surfaces, registry systems, signing mechanisms, or enforcement paths address the same domain, the inference that they are in conflict with each other, that one is redundant, that one must be eliminated, or that they must be converged into a single unified system.

**Why constitutionally impermissible:**
Symphony's constitutional architecture intentionally maintains parallel authority surfaces that address the same domain from different sovereignty perspectives. Wave 4 and Wave 8 both address the authority to process records, but they do so from orthogonal sovereignty surfaces — operational/runtime and provenance/cryptographic respectively. Their parallelism is constitutionally deliberate. It is not a system design error, a transitional state, or an architectural debt requiring resolution.

Similarly, `enforce_transition_signature` and `wave8_cryptographic_enforcement` both address signing in the state transitions and asset batches paths respectively. Their parallel existence reflects the constitutional distinction between these write paths' sovereignty models, not a duplication requiring consolidation.

**Constitutional fact:**
Parallel authority surfaces in Symphony are constitutionally orthogonal. Orthogonality is not conflict. Conflict exists when two authorities within the same sovereignty domain produce contradictory determinations within that domain. Parallelism between two authorities in different sovereignty domains is the expected and constitutionally required state.

**Corrected constitutional reframing:**
*Prohibited:* "Both `enforce_transition_signature` and `wave8_cryptographic_enforcement` address signing. They should be consolidated into a single signing enforcement path."
*Correct:* "`enforce_transition_signature` enforces signing on the Wave 4 state transitions path. `wave8_cryptographic_enforcement` enforces signing on the Wave 8 asset batches path. These are distinct write paths under distinct sovereignty models. Their parallel existence is constitutionally required, not constitutionally problematic."

---

### Pattern PI-2: Inactive Implies Obsolete

**Statement of prohibited inference:**
When a constitutional component — trigger, function, table, registry, or enforcement surface — is not currently invoked, not currently receiving writes, not currently read by any active path, or is present in the constitutional record without observable runtime activity, the inference that it is obsolete, deprecated, dead code, or a candidate for removal.

**Why constitutionally impermissible:**
Inactivity within Symphony's constitutional architecture carries no constitutional meaning. A component's activity level is determined by the current operational phase, the current cryptographic infrastructure availability, and the current wave activation state. A component that is constitutionally inactive at the current moment may be:
- **Constitutionally dormant:** Awaiting a phase transition that will activate it.
- **Constitutionally deferred:** Its activation is defined in governing phase or wave doctrine as occurring at a specified constitutional moment.
- **Constitutionally protected:** Its presence in the record is required for historical admissibility continuity regardless of current activity.
- **Constitutionally necessary for replay:** Its schema must remain intact for replay events to be executable against the historical constitutional state.

Declaring an inactive component obsolete and removing it would constitute an unauthorized alteration of the constitutional record and may destroy replay survivability, historical admissibility continuity, or sovereignty infrastructure awaiting activation.

**Constitutional fact:**
The activity level of a constitutional component is not a constitutional indicator. Constitutional status — active, dormant, deferred, scaffolded — is determined by governing constitutional doctrine, not by operational observation of activity.

**Corrected constitutional reframing:**
*Prohibited:* "`historical_verification_runs` has no active writers or readers. It is dead schema and should be removed."
*Correct:* "`historical_verification_runs` is constitutionally present. Its current inactivity reflects its governance by applicable wave or phase doctrine. Its constitutional status — whether dormant, deferred, or awaiting activation — is determined by that doctrine, not by observing its current activity level. Removal requires Root constitutional amendment, not operational cleanup."

---

### Pattern PI-3: Unwired Implies Accidental

**Statement of prohibited inference:**
When a constitutional component exists in the schema but has no enforcement connection to active triggers, functions, or CI gates — that is, when it is "unwired" to the active enforcement graph — the inference that its unwired state is a mistake, an oversight, an implementation gap, or an accidental omission requiring remediation.

**Why constitutionally impermissible:**
Unwired components in Symphony may represent:
- **Constitutionally scaffolded substrate:** Schema established ahead of activation, where the activation condition is defined in governing doctrine.
- **Convergence-obligated substrate:** Components that have a declared convergence obligation to active surfaces (as documented in the CONSTITUTIONAL_GRAPH) but whose convergence is constitutionally deferred to a specific phase or wave activation event.
- **Declarative registry:** Components that declare constitutional existence and will be populated upon the constitutional moment defined for their activation.
- **Sovereignty-partitioned substrate:** Components that are intentionally isolated from one enforcement path because they belong to a different sovereignty partition.

Treating unwired substrate as accidental and connecting it to arbitrary enforcement paths would constitute an unauthorized alteration of the constitutional enforcement topology, potentially creating authority collapses or sovereignty boundary violations.

**Constitutional fact:**
Whether an unwired substrate is accidental or constitutionally intentional is determined by governing constitutional doctrine, not by observing that it has no current enforcement connections. The CONSTITUTIONAL_GRAPH's identification of convergence obligations describes what these components are expected to converge to; it does not authorize arbitrary wiring in advance of the constitutionally defined convergence event.

**Corrected constitutional reframing:**
*Prohibited:* "`public_keys_registry` has no enforcement connections. This is an implementation gap that should be fixed by connecting it to the signing enforcement path."
*Correct:* "`public_keys_registry` is constitutionally declared and has a documented convergence obligation to `wave8_signer_resolution`. Its current unwired state reflects a constitutionally deferred convergence. The convergence is to be executed at the constitutional moment defined in Wave 8 Sovereignty Doctrine, not arbitrarily in advance of that moment."

---

### Pattern PI-4: Scaffold Implies Dead Schema

**Statement of prohibited inference:**
When a component is identified as "scaffolded" — meaning its schema exists but its full enforcement and operational population are not yet active — the inference that it is empty, non-functional, constitutionally irrelevant, or safely removable without consequence.

**Why constitutionally impermissible:**
Scaffolded schema in Symphony serves multiple constitutional functions that are not visible from operational observation:
- It establishes the constitutional existence of the component in the migration record, creating an evidentiary anchor for the component's future activation.
- It defines the schema that future enforcement will use, ensuring that constitutional enforcement added in later migrations operates on a stable, constitutionally registered schema.
- It may carry temporal constraints, foreign key relationships, or uniqueness indexes that are constitutionally operative even before the component's primary enforcement path is active.
- Its presence in the constitutional record is a constitutional act that cannot be undone without a formal supersession event.

Removing scaffolded schema breaks the constitutional record continuity, may destroy the admissibility basis for future records that will be admitted under the scaffolded schema's structure, and constitutes an unauthorized constitutional amendment.

**Constitutional fact:**
"Scaffolded" is a constitutional status indicating that a component's schema is constitutionally established and awaiting its designated activation event. It is not a synonym for "empty" or "unused."

**Corrected constitutional reframing:**
*Prohibited:* "`delegated_signing_grants` is just a scaffold with no data. It adds no value in its current state and can be dropped."
*Correct:* "`delegated_signing_grants` has a constitutionally established schema and a documented convergence obligation to the Wave 8 cryptographic enforcement path. Its scaffolded status confirms its constitutional existence. Its current empty state reflects its position in the activation sequence. Dropping it would break the constitutional record and require a formal amendment."

---

### Pattern PI-5: Deferred Implies Missing

**Statement of prohibited inference:**
When a constitutional capability, component, or obligation is classified as deferred — meaning its activation, population, or enforcement is assigned to a future constitutional moment — the inference that it is absent, incomplete, not yet designed, or a gap in the constitutional architecture.

**Why constitutionally impermissible:**
Deferral in Symphony is a constitutional status, not an absence. A deferred capability has been constitutionally defined, its activation conditions have been specified in governing doctrine, and its deferred state is itself constitutionally authoritative. Treating deferral as absence produces the following constitutional harms:
- It mischaracterizes the completeness of the constitutional architecture.
- It may prompt unauthorized activation attempts outside the constitutionally defined activation sequence.
- It leads to incorrect admissibility assessments for records that depend on the deferred component's eventual activation.
- It produces incorrect constitutional health assessments that declare the architecture incomplete when it is in fact constitutionally phased.

**Constitutional fact:**
Deferral is an affirmative constitutional classification. A deferred component is constitutionally present in its deferred state. Its absence from current operational enforcement is the constitutionally correct state for this moment in the activation sequence.

**Corrected constitutional reframing:**
*Prohibited:* "The `invariant_registry` has no runtime reader. This is a missing implementation that needs to be built."
*Correct:* "The `invariant_registry` is constitutionally declared with its append-only constraint active. Its runtime reader is constitutionally deferred, with a documented convergence obligation to CI enforcement scripts. The absence of the runtime reader reflects the current position in the activation sequence. The reader is to be implemented at the constitutionally defined convergence event, not as an emergency remediation."

---

### Pattern PI-6: Multiple Authorities Imply Convergence Pressure

**Statement of prohibited inference:**
When multiple authority surfaces address related constitutional domains — multiple signing registries, multiple admissibility surfaces, multiple enforcement triggers on related tables — the inference that these must converge into a single unified authority, that their multiplicity is a transitional state, or that architectural health requires their consolidation.

**Why constitutionally impermissible:**
Symphony's constitutional architecture maintains multiple authorities in related domains precisely because those domains require independent sovereign treatment. The multiplicity of authority surfaces is not a transitional state en route to a unified architecture; it is the constitutionally required steady state for a regulator-partitioned, wave-partitioned trust coordination system.

Convergence pressure — the assumption that multiple related authorities should eventually become one — produces:
- Sovereignty domain collapse when applied to Wave 4 / Wave 8 authority surfaces.
- Regulator domain merger when applied to regulator-partitioned admissibility surfaces.
- Phase capability collapse when applied to phase-specific enforcement surfaces.

Where convergence obligations exist (as documented in the CONSTITUTIONAL_GRAPH), they are constitutionally specific: a particular unwired component is obligated to converge with a particular active surface at a constitutionally defined moment. This does not generalize to a systemic convergence pressure across all parallel authorities.

**Constitutional fact:**
Multiple authorities in related domains are constitutionally expected and constitutionally protected. Convergence is a specific, documented, constitutionally bounded obligation where it exists. It is not a general architectural imperative.

**Corrected constitutional reframing:**
*Prohibited:* "Symphony has two signer resolution mechanisms: `wave8_signer_resolution` (active) and `public_keys_registry` (scaffolded). They should be merged into one."
*Correct:* "`wave8_signer_resolution` is the active Wave 8 signer resolution mechanism. `public_keys_registry` is a constitutionally declared registry with a convergence obligation to `wave8_signer_resolution`. The convergence obligation requires `public_keys_registry` to be wired into the Wave 8 enforcement path at the constitutionally defined moment, not merged with or replacing `wave8_signer_resolution`."

---

### Pattern PI-7: Runtime Supremacy

**Statement of prohibited inference:**
When operational/runtime behavior produces a determination — a record is processed, a state transition is accepted, a settlement is completed — the inference that this runtime determination is constitutionally authoritative and that any constitutional obligation that was not enforced at runtime is thereby waived, satisfied, or overridden.

**Why constitutionally impermissible:**
Runtime supremacy is constitutionally void in Symphony. The operational enforcement surfaces (Wave 4 runtime sovereignty) express constitutional obligations; they do not define them. Where a runtime surface fails to enforce a constitutional obligation — whether because of a stub implementation, a conditional path, a missing extension, or an implementation gap — the constitutional obligation persists. The record produced in the absence of full enforcement is operationally present but constitutionally defective in the dimensions where enforcement was absent.

This is especially critical for the cryptographic enforcement path: `verify_ed25519_signature` returning `true` unconditionally does not constitute cryptographic validation. The record passes the trigger check but does not satisfy the Wave 8 provenance integrity obligation. Runtime passage is not constitutional satisfaction.

**Constitutional fact:**
Runtime acceptance of a record establishes its operational admissibility within the current enforcement surface's capability. It does not establish its constitutional validity against all applicable sovereignty obligations. Constitutional validity is determined by governing constitutional doctrine, not by runtime enforcement outcome.

**Corrected constitutional reframing:**
*Prohibited:* "The record passed `enforce_transition_signature`. It is therefore constitutionally signed."
*Correct:* "The record passed `enforce_transition_signature`, which enforces signature presence only. This establishes that the `transition_hash` field is populated. It does not establish cryptographic signature validity under Wave 8 provenance doctrine, which requires actual cryptographic verification via `ed25519_verify()`. The record's constitutional signature status under Wave 8 is governed by Wave 8 Sovereignty Doctrine, not by the outcome of the Wave 4 presence-check trigger."

---

### Pattern PI-8: Provenance Subordination

**Statement of prohibited inference:**
When a runtime operational determination and a cryptographic provenance determination are simultaneously applicable to a record, the inference that the runtime determination is primary or superior, that the provenance determination is a supplementary check, or that provenance authority derives from and is validated by operational authority.

**Why constitutionally impermissible:**
Wave 8 provenance/cryptographic sovereignty is constitutionally independent of Wave 4 operational/runtime sovereignty. Neither sovereignty surface derives its authority from the other. Neither validates the other. They are orthogonal constitutional surfaces that produce independent determinations about records within their respective domains.

Provenance subordination produces the constitutional harm of allowing operationally accepted records to evade Wave 8 cryptographic accountability by treating Wave 4 acceptance as Wave 8 validation. It eliminates the independent evidentiary function of the provenance sovereignty surface and reduces Symphony's trust coordination architecture to a single-layer operational system.

**Constitutional fact:**
Wave 8 provenance integrity is a sovereignty obligation independent of and not subordinate to Wave 4 runtime determination. A record that passes Wave 4 operational enforcement and fails Wave 8 cryptographic enforcement is constitutionally defective in the Wave 8 dimension regardless of its Wave 4 status.

**Corrected constitutional reframing:**
*Prohibited:* "The record was accepted by the Wave 4 runtime enforcement surface. Wave 8 provides additional assurance but the record is constitutionally valid based on Wave 4 acceptance."
*Correct:* "The record's constitutional validity under Wave 4 operational sovereignty is established by Wave 4 enforcement. Its constitutional validity under Wave 8 provenance sovereignty is an independent determination made by Wave 8 enforcement. Both determinations are required. Wave 4 acceptance does not satisfy Wave 8 requirements. Wave 8 non-compliance is a constitutional defect regardless of Wave 4 acceptance status."

---

### Pattern PI-9: Replay Irrelevance

**Statement of prohibited inference:**
When a record or event class has not been explicitly associated with a replay obligation in current operational documentation, or when the replay infrastructure for a record class is dormant or unwired, the inference that replay obligations do not apply to that record class, that the record may be altered or deleted, or that replay is an optional feature rather than a constitutional requirement.

**Why constitutionally impermissible:**
Replay survivability is Priority 1 in Symphony's constitutional priority ordering. It is constitutional permanence infrastructure. The absence of documented explicit replay association in operational records does not constitute the absence of replay obligation. Replay obligations are established by constitutional doctrine, not by operational documentation inventory. An undocumented replay obligation is still a replay obligation.

Furthermore, the dormancy or unwired status of replay infrastructure (e.g., `historical_verification_runs`, `archive_verification_runs`, `resign_sweeps`) does not reduce the constitutional replay obligation. The infrastructure awaits activation; the obligation is already operative.

**Constitutional fact:**
Replay obligations attach to record classes by constitutional doctrine. Their documentation in operational materials is evidence of the obligation; absence of documentation in operational materials is not evidence of the obligation's absence. The presumption of replay obligation applies to all constitutionally significant record classes until governing doctrine explicitly establishes otherwise.

**Corrected constitutional reframing:**
*Prohibited:* "`signing_audit_log` has no active writer. Since it is not currently populated, there are no replay obligations associated with it."
*Correct:* "`signing_audit_log` is constitutionally declared and has a documented convergence obligation to the active signing path. The absence of an active writer reflects a constitutional deferral. Replay obligations for signing audit records exist by constitutional doctrine regardless of current writer activity. When the writer is activated, the resulting records will carry replay obligations from their constitutional inception."

---

### Pattern PI-10: Regulator Flattening

**Statement of prohibited inference:**
When multiple regulator domains impose admissibility requirements on record classes within Symphony, the inference that a single unified admissibility standard can or should be established, that admissibility in the most demanding domain constitutes admissibility in all domains, that admissibility standards can be averaged or harmonized, or that regulator domain boundaries are implementation distinctions rather than constitutional partitions.

**Why constitutionally impermissible:**
Regulator domains in Symphony are constitutionally orthogonal sovereign partitions. Each domain's admissibility standard is constitutionally independent. No domain's standard governs any other domain. Regulator flattening — treating multiple admissibility standards as a single unified standard — is constitutionally equivalent to sovereignty domain collapse in the regulator dimension.

Flattening produces:
- False admissibility determinations (records admitted in all domains by satisfying only one domain's requirements).
- False inadmissibility determinations (records denied in all domains because they fail one domain's requirements they were never constitutionally required to satisfy).
- Regulatory arbitrage opportunities where the least demanding domain's standard is treated as universal.
- Destruction of the independent evidentiary function of each regulator domain.

**Constitutional fact:**
Admissibility in each regulator domain must be evaluated independently against that domain's governing Regulator Partition Doctrine. There is no universal admissibility determination in Symphony. A record may be simultaneously admissible in Domain A and inadmissible in Domain B; this is the correct constitutional outcome, not an inconsistency to be resolved.

**Corrected constitutional reframing:**
*Prohibited:* "If a record satisfies the most stringent regulator domain's requirements, it satisfies all domains. We can optimize by targeting the highest standard."
*Correct:* "Each regulator domain's admissibility requirements must be satisfied independently. A record satisfying Domain A's requirements is admissible in Domain A. Its status in Domain B is evaluated independently against Domain B's requirements. Targeting the highest standard may satisfy the most demanding domain's requirements; it does not constitute or substitute for independent evaluation in each domain."

---

## Constitutional Inference Legality

The following defines what inferential reasoning may lawfully be applied to Symphony's constitutional architecture:

### Permitted Inferential Reasoning

**PIL-1. Constitutional text-grounded inference.**
Inference from the explicit text of constitutional documents, within the interpreting document class's scope and authority, is constitutionally permitted. Text-grounded inference reasons from what constitutional documents explicitly state to conclusions that necessarily follow from that text without introducing new constitutional obligations, redefining sovereignty boundaries, or altering admissibility standards.

**PIL-2. Topology description from evidence.**
Descriptive inference about the current state of Symphony's constitutional topology — which components are active, which are dormant, which enforcement connections exist, which convergence obligations are documented — is constitutionally permitted as description. This is the function performed by CONSTITUTIONAL_GRAPH.md. Such description carries Rank 1 authority and is not constitutionally binding as interpretation.

**PIL-3. Phase-conditioned capability inference.**
Inference that a specific operation is constitutionally permitted or prohibited within a specific phase, based on the explicit capability boundary defined in that phase's governing doctrine, is constitutionally permitted within Phase Constitutional Doctrine's interpretation scope.

**PIL-4. Sequential record reconstruction.**
Inference from the sequential record of migrations that a specific constitutional state existed at a specific migration tip is constitutionally permitted within the Constitutional Migration Record's authority. This inference reconstructs what was enacted; it does not interpret what enacted provisions mean.

**PIL-5. Admissibility condition inference within domain.**
Inference within a regulator domain that a specific record satisfies or fails to satisfy that domain's explicit admissibility requirements is constitutionally permitted within the governing Regulator Partition Doctrine's interpretation scope.

### Prohibited Inferential Reasoning

**PIB-1. Gap-filling inference.**
Inference that where a constitutional document is silent, a specific rule applies by analogy to adjacent provisions or conventional practice. Constitutional gaps must be addressed through authorized interpretation (per CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md) or amendment, not by inferential gap-filling.

**PIB-2. Intent inference.**
Inference about the intent of constitutional actors based on migration commentary, operational behavior, or historical context. Constitutional provisions mean what they explicitly state. Author intent that is not expressed in constitutional text has no constitutional standing.

**PIB-3. Convergence-by-analogy inference.**
Inference that because two components addressed similar domains in similar ways in other systems, they should converge in Symphony. Symphony's constitutional architecture is not comparable to other systems on this question.

**PIB-4. Operational-precedent inference.**
Inference that because a constitutional component has behaved in a certain way consistently, that behavior constitutes or establishes the constitutional rule. Operational precedent has no constitutional standing (see Pattern PI-7).

**PIB-5. Synthesis-based inference.**
Inference derived from AI synthesis, NotebookLM output, or analytical aggregation about what constitutional provisions mean or require. Synthesis products carry Rank 0 authority and may not be the basis for constitutional inference.

---

## Sovereignty-Aware Interpretation Constraints

All interpretive reasoning about Symphony must be conducted within the following sovereignty-aware constraints:

**SAC-1. Wave orthogonality constraint.**
No interpretation may assume that Wave 4 and Wave 8 determinations about the same record are mutually substitutable, that one validates the other, or that a single wave's determination is sufficient. Both waves' determinations are required independently.

**SAC-2. Regulator independence constraint.**
No interpretation may assume that admissibility in one regulator domain implies, substitutes for, or constrains admissibility in another domain. Each domain's admissibility evaluation is constitutionally independent.

**SAC-3. Domain boundary preservation constraint.**
No interpretation may produce an outcome that, as a necessary consequence, collapses, merges, or subordinates any sovereignty domain. An interpretation that produces this outcome is constitutionally impermissible regardless of the apparent logic of the reasoning.

**SAC-4. Non-attribution of deficiency.**
No interpretation may attribute constitutional deficiency — incompleteness, inconsistency, or error — to Symphony's constitutional architecture based on the presence of parallel, dormant, deferred, or scaffolded components. The presence of such components is consistent with constitutional design.

**SAC-5. Supremacy of constitutional doctrine over operational observation.**
No observation of operational behavior — including consistently applied enforcement logic, consistently accepted records, consistently unused components — may override the constitutional obligations established by governing doctrine. Doctrine governs behavior; behavior does not govern doctrine.

---

## Replay-Aware Interpretation Doctrine

All interpretive reasoning about Symphony must be conducted within the following replay-aware constraints:

**RAC-1. Presumption of replay obligation.**
In the absence of explicit constitutional doctrine establishing that a record class is exempt from replay obligations, the presumption is that replay obligations apply. The burden of establishing replay-obligation exemption falls on the governing doctrine; it does not fall on those asserting the obligation's existence.

**RAC-2. Historical state reconstructability as interpretation constraint.**
No interpretation may be adopted that, if applied to historical records, would render the constitutional state at any prior constitutional moment unreconstruable. Interpretations must preserve the capacity to reconstruct prior constitutional states for replay evaluation.

**RAC-3. Replay infrastructure dormancy is not replay obligation absence.**
The dormancy, unwired status, or inactivity of replay infrastructure components does not constitute the absence of replay obligations for the record classes they serve. Replay obligations are established by doctrine; their infrastructure is a separate question.

**RAC-4. Replay scope is not reduced by operational scope.**
If the current operational write path for a record class is narrower than the full constitutional record class, replay obligations apply to the full constitutional record class, not only to currently written records.

**RAC-5. Future replay evaluates against historical doctrine.**
Interpretations that alter constitutional doctrine must preserve the capacity to replay historical events against the doctrine that was operative when those events occurred. The interpretation's prospective application does not extend retroactively to prior events.

---

## Phase-Aware Interpretation Legality

All interpretive reasoning about Symphony must be conducted within the following phase-aware constraints:

**PAC-1. Phase capability boundaries are constitutional constraints, not operational guidelines.**
No interpretation may treat a phase capability boundary as a recommendation, a default, or an operational preference that can be overridden by operational necessity. Phase boundaries are constitutionally enforceable constraints.

**PAC-2. Records are evaluated against their production-phase doctrine.**
A record produced during Phase N is evaluated for constitutional admissibility and replay eligibility against the constitutional doctrine operative during Phase N. Current-phase doctrine does not retroactively govern prior-phase records.

**PAC-3. Deferred capabilities are phase-conditioned, not absent.**
A capability deferred to Phase N+1 is constitutionally present as a deferred capability. It is not absent from the constitutional architecture. Its deferred status does not imply that its constitutional design is incomplete.

**PAC-4. Phase transition does not invalidate prior-phase records.**
A constitutionally executed phase transition does not alter the admissibility status of records produced in the prior phase. Phase transitions are prospective; they do not retroactively govern prior records.

**PAC-5. Phase-conditioned inference is bounded by phase scope.**
Interpretive reasoning that is valid within a specific phase's doctrine is bounded by that phase's scope. It does not generalize to other phases without independent authorization.

---

## Invalid Inference Examples with Corrected Constitutional Reframings

### Example INF-1: `verify_ed25519_signature` Is Constitutionally Operative

**Invalid inference:** "`verify_ed25519_signature` exists as a SECURITY DEFINER function in the migration record and is called by the signing enforcement path. Therefore it constitutes cryptographic enforcement."

**Why invalid:** This inference applies Pattern PI-7 (Runtime Supremacy). The function's existence and invocation are observable. Its constitutional status — that it returns `true` unconditionally and constitutes a shadow authority surface — is established by constitutional doctrine, not by operational observation of its invocation.

**Corrected constitutional reframing:** "`verify_ed25519_signature` is constitutionally classified as a shadow authority surface. It is invoked in the signing path but returns `true` unconditionally, providing no actual cryptographic validation. Its invocation does not satisfy Wave 8 provenance integrity obligations. Its constitutional status is determined by Wave 8 Sovereignty Doctrine, which requires actual `ed25519_verify()` cryptographic validation. The function's presence and invocation establish that it is in the enforcement path; they do not establish that it satisfies the enforcement obligation."

---

### Example INF-2: Dormant Evidence Tables Are Safe to Remove

**Invalid inference:** "`historical_verification_runs`, `archive_verification_runs`, and `resign_sweeps` have no active writers. They are dormant and can be safely removed to simplify the schema."

**Why invalid:** This inference applies Pattern PI-2 (Inactive Implies Obsolete) and Pattern PI-9 (Replay Irrelevance). The tables' inactivity reflects their position in the Wave 8 activation sequence. Their constitutional purpose — providing the infrastructure for historical verification, archive verification, and re-signing workflows — is constitutionally documented. Removal would break Wave 8 replay and provenance infrastructure.

**Corrected constitutional reframing:** "`historical_verification_runs`, `archive_verification_runs`, and `resign_sweeps` are constitutionally declared Wave 8 provenance infrastructure. Their current inactivity reflects their deferred status in the Wave 8 activation sequence. They are constitutionally protected. Removal requires a formal Root constitutional amendment establishing that Wave 8 provenance infrastructure for historical verification is no longer required — an amendment that would face significant constraints under CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md's replay obligation modification constraints."

---

### Example INF-3: Placeholder Signing Satisfies Wave 8

**Invalid inference:** "`state_transitions.transition_hash` is populated with a `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix value. This satisfies the signing field requirement and the record is constitutionally signed."

**Why invalid:** This inference applies Pattern PI-7 (Runtime Supremacy) and Pattern PI-8 (Provenance Subordination). The placeholder prefix is accepted by `enforce_transition_signature` because that trigger enforces presence, not cryptographic validity. Runtime acceptance of the placeholder does not constitute Wave 8 cryptographic signing.

**Corrected constitutional reframing:** "The `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix value in `state_transitions.transition_hash` satisfies the Wave 4 presence-check enforcement applied by `enforce_transition_signature`. It does not satisfy Wave 8 provenance integrity requirements, which require actual cryptographic signing. Records bearing placeholder hashes are operationally admitted under Wave 4 enforcement but are constitutionally defective in the Wave 8 dimension. Their Wave 8 constitutional defect persists regardless of their Wave 4 operational admissibility."

---

### Example INF-4: `canonicalization_registry` Is Accidental Schema

**Invalid inference:** "`canonicalization_registry` has no consumer wired to it in the migration evidence. It was probably created by mistake and can be dropped."

**Why invalid:** This inference applies Pattern PI-3 (Unwired Implies Accidental) and Pattern PI-4 (Scaffold Implies Dead Schema). The registry's unwired state reflects its constitutionally deferred convergence with the active canonicalization path. Its presence establishes the constitutional existence of a canonicalization versioning substrate.

**Corrected constitutional reframing:** "`canonicalization_registry` is constitutionally declared as a canonicalization version authority registry. Its unwired state reflects a documented convergence obligation to the active canonicalization path. Its current absence of consumers does not indicate accidental creation. Its constitutional purpose — versioning canonicalization schemas — is defined in governing doctrine. Dropping it would require constitutional amendment and would break the canonicalization version lineage that will be required when the convergence is executed."

---

### Example INF-5: Two Signer Registries Must Become One

**Invalid inference:** "Symphony has two signer resolution mechanisms (`wave8_signer_resolution` and `public_keys_registry`). This dual-registry architecture is inefficient and should be unified into a single signer registry."

**Why invalid:** This inference applies Pattern PI-1 (Parallel Implies Conflict) and Pattern PI-6 (Multiple Authorities Imply Convergence Pressure). The two registries serve distinct constitutional functions in the Wave 8 signing architecture. Their convergence obligation is specific and documented; it does not imply merger.

**Corrected constitutional reframing:** "`wave8_signer_resolution` is the active, enforcement-connected signer registry serving `resolve_authoritative_signer`. `public_keys_registry` is the constitutionally declared public key registry with a convergence obligation to `wave8_signer_resolution`. The convergence means `public_keys_registry` will be wired as an input to the signer resolution path. It does not mean the two registries will be merged into one. Their distinct schemas serve distinct constitutional purposes in the Wave 8 provenance architecture."

---

### Example INF-6: Phase 1 Boundary Is an Advisory Check

**Invalid inference:** "`enforce_phase1_boundary` blocks certain data authority values in `monitoring_records`. This is an operational validation that can be relaxed when Phase 2 begins without a formal constitutional transition."

**Why invalid:** This inference applies Pattern PI-7 (Runtime Supremacy) and violates the phase-aware interpretation constraint PAC-1. Phase capability boundaries are constitutional constraints, not operational guidelines.

**Corrected constitutional reframing:** "`enforce_phase1_boundary` expresses the Phase 1 constitutional capability boundary by enforcing admissible data authority values in `monitoring_records`. Relaxing or disabling this enforcement before a formal constitutional Phase 2 entry constitutes a phase-legality violation. Records admitted outside the Phase 1 boundary without a valid Phase 2 constitutional entry are phase-inadmissible regardless of their operational processing status. The boundary is a constitutional constraint; it is not relaxed by operational decision."

---

## NotebookLM Anti-Drift Interpretation Rules

The following rules apply specifically to NotebookLM's synthesis of this constitutional corpus. They supplement the restrictions defined in CONSTITUTIONAL_INTERPRETATION_PRECEDENCE.md.

**NB-AD-1. Parallelism must not be characterized as conflict.**
When synthesizing documents that describe multiple parallel authority surfaces, enforcement paths, or registry systems, NotebookLM must not characterize their parallel existence as conflict, redundancy, or architectural debt. The correct characterization is: parallel sovereignty surfaces coexisting as designed.

**NB-AD-2. Dormancy must not be characterized as obsolescence.**
When synthesizing documents that describe inactive, dormant, or unwired components, NotebookLM must not characterize these components as obsolete, dead, unused, or removable. The correct characterization is: constitutionally deferred or constitutionally dormant pending activation event.

**NB-AD-3. Placeholder posture must not be characterized as signing compliance.**
When synthesizing documents that describe the `PLACEHOLDER_PENDING_SIGNING_CONTRACT:` prefix or the presence-only enforcement of `enforce_transition_signature`, NotebookLM must not characterize these as constituting cryptographic signing compliance. The correct characterization is: Wave 4 presence enforcement; Wave 8 provenance obligation unmet.

**NB-AD-4. Wave 4 acceptance must not be characterized as Wave 8 validation.**
When synthesizing documents that describe Wave 4 runtime enforcement outcomes, NotebookLM must not characterize those outcomes as establishing Wave 8 provenance validity. The correct characterization is: independent determinations on orthogonal sovereignty surfaces; Wave 4 acceptance does not constitute Wave 8 validation.

**NB-AD-5. Convergence obligations must not be characterized as merger requirements.**
When synthesizing documents that describe convergence obligations between constitutional components, NotebookLM must not characterize these as requirements for the components to be merged into a single unified system. The correct characterization is: a specific wiring obligation between constitutionally distinct components at a constitutionally defined activation moment.

**NB-AD-6. Regulator domain differences must not be characterized as inconsistencies.**
When synthesizing documents that describe different admissibility standards across regulator domains, NotebookLM must not characterize these differences as inconsistencies requiring harmonization. The correct characterization is: independent admissibility standards in constitutionally orthogonal sovereign partitions.

**NB-AD-7. Prohibited inference patterns are exhaustive negative examples.**
The prohibited inference patterns defined in this document constitute a catalogue of reasoning patterns that NotebookLM must recognize and avoid when producing synthesis outputs about Symphony. Synthesis outputs that exhibit any of these patterns constitute anti-drift failures requiring correction through canonical ingestion review.

**NB-AD-8. Inactivity language must be sovereignty-aware.**
NotebookLM synthesis outputs must not use language that treats inactivity as absence, dormancy as deletion, or deferral as incompleteness. Every characterization of component status must be sovereignty-aware: reflecting that component status is determined by constitutional doctrine, not by operational observation.

**NB-AD-9. Constitutional defects must not be characterized as design conclusions.**
When synthesizing documents that describe constitutional defects — shadow authority surfaces, placeholder signing, conditional enforcement paths, disconnected convergence obligations — NotebookLM must not characterize these as evidence that the constitutional architecture has reached its intended design state. The correct characterization is: identified constitutional defects awaiting remediation under governing doctrine.

---

## Admissibility Implications

The inference prohibitions defined in this document have the following admissibility implications:

- Records whose admissibility was determined by reasoning that applied a prohibited inference pattern are constitutionally suspect in the dimensions affected by that pattern. Their admissibility must be re-evaluated under constitutionally authorized interpretation.
- Records admitted based on the inference that runtime acceptance constitutes Wave 8 cryptographic validation are constitutionally defective in the Wave 8 dimension regardless of their operational status.
- Records admitted based on the inference that placeholder signing satisfies provenance integrity obligations are constitutionally defective in the Wave 8 dimension.
- Records excluded based on the inference that a regulator domain's rejection implies universal inadmissibility may be constitutionally admissible in other domains and must be independently evaluated per domain.

---

## Replay Implications

The inference prohibitions defined in this document have the following replay implications:

- Replay events involving records admitted under prohibited inference patterns must be evaluated against the constitutionally correct understanding of the applicable obligations, not against the void inferential determination.
- The removal of constitutionally dormant components based on prohibited Pattern PI-2 inferences would destroy replay survivability for the record classes those components serve. Such removals are constitutionally impermissible.
- The activation of unwired components outside constitutionally defined convergence events based on prohibited Pattern PI-3 inferences may introduce unauthorized authority surfaces affecting replay authenticity.

---

## Sovereignty Implications

The inference prohibitions defined in this document preserve sovereign orthogonality by:

- Prohibiting the PI-1 inference that eliminates sovereign parallelism through conflict resolution.
- Prohibiting the PI-7 and PI-8 inferences that subordinate Wave 8 sovereignty to Wave 4 operational determinations.
- Prohibiting the PI-6 inference that treats multiple sovereign authorities as a transitional state requiring consolidation.
- Prohibiting the PI-10 inference that flattens regulator sovereign partitions into a unified admissibility standard.

Each prohibition protects a specific dimension of Symphony's sovereign orthogonality against the natural erosion pressure exerted by conventional software reasoning applied to a constitutional trust coordination architecture.

---

## Phase Interaction Rules

This document applies globally across all phases. The phase-aware interpretation constraints (PAC-1 through PAC-5) apply within every phase without exception. No phase doctrine may establish phase-specific inference permissions that contradict the inference prohibitions defined herein.

Within a given phase, the constitutional inference legality rules apply to all interpretive reasoning about that phase's constitutional state: what capabilities exist, which components are constitutionally active, which are deferred to subsequent phases, and which enforcement surfaces express the phase's capability boundaries.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the inference and interpretation boundaries applicable across all of Symphony's sovereignty domains. It applies to reasoning about Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, all regulator partitions, and all phase capability boundaries.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine the substantive scope of Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator sovereignty domains, or phase capability boundaries. It prohibits reasoning patterns that would collapse or mischaracterize those domains; it does not redefine them.

**Replay obligations preserved by this document:**
This document preserves replay obligations by prohibiting the PI-9 inference (replay irrelevance), establishing the presumption of replay obligation (RAC-1), and protecting constitutionally dormant replay infrastructure from removal on the basis of inactivity (PI-2 corrected reframing, Example INF-2).

**Regulator boundaries constraining this document:**
This document is constrained by the constitutional principle of regulator orthogonality. Its inference prohibitions must not be applied in a manner that produces regulator domain hierarchy, equivalence, or merger. The PI-10 prohibition and associated reframing are specifically designed to preserve regulator boundary integrity.

**Phases this document applies to:**
GLOBAL. This document applies across all phases without exception. No phase doctrine may establish phase-specific inference permissions that contradict the inference prohibitions defined herein.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10 (ROOT). Any lower-rank artifact applying prohibited inference patterns constitutes a constitutional defect.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, CI gates, operational enforcement artifacts, declarative substrate, repository observations, AI syntheses, and NotebookLM outputs are prohibited from reinterpreting the prohibited inference patterns, constitutional inference legality rules, sovereignty-aware interpretation constraints, replay-aware interpretation doctrine, phase-aware interpretation legality, and NotebookLM anti-drift rules defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Inference prohibitions as implementation guidelines:**
The prohibited inference patterns defined herein are not implementation preferences, best-practice recommendations, or coding guidelines. They are constitutional prohibitions. Their violation in any artifact — human-authored or machine-generated — constitutes a constitutional defect, not a style deviation.

**Invalid simplification — Conventional software reasoning is a permitted fallback:**
Where Symphony's constitutional doctrine does not explicitly address an interpretive question, conventional software reasoning is not a permitted fallback. Constitutional gaps must be addressed through authorized interpretation or amendment. Conventional software reasoning applied to Symphony's constitutional architecture produces the prohibited inference patterns this document exists to prevent.

**Forbidden authority collapse — Operational team consensus ratifies prohibited inference:**
Agreement among operational team members that a prohibited inference pattern produces the correct result does not ratify that inference. Constitutional authority is not conferred by operational consensus. A constitutionally prohibited inference remains prohibited regardless of how many actors accept its conclusion.

**Forbidden authority collapse — NotebookLM synthesis confirms prohibited inference:**
A NotebookLM output that appears to confirm a prohibited inference pattern does not ratify that inference. NotebookLM synthesis carries Rank 0 authority. Its apparent confirmation of a prohibited inference reflects a synthesis drift failure, not constitutional validation of the inference.

**Replay-destructive interpretation — Dormant components have no replay relevance:**
The dormancy of replay infrastructure components does not establish that those components have no replay relevance. Replay obligations are established by doctrine; infrastructure dormancy is a separate question. Treating dormancy as replay irrelevance is Pattern PI-9 and produces direct replay survivability harm.

**Replay-destructive interpretation — Operational admission constitutes replay completeness:**
A record's operational admission — its presence in the database, its passage through enforcement triggers — does not constitute the satisfaction of all replay obligations applicable to that record. Replay obligations require the full constitutional record to be reconstructable and the full provenance chain to be verifiable. Operational admission is a necessary but not sufficient condition for replay completeness.

**Regulator-flattening interpretation — Most demanding domain governs all:**
Treating the most demanding regulator domain's admissibility standard as the universal admissibility standard eliminates the independent evidentiary function of less demanding domains. A record that satisfies the most demanding domain's requirements is admissible in that domain. Its status in every other domain is evaluated independently. Targeting the highest standard is an operational choice; it is not a constitutional substitute for independent per-domain evaluation.

**Phase-illegality misreading — Operational urgency overrides phase inference prohibition:**
Operational urgency does not override the prohibition on treating phase boundaries as operational guidelines (Pattern PI-7 applied to phase context). The constitutional inference that phase boundaries may be relaxed by operational necessity is prohibited regardless of the operational pressure driving that inference.

**Provenance/runtime collapse — Wave 4 completeness implies Wave 8 completeness:**
The inference that a complete, fully enforced Wave 4 operational record necessarily satisfies Wave 8 provenance requirements is constitutionally prohibited. Wave 4 completeness and Wave 8 completeness are independent determinations. A record may be constitutionally complete in the Wave 4 dimension and constitutionally defective in the Wave 8 dimension simultaneously.

**Convergence misreading — Documented convergence obligation implies immediate merger:**
A documented convergence obligation between two constitutional components does not authorize or require their immediate merger. Convergence obligations are constitutionally bounded: they specify what is to converge with what, under what constitutional conditions, at what constitutional moment. They are not general permissions for unauthorized consolidation.
