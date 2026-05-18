# TSK-P3-CAP-011 Verifier And CI Closure Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-011
Execution-Surface: P3-SURF-011
DAG-Nodes: TSK-P3-WP-011
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-005_wave5_verifier_segregation_closeout.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  - docs/PHASE3/PHASE3_INVARIANT_REGISTER.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  replay_owner: docs/PHASE3/PHASE3_INVARIANT_REGISTER.md
  verifier_owner: future Phase 3 verifier suite
  persistence_owner: future Phase 3 evidence namespace only after execution legality is resolved
Replay-Criticality: operational-exhaust
State-Mutability: derived-cache
Ontology-Classification: projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: none

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-011` — the Verifier And CI Closure Surface.

It refines the Wave 5 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-011`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-011` owns Phase 3 verifier-suite closure and CI enforcement. The
surface must establish:

- exhaustive invariant-to-verifier disposition for every Phase 3 enforceable
  invariant;
- blocking CI wiring, evidence expectations, and negative-test expectations for
  the approved verifier set;
- capability-boundary contamination checks that prevent verifier or CI surfaces
  from back-introducing forbidden future-phase semantics;
- invariant promotion discipline that remains evidence-backed rather than
  prose-backed.

Every constitutional invariant designated as Phase 3 enforceable must map to
an approved verifier, a documented justification for deferred verification, or
an explicit constitutional exemption. Closure is not complete until this
mapping is exhaustive.

This surface does **not** own:

- doctrine creation by verifier or CI configuration;
- domain-semantic reinterpretation of lineage, projection, contradiction,
  failure, authority, regulator, COI, spatial, or temporal surfaces;
- evidence emission before execution legality is resolved;
- runtime/verifier trust-boundary implementation that belongs to
  `P3-SURF-012`.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-011` | `docs/constitutional/TASK_GENERATION_CONSTITUTION.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md`; `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md` | Verifier closure must remain mechanical, evidence-backed, and exhaustive over already-declared Phase 3 invariants and must not create doctrine or reinterpret domain meaning locally. |

If later planning cannot map a `P3-SURF-011` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-011` becomes runnable only after `TSK-P3-WP-001` through
  `TSK-P3-WP-010` and `TSK-P3-WP-012` are complete; it does not unlock its
  predecessors.
- `TSK-P3-WP-011` must consume the implementation truth of prior surfaces as
  already-declared replay substrate; it may verify and route evidence for those
  surfaces but may not redefine their semantics locally.
- `TSK-P3-WP-011` must consume runtime/verifier segregation from
  `TSK-P3-CAP-013`; verifier closure may not silently assume shared trust
  contexts, runtime-authored verifier proof, or undeclared artifact exchange
  authority.
- `TSK-P3-SUPPORT-DOC-001` remains shared Wave 5 closeout scope and must be
  reconciled jointly with `TSK-P3-CAP-013` rather than frozen here
  unilaterally.

## Wave 5 Obligations Bound To This Surface

The following Wave 5 obligations apply directly to `P3-SURF-011` planning:

- verifier closure must remain exhaustive over the enforceable Phase 3
  invariant set;
- every remaining invariant must be verifier-covered, constitutionally exempted,
  or formally deferred with justification before closeout can be claimed;
- CI wiring must remain blocking and evidence-backed rather than advisory-only;
- contamination checks must prevent verifier or CI surfaces from backfilling
  forbidden future-phase semantics;
- this surface must not absorb runtime/verifier trust-boundary implementation,
  doctrine invention, or operator-facing documentation semantics.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-011` | Verifier suite, CI wiring, evidence expectations, negative tests, invariant-to-verifier registry, capability-boundary contamination tests, and invariant promotion protocol | 3 | verifier/CI/docs references declared later by task pack; invariant register references; contamination-check references | Phase 3 verifier closure is exhaustive, blocking, evidence-backed, and free of doctrine invention, with every enforceable invariant mapped to an approved verifier, formal deferment, or constitutional exemption. | Deterministic verifier paths and evidence expectations must ultimately align with the declared Phase 3 verifier suite, `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`, and contract row `P3-009`. | Stop if the task introduces doctrine locally, emits evidence before execution legality, treats CI as advisory-only, or silently leaves enforceable invariants unmapped. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-013` exists and Wave 5 segregation anchoring is explicit;
- the future task pack stays within the exact node scope;
- the invariant-to-verifier disposition model is explicit and exhaustive for the
  enforceable Phase 3 invariant set;
- the task pack cites this plan, the Wave 5 broad plan, `docs/PHASE3/PHASE3_INVARIANT_REGISTER.md`,
  and contract row `P3-009`.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-011` is refined without inventing doctrine or absorbing
  runtime/verifier segregation ownership;
- verifier closure, CI blocking semantics, and invariant disposition rules are
  bound to the correct node;
- the distinction between this surface and `P3-SURF-012` is explicit;
- shared Wave 5 documentation closeout is left additive and unreified here;
- no atomic task pack files are created by this planning step.
