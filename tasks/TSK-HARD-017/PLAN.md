# TSK-HARD-017 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-017

- task_id: TSK-HARD-017
- title: Schema drift anomaly circuit breaker
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-016, TSK-OPS-A1-STABILITY-GATE]
- goal: Implement a per-adapter, per-rail circuit breaker that monitors the rolling
  malformed response rate using the quarantine data from TSK-HARD-016. When the
  malformed rate exceeds a configured threshold, the adapter is automatically
  suspended. Suspension blocks all further dispatch from that adapter until an
  authorized operator explicitly resumes it. No automatic recovery. Suspension and
  resume both produce evidence artifacts.
- required_deliverables:
  - malformed rate monitor (rolling window per adapter/rail, fed from quarantine
    store)
  - auto-suspend logic (rate threshold breach → adapter suspended)
  - manual operator override required to resume (no automatic recovery path)
  - suspension evidence artifact
  - resume evidence artifact (including operator_id, justification, secondary
    approval if required by TSK-HARD-092 UX controls)
  - tasks/TSK-HARD-017/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_017.json
- verifier_command: bash scripts/audit/verify_tsk_hard_017.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_017.json
- schema_path: evidence/schemas/hardening/tsk_hard_017.schema.json
- acceptance_assertions:
  - malformed rate computed per adapter_id and rail_id on a rolling window;
    window duration loaded from policy metadata (TSK-HARD-011)
  - when observed malformed rate >= circuit_breaker_threshold_rate (from policy),
    adapter state transitions to SUSPENDED automatically
  - SUSPENDED adapter rejects all dispatch attempts with named error
    (e.g. P7401 ADAPTER_SUSPENDED_CIRCUIT_BREAKER)
  - no automatic recovery path exists: adapter remains SUSPENDED until explicit
    operator resume action
  - suspension evidence artifact schema-valid and contains: adapter_id, rail_id,
    trigger_threshold, observed_rate, suspension_timestamp, policy_version_id
  - resume requires explicit operator action with: operator_id,
    justification_text, timestamp; resume action produces a resume evidence
    artifact
  - negative-path test: driving malformed rate above threshold produces suspension;
    subsequent dispatch attempt returns P7401; adapter confirmed SUSPENDED by
    direct state query; adapter does not auto-recover after time passes
  - [METADATA GOVERNANCE — FIX-7 / MICRO-FIX-2] circuit_breaker_threshold_rate and
    rolling window duration are loaded from versioned policy config (TSK-HARD-011);
    activation of a new policy version produces an evidence artifact; signed when
    signing service is available; if not available, emitted with
    unsigned_reason=DEPENDENCY_NOT_READY and re-signed with back-linkage once
    TSK-HARD-051 is complete; in-place edits to active policy version are blocked;
    runtime references policy_version_id at evaluation time
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - adapter auto-recovers without operator action => FAIL_CLOSED
  - dispatch proceeds while adapter is SUSPENDED => FAIL_CLOSED
  - suspension produces no evidence artifact => FAIL
  - threshold hardcoded rather than policy-resolved => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
