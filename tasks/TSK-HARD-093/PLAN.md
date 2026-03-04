# TSK-HARD-093 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-093

- task_id: TSK-HARD-093
- title: Reporting continuity and activation controls
- phase: Hardening
- wave: 6
- depends_on: [TSK-HARD-092]
- goal: Ensure all hardening-related regulatory report outputs are signed,
  activation-controlled via signed policy bundles, and continuous. A gap in
  the report sequence produces an alert — not a silent skip. This closes the
  regulatory reporting surface of the hardening program.
- required_deliverables:
  - signed report output enforcement in reporting pipeline
  - policy bundle activation control for each report type
  - report sequence gap detection and alerting
  - tasks/TSK-HARD-093/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_093.json
- verifier_command: bash scripts/audit/verify_tsk_hard_093.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_093.json
- schema_path: evidence/schemas/hardening/tsk_hard_093.schema.json
- acceptance_assertions:
  - every hardening-related regulatory report output is signed per TSK-HARD-052
    metadata standard before delivery
  - report activation is controlled via a signed policy bundle (TSK-HARD-011B);
    report generation blocked if governing policy bundle is unsigned or inactive
  - report sequence gap detection: each report type has a sequence number or
    scheduled interval; a missing report or out-of-sequence report produces
    an alert evidence artifact — not a silent skip
  - report gap alert evidence artifact contains: report_type, expected_sequence,
    detected_gap, alert_timestamp, alert_delivered: true/false
  - report gaps are recoverable: gap alert is resolved by either producing the
    missing report (with backdated_report: true flag) or recording an explicit
    gap acknowledgement with operator justification
  - negative-path test: deliberately skipping one report in a sequence produces
    a gap alert evidence artifact within one scheduled interval
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - report output unsigned => FAIL
  - report gap produces silent skip => FAIL_CLOSED
  - report activation not controlled by signed policy bundle => FAIL
  - gap alert evidence artifact not produced => FAIL
  - negative-path test absent => FAIL

---
