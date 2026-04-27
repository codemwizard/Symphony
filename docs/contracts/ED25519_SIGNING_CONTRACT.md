# ED25519 Signing Contract

Canonical-Reference: docs/contracts/ED25519_SIGNING_CONTRACT.md
Related:
- docs/architecture/SIGNATURE_METADATA_STANDARD.md
- docs/contracts/TRANSITION_HASH_CONTRACT.md
- docs/contracts/sqlstate_map.yml
- docs/contracts/ERROR_MAPPING_SPEC.md

## 1. Purpose

This contract defines the deterministic signing and verification boundary for
state-transition signatures in Symphony.

No implementation task may introduce runtime signing or signature verification
until it conforms to this contract.

## 2. Scope

This contract governs:
- canonical message construction for transition signatures
- exact byte representation of the signed payload
- accepted signature algorithm and encoding
- key-scope verification requirements
- replay and fail-closed semantics

This contract does not govern:
- key custody or HSM vendor selection
- transition-hash derivation
- data-authority derivation
- external API envelopes
- SQLSTATE registration values

## 3. Determinism Goals

The signing system MUST satisfy all of the following:
- the same logical transition input yields the same canonical payload bytes
- verification is independent of whitespace, key ordering, and serializer choice
- replay verification is possible from persisted artifacts alone
- signature acceptance is fail-closed
- no hidden runtime context may influence the signed bytes

## 4. Signature Algorithm

The only accepted algorithm for contract version 1 is:
- `Ed25519`

The following are forbidden:
- `Ed25519ph`
- `Ed448`
- ECDSA variants
- implementation-defined prehashing

Contract version:
- `signing_contract_version = 1`
- `canonicalization_version = "JCS-RFC8785-V1"`

## 5. Signed Message Model

The signed payload MUST be a JSON object with exactly these top-level keys:
- `contract_version`
- `canonicalization_version`
- `project_id`
- `entity_type`
- `entity_id`
- `from_state`
- `to_state`
- `execution_id`
- `interpretation_version_id`
- `policy_decision_id`
- `transition_hash`
- `occurred_at`

No additional top-level keys are allowed for version 1.

## 6. Field Semantics

- `contract_version`: integer; MUST be `1`
- `canonicalization_version`: string; MUST be `JCS-RFC8785-V1`
- `project_id`: UUID string in lowercase canonical form
- `entity_type`: non-empty case-sensitive string
- `entity_id`: UUID string in lowercase canonical form
- `from_state`: non-empty case-sensitive string
- `to_state`: non-empty case-sensitive string
- `execution_id`: UUID string in lowercase canonical form
- `interpretation_version_id`: UUID string in lowercase canonical form
- `policy_decision_id`: UUID string in lowercase canonical form
- `transition_hash`: lowercase hex string produced according to
  `TRANSITION_HASH_CONTRACT.md`
- `occurred_at`: UTC timestamp in RFC 3339 format with `Z` suffix and exactly
  six fractional digits

`occurred_at` MUST be persisted on the authoritative transition record before
signature payload construction begins. The exact persisted value MUST be used for
signing and replay verification. It MUST NOT be regenerated during verification,
retry, or replay.

## 7. Canonicalization Rules

The signed payload MUST be canonicalized using RFC 8785 with these constraints:
- valid UTF-8 input only
- JSON object input only
- required fields only
- no duplicate keys
- no null values
- UUIDs in lowercase canonical string form
- strings serialized exactly as JCS emits them

The canonical byte sequence is:
1. construct the JSON object with the required fields only
2. validate field presence and format
3. canonicalize with RFC 8785
4. encode canonical JSON text as UTF-8 bytes

These UTF-8 bytes are the exact bytes that MUST be signed and verified.

## 8. Signing Input

Ed25519 MUST sign the canonical UTF-8 bytes directly.

The implementation MUST NOT:
- sign pretty-printed JSON
- sign implementation-private struct encodings
- sign only a subset of fields
- sign before `transition_hash` exists

## 9. Signature Encoding and Metadata

Persisted signature artifacts MUST include:
- `algorithm`
- `key_id`
- `key_version`
- `canonicalization_version`
- `signature`
- `signing_contract_version`

Encoding rules:
- `algorithm` MUST be `Ed25519`
- `signature` MUST be base64url without padding
- metadata required by `SIGNATURE_METADATA_STANDARD.md` MUST be present where
  signatures are materialized as evidence artifacts

## 10. Key Scope Authorization

A cryptographically valid signature is not sufficient by itself.

The resolved verifier trust record for `key_id` and `key_version` MUST authorize
the key for the authority domain of the transition.

Minimum required scope checks:
- the key MUST be authorized for `project_id`
- if the key is entity-scoped or domain-scoped, it MUST also authorize the
  relevant `entity_type`
- expired, revoked, disabled, or out-of-window keys MUST fail verification

## 11. Verification Contract

Verification MUST perform these steps in order:
1. assert all required metadata fields exist
2. assert `algorithm = Ed25519`
3. assert `signing_contract_version = 1`
4. validate every signed field format
5. assert `occurred_at` was persisted before signing and is replayed from the
   authoritative persisted value
6. reconstruct the signed payload from authoritative persisted values
7. canonicalize using RFC 8785 and UTF-8
8. resolve the verifier key by `key_id` and `key_version`
9. assert the key is active and authorized for `project_id`
10. if the key carries narrower scope, assert it is authorized for the relevant
    `entity_type`
11. verify the base64url-decoded signature over the canonical bytes
12. return success only if every step succeeds

Verification MUST use authoritative persisted values only. It MUST NOT trust
caller-supplied reserialized JSON.

## 12. Failure Classes

Implementations MUST distinguish at least these failure classes:
- `SIGNATURE_METADATA_MISSING`
- `SIGNATURE_UNSUPPORTED_ALGORITHM`
- `SIGNATURE_INVALID_FIELD_FORMAT`
- `SIGNATURE_CANONICALIZATION_FAILURE`
- `SIGNATURE_KEY_NOT_FOUND`
- `SIGNATURE_KEY_SCOPE_VIOLATION`
- `SIGNATURE_DECODE_FAILURE`
- `SIGNATURE_VERIFICATION_FAILED`
- `SIGNATURE_TIMESTAMP_INVALID`

## 13. Replay and Audit Requirements

Replay verification MUST be possible from persisted artifacts alone. The system
MUST persist or be able to deterministically reconstruct:
- every field in the signed payload
- `algorithm`
- `key_id`
- `key_version`
- `canonicalization_version`
- `signing_contract_version`
- the encoded signature bytes
- the exact persisted `occurred_at` used at signing time
- sufficient trust metadata to determine whether the key was authorized for the
  transition authority domain

If any required replay artifact is absent, verification MUST fail closed.

## 14. Versioning Rules

Future contract versions MAY add fields, but only under a new
`signing_contract_version`.

Version 1 verifiers MUST reject:
- unknown required-field sets
- unknown canonicalization versions
- unsupported algorithms

Backward compatibility MUST be explicit.

## 15. Implementation Gate Conditions

Any implementation claiming to satisfy this contract MUST prove:
- canonical bytes are stable across at least two independent serializer paths
- field-order and whitespace mutations do not change verification results
- malformed UUID, timestamp, and base64url inputs fail closed
- a valid payload and signature pair verifies successfully
- a single-bit mutation in canonical bytes fails verification
- a key mismatch fails verification
- a key-scope mismatch fails verification
- a regenerated or altered `occurred_at` fails verification
