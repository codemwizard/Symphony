# CONSTITUTIONAL INTERPRETATION PRECEDENCE

**Constitutional-Status:** AUTHORITATIVE
**Interpretation-Authority:** ROOT
**NotebookLM-Ingestion:** CANONICAL
**Authority-Rank:** 10
**Phase-Scope:** GLOBAL
**Supersedes:** None (root doctrine)
**Depends-On:** CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md, CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md

---

## Purpose

This document defines the constitutional rules governing interpretation within Symphony. It establishes which document classes possess interpretation authority over which other classes, the boundaries within which interpretation may lawfully occur, the admissibility conditions for interpretive acts, the constraints binding constitutional interpretation, and the escalation rules applicable when interpretation exceeds its lawful boundaries.

Interpretation in Symphony is a constitutional act. It is not an editorial judgment, an analytical inference, a synthesis operation, or a runtime heuristic. When a constitutional document is interpreted — that is, when its meaning in a contested case is determined — that determination carries the authority of the interpreting document class. Only document classes that possess interpretation authority may perform constitutionally binding interpretation. Interpretation performed by a document class lacking interpretation authority is constitutionally void, regardless of its accuracy, sophistication, or operational effect.

This document applies with equal force to human-authored interpretive acts, machine-generated interpretive outputs, AI-assisted analyses, and automated synthesis products. The mechanism of interpretation production does not determine its constitutional validity. Constitutional validity is determined by the authority class of the interpreting entity and the boundaries within which interpretation is performed.

---

## Constitutional Scope

This document governs:

1. The assignment of interpretation authority to document classes within Symphony's constitutional corpus.
2. The interpretation boundaries applicable to each document class.
3. The admissibility conditions for interpretive acts — the conditions under which an interpretation is constitutionally valid and binding.
4. The constitutional interpretation constraints applicable to all interpreting entities, including human custodians, automated systems, AI-assisted processes, and synthesis tools.
5. The authority inheritance restrictions that prevent delegated interpretation authority from exceeding the scope of the delegating document.
6. The escalation rules applicable when an interpretation question exceeds the lawful interpretation scope of the document class currently addressing it.
7. The specific interpretation restrictions applicable to NotebookLM and analogous synthesis systems.

This document does NOT govern:

- The substantive content of any specific constitutional interpretation.
- The operational implementation of enforcement surfaces, except insofar as those surfaces assert interpretation authority.
- The amendment procedures for constitutional doctrine, which are governed by CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.
- The priority ordering applicable when interpretations conflict, which is governed by CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.

---

## Authority Boundaries

This document operates at Authority-Rank 10 (ROOT). Its interpretation precedence rules are constitutionally binding on all artifact classes. No lower-rank artifact may establish, apply, or imply an interpretation precedence arrangement that contradicts the rules defined herein. Where any artifact's interpretive behavior diverges from this document's rules, this document is authoritative and the artifact's interpretive behavior constitutes a constitutional defect.

---

## Foundational Principles of Constitutional Interpretation

**I1. Interpretation authority is class-determined, not content-determined.**
The authority of an interpretation is determined by the authority class of the interpreting document, not by the accuracy, comprehensiveness, or analytical quality of the interpretation itself. A highly accurate interpretation produced by a Rank 0 artifact (AI synthesis) has zero constitutional standing. A less comprehensive interpretation produced by a Rank 10 artifact (Root Constitutional Doctrine) is constitutionally binding.

**I2. Interpretation is bounded by scope.**
Every document class that possesses interpretation authority possesses it only within a defined scope. Interpretation that exceeds that scope is constitutionally void, regardless of the interpreting document's authority rank within its scope.

**I3. Interpretation cannot substitute for amendment.**
Where an interpretation would effectively alter the meaning of a constitutional obligation, redefine a sovereignty boundary, modify a replay obligation, change a regulator partition boundary, or reassign an authority rank, that act constitutes constitutional amendment, not interpretation. Constitutional amendment requires compliance with CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md. Interpretation cannot be used to accomplish what amendment requires.

**I4. Lower-layer documents cannot interpret higher-layer documents.**
No document class may produce a constitutionally binding interpretation of any document class at a higher authority rank. This prohibition is unconditional. A lower-layer document may reference, describe, or apply a higher-layer document's provisions; it may not determine their meaning in contested cases.

**I5. Accurate description is not interpretation.**
A document that accurately describes the content or operational effect of a constitutional provision is performing description, not interpretation. Description does not carry interpretation authority. Description by any document class, including Rank 0 artifacts, may be accurate; only interpretation by an authorized document class is constitutionally binding.

**I6. Synthesis is not interpretation.**
The aggregation, summarization, pattern-recognition, or synthesis of constitutional provisions — whether performed by human analysis, automated processing, or AI systems — does not constitute constitutional interpretation. Synthesis produces descriptive outputs that carry the authority class of the synthesizing entity. AI synthesis is Rank 0; its outputs carry zero interpretation authority regardless of synthesis quality.

---

## Interpretation Authority by Document Class

The following table defines the complete interpretation authority assignment for each document class in Symphony's constitutional corpus. A document class may produce constitutionally binding interpretations only of the document classes listed in its "Interpretable Classes" column, and only within its defined scope.

