# Wave 6 Contract Pack

This folder is a self-contained packaging set for the Wave 6 authority/signature
hardening documents. It is intentionally kept separate from the repo's canonical
documentation locations so the contents can be reviewed, shared, or pasted
manually without mutating the authoritative doc tree.

## Contents

- `TRANSITION_HASH_CONTRACT.md`
- `DATA_AUTHORITY_DERIVATION_SPEC.md`
- `ED25519_SIGNING_CONTRACT.md`
- `DATA_AUTHORITY_SYSTEM_DESIGN.md`
- `sqlstate_map.wave6.merge.json`

## Document Roles

- `TRANSITION_HASH_CONTRACT.md`
  Defines the deterministic `transition_hash` primitive.
- `DATA_AUTHORITY_DERIVATION_SPEC.md`
  Defines the deterministic `data_authority` primitive.
- `ED25519_SIGNING_CONTRACT.md`
  Defines canonical signing payload construction and verification.
- `DATA_AUTHORITY_SYSTEM_DESIGN.md`
  Defines the subsystem-level runtime design, invariants, and ordering.
- `sqlstate_map.wave6.merge.json`
  Is not a replacement registry. It is a merge block for Symphony's existing
  `docs/contracts/sqlstate_map.yml` registry.

## Dependency Graph

1. `TRANSITION_HASH_CONTRACT.md`
   `transition_hash` is computed first.
2. `ED25519_SIGNING_CONTRACT.md`
   The signed payload includes `transition_hash`.
3. `DATA_AUTHORITY_DERIVATION_SPEC.md`
   `data_authority` includes `transition_hash` and signature outcome data.
4. `DATA_AUTHORITY_SYSTEM_DESIGN.md`
   References the three lower-level contracts and defines how they work
   together in the runtime path.
5. `sqlstate_map.wave6.merge.json`
   Registers the concrete error codes used by implementations of the contracts.

## Registry Note

`sqlstate_map.wave6.merge.json` exists because Symphony already has a shared
global SQLSTATE registry. The Wave 6 codes belong inside that registry and
should be merged into the existing schema rather than replacing the whole file.
