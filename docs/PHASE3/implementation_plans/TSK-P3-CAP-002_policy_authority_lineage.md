# TSK-P3-CAP-002 Policy And Authority Lineage Implementation Plan

Constitutional-Status: PLANNING
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Plan-ID: TSK-P3-CAP-002
Execution-Surface: P3-SURF-002
DAG-Nodes: TSK-P3-WP-002; TSK-P3-SUPPORT-CONTRACT-001; TSK-P3-SUPPORT-DB-001; TSK-P3-SUPPORT-SEC-001
Master-Implementation-Plan: docs/PHASE3/PHASE3_MASTER_IMPLEMENTATION_PLAN.md
Wave-Plan: docs/PHASE3/implementation_plans/TSK-P3-PLAN-001_wave1_lineage_foundations.md
Source-Pack: docs/PHASE3/PHASE3_SOURCE_PACK.md
Task-DAG: docs/PHASE3/PHASE3_TASK_DAG.md
Machine-DAG: docs/PHASE3/phase3_task_dag.yml
Atomic-Task-Creation-Allowed: false
Governing-Doctrine:
  - docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  - docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md
  - docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  - docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md
Ownership-Binding:
  constitutional_owner: docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md
  replay_owner: docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md
  verifier_owner: future policy and authority lineage verifier
  persistence_owner: future Phase 3 policy and authority lineage storage
Replay-Criticality: replay-authoritative
State-Mutability: revocable-authority
Ontology-Classification: authority-projection
Determinism-Classification: deterministic
Doctrine-Gap-Outcome: IMPLEMENT
Future-Phase-Isolation: methodology policy execution routes to Phase 5; Article 6 authorization routes to Phase 8A; no other future-phase absorption permitted

---

## Purpose

This document is the surface-specific implementation plan for
`P3-SURF-002` — the Policy And Authority Lineage Surface.

It refines the Wave 1 broad plan into the concrete planning obligations for:

- `TSK-P3-WP-002`
- the `P3-SURF-002` share of `TSK-P3-SUPPORT-CONTRACT-001`
- the `P3-SURF-002` share of `TSK-P3-SUPPORT-DB-001`
- the `P3-SURF-002` share of `TSK-P3-SUPPORT-SEC-001`

This is not an atomic task pack. It does not create `tasks/<TASK_ID>/`,
`docs/plans/phase3/<TASK_ID>/PLAN.md`, `EXEC_LOG.md`, verifier scripts,
migrations, approvals, runtime code, or evidence files.

## Surface Scope

`P3-SURF-002` owns policy artifact lineage and authority-source reconstruction
for Phase 3. The surface must establish:

- replay-authoritative policy artifact lineage;
- replay-authoritative authority lineage and resource-bound authority claims;
- deterministic reconstruction of which policy or authority source governed a
  later admissibility decision;
- revocable-authority semantics without historical truth mutation;
- persistence and access-control planning that preserves authority lineage
  without inventing legitimacy or sovereign mandate semantics.

This surface does **not** own:

- recursive legitimacy meaning;
- contradiction taxonomies;
- regulator partition execution;
- host-country authorization workflow runtime;
- methodology policy execution;
- runtime access as constitutional authority.

## Governing Doctrine Routing

| Node | Governing Doctrine | Routing Rule |
|---|---|---|
| `TSK-P3-WP-002` | `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md` | Policy and authority lineage must be derived only from lineage doctrine and declared delegation doctrine. |
| `TSK-P3-SUPPORT-CONTRACT-001` (`P3-SURF-002` share) | `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/EVIDENTIARY_ADMISSIBILITY_AND_PROVENANCE_DOCTRINE.md` | Authority and policy lineage proof exchange must preserve provenance and replay-safe contract shape. |
| `TSK-P3-SUPPORT-DB-001` (`P3-SURF-002` share) | `docs/constitutional/POLICY_ARTIFACT_AND_AUTHORITY_LINEAGE_DOCTRINE.md`; `docs/constitutional/TEMPORAL_VALIDITY_AND_REPLAY_DOCTRINE.md` | Persistence must preserve policy/authority lineage with revocation-lineage metadata and replay compatibility. |
| `TSK-P3-SUPPORT-SEC-001` (`P3-SURF-002` share) | `docs/constitutional/AUTHORITY_SCOPE_AND_DELEGATION_DOCTRINE.md`; `docs/constitutional/TASK_GENERATION_CONSTITUTION.md` | Access control must preserve declared authority separation and later verifier independence without inventing runtime sovereignty. |

If later planning cannot map a `P3-SURF-002` decision to this routing table, it
must record a doctrine gap rather than infer semantics locally.

## Sequencing And Shared-Ownership Rules

For this surface:

- `TSK-P3-WP-002` depends on `TSK-P3-WP-001` and therefore must preserve the
  dependency-lineage substrate established earlier in Wave 1.
- `TSK-P3-SUPPORT-CONTRACT-001`, `TSK-P3-SUPPORT-DB-001`, and
  `TSK-P3-SUPPORT-SEC-001` are shared support nodes across `P3-SURF-001` and
  `P3-SURF-002`.
