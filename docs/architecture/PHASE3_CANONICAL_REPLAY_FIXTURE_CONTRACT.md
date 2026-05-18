Constitutional-Status: IMPLEMENTATION-REFERENCE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Contract-ID: PHASE3-CANONICAL-REPLAY-FIXTURE-CONTRACT
Owning-Surfaces: P3-SURF-001; P3-SURF-002; P3-SURF-003; P3-SURF-006

---

# Phase 3 Canonical Replay Fixture Contract

## Purpose

This document defines the single canonical shared replay-fixture contract for:

- `P3-SURF-001` dependency lineage;
- `P3-SURF-002` policy and authority lineage;
- `P3-SURF-003` legitimacy projection;
- `P3-SURF-006` authority-scope and delegation enforcement.

This contract is implementation-facing only. It defines fixture identity,
coverage obligations, additive-only reconciliation rules, and deterministic
positive/negative replay cases used for verifier closure.

## Ownership And Scope

This contract jointly serves all four owning surfaces and must remain
additive-only across them.

This contract does not authorize:

- runtime implementation of the owning surfaces;
- regulator partition semantics;
- settlement semantics;
- product authorization semantics;
- future-phase workflow design.

## Additive-Only Reconciliation Rule

Shared fixtures under this contract must be additive-only:

- a new fixture may extend coverage;
- a new fixture may refine machine-readable annotations;
- a new fixture may not silently rewrite Wave 1 lineage meaning;
- a new fixture may not silently rewrite Wave 1 authority meaning;
- a new fixture may not redefine legitimacy doctrine or delegation doctrine locally.

If a new fixture needs different semantics, that is a doctrine or task-creation
issue, not a fixture-contract rewrite.

## Canonical Fixture Families

The contract must cover these fixture families:

| Fixture Family | Required Coverage |
|---|---|
| `lineage_valid` | Deterministic valid dependency lineage cases with immutable provenance anchors. |
| `lineage_invalid` | Invalid dependency lineage cases, including traversal-blocking negative cases. |
| `authority_valid` | Valid policy/authority lineage and in-scope delegation cases. |
| `authority_invalid` | Revoked, overflow, or otherwise invalid authority cases. |
| `delegation_valid` | Delegation chain reconstruction that remains inside the delegator's declared scope. |
| `delegation_invalid` | Delegation overflow or revoked-delegation cases. |
| `legitimacy_projection_valid` | Replay-derived legitimacy cases that remain legitimate inside a declared projection universe. |
| `legitimacy_projection_invalid` | Illegitimate-ancestor or blocked legitimacy cases within a declared projection universe. |

## Deterministic Fixture Identity

Every fixture record must declare:

| Field | Requirement |
|---|---|
| `fixture_id` | Required stable identifier. |
| `fixture_family` | Required canonical family name. |
| `surface_coverage` | Required list of owning surfaces exercised by the fixture. |
| `lineage_provenance_ids` | Required immutable provenance anchors for the participating records. |
| `expected_outcome` | Required deterministic replay outcome. |
| `negative_sqlstate` | Required for negative fixtures that must fail closed. |
| `replay_context` | Required replay inputs, ordering rules, and tie-break rules. |
| `wave1_semantics_preserved` | Required boolean affirming that the fixture does not silently rewrite Wave 1 lineage or authority meaning. |

## Fixture Coverage Matrix

The shared fixture set must prove at minimum:

- valid dependency traversal for `P3-SURF-001`;
- valid policy and authority lineage traversal for `P3-SURF-002`;
- illegitimate-ancestor blocking for `P3-SURF-003`;
- out-of-scope and revoked-authority blocking for `P3-SURF-006`;
- cross-surface compatibility where legitimacy and authority rely on Wave 1 lineage;
- deterministic positive and negative replay closure.

## Replay Safety

Fixtures must be replay-safe:

- no fixture may depend on runtime-only state;
- no fixture may depend on DB row order or insertion order;
- replay context must specify deterministic ordering and tie-break rules;
- fixture meaning must be derivable from persisted constitutional artifacts and declared replay inputs only.

## Non-Goals

This contract does not define:

- regulator or settlement fixture semantics;
- user workflow examples;
- narrative-only scenario prose detached from verifier closure;
- runtime API payload examples;
- doctrine invention for projection or authority meaning.
