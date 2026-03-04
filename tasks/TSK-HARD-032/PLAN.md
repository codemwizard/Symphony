# TSK-HARD-032 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-032

- task_id: TSK-HARD-032
- title: Length-aware canonicalization and alias collision detection
- phase: Hardening
- wave: 3
- depends_on: [TSK-HARD-031]
- goal: Implement length-aware pre-dispatch canonicalization of outbound
  references to per-rail field length limits. Adapter-level outbound validation
  rejects references that exceed rail limits before they reach the wire.
  Truncation collision detection identifies cases where two distinct allocated
  references truncate to the same wire-level value, producing a collision
  evidence artifact rather than silently dispatching a duplicate.
- required_deliverables:
  - per-rail max length config (loaded from policy metadata)
  - pre-dispatch canonicalization to per-rail max length
  - adapter-level outbound field validation
  - truncation collision detection
  - collision evidence artifact on truncation collision
  - tasks/TSK-HARD-032/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_032.json
- verifier_command: bash scripts/audit/verify_tsk_hard_032.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_032.json
- schema_path: evidence/schemas/hardening/tsk_hard_032.schema.json
- acceptance_assertions:
  - per-rail max reference field length is loaded from policy metadata (not
    hardcoded per rail name); policy_version_id referenced at canonicalization time
  - outbound reference is canonicalized to per-rail max length before dispatch;
    canonicalization is deterministic given the same input and policy version
  - adapter-level validation rejects any outbound reference that exceeds the
    rail's max field length after canonicalization; rejection produces a named
    error (e.g. P7901 REFERENCE_LENGTH_EXCEEDED)
  - truncation collision detection: before dispatching a canonicalized reference,
    the registry is checked for any existing entry with the same
    post-canonicalization value but a different pre-canonicalization value;
    if found, this is a truncation collision
  - truncation collision produces an evidence artifact and blocks dispatch;
    the artifact contains: original_reference, truncated_reference,
    colliding_registry_entry_id, outcome: TRUNCATION_COLLISION_BLOCKED
  - duplicate detection test: two distinct full-length references that truncate
    to the same value are detected as a truncation collision before the second
    is dispatched
  - [METADATA GOVERNANCE] per-rail max length config is versioned; activation
    produces evidence artifact; signed when available; unsigned_reason field
    if not; in-place edits blocked; runtime references policy_version_id
  - negative-path test: dispatching a reference that exceeds rail max length
    is rejected with P7901; wire is not touched
  - negative-path test: dispatching a reference whose truncated form collides
    with an existing registry entry produces truncation collision evidence
    and dispatch is blocked
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - reference dispatched without length canonicalization => FAIL
  - reference exceeding rail max length dispatched to wire => FAIL_CLOSED
  - truncation collision not detected => FAIL_CLOSED
  - truncation collision produces no evidence artifact => FAIL
  - per-rail max length hardcoded => FAIL_CLOSED [METADATA GOVERNANCE violation]
  - negative-path tests absent => FAIL

---
