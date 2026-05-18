# Phase 3 Runtime/Verifier Segregation Contract

Constitutional-Status: IMPLEMENTED
Interpretation-Authority: PHASE
NotebookLM-Ingestion: CANONICAL
Authority-Rank: 3
Phase-Scope: PHASE-3
Surface: P3-SURF-012
Task: TSK-P3-WP-012

## Purpose

This contract defines the canonical runtime/verifier trust boundary for
Phase 3. It establishes replay-addressable artifact exchange, privilege
separation, and anti-trust-collapse rules without introducing generic
authentication redesign, portal workflow semantics, or external disclosure
packaging.

## Boundary Position

Phase 3 treats runtime and verification as distinct constitutional actors.
Runtime may emit constitutional artifacts. Verifiers may consume declared
artifacts and produce verifier-only findings. Runtime-authored verifier proof
is prohibited. Shared runtime/verifier trust context is prohibited. Verifier
mutation of runtime lineage truth is prohibited.

## Runtime-Emitted Artifact Classes

| Artifact Class | Producer | Consumer | Replay Addressable | Mutation Rule |
|---|---|---|---|---|
| Lineage truth records | Runtime | Verifier | yes | Runtime append-only; verifier read-only |
| Projection findings | Runtime | Verifier | yes | Runtime may supersede by declared policy; verifier may not mutate |
| Contradiction/failure records | Runtime surfaces | Verifier | yes | Verifier may inspect only |
| Segregation manifests | Governance/runtime packaging | Verifier | yes | Immutable once emitted for a given version |

## Verifier-Consumed Artifact Classes

| Artifact Class | Purpose | Prohibited Action |
|---|---|---|
| Runtime lineage truth | Replay substrate | Verifier may not rewrite or delete |
| Authority/COI findings | Independence boundary input | Verifier may not reinterpret locally |
| Failure continuity findings | Evidence continuity input | Runtime may not author verifier conclusions |
| Segregation manifest | Boundary declaration | Neither side may silently bypass |

## Privilege Separation Rules

- Verifier execution surfaces are privilege-separated from runtime mutation
  paths.
- Runtime credentials may not mint verifier findings.
- Verifier credentials may not write runtime lineage truth.
- Artifact exchange is replay-addressable and deterministic.
- Verifier-only conclusions remain verifier-owned and cannot be back-written
  into runtime truth as if runtime had authored them.

## Anti-Trust-Collapse Rules

- No shared trust context between runtime and verifier.
- No runtime-authored verifier proof.
- No verifier mutation of runtime lineage truth.
- No undeclared artifact exchange authority.
- No silent dependency on generic auth redesign or portal-product behavior.

## Dependency Anchors

This contract consumes but does not redefine:

- `TSK-P3-WP-005` failure continuity substrate
- `TSK-P3-WP-006` authority scope substrate
- `TSK-P3-WP-008` conflict-of-interest and verifier-independence substrate

## Evidence And Replay

The segregation contract itself is a machine-readable constitutional reference.
Replay reconstruction depends on declared artifact paths, deterministic
boundary rules, and explicit prohibited mutations. The contract is
descriptive-only for the boundary and does not itself implement authentication,
portal workflow, or disclosure packaging.
