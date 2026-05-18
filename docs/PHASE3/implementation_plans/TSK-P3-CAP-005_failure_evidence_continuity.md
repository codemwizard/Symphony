# TSK-P3-CAP-005 Failure Composition And Evidence Continuity Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-005
Execution-Surface: P3-SURF-005
DAG-Nodes: TSK-P3-WP-005; TSK-P3-SUPPORT-MIG-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-003_wave3_contradiction_failure_composition.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md
  replay_owner: docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  verifier_owner: scripts/audit/verify_p3_failure_composition_engine.sh
  persistence_owner: future Phase 3 failure and continuity records
Replay-Criticality: replay-derived
State-Mutability: compensating-lineage
Ontology-Classification: compensating-reconstruction
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: MADD/MAIN authorization routes to Phase 8A; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-005` — the Failure Composition And Evidence Continuity Surface.

It refines the Wave 3 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-005`
- the `P3-SURF-005` share of `TSK-P3-SUPPORT-MIG-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-005` owns failure composition and internal cross-system evidence
continuity for Phase 3. The surface must establish:

- machine-readable, append-only failure categories and composition trees;
- replay-survivable provenance continuity across internal system boundaries;
- failure records that remain linked to source records, governing doctrines,
  and projection universes when applicable;
- migration and backfill planning that preserves failure evidence and
  contradiction/authority/projection ancestry without destructive rewrites.

For Phase 3 purposes, an internal system boundary is a boundary between
constitutional subsystems within the Phase 3 capability boundary. External
boundary definitions, including registry interfaces, MADD/MAIN orchestration,
and regulatory submission surfaces, are not in scope and must not be invented
locally.

Surface-level classification is intentionally coarse. Task packs must classify
each output artifact type separately and must not inherit the surface-level
classification as a uniform type for all outputs:

| Artifact type | Replay criticality | Mutability class |
|---|---|---|
| Failure tree node | `replay-derived` | `compensating-lineage` |
| Provenance continuity record | `replay-derived` | `immutable-lineage` |
| Compensating continuity append | `replay-derived` | `compensating-lineage` |
| Replay acceleration continuity cache | `operational-exhaust` | `derived-cache` |

This surface does **not** own:

- external MADD/MAIN integration;
- new failure categories outside the failure taxonomy;
- human-only explanation layers as authoritative failure records;
- regulator workflow execution;
- product authorization or future-phase external orchestration semantics;
- contradiction classification semantics;
- contradiction severity transformations derived from contradiction semantic
  content;
- contradiction-based propagation-priority, remediation-urgency, or
  compensating-order derivation.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-005` | `docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Failure composition must use only declared failure categories and must preserve internal provenance continuity across replay-visible boundaries. |
| `TSK-P3-SUPPORT-MIG-001` (`P3-SURF-005` share) | `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md` | Migration and backfill planning must preserve failure trees, compensating lineage, and replay-addressable continuity across earlier surfaces. |

If later planning cannot map a `P3-SURF-005` decision to this routing table, it
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

- `TSK-P3-WP-005` becomes runnable only after `TSK-P3-WP-004` is complete,
  even though it also depends on `TSK-P3-WP-003`.
- `TSK-P3-WP-005` requires `TSK-P3-WP-004` because failure composition must
  consume contradiction outputs as already-declared substrates, and requires
  `TSK-P3-WP-003` because failure records must preserve projection provenance
  lineage.
- `TSK-P3-WP-005` must consume contradiction outputs, projection provenance,
  and authority lineage as already-declared substrates; it may not redefine
  them locally.
- `TSK-P3-SUPPORT-MIG-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
  `P3-SURF-003`, `P3-SURF-004`, `P3-SURF-005`, and `P3-SURF-006`.
- No shared support node may be frozen unilaterally under this plan. Shared
  migration and backfill shape must be reconciled jointly with
  `TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, `TSK-P3-CAP-004`, and
  `TSK-P3-CAP-006`.

## Wave 3 Obligations Bound To This Surface

