Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-PLAN-002
Plan-Type: broad-wave-implementation-plan
Wave-ID: WAVE-2
Wave-Title: Projection And Authority Enforcement
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false

---

## Purpose

This document is the second broad Phase 3 wave implementation plan. It does not
create atomic task packs. It defines the next consecutive dependency-safe
execution batch to be refined through surface-specific implementation plans
after the Wave 1 lineage foundations are complete.

The governing construction rule comes from
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`:

- waves are consecutive slices of the canonical linear task sequence;
- waves do not reorder tasks;
- when multiple tasks are runnable, the canonically lowest task ID wins;
- only after the serial order is derived may a wave boundary be named.

This plan therefore converts the current Phase 3 task universe into the next
projection-and-authority planning batch without inventing new phase scope.

## Wave Membership

Wave 2 is the first post-Wave-1 projection and authority batch and consists of
the following Phase 3 nodes:

| Node | Surface | Purpose |
|---|---|---|
| TSK-P3-WP-003 | P3-SURF-003 | Projection universes and recursive legitimacy evaluation. |
| TSK-P3-WP-006 | P3-SURF-006 | Authority scope and delegation enforcement. |
| TSK-P3-SUPPORT-FIXTURE-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-006 | Canonical valid and invalid lineage, authority, and legitimacy fixtures. |
| TSK-P3-SUPPORT-VERSION-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003 | Schema, projection, proof, policy format compatibility, and replay hash regression planning. |

## Canonical Serial Sequence

Using the current Phase 3 DAG and excluding all `complete` nodes, the next
canonical Wave 2 sequence is:

1. `TSK-P3-WP-003`
2. `TSK-P3-SUPPORT-VERSION-001`
3. `TSK-P3-WP-006`
4. `TSK-P3-SUPPORT-FIXTURE-001`

### Derivation Notes

- Wave 2 assumes the Wave 1 task packs are completed before execution begins;
  this plan only defines the next planning batch.
- After Wave 1 completion, `TSK-P3-WP-003` and `TSK-P3-WP-006` are both
  runnable from the DAG.
- The tie is resolved by canonical task ID ordering, so `TSK-P3-WP-003`
  precedes `TSK-P3-WP-006`.
- After `TSK-P3-WP-003`, both `TSK-P3-WP-006` and
  `TSK-P3-SUPPORT-VERSION-001` are runnable.
- The tie is again resolved by canonical task ID ordering, so
  `TSK-P3-SUPPORT-VERSION-001` precedes `TSK-P3-WP-006`.
- `TSK-P3-SUPPORT-FIXTURE-001` remains gated by both `TSK-P3-WP-003` and
  `TSK-P3-WP-006` and closes the second wave.

This is a serial planning sequence. It does not authorize parallel execution.

## Surface-Plan Extraction Order

Wave 2 implementation-plan extraction must follow the surfaces introduced by
the serial sequence:

1. `TSK-P3-CAP-003` for `P3-SURF-003`
2. `TSK-P3-CAP-006` for `P3-SURF-006`

The Wave 2 support nodes are not separate execution surfaces. They inherit from
their owning runtime surfaces and must be scoped inside those surface plans
rather than inventing new CAP records.

`TSK-P3-SUPPORT-VERSION-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
and `P3-SURF-003`. `TSK-P3-CAP-003` must therefore reconcile projection
compatibility and replay-hash regression planning with the already-created
Wave 1 surface plans `TSK-P3-CAP-001` and `TSK-P3-CAP-002` before finalization.

