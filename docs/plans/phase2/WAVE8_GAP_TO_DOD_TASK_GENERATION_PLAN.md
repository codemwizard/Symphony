# Wave 8 Final Replacement Plan

Status: Canonical planning baseline for Wave 8 task creation
Canonical reference: `docs/operations/AI_AGENT_OPERATION_MANUAL.md`

## Summary

This document is the final in-place revision plan for the existing Wave 8
closure track. It governs task-pack creation and repair. It does not certify
Wave 8 complete.

### Decisions locked

- Keep the existing `TSK-P2-W8-*` task family and revise it in place.
- Keep `asset_batches` as the sole authoritative Wave 8 boundary.
- Keep PostgreSQL as the authoritative enforcement point.
- Keep `.NET 10` as the accepted platform contract.
- Keep `TSK-P2-W8-SEC-000`, but only as a runtime/provider/evidence honesty gate.
- Treat `TSK-P2-W8-DB-007a`, `007b`, and `007c` as the authoritative split and
  treat old unsplit `TSK-P2-W8-DB-007` as superseded for execution.

### Correct framing for `SEC-000`

`.NET 10` first-party Ed25519 is accepted as part of the platform contract.
Wave 8 does not question framework availability in the abstract. Wave 8 proves
only that its evidence ran on the exact declared production-parity runtime path
and that the declared first-party Ed25519 surface is the one actually
executing.

`SEC-000` is not:
- API discovery
- framework validation
- algorithm selection
- primitive correctness
- DB enforcement proof

`SEC-000` is:
- environment fidelity proof
- provider-path fidelity proof
- evidence honesty proof

## Acceptance Law Versus Execution Pin

### Acceptance law

- Wave 8 requires the first-party platform-native `.NET 10` Ed25519
  cryptography surface.
- No third-party provider.
- No managed fallback.
- No algorithm substitution.
- Linux production parity required.

### Execution pin for this proof cycle

- Service target: `LedgerApi`
- Host: Ubuntu Server 24.04
- Deployment: Docker
- RID: `linux-x64`
- SDK image:
  `mcr.microsoft.com/dotnet/sdk@sha256:1d5e6f2c1ece7d5826bafc8a7f2d54db2c6478a0f2bd1c995d05a37c0be4783e`
- Runtime image:
  `mcr.microsoft.com/dotnet/aspnet@sha256:ed557d471a2b702b72fd1fd4835040bbbdfbd2532ae78cfc90546773d88a91d7`
- Runtime family: `.NET 10.0.0-preview.1`
- SDK family: `.NET 10.0.100-preview.1`
- Base distro: Debian 12 Bookworm slim
- OpenSSL: `3.0.18-1~deb12u2`
- Framework-dependent
- Standard JIT
- FIPS off

## Fixed Decisions

- Authoritative Wave 8 write boundary: `asset_batches` only.
- Contract authority: contract documents define canonical form, replay law,
  signature semantics, and failure classes.
- Runtime authority: SQL is the authoritative executor of those contracts at
  the Wave 8 boundary.
- `policy_decisions` and `state_transitions` remain supporting provenance and
  preauth scaffolding only. They do not count toward Wave 8 completion unless
  explicitly routed through the same authoritative `asset_batches` trigger path.
- Wave 8 must expose one semantically closed authoritative signer-resolution
  surface with explicit precedence law.
- One dispatcher trigger only is permitted on the authoritative boundary.
- No task receives completion credit for helper code, key tables, signatures,
  crypto scaffolding, or detached verification primitives unless observable
  behavior at the authoritative `asset_batches` boundary changes.
- No Wave 8 path may degrade to advisory, warning-only, or structural-only
  acceptance when cryptographic validation fails or is unavailable.
- Inability to perform cryptographic verification is itself a hard verification
  failure and must fail closed.

## Anti-Goal

Wave 8 does not certify cryptographic truth for any surface outside the
authoritative `asset_batches` write boundary unless that surface is explicitly
routed through the same authoritative trigger path and verified by the same
behavioral evidence.

## `SEC-000` Gate Definition

`TSK-P2-W8-SEC-000 - Frozen .NET 10 Ed25519 Environment Fidelity Gate`

`SEC-000` exists for exactly four reasons:

