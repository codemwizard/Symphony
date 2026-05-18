# TSK-P3-CAP-007 Regulator Partition And Arbitration Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-007
Execution-Surface: P3-SURF-007
DAG-Nodes: TSK-P3-WP-007; TSK-P3-SUPPORT-OBS-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-004_wave4_regulator_coi_spatial_temporal.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  - docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md
  - docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md
  replay_owner: docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md
  verifier_owner: scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh
  persistence_owner: future Phase 3 regulator partition records
Replay-Criticality: replay-derived
State-Mutability: quarantined-state
Ontology-Classification: projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: regulator notification and submission workflows route to Phase 8A or Phase 8B; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-007` — the Regulator Partition And Arbitration Surface.

It refines the Wave 4 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-007`
- the `P3-SURF-007` share of `TSK-P3-SUPPORT-OBS-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-007` owns regulator-aware partitioning, precedence application, and
sovereignty non-collapse mechanics for Phase 3. The surface must establish:

- deterministic partitioning of replay-derived decision contexts by declared
  regulator regime;
- precedence application only where constitutional doctrine already declares
  the arbitration rule;
- quarantine-compatible regulator findings that preserve replay visibility
  without merging regulator domains;
- observability planning for regulator partition outcomes without expanding into
  operator dashboards or external workflow.

When no constitutional doctrine declares precedence between regulator regimes,
the implementation must preserve independent findings and emit a doctrine-gap
condition rather than infer a local arbitration result.

This surface does **not** own:

- real-world regulator mandate invention;
- cross-regime equivalence claims;
- new contradiction classes or regulator-specific contradiction taxonomies;
- external regulator notification or submission workflows;
- host-country authorization runtime;
- sovereign balancing logic not already declared by doctrine.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-007` | `docs/constitutional/REGULATOR_SOVEREIGNTY_NON_COLLAPSE_DOCTRINE.md`; `docs/constitutional/CONSTITUTIONAL_PRIORITY_AND_CONFLICT_ARBITRATION.md`; `docs/constitutional/CONTRADICTION_CLASSIFICATION_DOCTRINE.md` | Partitioning and arbitration must preserve regulator-domain separation and may apply only doctrine-declared precedence and contradiction handling. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-007` share) | `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Observability must remain machine-readable internal constitutional traceability for regulator partition outputs only. |

If later planning cannot map a `P3-SURF-007` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-007` becomes runnable only after `TSK-P3-WP-002` and
  `TSK-P3-WP-004` are complete; it does not unlock those predecessors.
- `TSK-P3-WP-007` must consume Wave 1 authority/policy lineage and Wave 3
  contradiction outputs as already-declared replay substrates; it may not
  reinterpret those substrates locally.
- `TSK-P3-SUPPORT-OBS-001` is shared across `P3-SURF-003`, `P3-SURF-004`,
  `P3-SURF-005`, `P3-SURF-007`, and `P3-SURF-009`.
- No shared support node may be frozen unilaterally under this plan. Shared
  observability shape must be reconciled jointly with `TSK-P3-CAP-003`,
  `TSK-P3-CAP-004`, `TSK-P3-CAP-005`, and `TSK-P3-CAP-009`.

## Wave 4 Obligations Bound To This Surface

The following Wave 4 obligations apply directly to `P3-SURF-007` planning:

- regulator partitioning must preserve sovereignty non-collapse and must not
  collapse orthogonal regulator domains into a shared meaning layer;
- precedence application must remain doctrine-declared and may not use local
  arbitration heuristics;
- when doctrine does not declare precedence between regulator regimes, task
  packs must preserve independent regulator findings and raise a doctrine gap
  instead of inferring a local arbitration result;
- contradiction handling must consume the existing contradiction taxonomy
  rather than invent a regulator-only branch;
- observability must remain internal, replay-safe, and machine-readable only.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-OBS-001`

The `P3-SURF-007` share of the observability node must define:

- replay-safe regulator partition findings and arbitration trace visibility;
- machine-readable observability for positive and negative regulator-partition
  outcomes;
- additive reconciliation only, so Wave 4 observability cannot silently
  redefine earlier projection, contradiction, or failure meanings;
- no UI, dashboard, operator console, or regulator disclosure behavior.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-007` | Regulator partitioning and arbitration mechanics | 3 | runtime/db/security surfaces declared later by task pack; regulator docs; verifier references | Regulator-aware partitioning and precedence application are deterministic, replay-derived, and preserve sovereignty non-collapse without cross-domain merger or undeclared precedence rules. | Deterministic verifier path must ultimately align with `scripts/audit/verify_p3_regulatory_sovereignty_partitioning.sh` and declared Phase 3 evidence. | Stop if the task merges regulator domains, invents precedence rules, or expands into external regulator workflow runtime. |
| `TSK-P3-SUPPORT-OBS-001` (`P3-SURF-007` slice) | Regulator partition observability | 3 | observability docs, verifier fixtures, shared support references | Observability is machine-readable, replay-safe, and limited to internal constitutional visibility of regulator partition outcomes. | Later observability verification must prove internal traceability without UI or dashboard drift. | Stop if observability expands into dashboards, user-facing disclosure, or regulator portal semantics. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-009` exists and Wave 4 shared-support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 4 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-007` is refined without inventing regulator meaning or local
  arbitration semantics;
- the `P3-SURF-007` slice of the shared observability node is explicit;
- sovereignty non-collapse, doctrine-declared precedence, and replay-safe
  regulator findings are bound to the correct nodes;
- shared support ownership with `TSK-P3-CAP-003`, `TSK-P3-CAP-004`,
  `TSK-P3-CAP-005`, and `TSK-P3-CAP-009` is explicit;
- no atomic task pack files are created by this planning step.