`TSK-P3-SUPPORT-FIXTURE-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
`P3-SURF-003`, and `P3-SURF-006`. `TSK-P3-CAP-003` and `TSK-P3-CAP-006` must
therefore jointly reconcile canonical valid and invalid fixtures with
`TSK-P3-CAP-001` and `TSK-P3-CAP-002` rather than freezing fixture semantics
locally.

## Wave 2 Planning Obligations

The next planning layer created from this wave must preserve these approved
Phase 3 obligations:

- `TSK-P3-WP-003` must remain projection-only legitimacy work and must not
  absorb contradiction, quarantine, regulator, or settlement semantics.
- `TSK-P3-WP-006` must remain authority-scope and delegation work and must not
  absorb regulator partition, product authorization, or sovereignty runtime
  semantics.
- `TSK-P3-SUPPORT-FIXTURE-001` must define canonical valid and invalid lineage,
  authority, and legitimacy fixtures that exist for verifier closure and
  negative-test value only.
- `TSK-P3-SUPPORT-VERSION-001` must carry schema, projection, proof, and policy
  format compatibility together with replay hash regression planning and must
  not expand into speculative product versioning.
- Wave 2 planning must preserve separation between projection semantics and
  authority enforcement semantics so that `TSK-P3-WP-003` and `TSK-P3-WP-006`
  remain independent constitutional surfaces.

## Wave 2 Obligation-To-Node Routing

The following obligations are required at the broad-wave planning layer and are
already routed to existing master-plan nodes. No new Wave 2 node is required.

| Obligation | Routed Master-Plan Nodes | Planning Meaning |
|---|---|---|
| Projection-only legitimacy obligations | `TSK-P3-WP-003`, `TSK-P3-SUPPORT-VERSION-001` | Projection planning must remain replay-derived and must not become source-truth mutation or contradiction classification work. |
| Authority-scope and delegation obligations | `TSK-P3-WP-006`, `TSK-P3-SUPPORT-FIXTURE-001` | Authority planning must enforce delegation boundaries without importing regulator partition or product-auth semantics. |
| Replay hash regression and format continuity | `TSK-P3-SUPPORT-VERSION-001`, `TSK-P3-WP-003` | Versioning and projection planning must preserve replay continuity across schemas, proofs, policy formats, and derived legitimacy projections. |
| Canonical valid/invalid fixture closure | `TSK-P3-SUPPORT-FIXTURE-001`, `TSK-P3-WP-003`, `TSK-P3-WP-006` | Fixtures must exist to support deterministic positive and negative tests for legitimacy projection and authority delegation behavior. |
| Cross-wave shared support reconciliation | `TSK-P3-SUPPORT-FIXTURE-001`, `TSK-P3-SUPPORT-VERSION-001`, `TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, `TSK-P3-CAP-006` | Shared support artifacts must be reconciled across prior and current owning surfaces before any Wave 2 surface plan is treated as finalized. |

This routing means the master implementation plan does not need new Wave 2
nodes for these concerns. The concerns are binding scope obligations on the
existing Wave 2 nodes listed above.

## Governing Doctrine Traceability Matrix

Wave 2 downstream planning must use this doctrine routing table.

| Node | Primary Governing Doctrine | Why It Governs |
|---|---|---|
| `TSK-P3-WP-003` | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | Owns replay-derived projection universes and recursive legitimacy evaluation. |
| `TSK-P3-WP-006` | `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md` | Owns authority scope enforcement and delegation boundary semantics. |
| `TSK-P3-SUPPORT-FIXTURE-001` | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Fixtures must preserve canonical lineage relationships while closing verifier-positive and verifier-negative coverage for projection and authority surfaces. |
| `TSK-P3-SUPPORT-VERSION-001` | `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Versioning must preserve replay continuity, historical reconstruction, admissible proof exchange, and replay hash regression planning. |

If a downstream surface-specific plan cannot map a Wave 2 decision to this
matrix, it must record a doctrine gap or escalation rather than substitute a
local interpretation.

## Non-Goals

This plan does not:

- create `tasks/<TASK_ID>/meta.yml`;
- create task `PLAN.md` or `EXEC_LOG.md`;
- create verifier scripts, migrations, approvals, or evidence;
- authorize implementation before `TSK-P3-CAP-003` and `TSK-P3-CAP-006` exist;
- introduce new Wave 2 nodes beyond the current master-plan routing above;
- reorder Wave 2 by staffing preference, subsystem preference, or support-node
  similarity.

## Ready State

This wave plan is complete when:

- the Wave 2 node set matches the current master plan;
- the serial order is derivable from the current DAG without contradiction;
- the extraction order for `TSK-P3-CAP-003` and `TSK-P3-CAP-006` is explicit;
- support nodes are bound to their owning surfaces rather than treated as free
  standing scope.
