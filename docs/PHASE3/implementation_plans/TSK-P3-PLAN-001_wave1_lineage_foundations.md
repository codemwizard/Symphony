Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-PLAN-001
Plan-Type: broad-wave-implementation-plan
Wave-ID: WAVE-1
Wave-Title: Lineage Foundations
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false

---

## Purpose

This document is the first broad Phase 3 wave implementation plan. It does not
create atomic task packs. It defines the first consecutive dependency-safe
execution batch to be refined next through surface-specific implementation
plans.

The governing construction rule comes from
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`:

- waves are consecutive slices of the canonical linear task sequence;
- waves do not reorder tasks;
- when multiple tasks are runnable, the canonically lowest task ID wins;
- only after the serial order is derived may a wave boundary be named.

This plan therefore converts the already-corrected Phase 3 task universe into a
first executable planning batch without inventing new phase scope.

## Wave Membership

Wave 1 is the first post-activation runtime batch and consists of the Phase 3
Lineage Foundations nodes:

| Node | Surface | Purpose |
|---|---|---|
| TSK-P3-WP-001 | P3-SURF-001 | Typed dependency graph lineage and traversal substrate. |
| TSK-P3-WP-002 | P3-SURF-002 | Policy artifact and authority lineage foundation. |
| TSK-P3-SUPPORT-CONTRACT-001 | P3-SURF-001, P3-SURF-002 | Deterministic internal serialization, proof contracts, and offline replay package schema contracts for lineage records. |
| TSK-P3-SUPPORT-DB-001 | P3-SURF-001, P3-SURF-002 | Persistence model for dependency, policy, and authority lineage surfaces. |
| TSK-P3-SUPPORT-SEC-001 | P3-SURF-001, P3-SURF-002 | Access-control and privilege model for lineage surfaces. |

## Canonical Serial Sequence

Using the current Phase 3 DAG and excluding all `completed` nodes, the first
canonical runnable sequence is:

1. `TSK-P3-WP-001`
2. `TSK-P3-WP-002`
3. `TSK-P3-SUPPORT-CONTRACT-001`
4. `TSK-P3-SUPPORT-DB-001`
5. `TSK-P3-SUPPORT-SEC-001`

### Derivation Notes

- `TSK-P3-WP-001` is the only node whose dependencies are fully satisfied by
  the completed activation sequence.
- After `TSK-P3-WP-001`, the next runnable node is `TSK-P3-WP-002`.
- After `TSK-P3-WP-002`, both `TSK-P3-SUPPORT-CONTRACT-001` and
  `TSK-P3-SUPPORT-DB-001` become runnable.
- The tie is resolved by canonical task ID ordering, so
  `TSK-P3-SUPPORT-CONTRACT-001` precedes `TSK-P3-SUPPORT-DB-001`.
- `TSK-P3-SUPPORT-SEC-001` remains gated by `TSK-P3-SUPPORT-DB-001` and closes
  the first wave.

This is a serial planning sequence. It does not authorize parallel execution.

## Surface-Plan Extraction Order

Wave 1 implementation-plan extraction must follow the surfaces introduced by
the serial sequence:

1. `TSK-P3-CAP-001` for `P3-SURF-001`
2. `TSK-P3-CAP-002` for `P3-SURF-002`

The Wave 1 support nodes are not separate execution surfaces. They inherit from
`P3-SURF-001` and `P3-SURF-002` and must be scoped inside those surface plans
rather than inventing new CAP records.

`TSK-P3-SUPPORT-CONTRACT-001` is jointly owned by `P3-SURF-001` and
`P3-SURF-002`. `TSK-P3-CAP-001` and `TSK-P3-CAP-002` must therefore reconcile
the shared serialization, proof, and offline replay package contracts together
before either surface-specific plan is treated as finalized. Neither CAP plan
may unilaterally freeze the contract shape for the shared support node.

## Wave 1 Planning Obligations

The next planning layer created from this wave must preserve these approved
Phase 3 obligations:

- `TSK-P3-SUPPORT-CONTRACT-001` must include offline replay package schema
  contracts as part of deterministic proof interfaces.
- `TSK-P3-SUPPORT-DB-001` and `TSK-P3-SUPPORT-SEC-001` must not expand into
  future-phase runtime DDL, product auth workflows, or speculative persistence.
- `P3-SURF-001` and `P3-SURF-002` remain the sole constitutional owners of Wave
  1 runtime work; support nodes must not be used to create shadow architecture.
- Future task packs derived from this wave must preserve the canonical serial
  order above unless a later approved planning artifact explicitly changes the
  wave boundary without changing task order.
- Runtime/verifier segregation obligations begin in Wave 1 because lineage
  schemas and replay package contracts are the first place where runtime truth,
  proof artifacts, verifier inputs, and verifier outputs can be incorrectly
  collapsed. Wave 1 planning must preserve verifier independence in a way that
  later `TSK-P3-WP-012` can enforce mechanically.
- Cross-system evidence continuity preparation is required in Wave 1 because
  lineage and authority schemas must reserve immutable provenance identifiers
  and exchange-stable record structure needed later by `INV-305`.
- Phase 2 replay compatibility is required in Wave 1 because the first Phase 3
  schemas and serialization contracts must preserve admissible replay from the
  existing Phase 2 proof substrate instead of forcing retroactive compatibility
  repair in later waves.

## Wave 1 Obligation-To-Node Routing

The following obligations are required at the broad-wave planning layer and are
already routed to existing master-plan nodes. No new Wave 1 node is required.

| Obligation | Routed Master-Plan Nodes | Planning Meaning |
|---|---|---|
| Runtime/verifier segregation obligations | `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-SEC-001`, future enforcement at `TSK-P3-WP-012` | Wave 1 contracts and access-control planning must not allow runtime-authored verifier proof, shared trust collapse, or ambiguous verifier input/output boundaries. |
| Cross-system evidence continuity schema preparation | `TSK-P3-WP-001`, `TSK-P3-WP-002`, `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001` | Typed lineage, authority lineage, proof contracts, and persistence planning must reserve immutable provenance identifiers and replay-stable exchange structure needed by `INV-305`. |
| Phase 2 replay compatibility requirements | `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, `TSK-P3-SUPPORT-VERSION-001` | Wave 1 planning must preserve compatibility with the admissible Phase 2 replay substrate and route later regression enforcement into the versioning support node. |
| Governing doctrine traceability | `TSK-P3-WP-001`, `TSK-P3-WP-002`, `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, `TSK-P3-SUPPORT-SEC-001` | Downstream CAP plans must bind every Wave 1 node directly to its governing doctrines instead of inferring requirements locally. |
| Shared contract ownership clarification | `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-CAP-001`, `TSK-P3-CAP-002` | Shared contracts are reconciled jointly across both owning surfaces before finalization. |

This routing means the master implementation plan does not need new Wave 1
nodes for these concerns. The concerns are binding scope obligations on the
existing Wave 1 nodes listed above.

## Governing Doctrine Traceability Matrix

Wave 1 downstream planning must use this doctrine routing table.

| Node | Primary Governing Doctrine | Why It Governs |
|---|---|---|
| `TSK-P3-WP-001` | `docs/constitutional/CONSTITUTIONAL_GRAPH.md` | Owns typed dependency lineage and machine-traversable upstream dependency truth. |
| `TSK-P3-WP-002` | `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md` | Owns policy artifact lineage and authority-source reconstruction. |
| `TSK-P3-SUPPORT-CONTRACT-001` | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Shared contracts must preserve typed lineage truth, authority provenance, and replay-safe proof exchange. |
| `TSK-P3-SUPPORT-DB-001` | `docs/constitutional/CONSTITUTIONAL_GRAPH.md`; `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md` | Persistence planning must support lineage truth, authority reconstruction, and compatibility with replay projection. |
| `TSK-P3-SUPPORT-SEC-001` | `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Access-control planning must preserve authority separation and future verifier independence. |

If a downstream surface-specific plan cannot map a Wave 1 decision to this
matrix, it must record a doctrine gap or escalation rather than substitute a
local interpretation.

## Non-Goals

This plan does not:

- create `tasks/<TASK_ID>/meta.yml`;
- create task `PLAN.md` or `EXEC_LOG.md`;
- create verifier scripts, migrations, approvals, or evidence;
- authorize implementation before surface-specific plans exist;
- introduce new Wave 1 nodes beyond the corrected master-plan routing above;
- reorder Wave 1 by theme, staffing preference, or support-domain similarity.

## Ready State

This wave plan is complete when:

- the Wave 1 node set matches the corrected master plan;
- the serial order is derivable from the current DAG without contradiction;
- the extraction order for `TSK-P3-CAP-001` and `TSK-P3-CAP-002` is explicit;
- support nodes are bound to their owning surfaces rather than treated as free
  standing scope.
