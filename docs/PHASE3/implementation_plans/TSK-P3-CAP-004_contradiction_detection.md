# TSK-P3-CAP-004 Contradiction Detection Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-004
Execution-Surface: P3-SURF-004
DAG-Nodes: TSK-P3-WP-004; TSK-P3-SUPPORT-MIG-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-003_wave3_contradiction_failure_composition.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
  replay_owner: docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  verifier_owner: scripts/db/verify_p3_contradiction_detection.sh
  persistence_owner: future Phase 3 contradiction records
Replay-Criticality: projection-state
State-Mutability: quarantined-state
Ontology-Classification: quarantine
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: regulator workflows route to Phase 8A or Phase 8B if externalized; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-004` — the Contradiction Detection And Quarantine Surface.

It refines the Wave 3 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-004`
- the `P3-SURF-004` share of `TSK-P3-SUPPORT-MIG-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-004` owns contradiction detection, quarantine, supersession, and
escalation posture for Phase 3. The surface must establish:

- deterministic detection of direct, temporal, authority-scope, policy,
  evidence-lineage, and projection-context contradictions using only declared
  contradiction classes;
- append-only contradiction findings and quarantine-compatible state;
- replay-aware contradiction evaluation over projected constitutional state
  without mutating source truth;
- migration and backfill planning that preserves contradiction records and
  pre-existing replay lineage without destructive rewrites.

Surface-level classification is intentionally coarse. Task packs must classify
each output artifact type separately and must not inherit the surface-level
classification as a uniform type for all outputs:

| Artifact type | Replay criticality | Mutability class |
|---|---|---|
| Contradiction finding record | `replay-derived` | `immutable-lineage` |
| Quarantine projection | `projection-state` | `quarantined-state` |
| Supersession append record | `replay-derived` | `compensating-lineage` |
| Escalation record | `replay-derived` | `supersedable-projection` |

This surface does **not** own:

- new contradiction classes;
- contradiction resolution where doctrine does not already define the rule;
- source record deletion;
- regulator workflow execution;
- failure-composition taxonomy itself;
- product authorization or future-phase integration semantics;
- synthesis of new contradiction resolution logic;
- sovereign adjudication inference;
- local balancing-rule invention;
- collapse of unresolved contradictions into deterministic closure outside
  doctrine.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-004` | `docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md`; `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | Contradiction detection must use only declared contradiction classes and may resolve only where doctrine already defines the outcome rule. |
| `TSK-P3-SUPPORT-MIG-001` (`P3-SURF-004` share) | `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md` | Migration and backfill planning must preserve replay-addressable contradiction records without destructive history rewrites. |

If later planning cannot map a `P3-SURF-004` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

Doctrine gaps discovered during implementation of any node under this plan must
be recorded as typed blocking artifacts, not prose notes, deferred comments, or
local resolutions. A doctrine gap record must identify the surface and node
where the gap was encountered, the specific doctrine that is insufficient or
absent, and the constitutional decision blocked by the gap. A doctrine gap
blocks the affected node and any downstream node whose constitutional validity
depends on the unresolved decision. This propagation applies forward from the
point of gap discovery; work completed before the gap was identified is not
retroactively invalidated unless it directly depended on the unresolved
decision. Continuation of any blocked node is not permitted until the doctrine
gap is formally resolved or the work is reclassified as doctrine-gap work. The
doctrine gap record is itself replay-visible and must be preserved in the
evidence namespace.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-004` becomes runnable only after `TSK-P3-WP-003` and
  `TSK-P3-WP-006` are complete; it does not unlock either predecessor.
- `TSK-P3-WP-004` may not redefine projection semantics from `TSK-P3-CAP-003`
  or authority semantics from `TSK-P3-CAP-006`; it must consume them as
  already-declared replay substrates.
- `TSK-P3-SUPPORT-MIG-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
  `P3-SURF-003`, `P3-SURF-004`, `P3-SURF-005`, and `P3-SURF-006`.
- No shared support node may be frozen unilaterally under this plan. Shared
  migration and backfill shape must be reconciled jointly with
  `TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, `TSK-P3-CAP-005`, and
  `TSK-P3-CAP-006`.
- `TSK-P3-SUPPORT-MIG-001` may not enter `CREATE-TASK` from this plan until
  `TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, `TSK-P3-CAP-005`, and
  `TSK-P3-CAP-006` are finalized as co-owning migration inputs.

## Wave 3 Obligations Bound To This Surface

The following Wave 3 obligations apply directly to `P3-SURF-004` planning:

- contradiction detection must remain limited to doctrine-declared classes and
  must not invent local contradiction categories;
- contradiction outcomes must preserve append-only findings, quarantine
  semantics, supersession discipline, and escalation when doctrine is
  insufficient;
- this surface must not collapse contradiction detection into failure
  composition or regulator workflow semantics;
- migration and backfill planning must preserve contradiction findings and
  replay-visible lineage across pre-/post-Phase-3 equality checks.
