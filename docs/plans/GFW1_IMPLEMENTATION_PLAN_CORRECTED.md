# GF-W1 Implementation Plan - CORRECTED
Phase Name: GF-W1-Implementation
Phase Key: GFW1-IMPL

## Goal
Implement all 31 green finance Wave 1 tasks across 6 waves, respecting the DAG dependency chain. Each task is implemented and individually tested. `pre_ci.sh` runs once at wave completion as the gate check.

## Wave 1 — Governance Freeze (5 tasks)
All Tranche A tasks. Establishes the policy baseline before any schema or design work.

| Order | Task          | Title                              | Produces |
|-------|---------------|------------------------------------|----------|
| 1     | GF-W1-FRZ-001 | Merge governance package v2         | 7 governance docs, updated template, hardened scripts |
| 2     | GF-W1-FRZ-002 | Wire policy into AGENTS.md          | AGENTS.md green finance constraints |
| 3     | GF-W1-FRZ-003 | CI blocking wiring                  | CI workflow for green finance gates |
| 4     | GF-W1-FRZ-004 | Supersede PWRM 0070-0078           | Cancellation doc for old migration plan |
| 5     | GF-W1-FRZ-005 | Create volatility map               | GREEN_FINANCE_VOLATILITY_MAP.md classification |

**Wave 1 gate:** `bash scripts/dev/pre_ci.sh`

## Wave 2 — Governance Tooling + Design Start (5 tasks)
Tranche B tooling (parallel) + first design document.

| Order | Task          | Title                              | Produces |
|-------|---------------|------------------------------------|----------|
| 1     | GF-W1-GOV-001 | Structured second-pilot test enforcement | Updated `verify_task_meta_schema.sh`, sector classes |
| 2     | GF-W1-GOV-002 | AST neutral schema verifier         | verify_neutral_schema_ast.py |
| 3     | GF-W1-GOV-003 | Migration sidecar manifests        | verify_migration_meta_alignment.py |
| 4     | GF-W1-GOV-005 | Migration sequence guard            | verify_migration_sequence.sh |
| 5     | GF-W1-GOV-006 | Phase 2 entry gate                 | Phase 2 blocking gate script |
| 6     | GF-W1-DSN-001 | Adapter contract interface skeleton | ADAPTER_CONTRACT_INTERFACE.md |

**Wave 2 gate:** `bash scripts/dev/pre_ci.sh`

## Wave 3 — Design Completion + Governance Gates + First Schema (5 tasks)
Finish design specs, create remaining governance gates, land first migration.

| Order | Task          | Title                              | Migration |
|-------|---------------|------------------------------------|-----------|
| 1     | GF-W1-DSN-002 | Interpretation pack exact schema    | INTERPRETATION_PACK_SCHEMA.md |
| 2     | GF-W1-DSN-003 | Interpretation pack validation spec | INTERPRETATION_PACK_VALIDATION_SPEC.md |
| 3     | GF-W1-GOV-004 | Pilot activation gate               | verify_pilot_activation_gate.sh |
| 4     | GF-W1-GOV-006 | Phase 2 entry gate                 | Phase 2 blocking gate script |
| 5     | GF-W1-SCH-001 | Migration 0070: adapter_registrations | 0070_gf_adapter_registrations.sql + sidecar |

**Wave 3 gate:** `bash scripts/dev/pre_ci.sh`

## Wave 4 — Schema Chain (8 tasks)
Sequential Phase 0 schema migrations. Each depends on the previous.

| Order | Task          | Title                              | Migration |
|-------|---------------|------------------------------------|-----------|
| 1     | GF-W1-SCH-002A | projects + methodology_versions (corrective foundation) | 0097-0098 |
| 2     | GF-W1-SCH-003 | monitoring_records                  | 0099 |
| 3     | GF-W1-SCH-004 | evidence_nodes + evidence_edges      | 0100 |
| 4     | GF-W1-SCH-005 | asset_batches + lifecycle + retirement | 0101 |
| 5     | GF-W1-SCH-006 | regulatory plane + jurisdictions    | 0078-0079 |
| 6     | GF-W1-SCH-007 | schema closeout verifier wiring     | CI wiring only |
| 7     | GF-W1-SCH-008 | verifier_registry + Reg 26 constraint | 0087 |
| 8     | GF-W1-GOV-005A | ownership/reference-order fail-closed verifier | no migration |

