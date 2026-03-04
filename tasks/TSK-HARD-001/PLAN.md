# TSK-HARD-001 PLAN

Canonical Source: docs/programs/symphony-hardening/HARDENING_TASK_PACKS.md

## Canonical Task Pack Block

### TSK-HARD-001

- task_id: TSK-HARD-001
- title: Trust invariants documentation freeze
- phase: Hardening
- wave: 1
- depends_on: [TSK-HARD-000]
- goal: Produce TRUST_INVARIANTS.md — the human-readable, institutionally legible
  specification of all 12 hard invariants. This document is the primary artifact
  shown to institutional buyers, regulators, and auditors before any runtime
  demonstration. It must be complete, frozen, and independently verifiable against
  the codebase without running any test.
- required_deliverables:
  - docs/programs/symphony-hardening/TRUST_INVARIANTS.md
  - tasks/TSK-HARD-001/EXEC_LOG.md
  - evidence/phase1/hardening/tsk_hard_001.json
- verifier_command: bash scripts/audit/verify_tsk_hard_001.sh
- evidence_path: evidence/phase1/hardening/tsk_hard_001.json
- schema_path: evidence/schemas/hardening/tsk_hard_001.schema.json
- acceptance_assertions:
  - TRUST_INVARIANTS.md exists and contains exactly 12 invariant entries
  - each invariant entry contains all of: invariant_id, plain_language_statement,
    enforcement_layer (one or more of: DB / API / CI / runtime),
    violation_impact_description, test_mapping (reference to specific verifier
    script or CI check that enforces this invariant)
  - no invariant entry has an empty or placeholder value in any field
  - TRUST_INVARIANTS.md is referenced from TRACEABILITY_MATRIX.md
  - verifier script confirms invariant count >= 12 and all required fields present
    by parsing TRUST_INVARIANTS.md programmatically (not by visual inspection)
  - EXEC_LOG.md contains Canonical-Reference line
- failure_modes:
  - TRUST_INVARIANTS.md missing => FAIL_CLOSED
  - fewer than 12 invariants documented => FAIL
  - any invariant entry missing a required field => FAIL
  - verifier relies on visual inspection only (no programmatic parse) => FAIL_REVIEW

---