The following Wave 3 obligations apply directly to `P3-SURF-005` planning:

- failure composition must remain machine-readable, append-only, and rooted in
  doctrine-declared failure categories and severity classes;
- evidence continuity must remain internal and replay-survivable and must not
  drift into external MADD/MAIN integration scope;
- this surface must preserve sibling root failures and traversable failure
  trees rather than flattening them into opaque messages;
- migration and backfill planning must preserve compensating lineage and
  internal provenance continuity across pre-/post-Phase-3 equality checks.
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
- provenance continuity records must remain reconstructable from persisted
  constitutional artifacts without runtime-only state, in-memory trust anchors,
  ephemeral runtime context, transient orchestration identifiers, or live
  service references.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-MIG-001`

The `P3-SURF-005` share of the migration node must define:

- replay-addressable migration and backfill expectations for failure records
  and internal continuity records;
- preservation of append-only failure trees, compensating lineage, and
  provenance continuity across contradiction, authority, and projection inputs;
- pre-/post-Phase-3 fixture equality rules so failure and continuity cases do
  not silently change meaning as earlier surfaces evolve;
- additive reconciliation only, so Wave 3 migration planning cannot rewrite
  prior-wave lineage, authority, projection, or contradiction semantics.

Contradiction findings that cross from `P3-SURF-004` into `P3-SURF-005` inputs
must be consumed as read-only immutable-lineage references. `P3-SURF-005` may
record a failure that cites a contradiction finding but must not mutate,
re-classify, supersede, or absorb contradiction ontology semantics. This
prohibition applies to operational derivation as well as direct mutation:
failure composition must not derive severity, propagation priority, remediation
urgency, or compensating reconstruction ordering from contradiction semantic
content. Operational attributes of failure records must derive from the failure
taxonomy and governing doctrine, not from contradiction context.

Replay acceleration caches are non-authoritative, must be fully reconstructable
from persisted constitutional artifacts, and must not influence replay outputs.
Cache existence, eviction, or ordering is constitutionally invisible. Any
implementation where replay behavior depends on cache state is a determinism
violation and must be raised as a doctrine gap.

`TSK-P3-CAP-004` and `TSK-P3-CAP-005` must be finalized jointly before either
Wave 3 `TSK-P3-SUPPORT-MIG-001` share enters `CREATE-TASK`. Neither plan's
migration slice may be frozen in isolation.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-005` | Failure composition and cross-system evidence continuity | 3 | runtime/db/audit surfaces declared later by task pack; failure docs; verifier references | Failure composition is deterministic, append-only, machine-readable, and preserves internal cross-system provenance continuity without external integration drift. Provenance continuity across internal system boundaries must be independently verified with negative-test coverage aligned to INV-305. | Deterministic verifier paths are the expected targets declared by INV-305 and must ultimately align with `scripts/audit/verify_p3_failure_composition_engine.sh` and declared Phase 3 evidence. This plan does not create those verifiers. | Stop if the task invents new failure categories, flattens root failures, expands into external integration semantics, or fails to verify provenance continuity across internal system boundaries independently. |
| `TSK-P3-SUPPORT-MIG-001` (`P3-SURF-005` share) | Failure-record migration and backfill planning | 3 | migration/backfill docs and allowed planning surfaces only | Migration planning preserves replay-addressable failure trees, compensating lineage, and continuity records across fixture equality checks. | Later migration verification must prove failure-record preservation and replay-safe equality coverage. | Stop if planning expands into applied migration edits or destructive continuity rewrites. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-004` exists and Wave 3 shared-support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 3 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-005` is refined without inventing failure categories or external
  integration semantics;
- the `P3-SURF-005` slice of the shared migration node is explicit;
- machine-readable failure composition, append-only compensating lineage, and
  replay-safe continuity expectations are bound to the correct nodes;
- shared support ownership with prior-wave surfaces and `TSK-P3-CAP-004` is
  explicit;
- no atomic task pack files are created by this planning step.
