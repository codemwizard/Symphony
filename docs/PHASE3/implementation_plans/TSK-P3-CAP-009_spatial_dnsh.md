# TSK-P3-CAP-009 Spatial Constraint And DNSH Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-009
Execution-Surface: P3-SURF-009
DAG-Nodes: TSK-P3-WP-009; TSK-P3-SUPPORT-OBS-001; TSK-P3-SUPPORT-PERF-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md
  replay_owner: docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  verifier_owner: scripts/db/verify_p3_spatial_legality_dnsh_gates.sh
  persistence_owner: future Phase 3 spatial finding records
Replay-Criticality: replay-derived
State-Mutability: supersedable-projection
Ontology-Classification: admissibility-projection
Determinism-Classification: bounded-nondeterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: external registry double-counting integrations route to Phase 8B; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-009` — the Spatial Constraint And DNSH Surface.

It refines the Wave 4 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-009`
- the `P3-SURF-009` share of `TSK-P3-SUPPORT-OBS-001`
- the `P3-SURF-009` share of `TSK-P3-SUPPORT-PERF-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-009` owns spatial legality and DNSH admissibility gates for Phase 3.
The surface must establish:

- authoritative replay-derived spatial and DNSH findings against declared
  policy and authority lineage;
- supersedable admissibility projections that remain reconstructable from
  persisted constitutional artifacts;
- bounded-nondeterministic spatial evaluation over declared externalized
  datasets and policy inputs;
- internal observability and deterministic performance-bound planning for
  spatial legality outcomes without changing replay truth.

This surface does **not** own:

- statutory environmental legal opinions;
- universal DNSH meaning outside declared doctrine;
- cross-registry legal completeness claims;
- product geospatial workflow behavior;
- regulator submission workflow or settlement semantics;
- external registry integrations that route to Phase 8B.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-009` | `docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md` | Spatial and DNSH gating must remain authoritative, evidence-backed, and grounded in canonical policy/authority lineage. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-009` share) | `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Observability must remain machine-readable internal constitutional traceability for spatial admissibility findings only. |
| `TSK-P3-SUPPORT-PERF-001` (`P3-SURF-009` share) | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`; `docs/constitutional/CONSTITUTIONAL_GRAPH.md` | Performance planning must remain deterministic-bound planning for spatial evaluation scale, not infrastructure tuning or optimization that changes replay truth. |

If later planning cannot map a `P3-SURF-009` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

Spatial and DNSH doctrine gaps affecting admissibility semantics must block
task generation and implementation until constitutional interpretation is
supplied. The `Doctrine-Gap-Outcome: IMPLEMENT` header remains repo-standard
metadata and does not authorize local implementation across unresolved
admissibility doctrine gaps.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-009` becomes runnable only after `TSK-P3-WP-002` and
  `TSK-P3-WP-005` are complete; it does not unlock its predecessors.
- `TSK-P3-WP-009` must consume canonical policy/authority lineage and failure
  continuity outputs as already-declared replay substrates; it may not invent
  detached spatial admissibility semantics.
- `TSK-P3-SUPPORT-OBS-001` is shared across `P3-SURF-003`, `P3-SURF-004`,
  `P3-SURF-005`, `P3-SURF-007`, and `P3-SURF-009`.
- `TSK-P3-SUPPORT-PERF-001` is shared across `P3-SURF-001`, `P3-SURF-003`, and
  `P3-SURF-009`.
- No shared support node may be frozen unilaterally under this plan. Shared
  observability shape must be reconciled jointly with `TSK-P3-CAP-003`,
  `TSK-P3-CAP-004`, `TSK-P3-CAP-005`, and `TSK-P3-CAP-007`. Shared performance
  shape must be reconciled jointly with `TSK-P3-CAP-001` and `TSK-P3-CAP-003`.

## Wave 4 Obligations Bound To This Surface

The following Wave 4 obligations apply directly to `P3-SURF-009` planning:

- spatial and DNSH gating must remain authoritative and evidence-backed without
  expanding into broad geospatial product semantics;
- bounded nondeterminism must be explicit: task packs must declare the
  admissible nondeterministic input set, the replay-stable comparison method,
  and the proof limitations of that comparison;
- all external datasets contributing to bounded-nondeterministic evaluation
  must be version-identified and replay-addressable;
- no ordering, cache, or dataset-staleness assumption may be implicit;
- observability must remain internal and machine-readable only;
- performance planning must remain deterministic scale-bound planning only.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-OBS-001`

The `P3-SURF-009` share of the observability node must define:

- replay-safe visibility of spatial and DNSH gate findings;
- machine-readable positive and negative spatial admissibility traces;
- additive reconciliation only, so Wave 4 observability cannot silently
  redefine earlier projection, contradiction, failure, or regulator meanings.

### `TSK-P3-SUPPORT-PERF-001`

The `P3-SURF-009` share of the performance node must define:

- deterministic scale-bound expectations for spatial evaluation, traversal, and
  projection cost;
- bounded-nondeterministic proof obligations that do not alter replay truth;
- version-identified and replay-addressable dataset dependencies for every
  bounded-nondeterministic spatial input;
- additive reconciliation only, so performance planning cannot weaken replay
  guarantees or mutate admissibility outcomes.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-009` | Spatial legality and DNSH gates | 3 | runtime/db/migration/security/performance/versioning surfaces declared later by task pack; spatial docs; verifier references | Spatial legality and DNSH gating is authoritative, replay-derived, and bounded-nondeterministic only within declared inputs, version-identified replay-addressable datasets, and replay-stable comparison rules. | Deterministic verifier path must ultimately align with `scripts/db/verify_p3_spatial_legality_dnsh_gates.sh` and declared Phase 3 evidence. | Stop if the task invents universal DNSH meaning, expands into external registry integration, leaves nondeterministic inputs/comparison rules undeclared, or proceeds across unresolved admissibility doctrine gaps. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-009` slice) | Spatial admissibility observability | 3 | observability docs, verifier fixtures, shared support references | Observability is machine-readable, replay-safe, and limited to internal constitutional visibility of spatial admissibility outcomes. | Later observability verification must prove internal traceability without UI or dashboard drift. | Stop if observability expands into user-facing explanation or external disclosure semantics. |
| `TSK-P3-SUPPORT-PERF-001` (`P3-SURF-009` slice) | Spatial performance and scale-bound planning | 3 | performance docs, traversal/fixture references, shared support references | Performance planning declares deterministic scale bounds and bounded-nondeterministic inputs without altering replay-visible admissibility outcomes. | Later performance verification must prove scale-bound coverage without infrastructure-tuning drift. | Stop if planning expands into infrastructure optimization, deployment tuning, or replay-truth mutation. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-007` exists and Wave 4 observability reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- verifier, bounded-nondeterminism, and version-addressable dataset
  expectations are declared;
- the task pack cites this plan, the Wave 4 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-009` is refined without expanding into external registry or broad
  geospatial product semantics;
- the `P3-SURF-009` slices of the shared observability and performance nodes
  are explicit;
- authoritative spatial gating, bounded nondeterminism, and replay-safe support
  obligations are bound to the correct nodes;
- shared support ownership with `TSK-P3-CAP-001`, `TSK-P3-CAP-003`,
  `TSK-P3-CAP-004`, `TSK-P3-CAP-005`, and `TSK-P3-CAP-007` is explicit;
- no atomic task pack files are created by this planning step.
