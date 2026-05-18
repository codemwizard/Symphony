# TSK-P3-CAP-008 Conflict-Of-Interest Enforcement Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-008
Execution-Surface: P3-SURF-008
DAG-Nodes: TSK-P3-WP-008
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  replay_owner: docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  verifier_owner: scripts/db/verify_p3_conflict_of_interest_enforcement.sh
  persistence_owner: future Phase 3 role and verifier-independence records
Replay-Criticality: replay-derived
State-Mutability: immutable-lineage
Ontology-Classification: lineage-truth
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: VVB portal and user workflow surfaces route to Phase 6; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-008` — the Conflict-Of-Interest Enforcement Surface.

It refines the Wave 4 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-008`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-008` owns conflict-of-interest enforcement and verifier-independence
preservation for Phase 3. The surface must establish:

- deterministic COI detection against declared submitter, verifier, and asset
  relationships;
- replay-visible verifier-independence findings derived from persisted role and
  authority records;
- immutable-lineage COI outcomes that do not rely on runtime-only trust state;
- enforcement that preserves external-verifier independence without absorbing
  broad identity, access, or portal semantics.

COI findings under this surface represent deterministic constitutional facts
derived from declared relationship records and do not encode discretionary
policy interpretation. That is why this surface remains `immutable-lineage` and
`lineage-truth` rather than projection-state.

This surface does **not** own:

- generalized application access control;
- product authorization or user-journey permissioning;
- external verifier portal behavior;
- undeclared identity-correlation semantics;
- runtime/verifier segregation implementation that belongs to `P3-SURF-012`.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-008` | `docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md`; `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md` | COI enforcement must remain mechanical, replay-visible, and verifier-safe without expanding into generic identity or application-access semantics. |

If later planning cannot map a `P3-SURF-008` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-008` becomes runnable only after `TSK-P3-WP-006` is complete; it
  does not unlock its predecessor.
- `TSK-P3-WP-008` must consume authority lineage and delegation scope from
  `TSK-P3-CAP-006` as already-declared replay substrate; it may not invent a
  detached authority model.
- `TSK-P3-WP-008` must remain distinct from `TSK-P3-WP-012`; this plan may
  constrain trust-collapse risk but may not absorb runtime/verifier artifact
  exchange or privilege-separation implementation that belongs to
  `P3-SURF-012`.
- This surface does not co-own `TSK-P3-SUPPORT-OBS-001` or
  `TSK-P3-SUPPORT-PERF-001`. Any later observability or performance
  requirements must be consumed through already-owned shared support rather than
  inventing a new Wave 4 support slice here.

## Wave 4 Obligations Bound To This Surface

The following Wave 4 obligations apply directly to `P3-SURF-008` planning:

- COI enforcement must remain bound to verifier independence and may not drift
  into portal, workflow, or product-access semantics;
- enforcement must remain deterministic and replay-visible, with no runtime
  trust collapse;
- role and verifier-independence findings must remain constitutional outputs,
  not operational auth state;
- this surface must not silently assume broader runtime/verifier segregation
  semantics than already declared by Wave 1 and reserved for `P3-SURF-012`.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-008` | Conflict-of-interest and verifier independence enforcement | 3 | runtime/db/security surfaces declared later by task pack; COI docs; verifier references | COI enforcement is deterministic, replay-visible, DB-layer enforceable, and preserves verifier independence without expanding into generic auth or portal semantics. | Deterministic verifier path must ultimately align with `scripts/db/verify_p3_conflict_of_interest_enforcement.sh` and declared Phase 3 evidence. | Stop if the task expands into application-access redesign, portal workflow behavior, undeclared identity correlation semantics, or runtime/verifier segregation implementation owned by `P3-SURF-012`. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-006` exists and Wave 2 authority-lineage anchoring is explicit;
- the future task pack stays within the exact node scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 4 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-008` is refined without expanding into generic auth or portal
  semantics;
- verifier-independence preservation, authority-lineage anchoring, and
  anti-trust-collapse constraints are bound to the correct node;
- the distinction between this surface and `P3-SURF-012` is explicit;
- no atomic task pack files are created by this planning step.
