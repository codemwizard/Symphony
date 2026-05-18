# TSK-P3-CAP-001 Typed Dependency Graph Lineage Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-001
Execution-Surface: P3-SURF-001
DAG-Nodes: TSK-P3-WP-001; TSK-P3-SUPPORT-CONTRACT-001; TSK-P3-SUPPORT-DB-001; TSK-P3-SUPPORT-SEC-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-001_wave1_lineage_foundations.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/CONSTITUTIONAL_GRAPH.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/CONSTITUTIONAL_GRAPH.md
  replay_owner: docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  verifier_owner: scripts/db/verify_p3_typed_dependency_graph.sh
  persistence_owner: future Phase 3 dependency graph storage
Replay-Criticality: replay-authoritative
State-Mutability: immutable-lineage
Ontology-Classification: lineage-truth
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: methodology dependency semantics route to Phase 5; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-001` — the Typed Dependency Graph Lineage Surface.

It refines the Wave 1 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-001`
- the `P3-SURF-001` share of `TSK-P3-SUPPORT-CONTRACT-001`
- the `P3-SURF-001` share of `TSK-P3-SUPPORT-DB-001`
- the `P3-SURF-001` share of `TSK-P3-SUPPORT-SEC-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-001` owns typed dependency lineage truth for Phase 3. The surface must
establish:

- machine-traversable typed upstream dependency declarations;
- immutable lineage truth for dependency edges;
- deterministic replay of dependency lineage;
- provenance-safe dependency serialization compatible with later replay and
  verifier use;
- persistence and access-control planning that preserves dependency truth
  without inventing policy or legitimacy semantics.

This surface does **not** own:

- policy meaning or sovereign authority meaning;
- recursive legitimacy evaluation;
- contradiction semantics;
- failure taxonomies;
- external replay package productization;
- methodology execution semantics.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-001` | `docs/constitutional/CONSTITUTIONAL_GRAPH.md` | Typed dependency lineage must be derived from graph doctrine only. |
| `TSK-P3-SUPPORT-CONTRACT-001` (`P3-SURF-001` share) | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Dependency lineage serialization must preserve graph truth and replay-safe proof exchange. |
| `TSK-P3-SUPPORT-DB-001` (`P3-SURF-001` share) | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md` | Persistence must preserve immutable dependency lineage and replay-authoritative reconstruction. |
| `TSK-P3-SUPPORT-SEC-001` (`P3-SURF-001` share) | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Access control must preserve lineage truth and future verifier independence without conferring constitutional meaning. |

If later planning cannot map a `P3-SURF-001` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

`depends_on` and `blocked_by` are separate fields.

- `depends_on` defines structural DAG order.
- `blocked_by` defines live impediments.
- `blocked_by` must not duplicate normal predecessors already listed in
  `depends_on`.

For this surface:

- `TSK-P3-WP-001` is the root Wave 1 runtime node and is the first eligible
  Phase 3 implementation surface after the completed activation sequence.
- `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, and
  `TSK-P3-SUPPORT-SEC-001` are shared support nodes across `P3-SURF-001` and
  `P3-SURF-002`.
- No shared support node may be frozen unilaterally under this plan. Shared
  support shape must be reconciled jointly with `TSK-P3-CAP-002`.

## Wave 1 Obligations Bound To This Surface

The following Wave 1 obligations apply directly to `P3-SURF-001` planning:

- dependency schemas must reserve immutable provenance identifiers needed later
  for cross-system evidence continuity under `INV-305`;
- dependency serialization and proof contracts must preserve admissible replay
  compatibility with the Phase 2 proof substrate;
- dependency-lineage contracts and security planning must not collapse runtime
  truth with verifier-authored proof expectations;
- support planning must not absorb methodology semantics or future-phase
  runtime behavior.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-CONTRACT-001`

The `P3-SURF-001` share of the contract node must define:

- deterministic dependency-edge serialization;
- replay-stable dependency proof structures;
- immutable provenance identifiers and exchange-safe field shape needed by
  later evidence-continuity work;
- offline replay package schema inputs required for dependency lineage proof;
- Phase 2 replay compatibility expectations for dependency-lineage artifacts.

This node is jointly reconciled with `TSK-P3-CAP-002` before finalization.

### `TSK-P3-SUPPORT-DB-001`

The `P3-SURF-001` share of the persistence node must define:

- storage shape for immutable dependency lineage;
- canonical dependency edge typing and traversal support requirements;
- replay-authoritative persistence requirements;
- non-destructive compatibility posture for the existing admissible proof
  substrate.

### `TSK-P3-SUPPORT-SEC-001`

The `P3-SURF-001` share of the security node must define:

- write-path separation for dependency lineage truth;
- read-path constraints for replay and verifier use;
- no verifier-authority collapse with runtime lineage writers;
- no broad product-auth or future-phase security expansion.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-001` | Typed dependency graph lineage and traversal substrate | 3 | runtime/db surfaces declared later by task pack; lineage docs; verifier references | Dependency edges are typed, machine-traversable, and scoped to immutable lineage truth without importing policy or legitimacy semantics. | Deterministic verifier path must ultimately align with `scripts/db/verify_p3_typed_dependency_graph.sh` and declared Phase 3 evidence. | Stop if the task invents policy meaning, mutates historical lineage truth, or absorbs methodology semantics. |
| `TSK-P3-SUPPORT-CONTRACT-001` (`P3-SURF-001` slice) | Dependency-lineage proof and replay package contracts | 3 | deterministic interface definitions, lineage contract docs, shared contract references | Dependency lineage serialization is deterministic, replay-safe, Phase 2 compatible, and jointly reconciled with `P3-SURF-002`. | Shared contract verification must prove deterministic shape and replay-safe compatibility once the downstream task pack exists. | Stop if this slice is finalized unilaterally or if it collapses runtime and verifier trust boundaries. |
| `TSK-P3-SUPPORT-DB-001` (`P3-SURF-001` slice) | Dependency-lineage persistence planning | 3 | persistence model docs and allowed planning surfaces only | Persistence planning preserves immutable dependency lineage and replay-authoritative reconstruction expectations. | Later task-pack verifier must prove persistence shape matches lineage-truth and replay requirements. | Stop if the task performs unapproved runtime migration work or introduces mutable historical truth. |
| `TSK-P3-SUPPORT-SEC-001` (`P3-SURF-001` slice) | Dependency-lineage access-control planning | 3 | access model docs and security planning surfaces only | Access model preserves lineage write authority, verifier-read separation, and no product-auth expansion. | Later security verification must prove separation rules without inventing constitutional authority. | Stop if the task broadens privilege model into product auth or shared runtime/verifier authority. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-002` exists and shared support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 1 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-001` is refined without inventing non-lineage semantics;
- the `P3-SURF-001` slices of the shared support nodes are explicit;
- replay compatibility, provenance reservation, and runtime/verifier separation
  obligations are bound to the correct nodes;
- shared support ownership with `TSK-P3-CAP-002` is explicit;
- no atomic task pack files are created by this planning step.