| Document Class | Authority Rank | Interpretable Classes | Interpretation Scope | Scope Limit |
|---|---|---|---|---|
| Root Constitutional Doctrine | 10 | All classes (Ranks 0–10) | Universal — all constitutional questions within Symphony's corpus | None within Symphony's constitutional corpus |
| Wave Sovereignty Doctrine | 9 | Ranks 0–8 | Wave sovereignty questions within the relevant wave domain (Wave 4 or Wave 8) | May not interpret Root Doctrine or the other wave's doctrine |
| Phase Constitutional Doctrine | 8 | Ranks 0–7 | Phase capability boundary questions within the relevant phase | May not interpret wave sovereignty, Root Doctrine, or regulator doctrine |
| Regulator Partition Doctrine | 7 | Ranks 0–6 within domain | Regulator domain questions within the relevant partition | May not interpret across regulator domain boundaries or interpret higher ranks |
| Enforcement Doctrine | 6 | Ranks 0–5 within enforcement scope | Enforcement surface questions within defined enforcement scope | May not interpret sovereignty boundaries, phase definitions, or regulator domains |
| Constitutional Migration Record | 5 | Ranks 0–4 | Constitutional record state — what was enacted, when, in what sequence | May not interpret the meaning of constitutional provisions; records only what was enacted |
| CI Gate Authority | 4 | Ranks 0–3 | Merge-path admissibility for the specific artifact under review | May not interpret constitutional doctrine; enforces only the gates as defined |
| Operational Enforcement Artifact | 3 | None | No interpretation authority | Expresses enforcement; does not interpret doctrine |
| Declarative Substrate | 2 | None | No interpretation authority | Constitutional existence only |
| Repository Observation | 1 | None | No interpretation authority | Descriptive only |
| AI Synthesis / Analytical Artifact | 0 | None | No interpretation authority | Zero constitutional standing |

---

## Interpretation Precedence Tables

### Table 1: Direct Interpretation Precedence

Where multiple document classes address the same constitutional question, the following precedence governs which interpretation is constitutionally binding:

| Question Domain | Controlling Interpretation Class | Subordinate Classes (yield to controlling) |
|---|---|---|
| Root constitutional semantics | Root Constitutional Doctrine (10) | All other classes |
| Wave sovereignty scope (Wave 4) | Wave 4 Sovereignty Doctrine (9) | Ranks 0–8 |
| Wave sovereignty scope (Wave 8) | Wave 8 Sovereignty Doctrine (9) | Ranks 0–8 |
| Phase capability boundary | Phase Constitutional Doctrine (8) for the relevant phase | Ranks 0–7 |
| Regulator domain admissibility | Regulator Partition Doctrine (7) for the relevant domain | Ranks 0–6 |
| Enforcement surface requirement | Enforcement Doctrine (6) | Ranks 0–5 |
| Constitutional record state | Constitutional Migration Record (5) — tip authoritative | Ranks 0–4 |
| Merge-path admissibility | CI Gate Authority (4) | Ranks 0–3 |
| Runtime enforcement expression | Operational Enforcement Artifact (3) | Ranks 0–2 (expression only; not interpretation) |

### Table 2: Cross-Class Interpretation Prohibition Table

The following combinations are constitutionally prohibited. An interpretation produced in any of these combinations is void.

| Interpreting Class | Document Being Interpreted | Status |
|---|---|---|
| Repository Observation (1) | Any constitutional doctrine (Ranks 6–10) | PROHIBITED — Rank 1 has no interpretation authority |
| AI Synthesis (0) | Any document (Ranks 0–10) | PROHIBITED — Rank 0 has zero constitutional standing |
| Analytical Artifact (0) | Any sovereignty doctrine (Ranks 7–10) | PROHIBITED |
| Operational Artifact (3) | Enforcement Doctrine (6) | PROHIBITED — Rank 3 expresses; does not interpret |
| Migration Record (5) | Enforcement Doctrine (6) | PROHIBITED — Rank 5 records enactment; does not interpret obligation meaning |
| CI Gate (4) | Phase Doctrine (8) | PROHIBITED — CI gate enforces specific gates; does not interpret phase doctrine |
| Enforcement Doctrine (6) | Wave Sovereignty Doctrine (9) | PROHIBITED — outside enforcement doctrine's interpretation scope |
| Phase Doctrine (8) | Wave Sovereignty Doctrine (9) | PROHIBITED — phase doctrine does not interpret wave sovereignty |
| Regulator Doctrine (7) | Root Constitutional Doctrine (10) | PROHIBITED — regulator doctrine does not interpret root doctrine |
| Wave Sovereignty Doctrine (9) | Root Constitutional Doctrine (10) | PROHIBITED — wave doctrine does not interpret root doctrine |
| Any document class | Sovereignty ontology of a higher-rank domain | PROHIBITED — sovereignty ontology is defined, not interpreted, at root level |

### Table 3: Interpretation Scope Boundaries

For each document class possessing interpretation authority, the following defines the outer boundary of lawful interpretation scope:

