# TSK-HARD-081 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-081

- task_id: TSK-HARD-081
- title: Rail Command Center v1
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-080]
- goal: Implement the Rail Command Center v1 operational dashboard with exactly
  six specified metrics/dashboards. All six are required for acceptance. Each
  dashboard has a configurable alert threshold. Threshold breach produces a
  signed alert evidence artifact. This is the primary operational interface for
  managing the Wave-1 hardening controls in production.
- required_deliverables:
  - command center UI or API with all six dashboards
  - configurable alert thresholds per dashboard
  - alert evidence artifact per threshold breach
  - tasks/TSK-HARD-081/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_081.json
- verifier_command: bash scripts/audit/verify_tsk_hard_081.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_081.json
- schema_path: evidence/schemas/hardening/tsk_hard_081.schema.json
- acceptance_assertions:
  - all six dashboards present and individually verifiable; no dashboard may
    be deferred or merged with another:
    (1) MALFORMED_RESPONSE_RATE: rolling malformed rate per rail/adapter;
        configurable window duration; visual threshold marker; fed from
        quarantine store (TSK-HARD-016)
    (2) SCHEMA_DRIFT_ALERTS: current malformed rate vs circuit-breaker threshold
        per adapter; visual indicator when rate approaches or breaches threshold;
        shows current circuit breaker state (ACTIVE or SUSPENDED)
    (3) INQUIRY_EXHAUSTION: count of instructions currently in EXHAUSTED inquiry
        state; drill-down to instruction detail; age of each EXHAUSTED state
    (4) FINALITY_CONFLICTS: count and list of instructions in FINALITY_CONFLICT
        state; age of each conflict; responsible rail_id; time in conflict
    (5) LATE_CALLBACKS: count of orphaned attestation landing zone entries grouped
        by age bucket: 0–1h, 1–24h, 24h+; drill-down per entry
    (6) MEAN_TIME_TO_CONTAINMENT: median and 95th percentile time from
        malformed/conflict event creation to operator-acknowledged containment
        action; rolling window configurable
  - each dashboard has a configurable alert threshold loaded from policy metadata
  - threshold breach produces an alert evidence artifact schema-valid against
    an appropriate hardening event class and containing: dashboard_id,
    threshold_breached, observed_value, breach_timestamp, policy_version_id
  - all six alert thresholds independently configurable; changing one threshold
    does not affect others
  - [METADATA GOVERNANCE] dashboard thresholds and window durations are loaded
    from versioned policy config; activation of new version produces evidence
    artifact; signed when signing service available; unsigned_reason if not;
    in-place edits to active version blocked; runtime references policy_version_id
  - negative-path test: driving malformed rate above dashboard-1 threshold
    produces alert evidence artifact within one rolling window interval
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - any of the six dashboards absent => FAIL
  - any dashboard threshold not configurable => FAIL
  - threshold breach produces no alert evidence artifact => FAIL
  - alert evidence artifact not schema-valid => FAIL
  - threshold loaded from hardcoded constant => FAIL_CLOSED
    [METADATA GOVERNANCE violation]
  - negative-path test absent => FAIL

---
