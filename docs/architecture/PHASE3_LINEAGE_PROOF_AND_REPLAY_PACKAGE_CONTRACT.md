Constitutional-Status: IMPLEMENTATION-REFERENCE
Interpretation-Authority: PHASE
NotebookLM-Ingestion: DO-NOT-INGEST
Authority-Rank: 1
Phase-Scope: PHASE-3
Contract-ID: PHASE3-LINEAGE-PROOF-REPLAY-PACKAGE-CONTRACT
Owning-Surfaces: P3-SURF-001; P3-SURF-002

---

# Phase 3 Lineage Proof And Replay Package Contract

## Purpose

This document defines the single canonical shared contract artifact for:

- typed dependency-lineage proof exchange for `P3-SURF-001`;
- policy artifact and authority-lineage proof exchange for `P3-SURF-002`;
- offline replay package schema inputs required to reconstruct both surfaces
  from persisted constitutional artifacts.

This document is implementation-facing only. It may describe proof shape and
replay package inputs, but it may not introduce runtime API semantics, external
integration semantics, or product packaging semantics.

## Ownership And Scope

This contract jointly serves:

- `P3-SURF-001` typed dependency graph lineage and traversal substrate;
- `P3-SURF-002` policy artifact and authority lineage foundation.

This contract does not independently authorize:

- runtime implementation of either surface;
- public API shape;
- external replay package transport or orchestration behavior;
- runtime/verifier trust collapse.

## Deterministic Serialization Rules

All proof records and replay package inputs emitted under this contract must be:

- derived from persisted constitutional artifacts only;
- serialized deterministically;
- stable under replay for identical persisted state;
- explicit about ordering keys and tie-break keys;
- explicit about lineage provenance identifiers.

Canonical ordering for package lists is:

1. semantic primary key for the artifact type;
2. effective timestamp when applicable;
3. immutable provenance identifier as the deterministic tie-break.

Insertion order, DB engine row order, and runtime iteration order are not
admissible ordering authorities.

## Shared Proof Fields

Every proof exchange record produced under this contract must preserve these
shared fields:

| Field | Requirement |
|---|---|
| `proof_schema_version` | Required. Versioned contract identifier for the proof record shape. |
| `surface_id` | Required. Must be `P3-SURF-001` or `P3-SURF-002`. |
| `lineage_provenance_id` | Required. Immutable provenance identifier for the primary lineage artifact. |
| `effective_from` | Required where temporal applicability exists. |
| `effective_to` | Optional end boundary; if omitted, the record remains open-ended. |
| `resource_scope` | Required where scope applies. |
| `act_scope` | Required where scope applies. |
| `replay_reconstruction_inputs` | Required. Must identify the persisted inputs needed for future replay. |
| `phase2_compatibility_intent` | Required. States compatibility intent with the admissible Phase 2 proof substrate without claiming replay equality. |

## Surface-Specific Proof Shape

### `P3-SURF-001` Dependency-Lineage Proof Fields

| Field | Requirement |
|---|---|
| `node_id` | Required stable identifier for a dependency node. |
| `node_key` | Required deterministic node key. |
| `node_kind` | Required typed node discriminator. |
| `edge_id` | Required stable identifier for a dependency edge when edge data is exchanged. |
| `dependency_kind` | Required typed dependency discriminator. |
| `upstream_node_id` | Required when edge lineage is exchanged. |
| `downstream_node_id` | Required when edge lineage is exchanged. |

### `P3-SURF-002` Policy / Authority Proof Fields

| Field | Requirement |
|---|---|
| `policy_artifact_id` | Required stable identifier for the policy artifact. |
| `artifact_key` | Required deterministic policy artifact key. |
| `artifact_class` | Required doctrine-aligned policy artifact class. |
| `artifact_version` | Required policy artifact version. |
| `authority_lineage_id` | Required stable identifier for the source authority record. |
| `authority_key` | Required deterministic authority key. |
| `authority_source_kind` | Required source-authority discriminator. |
| `delegated_from_authority_lineage_id` | Optional direct delegation ancestor reference. |
| `revocation_lineage_metadata` | Required replay-safe revocation metadata object when authority lineage is exchanged. |

## Offline Replay Package Schema Inputs

An offline replay package constructed from this contract must declare these
inputs without inventing productization behavior:

| Input | Requirement |
|---|---|
| `package_schema_version` | Required package-level schema version. |
| `target_surface_set` | Required set of covered Phase 3 surfaces. |
| `baseline_cutoff` | Required migration/baseline cutoff reference. |
| `dependency_lineage_inputs` | Required when `P3-SURF-001` is included. |
| `policy_authority_lineage_inputs` | Required when `P3-SURF-002` is included. |
| `reconstruction_ordering_rules` | Required deterministic ordering and tie-break rules. |
| `evidence_namespace` | Required evidence namespace reference. |
| `phase2_compatibility_intent` | Required statement of admissible Phase 2 proof-substrate compatibility intent. |

The package contract is schema-input only. It must not define distribution,
authentication, user workflow, or external transport behavior.

## Runtime And Verifier Segregation

This contract must not collapse runtime/verifier trust boundaries.

Required separation rules:

- runtime systems may write persisted lineage artifacts;
- verifier systems may read persisted lineage artifacts and derive proof records;
- verifier proof must be reconstructable without runtime-only state;
- runtime-authored proof blobs are not authoritative proof under this contract;
- offline replay package generation must read persisted constitutional artifacts,
  not live runtime context.

## Phase 2 Compatibility Intent

This contract preserves compatibility intent with the admissible Phase 2 proof
substrate by requiring:

- immutable provenance identifiers;
- replay-safe field naming;
- deterministic ordering rules;
- explicit replay reconstruction inputs.

This contract does not claim full replay equivalence with Phase 2 artifacts.

## Non-Goals

This contract does not define:

- public API schema;
- external integration schema;
- runtime transport protocol;
- verifier UI or operator workflow;
- legitimacy, contradiction, regulator, or sovereign semantics.