| Document Class | Lawful Interpretation Boundary | Acts That Exceed Boundary |
|---|---|---|
| Root Constitutional Doctrine (10) | Any constitutional question within Symphony's corpus | Acts that would amend rather than interpret (governed by amendment doctrine) |
| Wave 4 Sovereignty Doctrine (9) | Questions about operational/runtime sovereignty | Interpreting Wave 8 provisions; interpreting root doctrine; establishing phase definitions |
| Wave 8 Sovereignty Doctrine (9) | Questions about provenance/cryptographic sovereignty | Interpreting Wave 4 provisions; interpreting root doctrine; establishing phase definitions |
| Phase Doctrine (8) | Questions about phase capability boundaries and phase-legality of specific records | Defining or interpreting wave sovereignty; defining regulator domain boundaries |
| Regulator Doctrine (7) | Questions about admissibility within the relevant regulator domain | Asserting admissibility in another domain; interpreting cross-domain constitutional obligations |
| Enforcement Doctrine (6) | Questions about what enforcement surfaces must do | Interpreting the sovereignty obligations that give rise to enforcement requirements |
| Migration Record (5) | Questions about what was enacted in the constitutional record | Interpreting the meaning of any enacted provision |

---

## Interpretive Admissibility

### Definition

An interpretation is constitutionally admissible when it satisfies all of the following conditions:

**IA1. Producing class has interpretation authority.**
The document class producing the interpretation possesses interpretation authority for the document class being interpreted, per Table 1 above.

**IA2. Interpretation is within scope.**
The interpretation falls within the producing class's defined interpretation scope, per Table 3 above.

**IA3. Interpretation does not constitute amendment.**
The interpretation does not alter the meaning of any constitutional obligation, redefine any sovereignty boundary, modify any replay obligation, change any regulator partition boundary, or reassign any authority rank. If it would, it constitutes amendment and must comply with CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

**IA4. Interpretation is formally registered.**
For interpretations produced by Ranks 6–10, the interpretation must be formally registered in the constitutional history record. An informal, operational, or oral interpretation produced by a document class possessing interpretation authority is not constitutionally admissible until it is formally registered.

**IA5. Interpretation does not collapse sovereignty boundaries.**
The interpretation does not produce an outcome that collapses, merges, or subordinates any sovereignty domain, even if the interpreting document class possesses Root authority.

**IA6. Interpretation preserves replay obligations.**
The interpretation does not reduce, eliminate, or render ambiguous any existing replay obligation.

### Inadmissible Interpretation Indicators

An interpretation is constitutionally inadmissible if it exhibits any of the following:

- Produced by a document class lacking interpretation authority for the interpreted class.
- Exceeds the producing class's interpretation scope.
- Redefines a sovereignty boundary under the guise of clarification.
- Introduces a new admissibility standard for prior-admitted records.
- Eliminates or reduces a replay obligation.
- Merges two regulator domains by asserting equivalence of their admissibility standards.
- Is produced by an AI synthesis, analytical artifact, or repository observation.
- Is not formally registered in the constitutional history record (for Ranks 6–10).

---

## Constitutional Interpretation Constraints

The following constraints apply to all constitutionally authorized interpretation acts, regardless of the interpreting document class's authority rank:

**IC1. Interpretation must be text-grounded.**
Every constitutional interpretation must be grounded in the explicit text of the document being interpreted. Interpretation that introduces concepts, obligations, or boundaries not found in the document's text constitutes amendment, not interpretation.

**IC2. Interpretation must preserve constitutional history.**
An interpretation may not be applied retroactively in a manner that alters the admissibility status of records produced under prior constitutional doctrine. Interpretations apply prospectively from their formal registration date.

**IC3. Interpretation must identify its basis.**
Every formally registered interpretation must identify the specific textual provisions of the interpreted document on which the interpretation is grounded, and must explain how the interpretation follows from those provisions.

**IC4. Interpretation must acknowledge scope limits.**
Every formally registered interpretation must explicitly acknowledge the limits of its interpretive scope and must identify any questions it is not addressing that fall outside its scope.

**IC5. Interpretation cannot resolve what amendment must determine.**
Where a constitutional question cannot be resolved by textual interpretation — because the text is genuinely ambiguous in a way that different interpretations would produce different sovereignty, replay, or admissibility outcomes — the question must be escalated to constitutional amendment. Interpretation may not be used to avoid the amendment procedure by forcing a reading that eliminates the ambiguity at constitutional cost.

**IC6. Interpretation must be sovereign-boundary-preserving.**
Every interpretation must preserve the constitutional boundaries of all sovereignty domains. An interpretation that would collapse Wave 4 and Wave 8, merge regulator domains, or retroactively alter phase capability boundaries is constitutionally impermissible regardless of the interpreting document class's authority rank.

---

## Authority Inheritance Restrictions

### General Rule

When interpretation authority is delegated from a higher-rank document class to a lower-rank document class for a specific interpretive purpose, the following restrictions apply:

**AH1. Delegated authority does not exceed delegating scope.**
An interpretation authority delegation from a Phase Constitutional Doctrine (Rank 8) to an Enforcement Doctrine (Rank 6) for a specific enforcement surface question does not grant the Enforcement Doctrine authority to interpret Phase Doctrine on any question other than the specific delegated question.

