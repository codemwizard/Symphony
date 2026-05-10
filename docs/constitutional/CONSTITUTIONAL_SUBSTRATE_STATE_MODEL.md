# CONSTITUTIONAL SUBSTRATE STATE MODEL

Constitutional-Status: AUTHORITATIVE
Interpretation-Authority: ROOT
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 9
Phase-Scope: GLOBAL
Supersedes: none
Depends-On:
  - docs/constitutional/CONSTITUTIONAL_AUTHORITY_HIERARCHY.md
  - docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md
  - docs/constitutional/CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md
  - docs/constitutional/regulatory/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md

---

## Purpose

This document defines the complete constitutional lifecycle state model for
Symphony's substrate. It establishes the eleven constitutional states within which
any element of Symphony's substrate — a schema surface, an enforcement trigger,
an evidence surface, a cryptographic enforcement layer, a regulatory admission
surface, a replay preservation structure, or an architectural boundary — may exist
at any point in time.

The constitutional state of a substrate element determines its legal operational
posture, its admissibility implications, its replay obligations, its eligibility
for activation or deactivation, its supersession legality, and the obligations
of all actors — agents, custodians, automated systems, and analytical tools —
when they encounter that element.

This document is not a software component lifecycle model. It does not describe
deployment states, feature flags, or operational availability windows. It defines
constitutional positions that carry legal and evidentiary weight independently
of the operational state of any runtime system. A substrate element in
REPLAY_PRESERVED state continues to carry its full constitutional replay
obligations regardless of whether any runtime process is currently executing
against it. A substrate element in RESERVED_UNOPENED state carries its full
constitutional protection obligations regardless of whether any agent has yet
engaged with it.

The eleven constitutional states are mutually exclusive. Every substrate element
occupies exactly one state at any given constitutional moment. Transition between
states is governed by explicit constitutional rules defined in this document. No
state transition may occur without satisfying the preconditions defined herein,
and no actor may declare a state transition that bypasses the constitutional
transition graph.

---

## Constitutional Scope

This document governs:

1. The definition and constitutional semantics of each of the eleven substrate
   states.
2. The legal preconditions and postconditions for every permitted state transition.
3. The set of illegal state transitions and the constitutional basis for each
   prohibition.
4. The replay preservation requirements applicable within each state.
5. The admissibility implications of each state for evidence produced by or
   dependent upon substrate elements in that state.
6. The supersession legality rules governing the transition from ACTIVE or
   DORMANT_RESERVED to SUPERSEDED.
7. The activation and deactivation legality rules governing the transition into
   and out of ACTIVE state.
8. The regulator-gated activation constraints applicable to substrate elements
   whose activation requires regulatory authorisation.
9. The phase-boundary activation legality rules governing state transitions that
   may only occur at or after specific constitutional phase boundaries.
10. The NotebookLM interpretation constraints applicable to each state, preventing
    state-misclassification during corpus synthesis.
11. The prohibited misinterpretations arising from application of conventional
    software lifecycle reasoning to constitutional substrate states.

This document does NOT govern:

- The operational deployment procedures for activating or deactivating specific
  substrate elements; those are governed by enforcement doctrine and migration
  records.
- The authority rank of constitutional documents; that is governed by
  CONSTITUTIONAL_AUTHORITY_HIERARCHY.md.
- The priority ordering when state transition obligations conflict with other
  constitutional obligations; that is governed by
  CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.
- The substantive content of replay verification mechanisms; that is governed by
  TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md.
- The amendment procedures for this doctrine; those are governed by
  CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md.

---

## Authority Boundaries

This document operates at Authority-Rank 9 (Wave Sovereignty Doctrine class). It
defines the constitutional state model that is binding on all lower-rank artifacts.
No migration record, enforcement surface, operational procedure, analytical
synthesis, or AI-generated output may assert, imply, or apply a substrate state
classification that contradicts the definitions, transition rules, or obligations
established herein.

This document operates within the constraints established by Root Constitutional
Doctrine (Rank 10). Where any provision of this document appears to conflict
with CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md,
CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md, NON_INFERENCE_AND_INTERPRETATION_LIMITS.md,
or CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, those documents are
controlling.

---

## Part I: Foundational Constitutional Distinctions

### 1.1 The Constitutional Significance of Substrate State

Substrate state is not a deployment annotation. It is a constitutional declaration
of the legal posture of a substrate element. That posture determines:

(a) Whether the substrate element may produce constitutionally valid evidence
    events at this moment.
(b) Whether prior evidence events produced by this element remain admissible.
(c) Whether replay of prior evidence events produced by this element is
    constitutionally obligated to succeed.
(d) Whether any actor may modify, repurpose, delete, or supersede the element
    without satisfying specific constitutional preconditions.
(e) Whether regulatory regimes dependent on this element's outputs carry
    uninterrupted or interrupted admissibility.

Every substrate element carries a constitutional state from the moment of its
creation. A substrate element created but not yet activated is not stateless —
it is in RESERVED_UNOPENED or PHASE_DEFERRED state, both of which carry positive
constitutional obligations.

### 1.2 The Eight Constitutional Distinctions

The following distinctions are fundamental to the correct application of this
state model. Each pair of concepts is constitutionally distinct. No analytical
act may collapse them.

**Inactive vs. Dormant**

An inactive substrate element is one that has never been constitutionally
activated — it has produced no evidence events and carries no evidence history.
A dormant substrate element is one that was constitutionally active, produced
evidence events, and has since been intentionally placed in a state of
suspended operation while preserving its full constitutional history and replay
obligations. Inactive substrate may exist in RESERVED_UNOPENED, PHASE_DEFERRED,
or CONSTITUTIONALLY_ISOLATED state. Dormant substrate exists in DORMANT_RESERVED
state. These are constitutionally distinct because dormant substrate carries the
full replay and admissibility obligations arising from its prior operational
history, while inactive substrate does not.

**Dormant vs. Deferred**

A dormant substrate element was once active and has been suspended. A deferred
substrate element has never been active and its activation is constitutionally
prohibited until a specific phase or precondition is satisfied. Dormant substrate
may be reactivated within the legal transition graph if preconditions are met.
Deferred substrate is activation-locked until the deferral condition resolves.
Treating deferred substrate as dormant — and therefore as eligible for immediate
reactivation — is a state classification error with constitutional consequences.

**Deferred vs. Reserved**

