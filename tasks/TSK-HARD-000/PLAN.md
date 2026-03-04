# TSK-HARD-000 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-000

- task_id: TSK-HARD-000
- title: Hardening program charter and invariant baseline
- phase: Hardening
- wave: 1
- depends_on: none
- goal: Establish the hardening charter, program governance documents, and baseline
  invariant map that all downstream tasks reference. This task produces no runtime
  code. Its output is the governance layer that makes all other tasks auditable.
- required_deliverables:
  - docs/programs/symphony-hardening/CHARTER.md
  - docs/programs/symphony-hardening/SCOPE.md
  - docs/programs/symphony-hardening/DECISION_LOG.md
  - docs/programs/symphony-hardening/MASTER_PLAN.md
  - docs/programs/symphony-hardening/WAVE_PLAN.md
  - docs/programs/symphony-hardening/TRACEABILITY_MATRIX.md
  - tasks/TSK-HARD-000/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_000.json
- verifier_command: bash scripts/audit/verify_tsk_hard_000.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_000.json
- schema_path: evidence/schemas/hardening/tsk_hard_000.schema.json
- acceptance_assertions:
  - CHARTER.md exists, is non-empty, and names the program owner and approval authority
  - SCOPE.md exists and defines in-scope and explicitly out-of-scope items
  - DECISION_LOG.md exists with at least one entry (program inception decision)
  - MASTER_PLAN.md exists and references all six waves by name
  - WAVE_PLAN.md exists and lists all Wave-1 task IDs in canonical order
  - TRACEABILITY_MATRIX.md exists with one row per hardening task ID; each row has
    columns: task_id, wave, title, depends_on, evidence_path, status
  - baseline invariant map in CHARTER.md or linked doc references all 12 hard
    invariants by ID
  - EXEC_LOG.md contains Canonical-Reference line
  - [MICRO-FIX-1] WAVE_PLAN.md lists Wave-1 task IDs in exactly this order:
    TSK-HARD-000, TSK-HARD-001, TSK-HARD-002, TSK-HARD-010, TSK-HARD-011,
    TSK-HARD-011A, TSK-HARD-012, TSK-HARD-013, TSK-HARD-014, TSK-HARD-015,
    TSK-HARD-016, TSK-HARD-017, TSK-HARD-094, TSK-HARD-101, TSK-HARD-013B,
    TSK-OPS-A1-STABILITY-GATE, TSK-OPS-WAVE1-EXIT-GATE; verifier script confirms
    this list by diffing WAVE_PLAN.md against the canonical order block in
    HARDENING_TASK_PACKS.md programmatically — not by visual inspection
  - [MICRO-FIX-6] TRACEABILITY_MATRIX.md contains TSK-HARD-013B as a distinct row
    with its own task_id, title, depends_on, and evidence_path; no row in
    TRACEABILITY_MATRIX or depends_on field in any task pack uses ID 013 to
    reference orphan/replay containment work; verifier script confirms absence of
    orphan/replay references under bare ID 013
- failure_modes:
  - any governance document missing => FAIL_CLOSED
  - TRACEABILITY_MATRIX.md absent => FAIL_CLOSED
  - invariant map references fewer than 12 invariants => FAIL
  - EXEC_LOG.md missing Canonical-Reference => FAIL
  - [MICRO-FIX-1] WAVE_PLAN.md Wave-1 task ID list does not match canonical order
    block in HARDENING_TASK_PACKS.md => FAIL_CLOSED
  - [MICRO-FIX-1] verifier uses visual inspection rather than programmatic diff
    to confirm WAVE_PLAN.md order => FAIL_REVIEW
  - [MICRO-FIX-6] TRACEABILITY_MATRIX.md missing TSK-HARD-013B row => FAIL_CLOSED
  - [MICRO-FIX-6] any task pack depends_on field references orphan/replay work
    under bare ID 013 => FAIL_CLOSED

---