**AH2. Delegated authority does not elevate rank.**
A document class that receives an interpretation authority delegation retains its own authority rank. The delegation is scoped; the rank is not transferred. The delegating document's interpretation of the delegated question supersedes the delegate's interpretation if they conflict.

**AH3. Delegated authority cannot be re-delegated.**
A document class that receives an interpretation authority delegation may not further delegate that authority to a lower-rank class. Interpretation authority may be delegated one level downward only; it may not cascade through the hierarchy.

**AH4. Delegation must be explicit and registered.**
Implicit interpretation authority inheritance — where a lower-rank document claims interpretation authority by virtue of its operational relationship to a higher-rank document without explicit delegation — is prohibited.

**AH5. Delegation is subject to all IC constraints.**
Delegated interpretation authority is subject to all constitutional interpretation constraints (IC1–IC6) defined above. Delegation does not exempt the delegate from any constraint applicable to authorized interpretation.

---

## Legal Interpretation Flows

The following flowcharts define the constitutionally required interpretation procedure for common question types.

### Flow 1: Constitutional Doctrine Interpretation

```
Constitutional question arises
        │
        ▼
Identify the document class whose text is the source of the question
        │
        ▼
Identify the document class with interpretation authority
over that source class (per Table 1)
        │
        ▼
Does the interpreting class possess authority within scope? ──NO──► ESCALATE (see Escalation Rules)
        │
       YES
        ▼
Produce text-grounded interpretation (IC1)
        │
        ▼
Does the interpretation alter sovereignty, replay, admissibility? ──YES──► STOP: This is amendment, not interpretation
        │
       NO
        ▼
Register interpretation in constitutional history record (IA4)
        │
        ▼
Interpretation is constitutionally admissible and binding
        within the interpreting class's scope
```

### Flow 2: AI-Assisted or Synthesis-Produced Output

```
AI system, NotebookLM, or analytical tool produces output
addressing a constitutional question
        │
        ▼
Determine authority class of producing entity
        │
        ▼
Is producing entity Rank 0 (AI Synthesis / Analytical Artifact)?
        │
       YES
        ▼
Output has ZERO constitutional standing as interpretation
        │
        ▼
Output may be used as: descriptive reference, research input,
identification of questions requiring authorized interpretation
        │
        ▼
Output MUST NOT be: applied as binding interpretation, registered
as constitutional history, used to resolve sovereignty questions,
used to determine admissibility, used to modify replay obligations
        │
        ▼
If the output identifies a constitutional question requiring
resolution, ESCALATE to authorized interpretation class
```

### Flow 3: Repository Observation Identifies Apparent Constitutional Condition

```
Repository observation (Rank 1) identifies apparent
constitutional condition (e.g., unwired substrate,
dormant registry, shadow authority surface)
        │
        ▼
Observation is constitutionally admissible as
DESCRIPTION of the condition
        │
        ▼
Observation has NO authority to determine:
- Whether the condition constitutes a defect
- Whether the substrate should be activated or eliminated
- Whether the shadow authority is constitutionally void
- What the constitutional resolution must be
        │
        ▼
Condition is referred to the appropriate authorized
interpretation class for constitutional determination
        │
        ▼
Authorized interpretation class produces binding determination
per Flow 1
```

---

## Invalid Reinterpretation Examples

### Example IR1: Migration Record Reinterprets Enforcement Obligation

**Description:** Migration 0153, which introduces `add_signature_placeholder_posture`, contains commentary asserting that the placeholder posture satisfies the enforcement obligation for transition signature enforcement. This commentary purports to interpret the enforcement doctrine governing `enforce_transition_signature`.

**Constitutional status:** Void. The Constitutional Migration Record (Rank 5) may record what was enacted. It may not interpret the enforcement obligation defined by Enforcement Doctrine (Rank 6). The commentary, however accurate as a description of operational intent, carries no interpretive authority. The enforcement obligation is interpreted by Enforcement Doctrine (Rank 6) or higher. A migration record's characterization of its own compliance with an enforcement obligation does not constitute binding interpretation of that obligation.

**Correct resolution:** The question of whether placeholder posture satisfies the enforcement doctrine obligation must be interpreted by the governing Enforcement Doctrine document. If no such document has addressed the question, it is an open constitutional question requiring authorized interpretation, not a settled question by virtue of the migration record's commentary.

### Example IR2: Repository Observation Determines Dormant Substrate Is Technical Debt

**Description:** An audit document (CONSTITUTIONAL_GRAPH.md, Rank 1) notes that `public_keys_registry`, `delegated_signing_grants`, `signing_audit_log`, and `canonicalization_registry` are disconnected from active enforcement paths and identifies them as having convergence obligations. A subsequent operational analysis (Rank 0) interprets this observation as establishing that these substrates are technical debt candidates for elimination.

**Constitutional status:** Both the observation and the analytical interpretation are void as constitutional determinations. The observation (Rank 1) accurately describes a topology condition; it does not determine whether that condition constitutes a defect, accidental design, or intentional deferral. The operational analysis (Rank 0) has zero constitutional standing. The constitutional status of these substrates — whether they are deferred, dormant-by-design, or constitutionally protected pending activation — is determined by governing Wave Sovereignty Doctrine (Rank 9) or Root Constitutional Doctrine (Rank 10), neither of which may be interpreted by Rank 0 or Rank 1 artifacts.

