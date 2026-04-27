# Transition Hash Contract

Canonical-Reference: docs/contracts/TRANSITION_HASH_CONTRACT.md
Related:
- docs/contracts/ED25519_SIGNING_CONTRACT.md
- docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md
- docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md

## 1. Purpose

This contract defines the deterministic derivation of `transition_hash` for
state transitions.

`transition_hash` is a content-addressable identifier of the transition payload.
It is a required input to:
- signature construction
- authority validation
- data-authority derivation

No implementation may compute or persist `transition_hash` outside this
contract.

## 2. Scope

This contract governs:
- the exact input field set for `transition_hash`
- canonicalization rules
- hash algorithm and output encoding
- ordering relative to signature generation
- replay and mismatch behavior

This contract does not govern:
- key management
- signature verification
- authority fingerprint derivation
- SQLSTATE assignment

SQLSTATE mappings for failure classes named here MUST be registered separately in
`docs/contracts/sqlstate_map.yml`.

## 3. Determinism Requirements

`transition_hash` MUST satisfy all of the following:
- identical logical input yields identical hash output
- hash output is independent of field ordering, whitespace, and serializer choice
- hash output is reproducible from persisted authoritative inputs alone
- hash computation occurs before signature generation
- hash computation excludes mutable, environment-derived, and post-signature data

## 4. Input Fields

The hash MUST be derived from exactly these fields:
- `project_id`
- `entity_type`
- `entity_id`
- `from_state`
- `to_state`
- `execution_id`
- `interpretation_version_id`
- `policy_decision_id`

The following MUST NOT be included:
- `signature`
- signature metadata
- `data_authority`
- timestamps, including `occurred_at`, `created_at`, `updated_at`
- database-generated IDs
- trigger-order artifacts
- mutable environment-derived values
- transport-only metadata

## 5. Field Semantics

- `project_id`: UUID string in lowercase canonical 8-4-4-4-12 form
- `entity_type`: non-empty case-sensitive string
- `entity_id`: UUID string in lowercase canonical 8-4-4-4-12 form
- `from_state`: non-empty case-sensitive string
- `to_state`: non-empty case-sensitive string
- `execution_id`: UUID string in lowercase canonical 8-4-4-4-12 form
- `interpretation_version_id`: UUID string in lowercase canonical 8-4-4-4-12 form
- `policy_decision_id`: UUID string in lowercase canonical 8-4-4-4-12 form

Null values are forbidden.

## 6. Canonicalization

Canonicalization MUST follow:
- JSON Canonicalization Scheme (RFC 8785)
- UTF-8 encoding
- object input only
- required fields only
- no duplicate keys
- no null values
- UUIDs in lowercase canonical string form
- strings preserved exactly and compared case-sensitively

The canonical byte sequence is:
1. construct a JSON object containing exactly the required fields
2. validate field presence and format
3. canonicalize with RFC 8785
4. encode canonical JSON as UTF-8 bytes

## 7. Hash Algorithm

- Algorithm: SHA-256
- Output encoding: lowercase hexadecimal
- Output length: exactly 64 characters

## 8. Derivation Procedure

`transition_hash` MUST be computed as:

1. Construct a JSON object with the required fields only
2. Validate all field formats and non-null requirements
3. Canonicalize using RFC 8785
4. Encode as UTF-8 bytes
5. Compute SHA-256 digest
6. Encode digest as lowercase hex

## 9. Ordering Constraints

The following ordering is mandatory:

1. `transition_hash` is computed
2. signature payload is constructed and includes `transition_hash`
3. signature is computed
4. `data_authority` is derived using `transition_hash` and signature outcome

Any implementation that computes signature before `transition_hash` is invalid.

## 10. Replay Requirements

Given persisted authoritative inputs, recomputing `transition_hash` MUST yield
the same value.

Mismatch MUST result in rejection.

Replay MUST NOT depend on:
- wall-clock time
- locale
- serializer implementation
- trigger order
- environment variables
- caller-provided hash values

## 11. Failure Classes

Implementations MUST distinguish at least these failure classes:
- `TRANSITION_HASH_INPUT_INVALID`
- `TRANSITION_HASH_CANONICALIZATION_FAILURE`
- `TRANSITION_HASH_MISMATCH`

## 12. Versioning

- `transition_hash_version = 1`

Future versions MUST NOT change behavior without a version bump.

## 13. Non-Negotiable Rules

Implementations MUST NOT:
- include signature or signature metadata in the hash input
- include `data_authority` in the hash input
- include timestamps in the hash input
- accept caller-supplied `transition_hash` as authoritative
- recompute using a different field set at verification time
