# TSK-HARD-099 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-099

- task_id: TSK-HARD-099
- title: Long-horizon audit replay continuity — five-year simulation
- phase: Hardening
- wave: 5
- depends_on: [TSK-HARD-097]
- goal: Confirm that artifacts produced today remain verifiable at a five-year
  horizon using only archived materials. The simulation must identify any
  component with a shelf life shorter than five years and define the
  archive/refresh policy for that component. No dependency on any operational
  runtime component that requires active maintenance to remain valid.
- required_deliverables:
  - five-year horizon simulation test
  - shelf life risk register
  - archive/refresh policy per component with shelf life risk
  - replay continuity evidence artifact
  - tasks/TSK-HARD-099/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_099.json
- verifier_command: bash scripts/audit/verify_tsk_hard_099.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_099.json
- schema_path: evidence/schemas/hardening/tsk_hard_099.schema.json
- acceptance_assertions:
  - simulation test verifies artifacts using only: archived PKA (TSK-HARD-070),
    archived canonicalization specs (TSK-HARD-062), archived trust anchors
    (TSK-HARD-071), archived revocation material (TSK-HARD-071), archived
    verification policy (TSK-HARD-071) — no dependency on any component that
    requires active operational maintenance to remain current
  - shelf life risk register documents every archived component and its expected
    shelf life; components with shelf life < 5 years are explicitly flagged
  - for each flagged component: an archive/refresh policy is defined that
    ensures the component remains verifiable at the five-year horizon
    (e.g. annual refresh of OCSP staples, quarterly test vector re-execution)
  - replay continuity evidence contains: simulation_timestamp,
    artifacts_verified[], archived_materials_used[], shelf_life_risks_documented[],
    refresh_policies_defined[], operational_runtime_used: false, pass
  - evidence artifact is schema-valid against verification_continuity_event class
  - negative-path test: simulating the absence of one archived component causes
    the simulation to fail with a named error — not a silent pass
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - simulation depends on any operational runtime component => FAIL_CLOSED
  - any archived component shelf life risk not documented => FAIL
  - any flagged component lacks a defined refresh policy => FAIL
  - five-year simulation not performed => FAIL
  - negative-path test absent => FAIL

---
