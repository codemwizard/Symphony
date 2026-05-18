# TSK-P3-CAP-003 Projection And Legitimacy Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-003
Execution-Surface: P3-SURF-003
DAG-Nodes: TSK-P3-WP-003; TSK-P3-SUPPORT-FIXTURE-001; TSK-P3-SUPPORT-VERSION-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-002_wave2_projection_authority_enforcement.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  - docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md
  replay_owner: docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md
  verifier_owner: scripts/db/verify_p3_recursive_legitimacy_engine.sh
  persistence_owner: future Phase 3 projection and derived legitimacy storage
Replay-Criticality: projection-state
State-Mutability: supersedable-projection
Ontology-Classification: admissibility-projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: external replay package productization routes to Phase 5 or Phase 8D depending on use; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-003` — the Replay Projection And Recursive Legitimacy Surface.

It refines the Wave 2 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-003`
- the `P3-SURF-003` share of `TSK-P3-SUPPORT-FIXTURE-001`
- the `P3-SURF-003` share of `TSK-P3-SUPPORT-VERSION-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-003` owns replay-derived legitimacy projection for Phase 3. The
surface must establish:

- replay-derived legitimacy evaluation contexts reconstructed from persisted
  constitutional lineage artifacts;
- deterministic recursive legitimacy evaluation over canonical lineage and
  authority inputs;
- projection-state outputs that remain supersedable and never become canonical
  truth;
- replay-safe projection storage and versioning expectations that preserve
  external verifier independence;
- fixture and versioning planning that preserves derived-legitimacy semantics
  without absorbing contradiction, regulator, or settlement meaning.

This surface does **not** own:

- source lineage truth mutation;
- contradiction classification or quarantine semantics;
- regulator partition mechanics;
- settlement finality, deductions, or sovereign mandate meaning;
- runtime-only legitimacy state that cannot be reconstructed from replay.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-003` | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/REPLAY_AND_HISTORICAL_TRUTH_PRIMACY.md` | Legitimacy projection must be replay-derived from canonical lineage inputs and must never upgrade projection-state into source truth. |
| `TSK-P3-SUPPORT-FIXTURE-001` (`P3-SURF-003` share) | `docs/constitutional/LEGITIMACY_AND_REPLAY_PROJECTION_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Fixtures must close positive and negative legitimacy-projection cases without redefining prior-wave lineage or authority semantics. |
| `TSK-P3-SUPPORT-VERSION-001` (`P3-SURF-003` share) | `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Versioning must preserve replay continuity, admissible proof compatibility, and replay-hash regression expectations for projection outputs. |

If later planning cannot map a `P3-SURF-003` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-003` becomes runnable independently of `TSK-P3-WP-006` once Wave 1
  completion conditions are satisfied; its earlier position in Wave 2 comes
  from canonical task-ID ordering, not from unlocking `TSK-P3-WP-006`.
- `TSK-P3-SUPPORT-VERSION-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
  and `P3-SURF-003`.
- `TSK-P3-SUPPORT-FIXTURE-001` is shared across `P3-SURF-001`, `P3-SURF-002`,
  `P3-SURF-003`, and `P3-SURF-006`.
- No shared support node may be frozen unilaterally under this plan. Shared
  support shape must be reconciled jointly with `TSK-P3-CAP-001`,
  `TSK-P3-CAP-002`, and `TSK-P3-CAP-006` where ownership overlaps.

## Wave 2 Obligations Bound To This Surface

The following Wave 2 obligations apply directly to `P3-SURF-003` planning:

- projection outputs must remain replay-derived and supersedable rather than
  canonical truth;
- projection-class artifacts must carry explicit mutability and ontology
  classification consistent with the execution-surface vocabulary, without
  expanding that taxonomy locally;
- projection logic must preserve external verifier independence and must not
  depend on runtime-only trust anchors, ephemeral legitimacy context, or
  non-replayable derived state;
- versioning in this wave refers only to replay continuity compatibility
  enforcement and excludes release management, deployment lifecycle, API
  lifecycle, or product versioning semantics;
- compatibility with the admissible Phase 2 proof substrate must remain
  explicit in versioning and replay-hash planning.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-FIXTURE-001`

The `P3-SURF-003` share of the fixture node must define:

- canonical valid and invalid legitimacy-projection fixtures derived from
  canonical Wave 1 lineage and authority substrates;
- positive and negative replay cases that exercise recursive legitimacy
  projection without changing prior-wave semantics;
- additive reconciliation rules only, so Wave 2 fixtures cannot silently
  redefine Wave 1 lineage or authority expectations.

### `TSK-P3-SUPPORT-VERSION-001`

The `P3-SURF-003` share of the versioning node must define:

- projection-schema compatibility expectations;
- replay-hash regression expectations for derived legitimacy projection;
- admissible Phase 2 proof compatibility carried forward into projection-state
  evidence and replay;
- versioning terminology narrowed to replay continuity and format compatibility
  only.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-003` | Projection universes and recursive legitimacy evaluation | 3 | runtime/db surfaces declared later by task pack; projection docs; verifier references | Legitimacy projection is deterministic, replay-derived, and supersedable without mutating source truth or requiring runtime-only trust. | Deterministic verifier path must ultimately align with `scripts/db/verify_p3_recursive_legitimacy_engine.sh` and declared Phase 3 evidence. | Stop if the task upgrades projection to canonical truth, imports contradiction/regulator semantics, or requires non-replayable legitimacy context. |
| `TSK-P3-SUPPORT-FIXTURE-001` (`P3-SURF-003` slice) | Legitimacy projection fixtures | 3 | canonical fixture definitions, verifier fixtures, shared support references | Fixtures provide additive valid/invalid projection coverage derived from Wave 1 substrates and compatible with shared authority fixtures. | Later fixture verification must prove deterministic positive and negative legitimacy-projection cases. | Stop if fixtures silently rewrite prior-wave semantics or invent projection doctrine. |
| `TSK-P3-SUPPORT-VERSION-001` (`P3-SURF-003` slice) | Projection replay compatibility and versioning planning | 3 | replay/versioning docs and allowed planning surfaces only | Versioning preserves projection replay continuity, Phase 2 admissible-proof compatibility, and replay-hash regression expectations. | Later versioning verification must prove continuity and replay-hash regression coverage. | Stop if versioning expands into product lifecycle semantics or omits historical replay continuity. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-006` exists and Wave 2 shared-support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 2 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-003` is refined without inventing non-projection semantics;
- the `P3-SURF-003` slices of the shared support nodes are explicit;
- replay-derived mutability, verifier-independence, and Phase 2 proof
  compatibility obligations are bound to the correct nodes;
- shared support ownership with prior-wave surfaces and `TSK-P3-CAP-006` is
  explicit;
- no atomic task pack files are created by this planning step.
