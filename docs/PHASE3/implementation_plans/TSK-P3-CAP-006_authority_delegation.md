# TSK-P3-CAP-006 Authority Scope And Delegation Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-006
Execution-Surface: P3-SURF-006
DAG-Nodes: TSK-P3-WP-006; TSK-P3-SUPPORT-FIXTURE-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-002_wave2_projection_authority_enforcement.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  replay_owner: docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  verifier_owner: scripts/db/verify_p3_authority_scope_engine.sh
  persistence_owner: future Phase 3 authority scope records
Replay-Criticality: replay-authoritative
State-Mutability: revocable-authority
Ontology-Classification: authority-projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: host-country authorization workflow routes to Phase 8A; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-006` — the Authority Scope And Delegation Enforcement Surface.

It refines the Wave 2 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-006`
- the `P3-SURF-006` share of `TSK-P3-SUPPORT-FIXTURE-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-006` owns authority-scope and delegation enforcement for Phase 3. The
surface must establish:

- replay-authoritative enforcement of authority scope against canonical
  authority lineage;
- deterministic delegation evaluation that never exceeds delegator scope;
- revocable-authority enforcement semantics reconstructed from persisted Wave 1
  policy and authority lineage;
- fixture planning that closes valid and invalid delegation and revocation
  cases without mutating source lineage truth.

This surface does **not** own:

- policy or authority lineage definition itself;
- regulator partition semantics;
- product authorization or runtime permission semantics;
- host-country workflow runtime;
- sovereign mandate invention beyond declared lineage and delegation doctrine.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-006` | `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md` | Authority enforcement must operate over canonical policy/authority lineage and must not invent detached enforcement semantics. |
| `TSK-P3-SUPPORT-FIXTURE-001` (`P3-SURF-006` share) | `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Fixtures must close valid and invalid delegation cases without redefining earlier lineage substrates or regulator meaning. |

If later planning cannot map a `P3-SURF-006` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-006` becomes runnable independently of `TSK-P3-WP-003` once Wave 1
  completion conditions are satisfied; its later position in Wave 2 comes from
  canonical task-ID ordering and the interleaved support node, not from
  projection-legitimacy unlocking authority enforcement.
- `TSK-P3-WP-006` must remain anchored to the Wave 1 `P3-SURF-002` authority
  lineage schema defined by `TSK-P3-CAP-002`; authority enforcement may not
  invent detached scope, revocation, or delegation replay semantics.
- `TSK-P3-SUPPORT-FIXTURE-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
  `P3-SURF-003`, and `P3-SURF-006`.
- No shared support node may be frozen unilaterally under this plan. Shared
  support shape must be reconciled jointly with `TSK-P3-CAP-001`,
  `TSK-P3-CAP-002`, and `TSK-P3-CAP-003`.

## Wave 2 Obligations Bound To This Surface

The following Wave 2 obligations apply directly to `P3-SURF-006` planning:

- authority enforcement must remain bound to canonical authority lineage and
  revocation metadata established in Wave 1;
- enforcement semantics must preserve replay-authoritative reconstruction of
  delegation and scope decisions;
- this surface must not absorb regulator partition, product authorization, or
  sovereignty runtime semantics;
- fixture planning must be additive only and must not silently override valid
  Wave 1 lineage or authority assumptions.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-FIXTURE-001`

The `P3-SURF-006` share of the fixture node must define:

- canonical valid delegation, invalid delegation, scope overflow, and
  revocation-edge fixtures;
- deterministic negative cases proving enforcement fails when authority exceeds
  declared lineage-backed scope;
- additive reconciliation rules only, so Wave 2 fixtures cannot silently
  redefine Wave 1 authority lineage or projection expectations.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-006` | Authority scope and delegation enforcement | 3 | runtime/db surfaces declared later by task pack; authority docs; verifier references | Authority scope and delegation enforcement is deterministic, replay-authoritative, and anchored to canonical policy/authority lineage without inventing regulator or product-auth semantics. | Deterministic verifier path must ultimately align with `scripts/db/verify_p3_authority_scope_engine.sh` and declared Phase 3 evidence. | Stop if the task detaches enforcement from `P3-SURF-002` lineage truth, invents new authority semantics, or treats runtime access as constitutional authority. |
| `TSK-P3-SUPPORT-FIXTURE-001` (`P3-SURF-006` slice) | Authority enforcement fixtures | 3 | canonical fixture definitions, verifier fixtures, shared support references | Fixtures provide additive valid/invalid authority-scope and delegation coverage derived from Wave 1 lineage substrates. | Later fixture verification must prove deterministic positive and negative delegation cases. | Stop if fixtures silently rewrite prior-wave authority semantics or invent regulator meaning. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-003` exists and Wave 2 shared-support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 2 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-006` is refined without inventing detached authority semantics;
- the `P3-SURF-006` slice of the shared fixture node is explicit;
- CAP-002 lineage anchoring, replay-authoritative delegation semantics, and
  additive fixture reconciliation are bound to the correct nodes;
- shared support ownership with prior-wave surfaces and `TSK-P3-CAP-003` is
  explicit;
- no atomic task pack files are created by this planning step.
