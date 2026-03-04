# TSK-HARD-031 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-031

- task_id: TSK-HARD-031
- title: Dispatch reference allocation and registry
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-030]
- goal: Implement the dispatch reference registry and the runtime allocation engine
  that applies the strategy DSL from TSK-HARD-030. The registry is a persistent,
  queryable store. Alias generation includes nonce retry on collision up to the
  configured limit. Every collision event — whether resolved by retry or not —
  produces an evidence artifact. The registry entry is created before dispatch,
  not after.
- required_deliverables:
  - dispatch reference registry (persistent, queryable store)
  - allocation engine implementing all four DSL strategy types
  - nonce retry logic with configurable max_retry limit
  - collision evidence artifact
  - pre-dispatch registry registration enforcement
  - tasks/TSK-HARD-031/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_031.json
- verifier_command: bash scripts/audit/verify_tsk_hard_031.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_031.json
- schema_path: evidence/schemas/hardening/tsk_hard_031.schema.json
- acceptance_assertions:
  - dispatch reference registry is a persistent store queryable by: reference,
    instruction_id, adjustment_id, allocation_timestamp, strategy_used
  - allocation engine implements all four strategy types defined in TSK-HARD-030
    DSL; strategy resolved from per-rail policy at allocation time
  - registry entry is created and committed before dispatch is attempted;
    dispatch without a registry entry is blocked (see TSK-HARD-033)
  - each registry entry contains: registry_id, instruction_id, adjustment_id
    (nullable), allocated_reference, strategy_used, policy_version_id,
    allocation_timestamp, collision_retry_count
  - on collision: nonce incremented and retry attempted up to max_retry_limit
    (from DSL policy); each retry logged on the registry entry
  - if max_retry_limit is reached without resolving collision: allocation fails
    with named error (e.g. P7801 REFERENCE_ALLOCATION_RETRY_EXHAUSTED) and
    produces a collision exhaustion evidence artifact
  - collision evidence artifact contains: reference_attempted, collision_count,
    strategy_used, outcome: EXHAUSTED or RESOLVED
  - [METADATA GOVERNANCE] max_retry_limit and strategy selection are loaded from
    versioned DSL policy config (TSK-HARD-030); activation produces evidence
    artifact; signed when available; unsigned_reason=DEPENDENCY_NOT_READY if not;
    in-place edits to active version blocked; runtime references policy_version_id
  - negative-path test: forcing collision exhaustion (all nonce variations
    collide) produces P7801 and exhaustion evidence artifact; no registry entry
    committed with unresolved reference
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - dispatch proceeds without registry entry => FAIL_CLOSED
  - collision silently retried without logging retry count => FAIL
  - collision exhaustion produces no evidence artifact => FAIL
  - allocation engine does not implement all four strategy types => FAIL
  - max_retry_limit hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