**Correct resolution:** The question of the constitutional status of these declarative substrate artifacts must be referred to Wave 8 Sovereignty Doctrine (Rank 9) for determination within its scope, or to Root Constitutional Doctrine (Rank 10) if the question exceeds wave scope.

### Example IR3: AI Synthesis Resolves Regulator Domain Admissibility Question

**Description:** A NotebookLM synthesis reviewing Symphony's constitutional documents produces an output concluding that a specific class of carbon credit transaction records is admissible under both Regulator Domain A and Regulator Domain B, based on pattern-matching the admissibility criteria defined in each domain's governing doctrine.

**Constitutional status:** Void as constitutional interpretation. The synthesis (Rank 0) has zero constitutional standing. Its conclusion regarding cross-domain admissibility carries no binding effect. Even if the synthesis's pattern-matching is factually accurate, admissibility determinations within a regulator domain are made by the governing Regulator Partition Doctrine (Rank 7) for that domain. Cross-domain admissibility cannot be determined by synthesis; it requires independent determination by each domain's governing doctrine.

**Correct resolution:** Admissibility in Domain A is determined by Domain A's Regulator Partition Doctrine. Admissibility in Domain B is determined by Domain B's Regulator Partition Doctrine. Each determination is independent. The synthesis output may be referenced as descriptive input to each domain's authorized interpretation process; it may not constitute or substitute for that process.

### Example IR4: Enforcement Trigger Behavior Interpreted as Constitutionally Authoritative

**Description:** The consistent operational behavior of `enforce_transition_signature` — which enforces signature presence only, not cryptographic validity — is cited as the authoritative interpretation of Symphony's signing enforcement obligation. The argument is that years of consistent trigger behavior establish operational precedent constituting binding constitutional interpretation.

**Constitutional status:** Void. Operational behavior (Rank 3) carries no interpretation authority over Enforcement Doctrine (Rank 6) or Wave Sovereignty Doctrine (Rank 9). Operational precedent is not a source of constitutional interpretation authority in Symphony's architecture. The consistent behavior of an enforcement surface establishes only what that surface has been doing; it does not establish what the constitutional obligation requires. Constitutional interpretation of the signing obligation belongs to the governing Enforcement Doctrine and, for the cryptographic sovereignty dimension, to Wave 8 Sovereignty Doctrine.

**Correct resolution:** The signing enforcement obligation must be interpreted by Enforcement Doctrine (Rank 6). The cryptographic provenance dimension of that obligation must be interpreted by Wave 8 Sovereignty Doctrine (Rank 9). The trigger's behavior is assessed for compliance with the authorized interpretation; it does not supply the interpretation.

### Example IR5: Phase Document Interprets Wave Sovereignty Scope

**Description:** A Phase 2 Constitutional Doctrine document contains a section asserting that Wave 8 cryptographic provenance obligations do not apply to records produced during Phase 2 because Phase 2's capability boundary did not include active cryptographic signing infrastructure.

**Constitutional status:** Void beyond Phase 2's interpretation scope. Phase Constitutional Doctrine (Rank 8) may interpret Phase 2 capability boundary questions. It may not interpret Wave 8 Sovereignty Doctrine (Rank 9). The assertion that Wave 8 provenance obligations are phase-conditional is an interpretation of wave sovereignty scope, not of phase capability scope. Wave 8 Sovereignty Doctrine determines whether its obligations apply within a given phase; the phase doctrine does not determine that question.

**Correct resolution:** The question of whether Wave 8 provenance obligations apply during Phase 2 must be interpreted by Wave 8 Sovereignty Doctrine (Rank 9). If Wave 8 doctrine is silent on phase conditionality, the question must be escalated to Root Constitutional Doctrine (Rank 10).

---

## AI-Assisted Interpretation Constraints

### Constitutional Status of AI-Assisted Interpretation

AI systems — including but not limited to large language models, retrieval-augmented synthesis tools, and automated analysis pipelines — are Rank 0 artifacts within Symphony's constitutional corpus. Their outputs carry zero interpretation authority regardless of the quality, accuracy, or comprehensiveness of those outputs.

This constraint applies unconditionally to:

- All generative AI systems producing constitutional analysis.
- All retrieval-augmented systems synthesizing constitutional documents.
- All automated pipelines producing constitutional summaries or conclusions.
- All AI-assisted drafting tools producing constitutional language.
- NotebookLM and analogous knowledge synthesis platforms in all operational modes.

### Permissible Uses of AI-Assisted Output

AI-assisted outputs may be used in the following constitutionally permissible ways:

**P1. Research input:** AI outputs may be used to identify questions requiring authorized constitutional interpretation. An AI synthesis that surfaces a potential conflict between two constitutional provisions is performing a useful research function; it is not resolving the conflict.

**P2. Descriptive reference:** AI outputs may be referenced as descriptive summaries of constitutional provisions, provided they are not treated as interpretations of those provisions.

**P3. Draft input to authorized interpretation process:** AI outputs may be used as draft material for authorized human constitutional custodians performing interpretation at the appropriate authority rank. The custodian's formally registered interpretation is authoritative; the AI draft is not.