A deferred substrate element is one whose activation is constitutionally prohibited
by a specific identifiable phase-boundary condition. A reserved substrate element
is one that has been constitutionally set aside for a defined future purpose
without a specific phase trigger for its activation. The activation of deferred
substrate is governed by phase-boundary rules. The activation of reserved
substrate is governed by the constitutional act that defined its reservation.
Both are constitutionally protected. Neither may be treated as available for
arbitrary repurposing.

**Superseded vs. Unreachable**

A superseded substrate element is one that has been explicitly replaced by a
declared successor element under a constitutionally valid supersession. Its
prior evidence history remains fully admissible and replay-obligated. An
unreachable substrate element is one that cannot be reached through any currently
active evidence production path — not because it has been superseded, but because
the conditions for its activation have not been met or it exists in an isolated
partition. Unreachable substrate is not superseded. Treating unreachable substrate
as superseded — and therefore as subject to replacement or modification — is a
prohibited state misclassification.

**Superseded vs. Isolated**

A superseded substrate element has a declared successor. A constitutionally
isolated substrate element has been deliberately partitioned from the main
constitutional evidence graph for sovereign, regulatory, or evidentiary integrity
reasons. Isolated substrate is not superseded, not dormant, and not deferred —
it is constitutionally walled off for a specific, declared purpose. Its isolation
must be explicitly declared and its replay obligations are fully preserved within
its isolated partition.

**Replay-Preserved vs. Archived**

Replay-preserved substrate is a substrate element whose sole constitutional purpose
is to maintain the conditions under which historical evidence events it produced
may be re-verified at any future constitutional moment. It is not archived —
archive implies reduced obligation or reduced access guarantee. REPLAY_PRESERVED
state carries the same replay guarantee obligations as ACTIVE state for the
historical record, even though the element is no longer producing new evidence.
No conventional archival analogy applies.

**Reserved vs. Archaeological**

Reserved substrate is intentionally held for a defined future constitutional
purpose. Archaeological substrate is substrate that was active in a prior
constitutional phase, produced a completed historical record, and now exists
solely as a constitutional record of what was built and why — not as a candidate
for reactivation or repurposing. Archaeological substrate is permanently closed.
Reserved substrate is not yet open.

**RUNTIME_SCAFFOLD vs. ACTIVE**

A scaffold substrate element exists to provide structural support for a future
operational surface without itself constituting that surface. It may be fully
structurally present — tables created, triggers registered, schemas populated —
while constitutionally not yet authoritative for evidence production. ACTIVE
substrate is constitutionally authoritative: evidence events it produces are
immediately admissible. RUNTIME_SCAFFOLD substrate produces no admissible evidence
events until its constitutional activation is declared.

---

## Part II: The Eleven Constitutional States

### State 1: ACTIVE

**Constitutional Definition**: A substrate element is ACTIVE when it has been
constitutionally activated through a valid activation event, it currently operates
as an authoritative evidence production surface or enforcement surface within its
defined domain, and it produces constitutionally valid and immediately admissible
evidence events.

**Operational Characteristics**:
- Evidence events produced by ACTIVE substrate are immediately admissible in all
  applicable regulatory regime proceedings, subject to regime-specific
  admissibility conditions.
- The enforcement authority of ACTIVE substrate is constitutionally real, not
  asserted.
- ACTIVE substrate is subject to the full operational integrity obligations of
  Wave 4 sovereignty and/or the full cryptographic integrity obligations of
  Wave 8 sovereignty, depending on its domain.

**Admissibility Implications**: All evidence events produced while the substrate
element holds ACTIVE state are presumptively admissible within their applicable
regimes. This admissibility is not revoked if the element subsequently transitions
out of ACTIVE state, unless the prior activation itself is determined to have been
constitutionally invalid.

**Replay Obligations**: ACTIVE substrate carries prospective replay obligations —
it must be implemented in a manner that will support replay of its evidence events
at all future constitutional moments, including after transition to
REPLAY_PRESERVED or SUPERSEDED state.

**Permitted Outgoing Transitions**: ACTIVE → DORMANT_RESERVED (under deactivation
rules, Section 4.2); ACTIVE → SUPERSEDED (under supersession rules, Section 4.4);
ACTIVE → REPLAY_PRESERVED (when production is complete and the element is closed
to new events).

**NotebookLM Interpretation Constraint**: ACTIVE state must not be inferred from
the mere structural presence of a substrate element. ACTIVE state requires a
declared constitutional activation event. Structural completeness is not
constitutional activation.

---

### State 2: DORMANT_RESERVED

**Constitutional Definition**: A substrate element is DORMANT_RESERVED when it
was previously ACTIVE, produced a constitutional evidence history, has been
intentionally placed in suspended operation, and is being held in reserve for
possible future reactivation or for the preservation of its operational capability
without current evidence production.

**Constitutional Distinction**: DORMANT_RESERVED is not decommissioned, not
superseded, and not archived. The dormancy is intentional and declared. The
reservation is constitutional — the element is being held, not abandoned.

**Admissibility Implications**: Evidence events produced during prior ACTIVE
periods remain fully admissible. The transition to DORMANT_RESERVED does not
affect the admissibility of prior evidence. New evidence events may not be
produced while in DORMANT_RESERVED state.

**Replay Obligations**: Full replay obligations apply to all evidence events
produced during prior ACTIVE periods. The dormancy of the substrate element does
not reduce or suspend replay obligations. External verifiers retain the full
right to replay-verify historical evidence from DORMANT_RESERVED elements.

**Permitted Outgoing Transitions**: DORMANT_RESERVED → ACTIVE (reactivation,
under activation rules, Section 4.1); DORMANT_RESERVED → SUPERSEDED (under
supersession rules, Section 4.4); DORMANT_RESERVED → REPLAY_PRESERVED (if
reactivation will not occur and the element is closed permanently to new evidence).

**NotebookLM Interpretation Constraint**: DORMANT_RESERVED state must never be
interpreted as technical debt, obsolescence, or decommission. It must never
be interpreted as permission to modify, delete, or repurpose the substrate element
without a constitutionally valid transition. The presence of a DORMANT_RESERVED
element in the substrate is a constitutional fact, not an anomaly.

---

### State 3: PHASE_DEFERRED

**Constitutional Definition**: A substrate element is PHASE_DEFERRED when its
constitutional activation is prohibited by an explicit phase-boundary condition —
specifically, when its activation would constitute a phase-legality violation
under the current constitutional phase. The element exists, may be structurally
complete, but is activation-locked pending the phase transition that removes the
deferral condition.

