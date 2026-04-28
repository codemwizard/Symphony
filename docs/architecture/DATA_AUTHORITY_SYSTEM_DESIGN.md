# Data Authority System Design

Canonical-Reference: docs/architecture/DATA_AUTHORITY_SYSTEM_DESIGN.md
Related:
- docs/architecture/SDD.md
- docs/contracts/TRANSITION_HASH_CONTRACT.md
- docs/contracts/ED25519_SIGNING_CONTRACT.md
- docs/contracts/DATA_AUTHORITY_DERIVATION_SPEC.md
- docs/architecture/THREAT_MODEL.md

## 1. Purpose

This document defines the Wave 6 data-authority subsystem for state transitions.
It is a formal design gate, not a narrative overview.

No implementation task for Wave 6 authority may proceed unless it conforms to
this design.

## 2. Problem Statement

The state machine already exists and is partially operational. Wave 6 is not a
replacement state machine. It is a correctness layer that binds transition writes
to deterministic authority sources.

Without a formal authority model, the system is vulnerable to:
- caller-injected authority assertions
- mismatched execution and policy lineage
- non-deterministic trigger behavior
- unverifiable replay outcomes
- cross-table drift between current state and append-only transition history

## 3. Design Goals

The subsystem MUST ensure:
- every accepted transition is traceable to a valid execution context
- every accepted transition is traceable to a valid policy decision
- authority is derived from authoritative records, not caller claims
- append-only transition history remains the source of truth
- `state_current` is a projection of `state_transitions`
- replay of the same persisted inputs yields the same authority result
- trigger ordering is deterministic and explainable

## 4. Authoritative Data Sources

For Wave 6, authority is derived only from:
- `execution_records`
- `policy_decisions`
- `state_rules`
- `state_transitions`
- `state_current`

Authority by role:
- `execution_records`: execution lineage and interpretation binding
- `policy_decisions`: policy authority lineage
- `state_rules`: allowed state movement
- `state_transitions`: append-only event truth
- `state_current`: latest-state projection only

No external payload or caller field is authoritative by itself.

## 5. Authority Tuple

Every transition MUST be validated against this authority tuple:
- `project_id`
- `entity_type`
- `entity_id`
- `from_state`
- `to_state`
- `execution_id`
- `interpretation_version_id`
- `policy_decision_id`
- `transition_hash`

The tuple is authoritative only when all of the following hold:
- `execution_id` resolves to exactly one valid execution record
- the execution record has a non-null `interpretation_version_id`
- `execution_records.project_id = state_transitions.project_id`
- `policy_decisions.project_id = state_transitions.project_id`
- `policy_decision_id` resolves to exactly one valid policy decision
- `policy_decisions.entity_type = state_transitions.entity_type`
- `policy_decisions.entity_id = state_transitions.entity_id` when the policy
  decision is entity-specific
- the state movement is permitted by `state_rules`
- `transition_hash` conforms to `TRANSITION_HASH_CONTRACT.md`

These are hard invariants, not guidance.

## 6. Trust Boundary

Clients MAY submit transition candidates, but they MUST NOT be able to assert
authority directly.

The system MUST treat these client-supplied values as untrusted until verified:
- `execution_id`
- `policy_decision_id`
- `transition_hash`
- signature material
- `data_authority`

The runtime MUST derive acceptance from database state, not caller intent.

## 7. Data Model Rules

### 7.1 `state_transitions`

`state_transitions` is append-only and is the canonical event log.

Required properties:
- inserts only for business events
- no update or delete of accepted rows
- each row represents one transition decision at one point in time
- `execution_id` MUST be non-null
- `policy_decision_id` MUST be non-null
- `transition_hash` MUST be deterministic
- `data_authority` MUST be derived server-side

### 7.2 `state_current`

`state_current` is a projection table.

Required properties:
- exactly one current row per logical entity
- `last_transition_id` MUST reference the latest accepted transition
- no row in `state_current` may exist without lineage to `state_transitions`
- rebuilding from `state_transitions` MUST yield the same logical state

## 8. Authority Derivation Model

Authority acceptance is the conjunction of four gates:
1. state rule validity
2. policy authority validity
3. execution lineage validity
4. signature validity

A transition is accepted only if all four gates pass.

### 8.1 State Rule Validity

The transition from `from_state` to `to_state` for the given `entity_type` MUST
exist in `state_rules`.

### 8.2 Policy Authority Validity

`policy_decision_id` MUST:
- exist
- be unique
- correspond to the required policy domain for the transition
- remain stable for replay
- belong to the same `project_id` as the transition
- match the transition target authority scope

Minimum matching rules:
- `policy_decisions.project_id = state_transitions.project_id`
- `policy_decisions.entity_type = state_transitions.entity_type`
- `policy_decisions.entity_id = state_transitions.entity_id` when the policy
  decision is entity-specific

The authority check MUST use `policy_decision_id`, not aliases or legacy fields.

### 8.3 Execution Lineage Validity

`execution_id` MUST:
- exist
- resolve to an execution record with non-null `interpretation_version_id`
- belong to the same `project_id` as the transition
- provide the same `interpretation_version_id` used by downstream authority and
  signing verification