1. digest fidelity
2. runtime fidelity
3. surface fidelity
4. semantic fidelity

`SEC-000` proves Wave 8 evidence is generated on the declared
production-parity `.NET 10` runtime path and that the declared first-party
Ed25519 surface is the one actually executing.

## Evidence Admissibility Law

Evidence is inadmissible if it violates:

- first-failure isolation
- SQLSTATE provenance
- branch provenance
- role/RLS discipline
- canonical seed discipline
- migration-state discipline
- instrumentation admissibility
- runtime/provider parity discipline

Inadmissible evidence cannot satisfy acceptance.

## Task Sequence

1. `TSK-P2-W8-GOV-001`
2. `TSK-P2-W8-ARCH-001`
3. `TSK-P2-W8-ARCH-002`
4. `TSK-P2-W8-ARCH-003`
5. `TSK-P2-W8-ARCH-006`
6. `TSK-P2-W8-SEC-000`
7. `TSK-P2-W8-SEC-001`
8. `TSK-P2-W8-DB-003`
9. `TSK-P2-W8-DB-004`
10. `TSK-P2-W8-DB-005`
11. `TSK-P2-W8-DB-006`
12. `TSK-P2-W8-DB-007a`
13. `TSK-P2-W8-DB-007b`
14. `TSK-P2-W8-DB-007c`
15. `TSK-P2-W8-DB-008`
16. `TSK-P2-W8-DB-009`
17. `TSK-P2-W8-QA-001`
18. `TSK-P2-W8-QA-002`

## Task-Pack Creation Rules

Every Wave 8 task pack created from this plan must:

1. Use the repo's task-pack generation process from
   `docs/operations/TASK_CREATION_PROCESS.md`.
2. Have exactly one primary objective.
3. Explicitly populate:
   - `out_of_scope`
   - `stop_conditions`
   - `proof_guarantees`
   - `proof_limitations`
   - exact `touches`
   - exact evidence paths
4. Include approval-before-edit discipline and append-only `EXEC_LOG.md`
   markers for regulated surfaces.
5. Use negative-first verifiers with external-state inspection.
6. Require evidence that proves behavior rather than schema shape alone.

## Execution Guardrails

- A Wave 8 task pack is invalid if it spans more than one primary enforcement
  domain such as canonicalization, hashing, signer resolution, cryptographic
  verification, replay, key lifecycle, or QA evidence.
- Multi-domain work must be split into separate task packs even when the same
  file set is involved.
- Any Wave 8 runtime verifier that does not cause PostgreSQL to physically
  accept or reject a write at the authoritative `asset_batches` boundary is
  insufficient for readiness and cannot be used as completion evidence.
- Reflection-only surface proof is inadmissible.
- Toy-crypto proof is inadmissible.

## Task-Pack Revision Highlights

### `TSK-P2-W8-GOV-001`

- Must output a Wave 8 proof-integrity threat register.
- Must output an evidence admissibility policy.
- Must output a false-completion pattern catalog.
- Must state that old `W8-DB-007` is superseded by `007a/007b/007c`.
- Inadmissible proof patterns must include detached function proof, grep proof,
  reflection-only surface proof, toy-crypto proof, garbage-payload matrix
  fraud, fake crypto behind real trigger wiring, superuser-only success, and
  mirrored-vector fraud.

### `TSK-P2-W8-ARCH-003`

- Must keep signing and replay contract hardening as semantic law.
- Must require the first-party `.NET 10` Ed25519 surface.
- Must reject third-party providers and fallbacks.
- Must treat `SEC-000` as the runtime/provider fidelity gate.
- Must not turn "discover whether Ed25519 exists" into contract law.

### `TSK-P2-W8-ARCH-006`

- Must register failure classes for provider-path unavailable, unavailable
  crypto, signer precedence conflict, replay invalidity, SQLSTATE provenance
  mismatch, and branch provenance mismatch.

### `TSK-P2-W8-SEC-000`

- Intent: prove Wave 8 evidence is generated on the declared production-parity
  `.NET 10` runtime path and that the declared first-party Ed25519 surface is
  the one actually executing.
- Must prove:
  - the frozen SDK digest was used
  - the frozen runtime digest was used
  - the runtime is the declared `.NET 10` family
  - the runtime follows the declared Linux/OpenSSL path
  - the executing code resolves the declared first-party Ed25519 surface
  - the surface is actually invoked
  - sign/verify semantics work for Wave 8-shaped contract bytes
  - provider drift or runtime drift fails the gate