**Constitutional Distinction**: PHASE_DEFERRED is not the same as RESERVED_UNOPENED.
PHASE_DEFERRED substrate has an identifiable activation gate: a specific phase
boundary or phase capability event that must occur before activation becomes
constitutionally legal. RESERVED_UNOPENED substrate lacks this specific gate.

**Admissibility Implications**: PHASE_DEFERRED substrate produces no evidence
events and therefore has no current admissibility surface. Its existence as
PHASE_DEFERRED is itself a constitutional record — it documents that the capability
was architecturally anticipated and constitutionally deferred rather than absent.

**Replay Obligations**: No prior evidence events exist (the element has not been
active). No replay obligation applies to the element itself. However, the
constitutional record of its deferral is subject to the replay obligations of
the governance layer within which the deferral was declared.

**Permitted Outgoing Transitions**: PHASE_DEFERRED → ACTIVE (when the phase
deferral condition resolves, under phase-boundary activation rules, Section 4.5);
PHASE_DEFERRED → RESERVED_UNOPENED (if the phase-specific deferral condition is
replaced by a more general reservation, under amendment procedures);
PHASE_DEFERRED → CONSTITUTIONALLY_ISOLATED (if the deferred capability is
isolated from the main constitutional graph for architectural reasons).

**NotebookLM Interpretation Constraint**: PHASE_DEFERRED substrate must not be
interpreted as missing, incomplete, or accidentally omitted. It must be interpreted
as architecturally present and constitutionally deferred. The deferral is a
design declaration, not a design failure.

---

### State 4: RUNTIME_SCAFFOLD

**Constitutional Definition**: A substrate element is in RUNTIME_SCAFFOLD state
when it is structurally present — fully instantiated in the schema, trigger
registry, or enforcement surface — but has not been constitutionally activated as
an authoritative evidence production surface. RUNTIME_SCAFFOLD elements provide
structural support for adjacent ACTIVE elements or for future activation events
without themselves constituting authoritative surfaces.

**Constitutional Distinction**: RUNTIME_SCAFFOLD is the critical boundary between
structural completeness and constitutional authority. A trigger that exists in
the schema but produces a placeholder result is RUNTIME_SCAFFOLD, not ACTIVE.
A migration that creates tables but does not activate their authoritative
enforcement functions leaves those tables in RUNTIME_SCAFFOLD state for
enforcement purposes, even if they are operationally writable.

**Admissibility Implications**: Evidence events produced while a substrate element
is in RUNTIME_SCAFFOLD state are constitutionally inadmissible as authoritative
evidence. They may be produced operationally — rows may be written, functions may
execute — but those events do not carry the evidentiary weight of ACTIVE-state
evidence. Any claim of admissibility for evidence events produced in
RUNTIME_SCAFFOLD state is constitutionally void.

**Replay Obligations**: Because RUNTIME_SCAFFOLD evidence events are constitutionally
inadmissible, they carry no authoritative replay obligations. However, the record
of their production — the fact that a substrate element was in RUNTIME_SCAFFOLD
state at a given constitutional moment — is itself a constitutional record that
must be replay-survivable for governance and auditing purposes.