- all evaluation, traversal, record emission, and projection ordering within
  this surface must be deterministic with respect to persisted constitutional
  input state alone;
- all replay-visible ordering must derive from constitutionally declared
  canonical ordering inputs; undeclared ordering assumptions are prohibited and
  constitute doctrine gaps;
- canonical ordering definitions must include deterministic tie-break
  resolution rules for identical canonical ordering values; absence of a
  declared tie-break rule is itself a doctrine gap;
- implementations must not resolve ordering ties through insertion order, UUID
  comparison, database engine behavior, cache state, or any undeclared
  substrate;
- replay equality obligations for contradiction records are layered, not
  peer-level alternatives; task packs must declare the minimum required
  equality floor, any additional independently verified layers, and any layers
  explicitly not verified with justification.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-MIG-001`

The `P3-SURF-004` share of the migration node must define:

- replay-addressable contradiction-record migration and backfill expectations;
- preservation of append-only contradiction findings and quarantine/supersession
  lineage;
- pre-/post-Phase-3 fixture equality rules so contradiction cases derived from
  earlier lineage and authority substrates do not silently change meaning;
- additive reconciliation only, so Wave 3 migration planning cannot mutate the
  semantics of prior-wave lineage, authority, or projection artifacts.

Escalation findings that cross from `P3-SURF-004` into `P3-SURF-005` inputs
must remain read-only immutable-lineage references. `P3-SURF-005` may cite a
contradiction finding but must not mutate, re-classify, supersede, or absorb
contradiction ontology semantics. This prohibition applies to operational
derivation as well as direct reclassification: downstream failure logic may not
derive severity transformations, closure reinterpretation, or local escalation
classification from contradiction semantic content. The contradiction-to-failure
ontology transition rule and semantic authority assignment must be explicitly
declared in the Wave 3 `TSK-P3-SUPPORT-MIG-001` reconciliation before either
plan's task packs are generated.

`TSK-P3-CAP-004` and `TSK-P3-CAP-005` must be finalized jointly before either
Wave 3 `TSK-P3-SUPPORT-MIG-001` share enters `CREATE-TASK`. Neither plan's
migration slice may be frozen in isolation.

Escalations under this surface must be classified as terminal or transitional
per `docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md`:

| Escalation class | Nature | Mutability | Required closure |
|---|---|---|---|
| Doctrine-insufficiency | Transitional | `supersedable-projection` | Must close with doctrine-gap record |
| Authority-conflict | Terminal | `compensating-lineage` | Must produce replay-visible finding |
| Replay-ambiguity | Transitional | `supersedable-projection` | Must close or escalate further with explicit routing |
| Unresolved-contradiction | Terminal if undischarged | `immutable-lineage` after discharge | Must produce explicit closure record |

Escalations that cross doctrine boundaries must record an authority transfer:
the receiving doctrine or surface that holds final adjudication authority must
be declared as a replay-visible authority lineage entry. An escalation without
a declared final authority owner is constitutionally incomplete and must not be
treated as resolved. Task packs implementing authority transfer for escalation
records must cite a governing doctrine that declares the ownership exclusivity
model for that transfer, whether exclusive, shared, delegated, or advisory.
Implementation that silently assumes any ownership model without citation
constitutes a doctrine gap.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-004` | Contradiction detection, quarantine, supersession, and escalation mechanics | 3 | runtime/db surfaces declared later by task pack; contradiction docs; verifier references | Contradiction detection is deterministic, replay-aware, append-only, and limited to doctrine-declared classes and outcomes. Evidence must cover all three INV-304 contradiction classes: direct, temporal, and authority-scope. The specific error encoding is left to the task pack. | Deterministic verifier path is the expected target declared by INV-304 and must ultimately align with `scripts/db/verify_p3_contradiction_detection.sh` and declared Phase 3 evidence. This plan does not create that verifier. | Stop if the task invents new contradiction classes, resolves outside doctrine, deletes source records, or fails to cover all three INV-304 contradiction classes. |
| `TSK-P3-SUPPORT-MIG-001` (`P3-SURF-004` share) | Contradiction migration and backfill planning | 3 | migration/backfill docs and allowed planning surfaces only | Migration planning preserves replay-addressable contradiction findings and pre-/post-Phase-3 fixture equality expectations. | Later migration verification must prove contradiction-record preservation and replay-safe equality coverage. | Stop if planning expands into applied migration edits or destructive history rewrites. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-005` exists and Wave 3 shared-support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 3 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-004` is refined without inventing contradiction classes or local
  resolution doctrine;
- the `P3-SURF-004` slice of the shared migration node is explicit;
- append-only contradiction posture, quarantine/supersession discipline, and
  replay-safe backfill expectations are bound to the correct nodes;
- shared support ownership with prior-wave surfaces and `TSK-P3-CAP-005` is
  explicit;
- no atomic task pack files are created by this planning step.