**P4. Admissibility identification:** AI outputs may assist in identifying which records may require admissibility evaluation. The admissibility determination itself must be made by the authorized document class.

### Prohibited Uses of AI-Assisted Output

AI-assisted outputs may not be used in the following ways:

**PH1.** As the basis for a constitutional determination regarding sovereignty boundaries.

**PH2.** As the basis for a determination that a replay obligation has been satisfied, eliminated, or reduced.

**PH3.** As the basis for a determination of admissibility in any regulator domain.

**PH4.** As the basis for a determination that a phase capability boundary has been satisfied or exceeded.

**PH5.** As the basis for a constitutional amendment or interpretation registration.

**PH6.** As an interpretation of any constitutional document at any authority rank.

**PH7.** As a resolution of any constitutional conflict, priority question, or sovereignty boundary dispute.

**PH8.** As evidence of constitutional intent, constitutional history, or constitutional precedent.

---

## NotebookLM Interpretation Restrictions

### Specific Restrictions Applicable to NotebookLM

NotebookLM is a knowledge synthesis platform that ingests constitutional documents and produces synthesized outputs. Its constitutional status within Symphony is Rank 0 (AI Synthesis / Analytical Artifact). The following restrictions apply specifically to NotebookLM outputs in Symphony constitutional contexts:

**NB1. NotebookLM outputs are descriptive, not interpretive.**
All outputs produced by NotebookLM — summaries, answers, comparisons, analyses, conclusions — are constitutionally descriptive. They describe what the ingested constitutional documents contain. They do not interpret what those documents mean in contested cases.

**NB2. NotebookLM outputs cannot resolve constitutional conflicts.**
Where NotebookLM produces an output that appears to resolve a conflict between two constitutional provisions, that output has zero constitutional standing as a resolution. The conflict remains unresolved and must be referred to the authorized interpretation class.

**NB3. NotebookLM synthesis does not constitute constitutional precedent.**
No NotebookLM output may be cited as constitutional precedent, constitutional authority, or constitutional interpretation in any formal constitutional proceeding.

**NB4. NotebookLM accuracy does not confer authority.**
A NotebookLM output that accurately restates constitutional doctrine is accurate description, not authorized interpretation. Its accuracy does not alter its Rank 0 constitutional status.

**NB5. NotebookLM may not be used to determine admissibility.**
No NotebookLM output may be used as the basis for any admissibility determination in any regulator domain, phase, or wave sovereignty context.

**NB6. NotebookLM drift must be governed by canonical ingestion.**
The canonical ingestion of constitutional documents into NotebookLM is the mechanism by which NotebookLM's descriptive outputs are aligned with constitutional doctrine. The canonical status of ingested documents (as defined by their NotebookLM-Ingestion: CANONICAL metadata) governs the corpus from which NotebookLM draws. Non-canonical documents must not be ingested as canonical source material. Ingestion of non-canonical documents as canonical source constitutes a constitutional information environment defect.

**NB7. NotebookLM stabilization is a constitutional obligation.**
The risk that NotebookLM synthesis will drift from constitutional doctrine — producing outputs that mischaracterize constitutional provisions, flatten sovereignty domains, collapse authority distinctions, or treat inadmissible interpretations as canonical — is a constitutional governance risk. The Prohibited Misinterpretations sections of all canonical constitutional documents serve as anti-drift stabilization provisions. They are mandatory inclusions, not optional additions, precisely because NotebookLM synthesis requires explicit negative examples to resist interpretive drift.

---

## Constitutional Interpretation Escalation Rules

### When Escalation Is Required

Escalation to a higher interpretation authority is constitutionally required when any of the following conditions are present:

**E1.** The question cannot be resolved within the interpreting document class's defined scope.

**E2.** Resolution of the question would require the interpreting document class to interpret a document class at a higher authority rank.

**E3.** Resolution of the question would require an act that constitutes amendment rather than interpretation.

**E4.** Two document classes at the same authority rank produce conflicting interpretations of the same provision and the supersession chain does not resolve the conflict.

**E5.** The question involves a sovereignty boundary determination that cannot be made within the scope of any single wave, phase, or regulator doctrine.

**E6.** The question involves a replay obligation determination that the governing enforcement doctrine is unable to resolve within its scope.

**E7.** An AI-assisted output has been applied as a constitutional interpretation and the resulting constitutional harm requires correction.

### Escalation Path

| Originating Question Level | First Escalation Target | Second Escalation Target | Final Authority |
|---|---|---|---|
| Enforcement surface question | Enforcement Doctrine (6) | Wave Doctrine (9) if wave sovereignty implicated | Root Doctrine (10) |
| Phase capability question | Phase Doctrine (8) | Wave Doctrine (9) if wave sovereignty implicated | Root Doctrine (10) |
| Regulator domain question | Regulator Doctrine (7) | Root Doctrine (10) | Root Doctrine (10) |
| Wave sovereignty question | Wave Doctrine (9) | Root Doctrine (10) | Root Doctrine (10) |
| Cross-wave question | Root Doctrine (10) | N/A | Root Doctrine (10) |
| Cross-regulator question | Root Doctrine (10) | N/A | Root Doctrine (10) |
| Replay obligation question | Enforcement Doctrine (6) | Wave Doctrine (9) if wave sovereignty implicated | Root Doctrine (10) |
| AI-assisted interpretation applied as constitutional authority | Immediate escalation to Root Doctrine (10) | N/A | Root Doctrine (10) |
| Amendment disguised as interpretation | Immediate escalation to Root Doctrine (10) | N/A | Root Doctrine (10) |