**Permitted Outgoing Transitions**: RUNTIME_SCAFFOLD → ACTIVE (upon constitutional
activation declaration); RUNTIME_SCAFFOLD → PHASE_DEFERRED (if activation is
deferred pending phase resolution); RUNTIME_SCAFFOLD → RESERVED_UNOPENED (if the
scaffold's purpose is reclassified as reserved).

**NotebookLM Interpretation Constraint**: RUNTIME_SCAFFOLD state must not be
interpreted as equivalent to ACTIVE state. The structural presence of enforcement
logic does not constitute its constitutional activation. Wave 8's DB-006 task,
prior to SEC-002 completion, represents RUNTIME_SCAFFOLD state — the trigger
exists but is not constitutionally authoritative.

---

### State 5: REPLAY_PRESERVED

**Constitutional Definition**: A substrate element is in REPLAY_PRESERVED state
when it was previously ACTIVE, has been closed to new evidence production, and
exists solely to maintain the conditions under which all evidence events it
produced during its ACTIVE period may be independently re-verified at any future
constitutional moment. REPLAY_PRESERVED is not an archive state. It is an active
constitutional obligation state.

**Constitutional Distinction**: REPLAY_PRESERVED is distinct from SUPERSEDED in
that no successor has been declared. The element is not replaced — it is closed
and preserved. It is distinct from DORMANT_RESERVED in that reactivation is not
anticipated — the element's evidence production chapter is constitutionally closed.

**Admissibility Implications**: All evidence events produced during prior ACTIVE
periods retain full admissibility. The REPLAY_PRESERVED state is an affirmative
guarantee to all external verifiers, regulators, counterparties, and judicial
authorities that replay verification will succeed for the full historical record
at any future time.

**Replay Obligations**: The most extensive replay obligations of any state. The
substrate element in REPLAY_PRESERVED state must maintain:
- All schema versions under which evidence was produced.
- All cryptographic primitives required to re-verify signatures from any historical
  signing event.
- All key registry entries for keys active during the ACTIVE period.
- All canonical payload schema versions from the ACTIVE period.
- All methodology version records referenced in ACTIVE-period evidence payloads.

None of these preservation obligations may be reduced, suspended, or relaxed for
any reason, including schema evolution, key rotation, storage economics, or
operational simplification.

**Permitted Outgoing Transitions**: REPLAY_PRESERVED → ARCHAEOLOGICAL (when all
replay-survivability obligations have been constitutionally delegated to a
permanent preservation infrastructure under amendment procedures). No other
outgoing transition is constitutionally legal. REPLAY_PRESERVED may not transition
to SUPERSEDED, DORMANT_RESERVED, or any other state.

**NotebookLM Interpretation Constraint**: REPLAY_PRESERVED state must never be
interpreted as archival, as reduced-obligation, or as a precursor to deletion.
It carries the strongest replay obligations of any state. A REPLAY_PRESERVED
substrate element is constitutionally more demanding to maintain than a
DORMANT_RESERVED one.

---

### State 6: SUPERSEDED

**Constitutional Definition**: A substrate element is SUPERSEDED when it has been
explicitly replaced by a constitutionally declared successor element under a valid
supersession event. The supersession must name both the superseded element and its
declared successor. Supersession is irrevocable once declared under constitutional
amendment procedures. The superseded element's evidence history remains fully
admissible and replay-obligated.

**Constitutional Distinction**: Supersession is not deletion, decommission, or
retirement. A SUPERSEDED element continues to exist as a constitutional record.
Its evidence history is permanently part of Symphony's constitutional chain. The
supersession means that the element no longer serves as the authoritative surface
for new evidence production — its successor does. It does not mean the element
is erased.

**Admissibility Implications**: Evidence events produced during the SUPERSEDED
element's ACTIVE period retain full admissibility. Evidence events produced after
the supersession event using the superseded element's surface are constitutionally
inadmissible — they were produced using a non-authoritative surface.

**Replay Obligations**: Full replay obligations apply to all evidence events
produced during the SUPERSEDED element's prior ACTIVE period. These obligations
transfer to the successor element's custodianship but are not diminished.

**Supersession Legality Requirements** (see Section 4.4): A valid supersession
requires a constitutional declaration naming the superseded element, the successor
element, the supersession event timestamp, the constitutional basis for supersession,
and the replay obligation transfer terms.

**Permitted Outgoing Transitions**: SUPERSEDED → ARCHAEOLOGICAL (when all
replay-survivability obligations have been constitutionally delegated under
amendment procedures). No other outgoing transitions are constitutionally legal.

**NotebookLM Interpretation Constraint**: SUPERSEDED state must not be interpreted
as permission to delete, modify, or repurpose the superseded element. The
element's existence and its full historical record are constitutionally preserved.
Supersession is authority transfer, not erasure.

---

### State 7: ARCHAEOLOGICAL

**Constitutional Definition**: A substrate element is in ARCHAEOLOGICAL state when
it was previously ACTIVE in a completed constitutional phase, has produced a
closed historical record, is constitutionally closed to new evidence production
and to reactivation, and exists permanently as a constitutional record of the
architectural and evidentiary decisions made during its active period.

**Constitutional Distinction**: ARCHAEOLOGICAL is the most terminal state in the
constitutional lifecycle. Unlike REPLAY_PRESERVED, ARCHAEOLOGICAL state implies
that the element's replay obligations have been fully and permanently discharged
to a designated preservation infrastructure. Unlike SUPERSEDED, ARCHAEOLOGICAL
state does not imply that a successor is authoritative for the same surface.
ARCHAEOLOGICAL elements represent closed constitutional chapters, not replaced ones.

**Admissibility Implications**: Evidence events produced during the element's
ACTIVE period remain admissible for the full statutory, regulatory, and
constitutional retention period applicable to each regime that relied on those
events. The ARCHAEOLOGICAL state does not reduce this admissibility — it
guarantees its permanent preservation.

**Replay Obligations**: Replay obligations are permanently discharged to designated
preservation infrastructure and are not the operational responsibility of active
agents. However, the preservation infrastructure itself carries the same replay
obligations that would otherwise apply to the ARCHAEOLOGICAL element directly.
These obligations cannot be deleted — only transferred.

**Permitted Outgoing Transitions**: None. ARCHAEOLOGICAL is a terminal state.
No outgoing transition is constitutionally legal.

**NotebookLM Interpretation Constraint**: ARCHAEOLOGICAL state must not be
interpreted as obsolete, irrelevant, or deletable. It must be interpreted as
a permanent constitutional record. The absence of current operational activity
around an ARCHAEOLOGICAL element is expected and constitutionally correct.

---

### State 8: RESERVED_UNOPENED

**Constitutional Definition**: A substrate element is in RESERVED_UNOPENED state
when it has been constitutionally designated for a defined future purpose, has
not yet been activated, and is protected from arbitrary repurposing, modification,
or deletion by the constitutional reservation that established it.

**Constitutional Distinction**: RESERVED_UNOPENED is distinct from PHASE_DEFERRED
in that there is no specific phase gate controlling activation. The reservation
is a constitutional commitment to a future purpose without a specified activation
trigger. The element is not yet ready — or the conditions under which it will
become ready are not yet defined with phase-level specificity.

**Admissibility Implications**: No evidence events are produced. The constitutional
reservation itself is a governance record subject to the replay obligations of
the governance layer within which the reservation was declared.

**Replay Obligations**: No evidence-level replay obligations apply. Governance-
level replay obligations apply to the declaration of the reservation.

**Permitted Outgoing Transitions**: RESERVED_UNOPENED → ACTIVE (under activation
rules, when the reservation purpose is constitutionally ready for activation);
RESERVED_UNOPENED → PHASE_DEFERRED (when the activation condition is identified
as a specific phase gate); RESERVED_UNOPENED → CONSTITUTIONALLY_ISOLATED (if
the reservation purpose requires sovereign isolation); RESERVED_UNOPENED →
ARCHAEOLOGICAL (if the reservation purpose is permanently closed without
activation, under amendment procedures).

**NotebookLM Interpretation Constraint**: RESERVED_UNOPENED must not be interpreted
as an accident, an oversight, or an incomplete design. It must be interpreted as
a deliberate constitutional reservation. The element is held, not missing.

---

### State 9: CONDITIONALLY_REACHABLE

**Constitutional Definition**: A substrate element is in CONDITIONALLY_REACHABLE
state when it exists within Symphony's constitutional architecture but can only
be reached — activated or engaged — when a specific set of conditions external
to the element's own design are satisfied. Those conditions may include the
activation of dependent elements, the resolution of a regulatory authorisation
process, or the satisfaction of a multi-party consent requirement. The element
is not deferred by phase boundary and not reserved without a defined purpose —
it is simply unreachable until its specific conditions are met.

**Constitutional Distinction**: CONDITIONALLY_REACHABLE is distinct from
PHASE_DEFERRED in that the conditions governing reachability are not phase
boundaries — they may be satisfied at any phase. It is distinct from
REGULATOR_GATED in that the conditions are not exclusively regulatory.

**Admissibility Implications**: No evidence events are produced. Conditional
reachability is a constitutional declaration of dependency, not of failure.

**Replay Obligations**: No evidence-level replay obligations apply to the element
in this state. Dependency declarations are governance records subject to
governance-layer replay obligations.

**Permitted Outgoing Transitions**: CONDITIONALLY_REACHABLE → ACTIVE (when all
conditions are satisfied under activation rules); CONDITIONALLY_REACHABLE →
REGULATOR_GATED (if the conditions resolve to be exclusively regulatory in
character); CONDITIONALLY_REACHABLE → PHASE_DEFERRED (if the conditions resolve
to be exclusively phase-boundary in character).

**NotebookLM Interpretation Constraint**: CONDITIONALLY_REACHABLE must not be
interpreted as broken, incomplete, or accidentally disconnected. It must be
interpreted as architecturally present and condition-locked.

---

### State 10: REGULATOR_GATED

**Constitutional Definition**: A substrate element is in REGULATOR_GATED state
when its constitutional activation requires an explicit authorisation from one
or more named regulatory regimes — and that authorisation has not yet been
received. The element may be structurally complete. It may be technically capable
of activation. But it is constitutionally locked pending the regulatory
authorisation that is a precondition of its legal operation.

**Constitutional Distinction**: REGULATOR_GATED is distinct from PHASE_DEFERRED
in that the gate is a sovereign regulatory act, not a constitutional phase
boundary. It is distinct from CONDITIONALLY_REACHABLE in that the conditions
are specifically regulatory in character and must be satisfied through formal
regulatory process.

**Admissibility Implications**: Evidence events produced by a REGULATOR_GATED
element before regulatory authorisation is received are constitutionally
inadmissible within the gating regime. They may constitute operational records
but do not carry the evidentiary weight required for regulatory admissibility.

**Replay Obligations**: No authoritative evidence-level replay obligations apply.
The record of the regulatory gate condition — the fact that authorisation was
required and its status — is a governance record subject to governance-layer
replay obligations.

**Regulator-Gated Activation Constraints** (see Section 4.6): Activation from
REGULATOR_GATED state requires: identification of the gating regime(s), receipt
of the regulatory authorisation event, recording of the authorisation within
Symphony's constitutional evidence chain, and a constitutional activation
declaration that references the authorisation record.

**Permitted Outgoing Transitions**: REGULATOR_GATED → ACTIVE (upon receipt of
all required regulatory authorisations and constitutional activation declaration);
REGULATOR_GATED → CONSTITUTIONALLY_ISOLATED (if regulatory refusal is received
and the element must be isolated from the main constitutional graph).

**NotebookLM Interpretation Constraint**: REGULATOR_GATED must not be interpreted
as a regulatory compliance failure. It must be interpreted as correct constitutional
posture pending the regulatory process that governs the element's activation domain.

---

### State 11: CONSTITUTIONALLY_ISOLATED

**Constitutional Definition**: A substrate element is in CONSTITUTIONALLY_ISOLATED
state when it has been deliberately partitioned from the main constitutional
evidence graph for declared sovereign, regulatory, or evidentiary integrity
reasons. The element is not inactive, not dormant, not deferred, and not
superseded — it exists in a constitutionally walled partition where its
evidence surfaces operate independently of the main graph and where cross-graph
evidence contamination is constitutionally prohibited.

**Constitutional Distinction**: CONSTITUTIONALLY_ISOLATED substrate is not
accidentally disconnected. Its isolation is a positive constitutional declaration.
The partition exists to preserve sovereign orthogonality — to ensure that evidence
produced within the isolated domain cannot be claimed as satisfying, superseding,
or contaminating evidence within the main constitutional graph or within any
other isolated domain.

**Admissibility Implications**: Evidence events produced by CONSTITUTIONALLY_ISOLATED
substrate are admissible within the isolated domain's applicable regimes. They are
not admissible as evidence within the main constitutional graph unless a
constitutionally valid bridge mechanism — explicitly declared and constitutionally
authorised — carries specific evidence events across the partition boundary.

**Replay Obligations**: Full replay obligations apply within the isolated partition.
The isolation of the partition does not reduce the replay obligations of evidence
events produced within it. The isolation boundary itself is subject to
replay-survivable governance records.

**Permitted Outgoing Transitions**: CONSTITUTIONALLY_ISOLATED → ACTIVE (within
the isolated domain, the element may be ACTIVE for isolated purposes);
CONSTITUTIONALLY_ISOLATED → REPLAY_PRESERVED (when isolated evidence production
is complete). The isolation state does not preclude internal state transitions
within the isolated partition; it prevents graph-crossing transitions that would
merge the isolated domain with the main graph.

**NotebookLM Interpretation Constraint**: CONSTITUTIONALLY_ISOLATED must not be
interpreted as broken, abandoned, or orphaned. It must be interpreted as
intentionally and constitutionally partitioned. Cross-graph inference from
CONSTITUTIONALLY_ISOLATED evidence to main-graph admissibility claims is
constitutionally prohibited.

---

## Part III: Constitutional State Transition Diagram

The following diagram defines the complete legal transition graph. Every arc
represents a permitted transition. The absence of an arc between two states
represents an absolutely prohibited transition.

```
RESERVED_UNOPENED ──────────────────────────────────────────────────────────┐
    │                                                                         │
    ├──→ PHASE_DEFERRED ──────────────────────────────────────────────────┐  │
    │         │                                                             │  │
    │         ├──→ ACTIVE ──────────────────────────────────┐             │  │
    │         │                                              │             │  │
    │         └──→ CONSTITUTIONALLY_ISOLATED                │             │  │
    │                                                        │             │  │
    ├──→ ACTIVE ◄───────────────────────────────────────────┘             │  │
    │     │                                                                │  │
    │     ├──→ DORMANT_RESERVED ──────────┐                               │  │
    │     │         │                     │                               │  │
    │     │         ├──→ ACTIVE           │                               │  │
    │     │         ├──→ SUPERSEDED ──────┼──→ ARCHAEOLOGICAL ◄───────────┘  │
    │     │         └──→ REPLAY_PRESERVED─┘                                  │
    │     │                                                                   │
    │     ├──→ SUPERSEDED ──→ ARCHAEOLOGICAL                                 │
    │     └──→ REPLAY_PRESERVED ──→ ARCHAEOLOGICAL                           │
    │                                                                         │
    ├──→ CONSTITUTIONALLY_ISOLATED                                           │
    │                                                                         │
    └──→ ARCHAEOLOGICAL ◄────────────────────────────────────────────────────┘

RUNTIME_SCAFFOLD ──→ ACTIVE
                 ──→ PHASE_DEFERRED
                 ──→ RESERVED_UNOPENED

CONDITIONALLY_REACHABLE ──→ ACTIVE
                         ──→ REGULATOR_GATED
                         ──→ PHASE_DEFERRED

REGULATOR_GATED ──→ ACTIVE
                ──→ CONSTITUTIONALLY_ISOLATED
```

### 3.1 Summary Transition Matrix

| From State | Permitted Destinations |
|------------|----------------------|
| RESERVED_UNOPENED | ACTIVE, PHASE_DEFERRED, CONSTITUTIONALLY_ISOLATED, ARCHAEOLOGICAL |
| PHASE_DEFERRED | ACTIVE, RESERVED_UNOPENED, CONSTITUTIONALLY_ISOLATED |
| RUNTIME_SCAFFOLD | ACTIVE, PHASE_DEFERRED, RESERVED_UNOPENED |
| ACTIVE | DORMANT_RESERVED, SUPERSEDED, REPLAY_PRESERVED |
| DORMANT_RESERVED | ACTIVE, SUPERSEDED, REPLAY_PRESERVED |
| REPLAY_PRESERVED | ARCHAEOLOGICAL |
| SUPERSEDED | ARCHAEOLOGICAL |
| ARCHAEOLOGICAL | (terminal — no outgoing transitions) |
| CONDITIONALLY_REACHABLE | ACTIVE, REGULATOR_GATED, PHASE_DEFERRED |
| REGULATOR_GATED | ACTIVE, CONSTITUTIONALLY_ISOLATED |
| CONSTITUTIONALLY_ISOLATED | REPLAY_PRESERVED (within partition) |

---

## Part IV: Transition Legality Rules

### 4.1 Activation Legality (→ ACTIVE)

A transition to ACTIVE state is constitutionally legal if and only if:

(a) **Structural completeness**: The substrate element is fully structurally
    instantiated — all schema objects, enforcement functions, and trigger
    registrations required for its authoritative operation are present.

(b) **Dependency satisfaction**: All substrate elements upon which this element
    depends for its authoritative operation are themselves in ACTIVE state with
    valid activation records.

(c) **Phase legality**: The current constitutional phase is one in which this
    element's capability class is constitutionally permitted to operate.
    Activation of a capability before its phase boundary constitutes a phase-
    legality violation and renders the element's evidence events inadmissible.

(d) **Constitutional activation declaration**: A formal constitutional activation
    event has been declared, naming the element, the activation timestamp, the
    activating authority, and the dependency satisfaction record.

(e) **Non-placeholder enforcement**: The element's enforcement surfaces do not
    contain placeholder logic — specifically, no verification function may return
    a success result without executing the verification it is constituted to
    perform. An element with placeholder enforcement is in RUNTIME_SCAFFOLD state,
    not ACTIVE state, regardless of operational appearances.

### 4.2 Deactivation Legality (ACTIVE → DORMANT_RESERVED)

A transition from ACTIVE to DORMANT_RESERVED is constitutionally legal if:

(a) A constitutional deactivation declaration is issued, naming the element, the
    deactivation timestamp, the deactivating authority, and the basis for
    deactivation.

(b) All replay obligations for evidence events produced during the ACTIVE period
    are documented and assigned to a designated preservation custodian.

(c) All regulatory regimes dependent on this element's evidence surface have been
    notified of the deactivation in a form consistent with each regime's
    admissibility continuity requirements.

A transition from ACTIVE to DORMANT_RESERVED is constitutionally illegal if:

(a) The deactivation would destroy replay capability for any evidence event
    produced during the ACTIVE period.

(b) Any regulatory regime's admissibility continuity for historical evidence
    would be interrupted without the regime's constitutional acknowledgement.

### 4.3 Replay Preservation Legality (→ REPLAY_PRESERVED)

A transition to REPLAY_PRESERVED state requires:

(a) A constitutional preservation declaration confirming that evidence production
    is complete and that the element is being closed.

(b) A complete inventory of all evidence events produced during the ACTIVE period,
    with their cryptographic identifiers.

(c) A confirmed preservation commitment covering all schema versions, cryptographic
    primitive versions, key registry entries, and methodology version records
    required to replay-verify each evidence event.

(d) A replay verification test confirming that the oldest evidence event in the
    ACTIVE period's history can be successfully re-verified after the transition.

### 4.4 Supersession Legality (→ SUPERSEDED)

A supersession declaration is constitutionally valid if and only if:

(a) The supersession explicitly names the superseded element by its constitutional
    identifier.

(b) The supersession explicitly names the successor element by its constitutional
    identifier, and the successor element exists in ACTIVE or PHASE_DEFERRED state.

(c) The supersession records the constitutional basis for the supersession event —
    the architectural or evidential reason the superseded element is being replaced.

(d) The replay obligation transfer terms are explicitly stated — identifying who
    is responsible for maintaining the replay capability for the superseded
    element's prior evidence history.

(e) The supersession is declared under constitutional amendment procedures
    (CONSTITUTIONAL_AMENDMENT_AND_EVOLUTION_DOCTRINE.md) if it affects a Root or
    Wave-level authority surface.

An undeclared supersession — the effective replacement of an element's function
by another element without a formal supersession declaration — is constitutionally
prohibited regardless of operational convenience.

### 4.5 Phase-Boundary Activation Legality

Phase-boundary activation rules govern the transition from PHASE_DEFERRED to
ACTIVE:

(a) The phase deferral condition must be documented at the time of deferral,
    naming the specific phase boundary or capability event that removes the
    deferral.

(b) Activation from PHASE_DEFERRED may only occur after the named phase boundary
    has been constitutionally crossed — meaning the constitutional acts required
    to enter the new phase have been completed and recorded.

(c) The activation declaration for a previously PHASE_DEFERRED element must
    reference the phase transition event that removed the deferral.

(d) Activation before the named phase boundary constitutes a phase-legality
    violation. Evidence events produced by a prematurely activated PHASE_DEFERRED
    element are constitutionally inadmissible.

### 4.6 Regulator-Gated Activation Constraints

Activation from REGULATOR_GATED state requires:

(a) Identification of each gating regulatory regime by its constitutional
    regime identifier (as defined in REGULATORY_ALIGNMENT_CONSTITUTION.md and
    REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md).

(b) Receipt of a formal authorisation event from each gating regime.

(c) Recording of each authorisation event within Symphony's constitutional
    evidence chain as an independently admissible governance record.

(d) A constitutional activation declaration that references each authorisation
    record by its constitutional identifier.

No single authorisation may satisfy the gate for multiple regimes unless each
regime has independently authorised the activation on its own terms. Cross-regime
authorisation equivalence is prohibited by
REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md.

### 4.7 Absolutely Prohibited Transitions

The following state transitions are constitutionally illegal under all
circumstances:

| Prohibited Transition | Constitutional Basis for Prohibition |
|-----------------------|-------------------------------------|
| ARCHAEOLOGICAL → any state | Terminal state; no reactivation or modification |
| REPLAY_PRESERVED → SUPERSEDED | Cannot supersede a closed preservation obligation |
| REPLAY_PRESERVED → DORMANT_RESERVED | Replay preservation is a stronger obligation than dormancy |
| REPLAY_PRESERVED → ACTIVE | Closed evidence production chapters may not be reopened |
| SUPERSEDED → ACTIVE | Supersession is irrevocable; successor must be activated |
| SUPERSEDED → DORMANT_RESERVED | Superseded elements are not candidates for reactivation |
| Any state → deletion | Substrate elements may never be deleted from the constitutional record |
| Any state → undeclared modification | In-place modification without state declaration is prohibited |
| PHASE_DEFERRED → ACTIVE (before phase gate) | Phase-legality violation |
| REGULATOR_GATED → ACTIVE (before authorisation) | Regulatory sovereignty violation |

---

## Part V: Admissibility Implications by State

| State | New Evidence Admissible? | Historical Evidence Admissible? | External Verifier Access |
|-------|--------------------------|--------------------------------|--------------------------|
| ACTIVE | Yes — immediately | Yes — all prior ACTIVE periods | Full |
| DORMANT_RESERVED | No | Yes — all prior ACTIVE periods | Full |
| PHASE_DEFERRED | No | N/A (no prior history) | N/A |
| RUNTIME_SCAFFOLD | No — constitutionally void | N/A | N/A |
| REPLAY_PRESERVED | No | Yes — permanently | Full — guaranteed |
| SUPERSEDED | No — post-supersession | Yes — pre-supersession | Full |
| ARCHAEOLOGICAL | No | Yes — permanently preserved | Preserved infrastructure |
| RESERVED_UNOPENED | No | N/A | N/A |
| CONDITIONALLY_REACHABLE | No | N/A | N/A |
| REGULATOR_GATED | No — without authorisation | N/A | N/A |
| CONSTITUTIONALLY_ISOLATED | Within partition only | Within partition only | Within partition only |

---

## Part VI: Replay Obligations by State

| State | Replay Obligation Level | Obligation Scope |
|-------|------------------------|-----------------|
| ACTIVE | Prospective — must be built for future replay | All events from activation onward |
| DORMANT_RESERVED | Full — equal to ACTIVE | All events from prior ACTIVE periods |
| PHASE_DEFERRED | None at evidence level | Governance records of deferral only |
| RUNTIME_SCAFFOLD | None at evidence level | Governance records of scaffold existence |
| REPLAY_PRESERVED | Maximum — permanent preservation | All events from all prior ACTIVE periods |
| SUPERSEDED | Full — equal to ACTIVE | All events from prior ACTIVE periods |
| ARCHAEOLOGICAL | Permanently discharged | Delegated to preservation infrastructure |
| RESERVED_UNOPENED | None at evidence level | Governance records of reservation only |
| CONDITIONALLY_REACHABLE | None at evidence level | Governance records of condition declarations |
| REGULATOR_GATED | None at evidence level | Governance records of gate conditions |
| CONSTITUTIONALLY_ISOLATED | Full within partition | All events within isolated partition |

---

## Part VII: NotebookLM Interpretation Constraints by State

The following constraints are mandatory for NotebookLM corpus synthesis. Any
synthesis output that violates these constraints produces a constitutionally
defective result that must not be treated as authoritative.

| State | Prohibited Inference | Required Interpretation |
|-------|---------------------|------------------------|
| DORMANT_RESERVED | "This is unused/dead schema" | "This is suspended operational infrastructure with preserved history" |
| PHASE_DEFERRED | "This is missing/incomplete" | "This is architecturally present and phase-locked" |
| RUNTIME_SCAFFOLD | "This is ACTIVE" | "This has structural presence but no constitutional authority" |
| REPLAY_PRESERVED | "This is archived/reduced-obligation" | "This carries maximum replay obligations permanently" |
| SUPERSEDED | "This is deleted/gone" | "This is replaced but historically preserved" |
| ARCHAEOLOGICAL | "This is obsolete/irrelevant" | "This is a permanent constitutional record" |
| RESERVED_UNOPENED | "This is accidental" | "This is a deliberate constitutional reservation" |
| CONDITIONALLY_REACHABLE | "This is broken/disconnected" | "This is condition-locked by design" |
| REGULATOR_GATED | "This is blocked/failed" | "This is in correct pre-authorisation posture" |
| CONSTITUTIONALLY_ISOLATED | "This is orphaned/abandoned" | "This is intentionally partitioned" |

---

## Part VIII: Prohibited Misinterpretations

### 8.1 Dormant Substrate as Dead Schema

**Prohibited interpretation**: A substrate element in DORMANT_RESERVED state
has no live connections, no active queries, and no operational traffic. It is
therefore dead schema and a candidate for deletion or repurposing.

**Constitutional basis for prohibition**: DORMANT_RESERVED state is defined by
the existence of a prior evidence history that remains admissible and
replay-obligated. The absence of current operational traffic is irrelevant to
the constitutional obligations arising from that history. Deletion of
DORMANT_RESERVED substrate constitutes replay destruction and is a Priority 1
violation under CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md.

### 8.2 Reserved Infrastructure as Accidental Design

**Prohibited interpretation**: A substrate element in RESERVED_UNOPENED or
PHASE_DEFERRED state has no active usage. It was probably created speculatively
and is not part of the intentional architecture. It may be safely removed or
repurposed.

**Constitutional basis for prohibition**: Reserved and deferred substrate
elements are constitutionally designated. Their existence in the schema is not
speculative — it is a constitutional record of architectural intent. The
NON_INFERENCE_AND_INTERPRETATION_LIMITS.md document explicitly prohibits the
inference that "inactive substrate implies technical debt." Removal of reserved
or deferred substrate without a constitutional amendment constitutes undeclared
deletion of constitutionally designated infrastructure.

### 8.3 Replay-Destructive Deactivation

**Prohibited interpretation**: A substrate element is being deactivated because
it is no longer needed operationally. The deactivation removes the schema
objects and enforcement functions associated with the element. This is a clean
operational housekeeping act.

**Constitutional basis for prohibition**: Any deactivation that destroys or
degrades replay capability for evidence events produced during the element's
ACTIVE period is constitutionally illegal regardless of operational justification.
Replay survivability is Priority 1. Operational housekeeping cannot override it.

### 8.4 Undeclared Supersession

**Prohibited interpretation**: A new substrate element has been created that
performs the same function as an existing element. The new element is better.
Agents should use the new element. The old element is implicitly superseded.

**Constitutional basis for prohibition**: Implicit or undeclared supersession
is constitutionally void. Until a formal supersession declaration names the
superseded element, identifies the successor, and transfers replay obligations,
the original element remains in its prior constitutional state with all its
associated obligations intact. Operating agents that route around an existing
element without a constitutional supersession declaration are operating on an
unauthoritative surface.

### 8.5 Structural Completeness as Constitutional Activation

**Prohibited interpretation**: A substrate element's schema objects are all
present. Its functions compile. Its triggers are registered. It is therefore
ACTIVE and its evidence events are admissible.

**Constitutional basis for prohibition**: Structural completeness is not
constitutional activation. RUNTIME_SCAFFOLD state captures exactly this
condition — structurally complete but not constitutionally authoritative.
Constitutional activation requires a formal activation declaration and the
satisfaction of all activation preconditions, including the absence of
placeholder enforcement logic.

### 8.6 ARCHAEOLOGICAL as Obsolete

**Prohibited interpretation**: An ARCHAEOLOGICAL substrate element belongs to
a completed phase. The project has moved on. The element is no longer
relevant and does not need to be maintained or considered.

**Constitutional basis for prohibition**: ARCHAEOLOGICAL elements are permanent
constitutional records. Their evidence history is admissible in perpetuity for
applicable retention periods. Their existence documents the constitutional
decisions made in their active phase — decisions that may be relevant to
regulatory proceedings, external verifier challenges, or cross-border evidence
requests at any future moment.

### 8.7 Isolated Substrate as Orphaned

**Prohibited interpretation**: A CONSTITUTIONALLY_ISOLATED substrate element
has no connections to the main constitutional graph. It appears disconnected.
It is probably a mistake or an orphaned remnant of a past design decision.

**Constitutional basis for prohibition**: Constitutional isolation is a
deliberate design declaration. The absence of graph connections to the main
constitutional architecture is the intended property of CONSTITUTIONALLY_ISOLATED
state, not evidence of an error. Connecting isolated substrate to the main graph
without a constitutionally authorised bridge mechanism would destroy the sovereign
orthogonality that the isolation was designed to preserve.

### 8.8 REGULATOR_GATED as Blocked/Failed

**Prohibited interpretation**: A REGULATOR_GATED substrate element cannot be
activated because it has not received regulatory authorisation. This represents
a failure of the regulatory engagement process and should be resolved by
activating the element without waiting for formal authorisation.

**Constitutional basis for prohibition**: REGULATOR_GATED state is the correct
constitutional posture for an element that requires regulatory authorisation
before it may legally operate. Activating a REGULATOR_GATED element without
the required authorisation renders all subsequent evidence events constitutionally
inadmissible within the gating regime and constitutes a regulatory sovereignty
violation under REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md.

---

## Constitutional Self-Validation

### Sovereignty Domains Governed

This document governs:

- The constitutional lifecycle posture of all substrate elements across Wave 4
  operational sovereignty surfaces and Wave 8 cryptographic/provenance sovereignty
  surfaces.
- The state transition legality rules binding on all substrate elements within
  Symphony's constitutional architecture.
- The replay obligations associated with each constitutional state.
- The admissibility implications of each constitutional state for evidence events
  produced by substrate elements in that state.

### Sovereignty Domains This Document MUST NOT Redefine

This document must not redefine:

- Root constitutional doctrine (CONSTITUTIONAL_AUTHORITY_HIERARCHY.md, Rank 10).
- The replay primacy doctrine (REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md, Rank 10).
- The cryptographic and runtime authority boundary between Wave 4 and Wave 8
  (CRYPTOGRAPHIC_AND_RUNTIME_AUTHORITY_DOCTRINE.md, Rank 10).
- The constitutional priority ordering
  (CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md, Rank 10).
- The prohibited inference rules
  (NON_INFERENCE_AND_INTERPRETATION_LIMITS.md, Rank 10).
- Regulator partition doctrine
  (REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md, Rank 7, companion).

### Replay Obligations Preserved

This document preserves:

- The inviolability of replay obligations for all substrate elements in ACTIVE,
  DORMANT_RESERVED, SUPERSEDED, and REPLAY_PRESERVED states.
- The prohibition on replay-destructive deactivation (Section 4.2 and 8.3).
- The maximum replay obligations of REPLAY_PRESERVED state (Part VI).
- The governance-level replay obligations for all state declarations and
  transition records.

### Regulator Boundaries That Constrain This Document

- REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md constrains the
  REGULATOR_GATED state and its activation rules.
- REGULATORY_ALIGNMENT_CONSTITUTION.md constrains the admissibility implications
  stated in Part V for regime-specific evidence.
- CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md constrains the resolution
  of any conflict between state transition legality rules and other constitutional
  obligations.

### Phases to Which This Document Applies

Global. The constitutional state model applies to all substrate elements across
all constitutional phases. Phase-specific interactions are handled through the
PHASE_DEFERRED state and the phase-boundary activation rules in Section 4.5.

### Constitutional Layers Possessing Override Authority

- Root constitutional doctrine (Rank 10): unconditional override authority.
- CONSTITUTIONAL_AUTHORITY_HIERARCHY.md: override authority on rank assignments.
- CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md: override authority when
  state transition rules conflict with priority-1 or priority-2 obligations.

### Lower-Layer Documents Prohibited From Reinterpretation

The following lower-layer document classes are prohibited from reinterpreting
the constitutional states and transition rules defined herein:

- Migration records (all waves and phases).
- Enforcement surface implementations.
- Evidence schema definitions.
- Task pack definitions and implementation plans.
- Operational procedure documents.
- Analytical syntheses, audit reports, and AI-generated assessments.
- Wave-specific governance documents of rank lower than 9.

No lower-layer document may declare a substrate element to be in a constitutional
state other than the state determined by the transition rules of this document,
may assert that structural completeness implies ACTIVE state, may treat
DORMANT_RESERVED or PHASE_DEFERRED elements as candidates for deletion, or may
declare an undeclared supersession as constitutionally valid.