- No shared support node may be frozen unilaterally under this plan. Shared
  support shape must be reconciled jointly with `TSK-P3-CAP-001`.

## Wave 1 Obligations Bound To This Surface

The following Wave 1 obligations apply directly to `P3-SURF-002` planning:

- policy and authority lineage schemas must reserve immutable provenance
  identifiers and exchange-safe structure required later by cross-system
  evidence continuity under `INV-305`;
- policy and authority lineage contracts must preserve admissible replay
  compatibility with the Phase 2 proof substrate;
- authority-lineage contracts and access-control planning must preserve the
  separation between runtime authority state and verifier proof expectations;
- this surface must not absorb host-country authorization runtime, regulator
  partition runtime, or methodology execution semantics.

## Shared Support Reconciliation

### `TSK-P3-SUPPORT-CONTRACT-001`

The `P3-SURF-002` share of the contract node must define:

- deterministic policy and authority lineage serialization;
- replay-stable proof structures for policy artifacts and authority sources;
- immutable provenance identifiers and exchange-safe field shape needed by
  later evidence-continuity work;
- offline replay package schema inputs required for authority-lineage proof;
- Phase 2 replay compatibility expectations for policy and authority artifacts.

This node is jointly reconciled with `TSK-P3-CAP-001` before finalization.

### `TSK-P3-SUPPORT-DB-001`

The `P3-SURF-002` share of the persistence node must define:

- storage shape for policy artifact lineage and authority lineage;
- revocable-authority persistence requirements compatible with replay truth;
- deterministic reconstruction expectations for policy-source and
  authority-source replay;
- no destructive mutation of historical authority lineage truth.

### `TSK-P3-SUPPORT-SEC-001`

The `P3-SURF-002` share of the security node must define:

- write-path and grant boundaries for policy and authority lineage;
- read-path constraints for replay and verifier use;
- no collapse between runtime authority state and verifier proof generation;
- no expansion into product authorization or future-phase sovereignty runtime.

## Future Atomic Task Candidates

Each row below is a candidate for later `CREATE-TASK` mode.

| Future Task | Title | Phase | Expected Touches | Acceptance Criteria | Verifier / Evidence Expectation | Stop Conditions |
|---|---|---:|---|---|---|---|
| `TSK-P3-WP-002` | Policy artifact and authority lineage foundation | 3 | runtime/db surfaces declared later by task pack; lineage docs; verifier references | Policy and authority lineage are reconstructable, replay-authoritative, and resource-scoped without inventing sovereign mandate semantics. | Deterministic verifier path must ultimately prove lineage reconstruction and authority provenance under declared Phase 3 evidence outputs. | Stop if the task invents regulator hierarchy, host-country mandate meaning, or runtime access as constitutional authority. |
| `TSK-P3-SUPPORT-CONTRACT-001` (`P3-SURF-002` slice) | Policy/authority proof and replay package contracts | 3 | deterministic interface definitions, contract docs, shared contract references | Policy and authority serialization is deterministic, replay-safe, Phase 2 compatible, and jointly reconciled with `P3-SURF-001`. | Shared contract verification must prove deterministic shape and replay-safe compatibility once the downstream task pack exists. | Stop if this slice is finalized unilaterally or if it collapses runtime and verifier trust boundaries. |
| `TSK-P3-SUPPORT-DB-001` (`P3-SURF-002` slice) | Policy/authority persistence planning | 3 | persistence model docs and allowed planning surfaces only | Persistence planning preserves replay-authoritative policy and authority lineage with revocable-authority semantics. | Later task-pack verifier must prove persistence shape matches lineage and replay requirements. | Stop if the task performs unapproved runtime migration work or mutates historical authority truth. |
| `TSK-P3-SUPPORT-SEC-001` (`P3-SURF-002` slice) | Policy/authority access-control planning | 3 | access model docs and security planning surfaces only | Access model preserves authority separation, verifier-read separation, and no product-auth expansion. | Later security verification must prove separation rules without inventing sovereign runtime semantics. | Stop if the task broadens privilege model into product auth or shared runtime/verifier authority. |

## Atomic Task Handoff Requirements

No node under this plan may enter `IMPLEMENT-TASK` directly. The next step is
`CREATE-TASK` only after:

- `TSK-P3-CAP-001` exists and shared support reconciliation is explicit;
- the future task pack stays within the exact node and support-slice scope;
- deterministic verifier expectations are declared;
- the task pack cites this plan, the Wave 1 broad plan, and the governing
  doctrines listed above.

## Readiness Checks For This Plan

This implementation plan is complete when:

- `TSK-P3-WP-002` is refined without inventing non-lineage authority meaning;
- the `P3-SURF-002` slices of the shared support nodes are explicit;
- replay compatibility, provenance reservation, and runtime/verifier separation
  obligations are bound to the correct nodes;
- shared support ownership with `TSK-P3-CAP-001` is explicit;
- no atomic task pack files are created by this planning step.
