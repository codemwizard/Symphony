Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-PLAN-004
Plan-Type: broad-wave-implementation-plan
Wave-ID: WAVE-4
Wave-Title: Regulator, COI, Spatial, And Temporal Gates
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false

---

## Purpose

This document is the fourth broad Phase 3 wave implementation plan. It does not
create atomic task packs. It defines the next consecutive dependency-safe
execution batch after the completed Wave 3 contradiction/failure planning set.

The governing construction rule comes from
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`:

- waves are consecutive slices of the canonical linear task sequence;
- waves do not reorder tasks;
- when multiple tasks are runnable, the canonically lowest task ID wins;
- only after the serial order is derived may a wave boundary be named.

This plan therefore converts the current Phase 3 task universe into the next
regulator/COI/spatial/temporal planning batch without inventing new phase
scope.

## Wave Membership

Wave 4 is the regulator/COI/spatial/temporal enforcement batch and consists of
the following Phase 3 nodes:

| Node | Surface | Purpose |
|---|---|---|
| TSK-P3-WP-007 | P3-SURF-007 | Regulator-aware partitioning, precedence application, and non-collapse mechanics. |
| TSK-P3-WP-008 | P3-SURF-008 | Conflict-of-interest and verifier independence enforcement. |
| TSK-P3-WP-009 | P3-SURF-009 | Spatial constraint and DNSH gates. |
| TSK-P3-WP-010 | P3-SURF-010 | Dwell-time forensic findings under temporal replay doctrine. |
| TSK-P3-SUPPORT-OBS-001 | P3-SURF-003, P3-SURF-004, P3-SURF-005, P3-SURF-007, P3-SURF-009 | Internal constitutional observability without UI or dashboard semantics. |
| TSK-P3-SUPPORT-PERF-001 | P3-SURF-001, P3-SURF-003, P3-SURF-009 | Deterministic traversal, spatial, and projection scale bounds. |

## Canonical Serial Sequence

Using the current Phase 3 DAG and excluding all `complete` and `tasks-created`
nodes, the next canonical Wave 4 sequence is:

1. `TSK-P3-WP-007`
2. `TSK-P3-WP-008`
3. `TSK-P3-WP-009`
4. `TSK-P3-WP-010`
5. `TSK-P3-SUPPORT-OBS-001`
6. `TSK-P3-SUPPORT-PERF-001`

### Derivation Notes

- Wave 4 assumes the Wave 3 task packs are created and later completed before
  execution begins; this plan only defines the next planning batch.
- `TSK-P3-WP-007`, `TSK-P3-WP-008`, `TSK-P3-WP-009`, and `TSK-P3-WP-010` all
  become runnable after their already-declared predecessors are complete.
- Their relative order is therefore determined by canonical task-ID ordering,
  not by new unlock relationships between the Wave 4 nodes themselves.
- `TSK-P3-SUPPORT-OBS-001` and `TSK-P3-SUPPORT-PERF-001` remain gated by the
  completion of their owning Wave 4 runtime nodes and therefore close the wave.
- The support-node order is likewise canonical task-ID ordering once both are
  runnable.

This is a serial planning sequence. It does not authorize parallel execution.

## Surface-Plan Extraction Order

Wave 4 implementation-plan extraction must follow the runtime surfaces
introduced by the serial sequence:

1. `TSK-P3-CAP-007` for `P3-SURF-007`
2. `TSK-P3-CAP-008` for `P3-SURF-008`
3. `TSK-P3-CAP-009` for `P3-SURF-009`
4. `TSK-P3-CAP-010` for `P3-SURF-010`

The Wave 4 support nodes are not separate execution surfaces. They inherit from
the already-created lineage, projection, contradiction, failure, regulator,
and spatial/temporal surfaces and must be scoped inside the owning surface
plans rather than inventing new CAP records.

`TSK-P3-SUPPORT-OBS-001` is shared across `P3-SURF-003`, `P3-SURF-004`,
`P3-SURF-005`, `P3-SURF-007`, and `P3-SURF-009`.

`TSK-P3-SUPPORT-PERF-001` is shared across `P3-SURF-001`, `P3-SURF-003`, and
`P3-SURF-009`.

The Wave 4 CAP plans must therefore reconcile observability and performance
support obligations with the already-created Wave 1 through Wave 3 surface
plans before any Wave 4 surface plan is treated as finalized.

## Wave 4 Planning Obligations

The next planning layer created from this wave must preserve these approved
Phase 3 obligations:

- `TSK-P3-WP-007` must remain regulator-aware partitioning, precedence, and
  non-collapse work and must not invent sovereign mandate meaning, merge
  regulator domains, or externalize regulator workflow runtime.
- `TSK-P3-WP-008` must remain conflict-of-interest and verifier-independence
  work and must not absorb product authorization, generalized application
  access control, or runtime/verifier trust-boundary implementation that
  belongs to `P3-SURF-012`.
- `TSK-P3-WP-009` must remain spatial constraint and DNSH gate work and must
  not absorb settlement semantics, regulator submission workflow, or unrelated
  geospatial product behavior.
- `TSK-P3-WP-010` must remain temporal replay and dwell-time forensic work and
  must not absorb contradiction ownership, failure taxonomy ownership, or
  external forensic workflow orchestration.
- `TSK-P3-SUPPORT-OBS-001` must remain internal constitutional observability
  work and must not drift into UI, dashboard, operator console, or human-only
  explanation surfaces.
- `TSK-P3-SUPPORT-PERF-001` must remain deterministic traversal/spatial/projection
  scale-bound planning and must not drift into infrastructure tuning, deployment
  optimization, or runtime product performance work.

## Wave 4 Obligation-To-Node Routing

The following obligations are required at the broad-wave planning layer and are
already routed to existing master-plan nodes. No new Wave 4 node is required.

| Obligation | Routed Master-Plan Nodes | Planning Meaning |
|---|---|---|
| Regulator partitioning and sovereignty non-collapse | `TSK-P3-WP-007` | Partitioning and precedence planning must preserve regulator-domain separation and may not collapse orthogonal sovereignty domains. |
| COI and verifier-independence enforcement | `TSK-P3-WP-008` | COI planning must remain mechanical and verifier-safe without absorbing later runtime/verifier segregation implementation. |
| Spatial/DNSH admissibility gating | `TSK-P3-WP-009` | Spatial planning must remain gate-focused and tied to declared spatial and DNSH doctrine rather than broad geospatial product semantics. |
| Temporal/dwell-time forensic findings | `TSK-P3-WP-010` | Temporal planning must remain replay-derived, append-only, and doctrine-routed rather than free-form forensic workflow design. |
| Internal constitutional observability | `TSK-P3-SUPPORT-OBS-001`, `TSK-P3-WP-007`, `TSK-P3-WP-009`, `TSK-P3-WP-010` | Observability planning must remain internal, machine-readable, and non-UI while preserving replay-safe visibility into the owning surfaces. |
| Deterministic scale bounds | `TSK-P3-SUPPORT-PERF-001`, `TSK-P3-WP-009`, `TSK-P3-WP-010` | Performance planning must remain a deterministic bound/scale contract for owning surfaces rather than infrastructure optimization work. |

This routing means the master implementation plan does not need new Wave 4
nodes for these concerns. The concerns are binding scope obligations on the
existing Wave 4 nodes listed above.

## Governing Doctrine Traceability Matrix

Wave 4 downstream planning must use this doctrine routing table.

| Node | Primary Governing Doctrine | Why It Governs |
|---|---|---|
| `TSK-P3-WP-007` | `docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md`; `docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md` | Owns regulator-aware partitioning, precedence application, and sovereignty non-collapse mechanics. |
| `TSK-P3-WP-008` | `docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md`; `docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md` | Owns COI and verifier-independence enforcement without expanding into unauthorized trust-boundary implementation. |
| `TSK-P3-WP-009` | `docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Owns spatial and DNSH admissibility gating over replay-safe evidence and policy lineage. |
| `TSK-P3-WP-010` | `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md` | Owns dwell-time forensic findings and replay-derived temporal reasoning over historical truth. |
| `TSK-P3-SUPPORT-OBS-001` | `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Internal observability planning must preserve machine-readable constitutional traceability without becoming a human-interface layer. |
| `TSK-P3-SUPPORT-PERF-001` | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/SPATIAL_CONSTRAINTS_AND_DNSH_DOCTRINE.md`; `docs/constitutional/CONSTITUTIONAL_GRAPH.md` | Deterministic performance planning must preserve projection/spatial/traversal legality and replay-safe scale bounds. |

If a downstream surface-specific plan cannot map a Wave 4 decision to this
matrix, it must record a doctrine gap or escalation rather than substitute a
local interpretation.

## Non-Goals

This plan does not:

- create `tasks/<TASK_ID>/meta.yml`;
- create task `PLAN.md` or `EXEC_LOG.md`;
- create verifier scripts, migrations, approvals, or evidence;
- authorize implementation before the Wave 4 CAP plans exist;
- introduce new Wave 4 nodes beyond the current master-plan routing above;
- reorder Wave 4 by subsystem preference, staffing preference, or support-node
  affinity.

## Ready State

This wave plan is complete when:

- the Wave 4 node set matches the current master plan;
- the serial order is derivable from the current DAG without contradiction;
- the extraction order for `TSK-P3-CAP-007` through `TSK-P3-CAP-010` is explicit;
- the shared observability/performance nodes are bound to their owning surfaces
  rather than treated as free-standing scope.
