# Run ID Evidence Audit

Status: Current-state audit
Owner: Operations / Governance

## Purpose

This document inventories runner-targeted JSON evidence writers that still emit
legacy JSON without `run_id`, after `TASK-GOV-AWC9` repaired the immediate
`TASK-INVPROC-06` blocker.

For this audit, "runner-targeted" means:
- the evidence path is declared in `tasks/**/meta.yml`
- the verifier is invoked from task `verification:` and is expected to be
  freshness-checked by `scripts/agent/run_task.sh`

`run_id` is required for freshness under the deterministic task runner.

## Resolved Reference Case

Resolved by `TASK-GOV-AWC9`:
- `scripts/audit/verify_invproc_06_ci_wiring_closeout.sh`
- `scripts/audit/verify_human_governance_review_signoff.sh`

These now emit `run_id` and serve as the reference implementation for
runner-targeted JSON evidence writers.

## Cleanup Batches

### Batch A — Phase-1 integrity verifier family

Proposed task ID: `TASK-GOV-RUNID-INT1`
Recommended owner role: `QA_VERIFIER`

Tasks:
- `TSK-P1-INT-001`
- `TSK-P1-INT-002`
- `TSK-P1-INT-003`
- `TSK-P1-INT-004`
- `TSK-P1-INT-005`
- `TSK-P1-INT-006`
- `TSK-P1-INT-007`
- `TSK-P1-INT-008`
- `TSK-P1-INT-009A`
- `TSK-P1-INT-009B`
- `TSK-P1-INT-010`
- `TSK-P1-INT-011`
- `TSK-P1-INT-012`

Verifier scripts:
- `scripts/audit/verify_tsk_p1_int_001.sh`
- `scripts/audit/verify_tsk_p1_int_002.sh`
- `scripts/audit/verify_tsk_p1_int_003.sh`
- `scripts/audit/verify_tsk_p1_int_004.sh`
- `scripts/audit/verify_tsk_p1_int_005.sh`
- `scripts/audit/verify_tsk_p1_int_006.sh`
- `scripts/audit/verify_tsk_p1_int_007.sh`
- `scripts/audit/verify_tsk_p1_int_008.sh`
- `scripts/audit/verify_tsk_p1_int_009a.sh`
- `scripts/audit/verify_tsk_p1_int_009b.sh`
- `scripts/audit/verify_tsk_p1_int_010.sh`
- `scripts/audit/verify_tsk_p1_int_011.sh`
- `scripts/audit/verify_tsk_p1_int_012.sh`

Evidence paths:
- `evidence/phase1/tsk_p1_int_001_claim_reframe.json`
- `evidence/phase1/tsk_p1_int_002_integrity_verifier_stack.json`
- `evidence/phase1/tsk_p1_int_003_tamper_detection.json`
- `evidence/phase1/tsk_p1_int_004_ack_gap_controls.json`
- `evidence/phase1/tsk_p1_int_005_restricted_posture.json`
- `evidence/phase1/tsk_p1_int_006_offline_bridge.json`
- `evidence/phase1/tsk_p1_int_007_dr_bundle_generator.json`
- `evidence/phase1/tsk_p1_int_008_offline_verification.json`
- `evidence/phase1/tsk_p1_int_009a_storage_policy_rescope.json`
- `evidence/phase1/tsk_p1_int_009b_restore_parity.json`
- `evidence/phase1/tsk_p1_int_010_language_sync.json`
- `evidence/phase1/tsk_p1_int_011_closeout_gate.json`
- `evidence/phase1/tsk_p1_int_012_retention_policy.json`

### Batch B — Phase-1 governance and self-test family

Proposed task ID: `TASK-GOV-RUNID-GOV1`
Recommended owner role: `QA_VERIFIER`

Tasks:
- `TSK-P1-061`
- `TSK-P1-062`
- `TSK-P1-063`
- `TSK-P1-064`
- `TSK-P1-065`
- `TSK-P1-066`
- `TSK-P1-067`
- `TSK-P1-068`
- `TSK-P1-069`
- `TSK-P1-070`
- `TSK-P1-071`
- `TSK-P1-072`
- `TSK-P1-073`
- `TASK-OI-10`
- `TASK-GOV-AWC4`

Verifier scripts:
- `scripts/audit/verify_agent_conformance.sh`
- `scripts/audit/verify_tsk_p1_061.sh`
- `scripts/audit/verify_tsk_p1_062.sh`
- `scripts/audit/verify_tsk_p1_063.sh`
- `scripts/audit/verify_tsk_p1_064.sh`
- `scripts/audit/verify_tsk_p1_065.sh`
- `scripts/audit/verify_tsk_p1_066.sh`
- `scripts/audit/verify_tsk_p1_067.sh`
- `scripts/audit/verify_tsk_p1_068.sh`
- `scripts/audit/verify_tsk_p1_069.sh`
- `scripts/audit/verify_tsk_p1_070.sh`
- `scripts/audit/verify_tsk_p1_071.sh`
- `scripts/audit/verify_tsk_p1_072.sh`
- `scripts/audit/verify_tsk_p1_073.sh`
- `scripts/audit/verify_task_pack_readiness.sh`