- Must not prove Ed25519 exists as a framework feature in the abstract.
- Method:
  - build inside frozen SDK image
  - run inside frozen ASP.NET runtime image
  - emit evidence with exact environment tuple and execution trace
- Forbidden:
  - inline C# in bash
  - host-local execution
  - verifier-only shims
  - different runtime image than production parity
- Reflection-only surface proof is inadmissible.
- Toy-crypto proof is inadmissible.

### `TSK-P2-W8-SEC-001`

- `SEC-000` proves the environment is honest.
- `SEC-001` proves the primitive is correct in that environment.
- `SEC-001` must depend on `SEC-000`.
- `SEC-001` no longer owns runtime discovery, environment honesty, or
  provider-path parity.

### `TSK-P2-W8-DB-006`

- PostgreSQL independently validates the exact `asset_batches` write.
- PostgreSQL does not trust a service claim or audit row.
- Cryptographic branch causality must be proven.
- Branch provenance must come from the same production execution path that
  emits the terminal SQLSTATE.

### `TSK-P2-W8-DB-007a / 007b / 007c`

- `007a`: scope authorization only.
- `007b`: persisted timestamp integrity only.
- `007c`: replay legality only.
- Old unsplit `007` is non-executable for closure.

### `TSK-P2-W8-QA-001`

- Contract vectors are frozen independently.
- Vectors are not implementation-generated.
- `.NET` runtime surface is the frozen `LedgerApi` path.
- SQL runtime and `.NET` runtime consume the same frozen vectors.
- QA fails if runtime vectors are regenerated from implementation logic.

### `TSK-P2-W8-QA-002`

- Reflection-only proof is inadmissible.
- Toy-crypto proof is inadmissible.
- Branch provenance must come from the production path, not wrapper-only
  markers.

## Acceptance Model

### Contract Tasks

- Must prove frozen contracts and byte-level test vectors exist.
- Must fail proof-graph validation if acceptance, verification, and evidence are
  not structurally linked.

### Runtime Tasks

Must reject:

- malformed signatures
- wrong signer or key
- wrong project scope
- wrong entity scope
- revoked keys
- expired keys
- stale or regenerated timestamps
- altered canonical inputs
- altered registry snapshots
- altered entity binding
- differently canonicalized byte representations of the same logical payload
- replay-invalid submissions
- unavailable-crypto states

Must accept:

- correctly canonicalized, correctly hashed, correctly signed payloads under an
  active authorized key

### QA Tasks

- Must prove behavior with execution traces.
- Must not rely on schema-only introspection, string-presence proofs,
  reflection-only proof, or toy-crypto proof.

## Test Plan

### `SEC-000` must fail when:

- wrong SDK digest is used
- wrong runtime digest is used
- runtime differs from declared `.NET 10` path
- the declared Ed25519 surface is not the one actually executing
- proof relies only on reflection or type presence
- proof relies only on toy sign/verify
- altered contract bytes still pass
- wrong keys still pass
- malformed signatures still pass
- evidence omits the runtime tuple or execution trace

### `SEC-000` passes only when:

- proof ran in the exact pinned environment
- the declared first-party Ed25519 surface is the one actually executing
- invocation is proven, not just symbol presence
- Wave 8-shaped bytes are used
- substitution and drift cases fail
- evidence proves runtime and provider honesty

## Default Assumptions

- Existing migrations `0168` through `0171` are structural or freshness
  scaffolding, not Wave 8 closure.
- Existing `TSK-P2-REG-*` packs are governance inputs only and cannot be used
  as Wave 8 completion evidence without the closure-track remediation.
- Existing `TSK-P2-W8-CRYPTO-*` stubs are not authoritative Wave 8 closure
  tasks and remain legacy planning artifacts unless separately reconciled.
- `.NET 10` first-party Ed25519 is accepted as part of the framework contract.
- The real risk is evidence, runtime, and provider dishonesty, not framework
  existence.
- `LedgerApi` remains the sole authoritative .NET runtime target for Wave 8
  crypto parity.
- `SEC-000` remains justified only as a narrow honesty gate.