Minimum matching rules:
- `execution_records.project_id = state_transitions.project_id`
- `execution_records.execution_id = state_transitions.execution_id`
- `execution_records.interpretation_version_id IS NOT NULL`

### 8.4 Signature Validity

If signature enforcement is active, verification MUST conform exactly to
`ED25519_SIGNING_CONTRACT.md`.

In addition to cryptographic validity, signature acceptance MUST enforce:
- key resolution by `key_id` and `key_version`
- key authorization for `project_id`
- narrower key-scope authorization for `entity_type` when defined
- replay of the exact persisted `occurred_at` used during signing

No signature task may substitute implementation-defined payload formats.

## 9. `data_authority` Semantics

`data_authority` MUST represent a deterministic authority fingerprint for the
accepted transition. It MUST NOT be a human-entered label.

The exact derivation contract is defined in
`DATA_AUTHORITY_DERIVATION_SPEC.md`.

Version 1 rules:
- `data_authority` is derived from authoritative inputs only
- derivation MUST be deterministic
- derivation MUST be reproducible during replay
- derivation MUST NOT depend on row insertion order, trigger creation order, or
  mutable ambient context

Implementations MUST NOT ship opaque placeholders such as `non_reproducible`.

## 10. Trigger and Function Ordering

Ordering is part of the contract.

Wave 6 MUST use a single dispatcher trigger for candidate inserts into
`state_transitions`.

The dispatcher trigger MUST invoke validation in this order:
1. state rule validation
2. policy authority validation
3. signature validation
4. execution lineage validation
5. transition hash validation or recomputation check
6. data-authority derivation
7. append-only admission
8. current-state projection update

Multiple independent BEFORE triggers for Wave 6 authority evaluation are not
permitted. The implementation MUST NOT rely on trigger creation order or lexical
name ordering for determinism.

## 11. Projection Rules for `state_current`

After an accepted transition insert:
- `state_current` MUST point to the accepted latest transition
- `last_transition_id` MUST be non-null
- the projected state MUST equal the `to_state` of the accepted latest transition

If the projection cannot be updated consistently, the entire transition insert
MUST fail.

The system MUST NOT accept:
- a transition row without an updateable projection path
- a projection row with null lineage
- divergence where `state_current` contradicts latest transition history

## 12. Injection Prevention Strategy

The subsystem MUST prevent authority injection by design.

Required controls:
- runtime roles use DB API functions, not direct trusted table mutation paths
- untrusted caller fields are validated against authoritative rows
- derived authority values are computed server-side
- append-only mutation denial remains active on `state_transitions`
- `SECURITY DEFINER` functions MUST pin `search_path = pg_catalog, public`

The subsystem MUST fail closed on:
- missing authority rows
- mismatched authority lineage
- signature verification failure
- projection update failure
- transition-hash mismatch
- data-authority mismatch

## 13. Replay Determinism

Replay of persisted transition evidence MUST yield the same result for:
- acceptance or rejection
- derived `data_authority`
- current-state projection outcome

Replay MUST NOT depend on:
- trigger creation order
- locale
- serializer implementation
- wall-clock time other than persisted timestamps
- mutable external service responses

## 14. Invariants

The implementation MUST prove at least these invariants:
- no accepted transition exists without valid `execution_id`
- no accepted transition exists without valid `policy_decision_id`
- no illegal state transition is accepted
- no accepted transition can be mutated after insert
- no `state_current.last_transition_id` is null for an existing current-state row
- rebuilding `state_current` from `state_transitions` yields the same result
- derived `data_authority` is reproducible from persisted authority inputs
- `execution_records.project_id = state_transitions.project_id` for every
  accepted transition
- `policy_decisions.project_id = state_transitions.project_id` for every
  accepted transition
- `policy_decisions.entity_type = state_transitions.entity_type` for every
  accepted transition
- `policy_decisions.entity_id = state_transitions.entity_id` whenever the policy
  decision is entity-specific
- the authority path executes through one dispatcher trigger, not multiple
  independent authority triggers

## 15. Required Failure Classes

The implementation MUST distinguish at least these failure classes:
- `AUTHORITY_STATE_RULE_REJECTED`
- `AUTHORITY_POLICY_DECISION_MISSING`
- `AUTHORITY_POLICY_DECISION_MISMATCH`
- `AUTHORITY_PROJECT_SCOPE_MISMATCH`
- `AUTHORITY_ENTITY_SCOPE_MISMATCH`
- `AUTHORITY_EXECUTION_MISSING`
- `AUTHORITY_EXECUTION_UNBOUND`
- `AUTHORITY_SIGNATURE_REJECTED`
- `AUTHORITY_PROJECTION_REJECTED`

## 16. Non-Negotiable Boundaries

Wave 6 authority work MUST NOT:
- rewrite or replace the existing state-machine foundation
- trust caller-provided `data_authority`
- permit nullable lineage on accepted transitions
- introduce non-deterministic signature payload construction
- rely on unregistered error codes
- weaken append-only guarantees