**Wave 4 gate:** `bash scripts/dev/pre_ci.sh`

## Wave 5 — Schema Closeout + Phase 1 Functions Start (5 tasks)
Complete Phase 0 schema, begin Phase 1 host functions.

| Order | Task          | Title                              | Migration |
|-------|---------------|------------------------------------|-----------|
| 1     | GF-W1-SCH-009 | Phase 0 closeout — promote invariants | CI wiring only |
| 2     | GF-W1-FNC-001 | register_project, activate_project  | 0080 |
| 3     | GF-W1-FNC-002 | record_monitoring_record            | 0081 |
| 4     | GF-W1-FNC-003 | attach_evidence, link_evidence_to_record | 0082 |
| 5     | GF-W1-FNC-004 | record_authority_decision, attempt_lifecycle_transition | 0083 |

**Wave 5 gate:** `bash scripts/dev/pre_ci.sh`

## Wave 6 — Functions Closeout + Pilot (5 tasks)
Complete remaining functions (with FNC-007→FNC-005 ordering constraint) and register first pilot.

| Order | Task          | Title                              | Migration |
|-------|---------------|------------------------------------|-----------|
| 1     | GF-W1-FNC-006 | issue_verifier_read_token           | 0086 |
| 2     | GF-W1-FNC-007 | confidence enforcement + issuance gate | 0087 |
| 3     | GF-W1-FNC-005 | issue_asset_batch, retire_asset_batch | 0084 |
| 4     | GF-W1-PLT-001 | Register PWRM0001 adapter           | ZERO migrations |

**⚠️ WARNING:** FNC-007 (migration 0087) must complete before FNC-005 (migration 0084). DAG order, not numeric order.

**Wave 6 gate:** `bash scripts/dev/pre_ci.sh` + checkpoint/WAVE-1-COMPLETE

## Verification Strategy
- **Per task:** Run the task's own verification commands (verifier scripts, evidence validation, negative tests)
- **Per wave:** Run `bash scripts/dev/pre_ci.sh` once at wave completion as the full gate check
- **Final:** After Wave 6, verify checkpoint/WAVE-1-COMPLETE criteria — second pilot can begin by registering a new adapter row with zero migrations

## Execution Rules
- Each task's `meta.yml` status transitions: planned → in-progress → completed
- `PLAN.md` must exist before status = in-progress
- `EXEC_LOG.md` is append-only during execution
- Evidence JSON must exist before status = completed
- No task may skip its negative tests
- `pre_ci.sh` runs only once per wave, not per task

## Corrected Migration Numbers
This plan uses the CORRECTED migration numbers from the updated DAG:
- SCH-002A: 0097-0098 (projects + methodology_versions foundational corrective root)
- SCH-003: 0099 (monitoring_records)
- SCH-004: 0100 (evidence_nodes + evidence_edges)
- SCH-005: 0101 (asset lifecycle tables)
- SCH-006: 0078-0079 (regulatory plane + jurisdictions)
- SCH-007: CI wiring only (Phase-0 schema closeout verifier wiring)
- SCH-008: 0087 (verifier_registry)
- FNC-001: 0080 (register/activate_project)
- FNC-002: 0081 (record_monitoring_record)
- FNC-003: 0082 (evidence functions)
- FNC-004: 0083 (authority decisions + transitions)
- FNC-005: 0084 (issue/retire asset_batch)
- FNC-006: 0086 (verifier read token)
- FNC-007: 0087 (confidence enforcement + issuance gate)
