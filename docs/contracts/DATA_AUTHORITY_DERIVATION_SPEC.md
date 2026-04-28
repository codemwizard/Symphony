# Data Authority Derivation Specification

Canonical-Reference: docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md
Related:
- docs/contracts/TRANSITION_HASH_CONTRACT.md
- docs/contracts/ED25519_SIGNING_CONTRACT.md
- docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md

## 1. Purpose

This specification defines the exact deterministic derivation of
`data_authority` for accepted state transitions.

`data_authority` is a cryptographic fingerprint of validated authority. It is
not a user-provided value.

## 2. Scope

This specification governs:
- the exact authoritative inputs to `data_authority`
- canonicalization rules
- derivation algorithm
- output encoding
- replay behavior
- mismatch semantics

This specification does not govern:
- transition hash derivation
- signature payload construction
- trigger orchestration
- SQLSTATE assignment

## 3. Design Principles

`data_authority` MUST be:
- derived only from authoritative persisted inputs
- deterministic
- reproducible during replay
- independent of runtime environment
- resistant to caller injection
- computed server-side only

## 4. Input Fields

`data_authority` version 1 MUST be derived from:
- `project_id`
- `entity_type`
- `entity_id`
- `execution_id`
- `interpretation_version_id`
- `policy_decision_id`
- `transition_hash`
- `signature_verification_result`
- `signing_contract_version` when signature enforcement is enabled

The following MUST hold before derivation:
- `execution_records.project_id = state_transitions.project_id`
- `policy_decisions.project_id = state_transitions.project_id`
- `policy_decisions.entity_type = state_transitions.entity_type`
- `policy_decisions.entity_id = state_transitions.entity_id` when the policy
  decision is entity-specific
- `transition_hash` conforms to `TRANSITION_HASH_CONTRACT.md`

## 5. Canonicalization

Canonicalization MUST follow:
- RFC 8785 JSON Canonicalization Scheme
- UTF-8 encoding
- object input only
- required fields only
- no additional fields
- no null values
- UUIDs in lowercase canonical string form
- booleans serialized as JSON booleans

## 6. Derivation Algorithm

`data_authority` MUST be:

SHA256(
  canonical_json({
    project_id,
    entity_type,
    entity_id,
    execution_id,
    interpretation_version_id,
    policy_decision_id,
    transition_hash,
    signature_verification_result,
    signing_contract_version
  })
)

If signature enforcement is disabled for a transition class, the implementation
MUST use a documented deterministic representation for the signature fields and
MUST NOT silently omit them without versioning.

## 7. Encoding

- lowercase hex string
- exactly 64 characters

## 8. Versioning

- `data_authority_version = 1`

The version MUST be persisted or deterministically derivable.

## 9. Constraints

The system MUST:
- compute `data_authority` server-side only
- reject any caller-supplied `data_authority`
- recompute during verification
- fail on mismatch
- use authoritative persisted values only

The system MUST NOT:
- use placeholder values such as `non_reproducible`
- depend on timestamps
- depend on trigger order
- include mutable metadata
- include caller-declared authority assertions

## 10. Replay Requirements

Given persisted authority inputs:
- recomputed `data_authority` MUST match the stored value
- mismatch MUST cause failure

Replay MUST NOT depend on:
- wall-clock time
- locale
- serializer implementation
- trigger order
- transport-specific metadata

## 11. Failure Classes

Implementations MUST distinguish at least these failure classes:
- `DATA_AUTHORITY_INPUT_INVALID`
- `DATA_AUTHORITY_DERIVATION_FAILURE`
- `DATA_AUTHORITY_MISMATCH`

## 12. Non-Negotiable Rules

Implementations MUST NOT:
- use `non_reproducible` placeholders
- skip `signature_verification_result` when signatures are enabled
- derive `data_authority` from caller input
- derive `data_authority` before `transition_hash` and signature outcome exist
