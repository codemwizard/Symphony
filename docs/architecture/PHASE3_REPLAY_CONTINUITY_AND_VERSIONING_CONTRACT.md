Constitutional-Status: IMPLEMENTATION-REFERENCE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Contract-ID: PHASE3-REPLAY-CONTINUITY-VERSIONING-CONTRACT
Owning-Surfaces: P3-SURF-001; P3-SURF-002; P3-SURF-003

---

# Phase 3 Replay Continuity And Versioning Compatibility Contract

## Purpose

This document defines the single canonical replay continuity and versioning
contract shared by:

- `P3-SURF-001` typed dependency lineage;
- `P3-SURF-002` policy and authority lineage;
- `P3-SURF-003` replay-derived legitimacy projection.

This contract is implementation-facing only. It defines replay continuity
obligations, deterministic compatibility anchors, and replay-hash regression
expectations. It does not define deployment lifecycle, release-management,
public API versioning, or product versioning semantics.

## Ownership And Scope

This contract jointly serves:

- dependency-lineage schema and traversal continuity for `P3-SURF-001`;
- policy/authority lineage continuity for `P3-SURF-002`;
- projection-universe and legitimacy-projection continuity for `P3-SURF-003`.

This contract does not authorize:

- runtime implementation of the owning surfaces;
- deployment rollout semantics;
- API compatibility guarantees;
- release train or product lifecycle policy;
- external replay package distribution behavior.

## Canonical Replay Continuity Anchors

Every continuity claim under this contract must be grounded in persisted,
replay-addressable anchors:

| Anchor | Requirement |
|---|---|
| `schema_migration_head` | Required. Names the forward-only migration head the continuity claim was evaluated against. |
| `proof_schema_version` | Required where verifier-emitted proof shape changes. |
| `policy_format_version` | Required where policy artifact serialization changes. |
| `projection_algorithm_version` | Required where replay-derived legitimacy behavior depends on algorithm selection. |
| `lineage_provenance_id` | Required immutable provenance anchor for the primary artifact. |
| `replay_context_hash` | Required deterministic hash over declared replay inputs. |
| `phase2_compatibility_intent` | Required statement of admissible Phase 2 compatibility intent without claiming equality. |

## Deterministic Versioning Rules

Versioning under this contract is replay-continuity versioning only.

All versioned replay artifacts must be:

- reconstructable from persisted constitutional artifacts;
- deterministic for identical persisted inputs;
- explicit about ordering and tie-break rules;
- explicit about which surface the version governs;
- explicit about compatibility direction.

Insertion order, DB engine row order, wall-clock evaluation order, and runtime
cache state are prohibited versioning authorities.

## Compatibility Classes

This contract recognizes the following continuity classes:

| Class | Meaning |
|---|---|
| `schema_compatible` | Migration shape preserves replay-addressable interpretation of persisted lineage artifacts. |
| `proof_compatible` | Verifier output shape preserves deterministic reading or provides an explicit version bridge. |
| `policy_format_compatible` | Policy artifact serialization preserves replay reconstruction semantics or provides a declared adapter. |
| `projection_compatible` | Derived legitimacy projection preserves deterministic replay under a declared algorithm/version pair. |
| `phase2_admissible_intent_only` | Compatibility is declared as admissible intent with the retained Phase 2 proof substrate, not replay equality. |

## Replay-Hash Regression Expectations

Every surface using this contract must declare replay-hash regression posture:

- hash domain inputs must be enumerated;
- normalization rules must be explicit;
- algorithm/version identifiers must be declared;
- a changed replay hash must be explained by a declared compatibility event,
  not by silent ordering or serialization drift.

Replay-hash changes without a declared compatibility explanation are
constitutionally suspect and must fail closed in verifier review.

## Surface-Specific Continuity Requirements

### `P3-SURF-001`

- dependency node and edge identity must remain tied to immutable provenance;
- traversal ordering must remain deterministic;
- typed edge semantics must not collapse into generic graph edges.

### `P3-SURF-002`

- authority and policy lineage must preserve effective-time reconstruction;
- delegation and revocation ancestry must remain replay-addressable;
- policy artifact classes and authority source kinds must remain explicitly versioned.

### `P3-SURF-003`

- projection universes must remain explicit, not inferred from runtime state;
- derived legitimacy states must remain supersedable projections;
- replay-derived blocking must remain reconstructable from persisted lineage,
  declared policy inputs, and declared projection algorithm version.

## Phase 2 Compatibility Intent

This contract preserves compatibility intent with the admissible Phase 2 proof
substrate by requiring:

- immutable provenance identifiers;
- deterministic serialization rules;
- explicit replay reconstruction inputs;
- replay-hash regression expectations;
- explicit statement that compatibility is intent-based, not equality-based.

This contract does not claim full replay equivalence with Phase 2 artifacts.

## Runtime And Verifier Boundary

This contract must not collapse runtime and verifier trust boundaries.

Required separation rules:

- runtime systems may write persisted lineage and projection artifacts;
- verifier systems may read persisted artifacts and derive continuity findings;
- continuity proof must be reconstructable without runtime-only state;
- runtime-authored continuity claims are not authoritative verifier proof.

## Non-Goals

This contract does not define:

- deployment lifecycle versioning;
- release train semantics;
- public API compatibility policy;
- product versioning language;
- contradiction, regulator, settlement, or sovereign semantics.