Representative evidence paths:
- `evidence/phase1/agent_conformance_architect.json`
- `evidence/phase1/agent_conformance_implementer.json`
- `evidence/phase1/agent_conformance_policy_guardian.json`
- `evidence/phase1/tsk_p1_061_git_containment_rule.json`
- `evidence/phase1/tsk_p1_062_worktree_cleanup_and_guards.json`
- `evidence/phase1/tsk_p1_063_git_script_audit.json`
- `evidence/phase1/tsk_p1_064_git_regression_wiring.json`
- `evidence/phase1/tsk_p1_065_selftest_secret_posture.json`
- `evidence/phase1/tsk_p1_066_bounded_amount_validation.json`
- `evidence/phase1/tsk_p1_067_db_error_sanitization.json`
- `evidence/phase1/tsk_p1_068_sensitive_endpoint_rate_limits.json`
- `evidence/phase1/tsk_p1_069_fail_first_triage_banner.json`
- `evidence/phase1/tsk_p1_070_remediation_casefile_scaffolder.json`
- `evidence/phase1/tsk_p1_071_failure_layer_taxonomy.json`
- `evidence/phase1/tsk_p1_072_two_strike_escalation.json`
- `evidence/phase1/tsk_p1_073_remediation_artifact_freshness.json`
- `evidence/phase1/task_gov_awc4_awc2_contract_repair.json`

### Batch C — Demo and closeout family

Proposed task ID: `TASK-GOV-RUNID-DEMO1`
Recommended owner role: `QA_VERIFIER`

Tasks:
- `TSK-P1-010`
- `TSK-P1-025`
- `TSK-P1-043`
- `TSK-P1-DEMO-001`
- `TSK-P1-DEMO-008`
- `TSK-P1-DEMO-009`
- `TSK-P1-DEMO-011`
- `TSK-P1-DEMO-013`
- `TSK-P1-DEMO-014`
- `TSK-P1-DEMO-015`

Representative verifier scripts:
- `scripts/audit/verify_phase1_closeout.sh`
- `scripts/audit/verify_phase1_demo_proof_pack.sh`
- `scripts/audit/verify_pilot_harness_readiness.sh`
- `scripts/audit/verify_product_kpi_readiness.sh`
- `scripts/audit/verify_tsk_p1_010.sh`
- `scripts/audit/verify_tsk_p1_025.sh`
- `scripts/audit/verify_tsk_p1_demo_001.sh`
- `scripts/audit/verify_tsk_p1_demo_008.sh`
- `scripts/audit/verify_tsk_p1_demo_009.sh`
- `scripts/audit/verify_tsk_p1_demo_011.sh`
- `scripts/audit/verify_tsk_p1_demo_013.sh`
- `scripts/audit/verify_tsk_p1_demo_014.sh`
- `scripts/audit/verify_tsk_p1_demo_015.sh`

### Batch D — Hardening and cutover family

Proposed task IDs:
- `TASK-GOV-RUNID-HARD1`
- `TASK-GOV-RUNID-CUT1`

Recommended owner role: `QA_VERIFIER`

Tasks:
- `TSK-HARD-000`
- `TSK-HARD-001`
- `TSK-HARD-002`
- `TSK-HARD-010`
- `TSK-HARD-011`
- `TSK-HARD-011A`
- `CQRS-001`
- `CUT-001`
- `CUT-002`
- `CUT-003`
- `CUT-004`
- `PROJ-002`
- `LEDGER-001`

Representative verifier scripts:
- `scripts/audit/verify_tsk_hard_000.sh`
- `scripts/audit/verify_tsk_hard_001.sh`
- `scripts/audit/verify_tsk_hard_002.sh`
- `scripts/audit/verify_tsk_hard_010.sh`
- `scripts/audit/verify_tsk_hard_011.sh`
- `scripts/audit/verify_tsk_hard_011a.sh`
- `scripts/audit/verify_cqrs_code_boundary.sh`
- `scripts/audit/verify_cut_001_one_shot_projection_cutover.sh`
- `scripts/audit/verify_cut_002_query_surface_boundary.sh`
- `scripts/audit/verify_cut_003_projection_cutover_runbook.sh`
- `scripts/audit/verify_cut_004_projection_cutover_gate.sh`
- `scripts/audit/verify_no_hot_table_external_reads.sh`
- `scripts/audit/verify_ledger_internal_model.sh`

### Batch E — Phase-0 and baseline verifier family

Proposed task ID: `TASK-GOV-RUNID-P0A`
Recommended owner role: `QA_VERIFIER`

This batch should cover the remaining Phase-0 and baseline audit verifiers that
still emit legacy JSON without `run_id`. Representative scripts include:
- `scripts/audit/verify_phase0_contract.sh`
- `scripts/audit/verify_phase0_contract_evidence_status.sh`
- `scripts/audit/verify_phase0_impl_plan.sh`
- `scripts/audit/verify_ci_order.sh`
- `scripts/audit/verify_ci_toolchain.sh`
- `scripts/audit/verify_control_planes_drift.sh`
- `scripts/audit/verify_compliance_manifest.sh`
- `scripts/audit/verify_batching_rules.sh`
- `scripts/audit/verify_task_plans_present.sh`
- `scripts/audit/generate_evidence.sh`

## Implementation Rule Going Forward

For runner-targeted JSON evidence writers:
- always emit `run_id`
- use `SYMPHONY_RUN_ID` when present
- emit a non-empty standalone run identifier when `SYMPHONY_RUN_ID` is absent

## Notes

- This is a backlog and normalization audit, not a claim that all verifiers are
  equally urgent.
- `TASK-INVPROC-06` is no longer an open defect after `TASK-GOV-AWC9`.