### Escalation Procedure

**ES1.** The escalating document class must produce a written escalation notice identifying the question, the escalating class, the reason escalation is required, and the next-level authority to which the question is referred.

**ES2.** The escalating class must not apply a provisional interpretation pending escalation resolution, unless the constitutional priority ordering (CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md) requires an interim determination to protect higher-priority obligations (replay survivability, provenance integrity, admissibility continuity).

**ES3.** If an interim determination is required, it must be the most conservative constitutionally available determination — the interpretation that least alters existing constitutional obligations and most preserves existing admissibility, replay, and sovereignty states.

**ES4.** The escalation resolution produced by the higher-authority class must be formally registered in the constitutional history record and is binding from the date of registration.

**ES5.** Where escalation reaches Root Constitutional Doctrine (Rank 10) and the question cannot be resolved by interpretation (because resolution requires amendment), the question must be processed through the amendment procedure defined in CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

---

## Admissibility Implications

The interpretation rules defined in this document have the following admissibility implications:

- Records whose admissibility was determined by a constitutionally unauthorized interpretation (Rank 0 or Rank 1 artifacts) are not constitutionally admitted. Their admissibility must be evaluated by the authorized interpretation class before their constitutional admissibility status is established.
- Records whose admissibility was determined by an authorized interpretation that was subsequently found to have exceeded its scope are admitted under the historical constitutional state applicable at the time of determination, consistent with CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md's admissibility continuity requirements.
- Interpretations that were admissibly produced (satisfying IA1–IA6) and formally registered remain constitutionally valid for all records produced while those interpretations were operative, regardless of subsequent amendments or supersessions.

---

## Replay Implications

The interpretation rules defined in this document have the following replay implications:

- Replay events must be evaluated against the constitutionally authorized interpretation that was operative at the time of the replayed event. Subsequent interpretations or amendments do not retroactively govern replay evaluation.
- An interpretation that reduced replay obligations — in violation of Principle I3 and IC6 — does not alter the underlying replay obligation for historical events. Replay is evaluated against the replay obligation as it existed at the time of the event, not as modified by the void interpretation.
- Formally registered interpretations that are later superseded retain their authority as the governing interpretation for replay events that occurred during their operative period.

---

## Sovereignty Implications

The interpretation rules defined in this document preserve sovereign orthogonality by:

- Prohibiting any document class below Root Constitutional Doctrine from producing binding interpretations of wave sovereignty doctrine, thereby preventing wave sovereignty scope from being narrowed or expanded by lower-layer actors.
- Prohibiting cross-domain interpretation by regulator partition doctrine, thereby preserving regulator domain independence.
- Prohibiting phase doctrine from interpreting wave sovereignty obligations, thereby preventing phase-conditional erosion of wave sovereignty requirements.
- Establishing that synthesis, observation, and AI-assisted outputs carry no interpretation authority over any sovereignty domain, regardless of descriptive accuracy.

---

## Phase Interaction Rules

This document applies globally across all phases. Within each phase, the following phase-specific interpretation rules apply:

- Interpretation of a phase's capability boundary is performed by the governing Phase Constitutional Doctrine for that phase. No other phase's doctrine may interpret the capability boundary of a different phase.
- Where a constitutional question requires interpretation of events spanning multiple phases, the question must be escalated to Root Constitutional Doctrine (Rank 10), which alone has universal interpretation scope.
- Phase Constitutional Doctrine may not interpret whether Wave 8 provenance obligations apply within its phase. That question belongs to Wave 8 Sovereignty Doctrine (Rank 9).
- A phase transition does not alter the interpretation authority applicable to records produced in the prior phase. Prior-phase records are interpreted under the constitutional doctrine operative in the phase in which they were produced.

---

## Constitutional Self-Validation

**Sovereignty domains governed by this document:**
This document governs the meta-constitutional domain of interpretation authority. It establishes which document classes may interpret which other classes and within what scope. It applies across all sovereignty domains — Wave 4, Wave 8, all regulator partitions, all phases — as the governing framework for interpretation authority. It does not define the substantive content of any sovereignty domain.

**Sovereignty domains this document MUST NOT redefine:**
This document must not redefine the substantive scope of Wave 4 operational sovereignty, Wave 8 provenance/cryptographic sovereignty, individual regulator sovereignty domains, or phase capability boundaries. It governs who may interpret those domains; it does not alter their definitions.

**Replay obligations preserved by this document:**
This document preserves replay obligations by prohibiting any interpretation that would reduce, eliminate, or render ambiguous a replay obligation (Principle I3, IC6, IA6); by establishing that replay events are evaluated against the interpretation operative at the time of the event (Replay Implications); and by requiring escalation rather than interpretation where a question's resolution would affect replay obligations.

