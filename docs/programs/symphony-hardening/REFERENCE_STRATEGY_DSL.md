# Reference Strategy DSL

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

This document describes the policy-driven DSL used to allocate dispatch references
for adjustment and parent-instruction dispatch flows.

## Enforcement Surface
- Enforcement schema: `evidence/schemas/hardening/reference_strategy_dsl.schema.json`
- Runtime resolution: `public.resolve_reference_strategy(rail_id)`
- Active policy table: `public.reference_strategy_policy_versions`

## Supported Strategy Types
- `SUFFIX`
- `DETERMINISTIC_ALIAS`
- `RE_ENCODED_HASH_TOKEN`
- `RAIL_NATIVE_ALT_FIELD`

Each strategy entry must include:
- `strategy_type`
- `rail_id` (specific rail or `*` wildcard)
- `max_length`
- `nonce_retry_limit`
- `collision_action`

## Governance
- Policies are versioned (`policy_version_id`)
- Active policy rows are immutable in-place
- Activation evidence may use `unsigned_reason=DEPENDENCY_NOT_READY` until signing dependency is available
