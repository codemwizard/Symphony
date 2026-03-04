# TSK-HARD-016 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-016

- task_id: TSK-HARD-016
- title: Malformed response quarantine and evidence capture
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-015, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a dedicated quarantine store for malformed, toxic, or unparseable
  provider payloads. Malformed responses must be captured as classified evidence
  artifacts — not routed to generic error handlers, not silently dropped, not
  stored with unbounded payload size. The quarantine store is the basis for the
  schema drift circuit breaker in TSK-HARD-017.
- required_deliverables:
  - malformed payload quarantine store (persistent, queryable)
  - streaming capture with hard truncation policy (first N KB, N from policy config)
  - payload hash stored alongside truncated capture
  - parser classification logic: TRANSPORT, PROTOCOL, SYNTAX, SEMANTIC
  - retention lifecycle policy per quarantine record
  - OOM-safe capture (test with oversized payload)
  - quarantine evidence artifact
  - tasks/TSK-HARD-016/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_016.json
- verifier_command: bash scripts/audit/verify_tsk_hard_016.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_016.json
- schema_path: evidence/schemas/hardening/tsk_hard_016.schema.json
- acceptance_assertions:
  - quarantine capture occurs regardless of upstream HTTP status code returned to
    caller; caller response must not prevent quarantine creation; a malformed
    payload that causes a 500 response to the caller must still produce a quarantine
    record — absence of quarantine record when any response was returned is the
    failure condition, not the HTTP status code itself
  - hard truncation: captured payload is truncated to first N KB before storage;
    N is loaded from policy metadata (TSK-HARD-011); no unbounded write permitted
  - payload hash (of full pre-truncation payload where possible, or of truncated
    payload with truncation_applied: true flag) stored with each record
  - parser classification applied and stored per record: exactly one of TRANSPORT,
    PROTOCOL, SYNTAX, SEMANTIC
  - retention lifecycle policy defined per classification type: duration and action
    (archive or purge) at expiry; loaded from policy metadata
  - OOM-safe test: sending payload larger than 10× truncation threshold completes
    without OOM; only first N KB captured
  - quarantine evidence artifact is schema-valid against malformed_quarantine_event
    schema (registered in TSK-HARD-002) and contains: quarantine_id,
    adapter_id, rail_id, classification, truncation_applied, payload_hash,
    capture_timestamp, retention_policy_version_id
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] truncation threshold N and
    retention lifecycle are loaded from versioned policy config; activation of a
    new policy version produces an evidence artifact; signed when signing service
    is available; if not available, emitted with unsigned_reason=DEPENDENCY_NOT_READY
    and re-signed with back-linkage once TSK-HARD-051 is complete; in-place edits
    to active policy version are blocked; runtime references policy_version_id at
    capture time
  - negative-path test: sending known-malformed payload to adapter produces quarantine
    record with correct classification; absence-of-quarantine is the failure
    condition regardless of HTTP status returned to caller
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - quarantine capture absent when any response (including 500) was returned
    to caller => FAIL_CLOSED [capture must occur regardless of HTTP status]
  - unbounded payload write permitted => FAIL_CLOSED
  - OOM on oversized payload => FAIL_CLOSED
  - parser classification absent from quarantine record => FAIL
  - truncation threshold or retention lifecycle hardcoded => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
