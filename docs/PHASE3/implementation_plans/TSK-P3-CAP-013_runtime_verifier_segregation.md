# TSK-P3-CAP-013 Runtime/Verifier Segregation Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-013
Execution-Surface: P3-SURF-012
DAG-Nodes: TSK-P3-WP-012
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-005_wave5_verifier_segregation_closeout.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/TASK_GENERATION_CONSTITUTION.md
  replay_owner: docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
  verifier_owner: future Phase 3 runtime/verifier segregation verifier suite
  persistence_owner: future Phase 3 verifier-boundary manifests and exchange contracts
Replay-Criticality: operational-exhaust
State-Mutability: derived-cache
Ontology-Classification: projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: external replay package productization routes to Phase 5 or Phase 8D; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-012` — the Runtime And Verifier Segregation Surface.

It refines the Wave 5 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-012`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-012` owns the constitutional trust boundary between runtime and
verification for Phase 3. The surface must establish:

- replay-addressable artifact exchange contracts between runtime-emitted and
  verifier-consumed constitutional artifacts;
- privilege-separated verification surfaces that remain independent of runtime
  trust contexts;
- deterministic manifests or equivalent machine-readable boundary declarations
  for what runtime may emit, what verifiers may consume, and what each side is
  prohibited from mutating;
- segregation rules that preserve verifier independence without absorbing
  general identity, access-control, or portal-product semantics.

This surface does **not** own:

- generalized application authentication or authorization redesign;
- external verifier portal behavior or user-facing verifier workflow;
- authority-scope semantics already owned by `P3-SURF-006`;
- conflict-of-interest semantics already owned by `P3-SURF-008`;
- external replay package productization or disclosure packaging.

Runtime-authored verifier proofs, shared runtime/verifier trust contexts, and
verifier mutation of runtime lineage truth are constitutionally prohibited
under this surface.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-012` | `docs/constitutional/EXTERNAL_VERIFIER_INDEPENDENCE_DOCTRINE.md`; `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/NON_INFERENCE_AND_INTERPRETATION_LIMITS.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Runtime/verifier segregation must preserve verifier independence, prohibit runtime-authored verifier proof, and keep artifact exchange replay-addressable without inventing new domain semantics locally. |

If later planning cannot map a `P3-SURF-012` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-012` becomes runnable only after `TSK-P3-WP-005`,
  `TSK-P3-WP-006`, and `TSK-P3-WP-008` are complete; it does not unlock its
  predecessors.
- `TSK-P3-WP-012` must consume failure continuity, authority scope, and COI
  verifier-independence findings as already-declared replay substrates from
  `TSK-P3-CAP-005`, `TSK-P3-CAP-006`, and `TSK-P3-CAP-008`; it may not
  redefine those semantics locally.
- `TSK-P3-WP-012` must remain distinct from `TSK-P3-WP-011`; this plan may
  constrain what verifier closure is allowed to rely on, but may not absorb
  verifier-suite closure, CI promotion semantics, or invariant disposition
  ownership that belongs to `P3-SURF-011`.
- This surface does not create a standalone documentation support slice.
  `TSK-P3-SUPPORT-DOC-001` remains shared Wave 5 closeout scope and must be
  reconciled jointly with `TSK-P3-CAP-011` rather than frozen here
  unilaterally.

## Wave 5 Obligations Bound To This Surface

The following Wave 5 obligations apply directly to `P3-SURF-012` planning:

- segregation must preserve verifier independence and privilege separation
  without broadening into generic auth or product-security policy;
- artifact exchange must remain deterministic, replay-addressable, and
  non-authoritative over domain semantics;
- runtime may emit admissible constitutional artifacts but may not author
  verifier proof, verifier truth, or verifier-only conclusions;
- verifiers may consume declared runtime artifacts but may not mutate runtime
  lineage truth or silently rely on shared trust context;
- this surface must not absorb external replay package productization, portal
  behavior, or disclosure workflow semantics.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-012` | Runtime/verifier trust-boundary segregation, artifact exchange contracts, and privilege-separated verification surfaces | 3 | verifier/CI/docs/interfaces declared later by task pack; boundary-manifest references; segregation verifier references | Runtime/verifier segregation is deterministic, replay-addressable, and prevents runtime-authored verifier proof or shared trust-context collapse while staying within declared artifact exchange boundaries. | Deterministic verifier path must ultimately align with the future Phase 3 runtime/verifier segregation verifier suite and declared Phase 3 evidence. | Stop if the task expands into generic auth redesign, portal workflow behavior, authority semantics owned by other surfaces, or external replay package productization. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-005`, `TSK-P3-CAP-006`, and `TSK-P3-CAP-008` exist and the
  Wave 3/Wave 4 substrate anchoring is explicit;
- the future task pack stays within the exact node scope;
- deterministic verifier expectations and declared artifact-exchange
  boundaries are explicit;
- the task pack cites this plan, the Wave 5 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-012` is refined without expanding into generic auth, portal, or
  disclosure-packaging semantics;
- verifier independence, privilege separation, and anti-trust-collapse
  constraints are bound to the correct node;
- the distinction between this surface and `P3-SURF-011` is explicit;
- shared Wave 5 documentation closeout is left additive and unreified here;
- no atomic task pack files are created by this planning step.
