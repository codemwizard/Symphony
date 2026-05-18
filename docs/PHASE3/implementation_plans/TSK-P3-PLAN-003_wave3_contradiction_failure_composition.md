Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-PLAN-003
Plan-Type: broad-wave-implementation-plan
Wave-ID: WAVE-3
Wave-Title: Contradiction And Failure Composition
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false

---

## Purpose

This document is the third broad Phase 3 wave implementation plan. It does not
create atomic task packs. It defines the next consecutive dependency-safe
execution batch to be refined through surface-specific implementation plans
after the Wave 2 projection and authority batch is complete.

The governing construction rule comes from
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`:

- waves are consecutive slices of the canonical linear task sequence;
- waves do not reorder tasks;
- when multiple tasks are runnable, the canonically lowest task ID wins;
- only after the serial order is derived may a wave boundary be named.

This plan therefore converts the current Phase 3 task universe into the next
contradiction-and-failure planning batch without inventing new phase scope.

## Wave Membership

Wave 3 is the contradiction and failure-composition batch and consists of the
following Phase 3 nodes:

| Node | Surface | Purpose |
|---|---|---|
| TSK-P3-WP-004 | P3-SURF-004 | Contradiction detection, quarantine, supersession, and escalation mechanics. |
| TSK-P3-WP-005 | P3-SURF-005 | Failure composition and cross-system evidence continuity. |
| TSK-P3-SUPPORT-MIG-001 | P3-SURF-001, P3-SURF-002, P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-006 | Migration and backfill planning for replay-addressable lineage, findings, and pre-/post-Phase-3 fixture equality preservation. |

## Canonical Serial Sequence

Using the current Phase 3 DAG and excluding all `complete` nodes, the next
canonical Wave 3 sequence is:

1. `TSK-P3-WP-004`
2. `TSK-P3-WP-005`
3. `TSK-P3-SUPPORT-MIG-001`

### Derivation Notes

- Wave 3 assumes the Wave 2 task packs are completed before execution begins;
  this plan only defines the next planning batch.
- `TSK-P3-WP-004` becomes runnable after `TSK-P3-WP-003` and `TSK-P3-WP-006`
  are complete.
- `TSK-P3-WP-005` remains gated by `TSK-P3-WP-004` even though it also depends
  on `TSK-P3-WP-003`.
- `TSK-P3-SUPPORT-MIG-001` remains gated by `TSK-P3-WP-005` and the already
  created `TSK-P3-SUPPORT-DB-001`, so it closes the third wave.

This is a serial planning sequence. It does not authorize parallel execution.

## Surface-Plan Extraction Order

Wave 3 implementation-plan extraction must follow the surfaces introduced by
the serial sequence:

1. `TSK-P3-CAP-004` for `P3-SURF-004`
2. `TSK-P3-CAP-005` for `P3-SURF-005`

The Wave 3 support node is not a separate execution surface. It inherits from
the already-created lineage, projection, authority, contradiction, and failure
surfaces and must be scoped inside the owning surface plans rather than
inventing a new CAP record.

`TSK-P3-SUPPORT-MIG-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
`P3-SURF-003`, `P3-SURF-004`, `P3-SURF-005`, and `P3-SURF-006`. `TSK-P3-CAP-004`
and `TSK-P3-CAP-005` must therefore reconcile replay-addressable migration and
backfill planning with the already-created Wave 1 and Wave 2 surface plans
`TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, and `TSK-P3-CAP-006`
before either Wave 3 surface plan is treated as finalized.

## Wave 3 Planning Obligations

The next planning layer created from this wave must preserve these approved
Phase 3 obligations:

- `TSK-P3-WP-004` must remain contradiction-only work and must not invent new
  contradiction classes, source-record deletion semantics, or contradiction
  resolution rules outside the contradiction doctrine.
- `TSK-P3-WP-005` must remain failure-composition and internal cross-system
  evidence continuity work and must not expand into external MADD/MAIN
  integration, regulator workflow semantics, or opaque-only failure recording.
- `TSK-P3-SUPPORT-MIG-001` must remain replay-addressable migration and backfill
  planning and must not expand into applied migration edits, unapproved runtime
  migration work, or destructive historical-truth rewrites.
- Wave 3 planning must preserve append-only contradiction and failure evidence
  posture and must not collapse quarantine, supersession, and compensating
  lineage into one undifferentiated state model.
- Wave 3 planning must preserve pre-/post-Phase-3 fixture equality
  expectations so later migration/backfill work cannot silently alter the
  meaning of already-defined lineage, authority, or projection fixtures.

## Wave 3 Obligation-To-Node Routing

The following obligations are required at the broad-wave planning layer and are
already routed to existing master-plan nodes. No new Wave 3 node is required.

| Obligation | Routed Master-Plan Nodes | Planning Meaning |
|---|---|---|
| Contradiction-class and quarantine discipline | `TSK-P3-WP-004` | Contradiction planning must use declared contradiction classes and quarantine/supersession mechanics rather than inventing resolution logic locally. |
| Cross-system evidence continuity and machine-readable failure composition | `TSK-P3-WP-005` | Failure planning must preserve internal provenance continuity and append-only machine-readable failure records without drifting into external integration or human-only explanation layers. |
| Replay-addressable migration and backfill planning | `TSK-P3-SUPPORT-MIG-001`, `TSK-P3-WP-004`, `TSK-P3-WP-005` | Migration planning must preserve replay reconstruction for contradiction and failure records and must carry forward fixture equality expectations across the earlier surfaces. |
| Cross-wave shared support reconciliation | `TSK-P3-SUPPORT-MIG-001`, `TSK-P3-CAP-001`, `TSK-P3-CAP-002`, `TSK-P3-CAP-003`, `TSK-P3-CAP-004`, `TSK-P3-CAP-005`, `TSK-P3-CAP-006` | Shared migration and backfill planning must be reconciled across prior and current owning surfaces before any Wave 3 surface plan is treated as finalized. |

This routing means the master implementation plan does not need new Wave 3
nodes for these concerns. The concerns are binding scope obligations on the
existing Wave 3 nodes listed above.

## Governing Doctrine Traceability Matrix

Wave 3 downstream planning must use this doctrine routing table.

| Node | Primary Governing Doctrine | Why It Governs |
|---|---|---|
| `TSK-P3-WP-004` | `docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md`; `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | Owns contradiction classes, quarantine posture, and replay-aware contradiction evaluation over projected constitutional state. |
| `TSK-P3-WP-005` | `docs/constitutional/FAILURE_COMPOSITION_TAXONOMY.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Owns machine-readable failure composition and internal cross-system evidence continuity. |
| `TSK-P3-SUPPORT-MIG-001` | `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md`; `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Migration and backfill planning must preserve replay-addressable historical truth, temporal reconstruction obligations, and deterministic fixture preservation. |

If a downstream surface-specific plan cannot map a Wave 3 decision to this
matrix, it must record a doctrine gap or escalation rather than substitute a
local interpretation.

## Non-Goals

This plan does not:

- create `tasks/<TASK_ID>/meta.yml`;
- create task `PLAN.md` or `EXEC_LOG.md`;
- create verifier scripts, migrations, approvals, or evidence;
- authorize implementation before `TSK-P3-CAP-004` and `TSK-P3-CAP-005` exist;
- introduce new Wave 3 nodes beyond the current master-plan routing above;
- reorder Wave 3 by subsystem preference, staffing preference, or support-node
  affinity.

## Ready State

This wave plan is complete when:

- the Wave 3 node set matches the current master plan;
- the serial order is derivable from the current DAG without contradiction;
- the extraction order for `TSK-P3-CAP-004` and `TSK-P3-CAP-005` is explicit;
- the shared migration/backfill node is bound to its owning surfaces rather
  than treated as free-standing scope.