**Regulator boundaries constraining this document:**
This document is constrained by the principle of regulator orthogonality. Its interpretation authority assignments must not produce outcomes that cause one regulator domain's doctrine to interpret another domain's admissibility requirements. Each regulator domain's doctrine interprets only within its own domain.

**Phases this document applies to:**
GLOBAL. This document applies across all phases without exception. No phase doctrine may establish phase-specific interpretation precedence rules that contradict the rules defined herein.

**Constitutional layers possessing override authority:**
No constitutional layer possesses override authority over this document within its defined scope. This document operates at Authority-Rank 10. Any lower-rank document that applies conflicting interpretation precedence rules constitutes a constitutional defect.

**Lower-layer documents prohibited from reinterpretation:**
All wave sovereignty doctrine, phase doctrine, regulator partition doctrine, enforcement doctrine, migration records, CI gates, operational enforcement artifacts, declarative substrate, repository observations, AI syntheses, and NotebookLM outputs are prohibited from reinterpreting the interpretation authority assignments, interpretation scope boundaries, interpretive admissibility conditions, constitutional interpretation constraints, authority inheritance restrictions, escalation rules, AI-assisted interpretation constraints, and NotebookLM interpretation restrictions defined herein.

---

## Prohibited Misinterpretations

**Invalid simplification — Interpretation as editorial judgment:**
Constitutional interpretation is not editorial judgment, analytical inference, or informed opinion. It is a constitutionally regulated act that can only be performed by authorized document classes within defined scope. Treating an interpretation as valid based on its apparent quality, comprehensiveness, or analytical rigor — rather than the authority class of the interpreting document — is constitutionally impermissible.

**Invalid simplification — Consensus as interpretation authority:**
Widespread agreement among operational teams, analytical reviewers, or AI synthesis outputs regarding the meaning of a constitutional provision does not constitute authorized constitutional interpretation. Consensus is not a source of interpretation authority. A provision's meaning is determined by authorized interpretation, not by the prevalence of a view about its meaning.

**Forbidden authority collapse — AI accuracy as interpretation validity:**
A NotebookLM output or AI synthesis that accurately characterizes constitutional doctrine has produced an accurate description, not an authorized interpretation. Accuracy does not confer authority. Treating an accurate AI output as constitutionally authoritative is a prohibited authority collapse.

**Forbidden authority collapse — Operational behavior as settled interpretation:**
The consistent operational behavior of Symphony's enforcement surfaces does not constitute a settled interpretation of the constitutional obligations those surfaces express. Operational behavior is Rank 3; constitutional interpretation authority begins at Rank 6. The gap between these ranks is unconditional.

**Forbidden authority collapse — Migration commentary as enforcement interpretation:**
Commentary in migration records characterizing the compliance or non-compliance of enacted schema with enforcement obligations does not constitute authorized interpretation of those obligations. Migration records (Rank 5) record constitutional enactment; they do not interpret constitutional meaning.

**Replay-destructive interpretation — Subsequent interpretation retroactively governs replay:**
A constitutionally authorized interpretation produced after a replay event does not govern the evaluation of that event during replay. Replay events are evaluated against the interpretation that was operative at the time of the event. Retroactive application of subsequent interpretations to prior replay events is constitutionally prohibited.

**Replay-destructive interpretation — Void interpretation eliminates replay obligation:**
An unauthorized interpretation — produced by a Rank 0 artifact or outside the interpreting class's scope — that purports to eliminate or reduce a replay obligation does not achieve that effect. The replay obligation persists. The void interpretation has no constitutional effect on the underlying obligation.

**Regulator-flattening interpretation — Cross-domain synthesis determines admissibility:**
A synthesis that concludes a record is admissible in multiple regulator domains does not constitute an admissibility determination in any of those domains. Each domain's admissibility determination is made independently by the governing Regulator Partition Doctrine for that domain. Synthesis across domains is not admissibility determination in any domain.

**Phase-illegality misreading — Phase doctrine governs wave sovereignty applicability:**
Phase Constitutional Doctrine does not determine whether wave sovereignty obligations apply within a phase. Wave sovereignty doctrine makes that determination. A phase doctrine document that contains language purporting to limit, condition, or exclude Wave 8 provenance obligations within its phase is exceeding its interpretation scope on that question. The language is void as an interpretation of Wave 8 obligations.

**Provenance/runtime collapse — Operational consensus validates cryptographic provenance:**
An operational determination by Wave 4 runtime enforcement that a record is valid does not constitute cryptographic provenance validation under Wave 8 sovereignty doctrine. These are independent determinations made by independent sovereignty surfaces. Neither interpretation authority governs the other's domain. An operational enforcement artifact (Rank 3) has no interpretation authority over Wave 8 Sovereignty Doctrine (Rank 9).

**NotebookLM stabilization misreading — Synthesis outputs are constitutional truth:**
NotebookLM synthesis outputs, however aligned with canonical constitutional documents, are not constitutional truth. They are knowledge synthesis products with Rank 0 constitutional standing. Their value lies in their capacity to surface questions and describe constitutional provisions. Their limitation is that they cannot answer constitutional questions with binding effect. Treating NotebookLM outputs as constitutional truth is the most operationally consequential form of prohibited authority collapse and must be actively resisted through canonical ingestion discipline and the Prohibited Misinterpretations sections of all constitutional documents.
