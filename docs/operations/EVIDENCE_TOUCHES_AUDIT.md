# Evidence vs `touches` Audit

Status: Baseline inventory captured on 2026-03-12

This document inventories current task packs whose declared `evidence:` paths
are not covered by `touches`. It also proposes cleanup batches by family.

## Rule Baseline

- Going forward, every concrete path listed under `evidence:` must also appear
  in `touches`.
- Evidence outputs complete scope but do not determine `assigned_agent`.

## Proposed Cleanup Batches

| Family | Proposed Batch Task ID | Recommended Owner |
|---|---|---|
| TASK-GOV | TASK-GOV-ETC-GOV1 | ARCHITECT |
| TASK-INVPROC | TASK-GOV-ETC-INVPROC1 | ARCHITECT |
| TASK-OI | TASK-GOV-ETC-OI1 | ARCHITECT |
| TSK-P1 | TASK-GOV-ETC-P1A | ARCHITECT |
| TSK-HARD | TASK-GOV-ETC-HARD1 | ARCHITECT |
| PERF | TASK-GOV-ETC-PERF1 | ARCHITECT |
| R | TASK-GOV-ETC-R1 | ARCHITECT |

## TASK-GOV

```text
TASK-GOV-AWC1|evidence/phase1/task_gov_awc1.json
TASK-GOV-AWC2|evidence/phase1/task_gov_awc2.json
TASK-GOV-C1|evidence/phase1/governance_c1_policy_precedence.json
TASK-GOV-C2C3|evidence/phase1/governance_c2c3_git_conventions.json
TASK-GOV-C4O4|evidence/phase1/governance_c4o4_trace_triggers.json
TASK-GOV-C5|evidence/phase1/governance_c5_path_authority.json
TASK-GOV-C6|evidence/phase1/governance_c6_invariants_quick.json
TASK-GOV-C7|evidence/phase1/governance_c7_lifecycle_taxonomy.json
TASK-GOV-O1|evidence/phase1/governance_o1_task_scaffold.json
TASK-GOV-O2|evidence/phase1/governance_o2_two_stage_approval.json
TASK-GOV-O3|evidence/phase1/governance_o3_boot_sequence.json
```

## TASK-INVPROC

```text
TASK-INVPROC-01|evidence/phase1/invproc_01_governance_baseline.json
TASK-INVPROC-02|evidence/phase1/invproc_02_register_parity.json
TASK-INVPROC-03|evidence/phase1/invproc_03_ci_gate_spec_parity.json
TASK-INVPROC-04|evidence/phase1/invproc_04_regulator_pack_template.json
TASK-INVPROC-05|evidence/phase1/invproc_05_governance_links.json
TASK-INVPROC-06|evidence/phase1/invproc_06_ci_wiring_closeout.json;evidence/phase1/human_governance_review_signoff.json
```

## TASK-OI

```text
TASK-OI-01|evidence/phase1/branch_remediation_inv134.json
TASK-OI-02|evidence/phase1/inv134_task_scaffold.json
TASK-OI-03|evidence/phase1/governance_oi03_stage_a_artifacts.json
TASK-OI-04|evidence/phase1/agent_conformance_policy_guardian.json
TASK-OI-05|evidence/phase1/conformance_spec_two_stage_alignment.json
TASK-OI-06|evidence/phase1/task_creation_process_path_alignment.json
TASK-OI-07|evidence/phase1/dep_audit_ci_wiring.json;evidence/phase1/dep_audit_gate.json
TASK-OI-08|evidence/phase1/branch_remediation_governance_bundle.json
TASK-OI-09|evidence/phase1/sec_g08_control_plane_rehome.json
TASK-OI-11|evidence/phase1/retro_scaffold_completion.json
```

## TSK-P1

```text
TSK-P1-001|evidence/phase1/agent_role_mapping.json
TSK-P1-003|evidence/phase1/agent_conformance_architect.json;evidence/phase1/agent_conformance_implementer.json;evidence/phase1/agent_conformance_policy_guardian.json
TSK-P1-004|evidence/phase1/verify_agent_conformance_spec.json
TSK-P1-005|evidence/phase0/boz_observability_role.json;evidence/phase0/pii_leakage_payloads.json;evidence/phase0/anchor_sync_hooks.json
TSK-P1-006|evidence/phase1/phase1_contract_status.json
TSK-P1-007|evidence/phase1/instruction_finality_invariant.json;evidence/phase1/instruction_finality_runtime.json
TSK-P1-008|evidence/phase1/pii_decoupling_invariant.json;evidence/phase1/pii_decoupling_runtime.json
TSK-P1-009|evidence/phase1/rail_sequence_truth_anchor.json;evidence/phase1/rail_sequence_runtime.json
TSK-P1-011|evidence/phase0/phase0_contract_evidence_status.json
TSK-P1-012|evidence/phase0/task_plans_present.json
TSK-P1-013|evidence/phase0/ci_toolchain.json
TSK-P1-014|evidence/phase0/policy_seed_checksum.json
TSK-P1-015|evidence/phase1/ingress_api_contract_tests.json;evidence/phase1/ingress_ack_attestation_semantics.json
TSK-P1-016|evidence/phase1/executor_worker_runtime.json;evidence/phase1/executor_worker_fail_closed_paths.json
TSK-P1-017|evidence/phase1/evidence_pack_api_contract.json;evidence/phase1/evidence_pack_api_access_control.json
TSK-P1-018|evidence/phase1/exception_case_pack_generation.json;evidence/phase1/exception_case_pack_completeness.json
TSK-P1-019|evidence/phase1/pilot_harness_replay.json;evidence/phase1/pilot_onboarding_readiness.json
TSK-P1-021|evidence/phase1/git_diff_semantics.json
TSK-P1-022|evidence/phase1/authz_tenant_boundary.json;evidence/phase1/boz_access_boundary_runtime.json
TSK-P1-023|evidence/phase1/sandbox_deploy_manifest_posture.json
TSK-P1-024|evidence/phase1/anchor_sync_operational_invariant.json;evidence/phase1/anchor_sync_resume_semantics.json
TSK-P1-026|evidence/phase1/dotnet_lint_quality.json
TSK-P1-027|evidence/phase1/git_diff_semantics.json;evidence/phase1/tsk_p1_027_range_only_diff_parity.json
TSK-P1-033|evidence/phase1/no_mcp_phase1_guard.json;evidence/phase1/tsk_p1_033_no_mcp_reintroduction_guard.json
TSK-P1-034|evidence/phase1/tsk_p1_034_approval_metadata_hardening.json
TSK-P1-035|evidence/phase1/ingress_api_contract_tests.json
TSK-P1-036|evidence/phase1/evidence_pack_api_access_control.json
TSK-P1-037|evidence/phase1/phase1_contract_status.json;evidence/phase0/remediation_trace.json
TSK-P1-038|evidence/phase0/db_timeout_posture.json
TSK-P1-039|evidence/phase1/ingress_hotpath_indexes.json
TSK-P1-040|evidence/phase0/n_minus_one.json
TSK-P1-041|evidence/phase1/anchor_sync_operational_invariant.json;evidence/phase1/anchor_sync_resume_semantics.json
TSK-P1-042|evidence/phase1/authz_tenant_boundary.json;evidence/phase1/exception_case_pack_generation.json;evidence/phase1/pilot_harness_replay.json
TSK-P1-043|evidence/phase1/pilot_onboarding_readiness.json;evidence/phase1/product_kpi_readiness_report.json;evidence/phase1/regulator_demo_pack.json;evidence/phase1/tier1_pilot_demo_pack.json;evidence/phase1/phase1_closeout.json
TSK-P1-044|evidence/phase1/sandbox_deploy_manifest_posture.json
TSK-P1-045|evidence/phase0/phase0_contract_evidence_status.json;evidence/phase1/phase1_contract_status.json
TSK-P1-046|evidence/phase0/remediation_trace.json;evidence/phase1/phase1_contract_status.json
TSK-P1-047|evidence/phase1/agent_conformance_architect.json;evidence/phase1/agent_conformance_implementer.json;evidence/phase1/agent_conformance_policy_guardian.json;evidence/phase1/phase1_contract_status.json
TSK-P1-048|evidence/phase1/invariant_semantic_integrity.json
TSK-P1-049|evidence/phase1/phase1_contract_status.json
TSK-P1-050|evidence/phase0/ci_toolchain.json
TSK-P1-051|evidence/phase0/control_planes_drift.json;evidence/phase1/phase1_contract_status.json
TSK-P1-052|evidence/phase1/phase1_contract_status.json;evidence/phase1/invariant_semantic_integrity.json;evidence/phase1/phase1_closeout.json
TSK-P1-053|evidence/phase1/agent_conformance_architect.json;evidence/phase1/agent_conformance_implementer.json;evidence/phase1/agent_conformance_policy_guardian.json;evidence/phase1/phase1_contract_status.json
TSK-P1-054|evidence/phase1/phase1_contract_status.json;evidence/phase1/phase1_closeout.json
TSK-P1-055|evidence/phase1/evidence_store_mode_policy.json
TSK-P1-056|evidence/phase1/perf_db_driver_bench.json
TSK-P1-057|evidence/phase1/perf_smoke_profile.json;evidence/phase1/perf_db_driver_bench.json;evidence/phase1/perf_driver_batching_telemetry.json
TSK-P1-057-FINAL|evidence/phase1/p1_057_final_perf_promotion.json
TSK-P1-058|evidence/phase1/outbox_retry_semantics.json
TSK-P1-059|evidence/phase1/tsk_p1_059__gate_script_modularization_no_behavior_changes.json
TSK-P1-060|evidence/phase1/p1_060_phase2_followthrough_gate.json
TSK-P1-061|evidence/phase1/tsk_p1_061_git_containment_rule.json
TSK-P1-062|evidence/phase1/tsk_p1_062_worktree_cleanup_and_guards.json
TSK-P1-063|evidence/phase1/tsk_p1_063_git_script_audit.json
TSK-P1-064|evidence/phase1/tsk_p1_064_git_regression_wiring.json
TSK-P1-065|evidence/phase1/tsk_p1_065_selftest_secret_posture.json
TSK-P1-066|evidence/phase1/tsk_p1_066_bounded_amount_validation.json
TSK-P1-067|evidence/phase1/tsk_p1_067_db_error_sanitization.json
TSK-P1-068|evidence/phase1/tsk_p1_068_sensitive_endpoint_rate_limits.json
TSK-P1-069|evidence/phase1/tsk_p1_069_fail_first_triage_banner.json
TSK-P1-070|evidence/phase1/tsk_p1_070_remediation_casefile_scaffolder.json
TSK-P1-071|evidence/phase1/tsk_p1_071_failure_layer_taxonomy.json
TSK-P1-072|evidence/phase1/tsk_p1_072_two_strike_escalation.json
TSK-P1-073|evidence/phase1/tsk_p1_073_remediation_artifact_freshness.json
TSK-P1-ESC-001|evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json
TSK-P1-ESC-002|evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json
```

## TSK-HARD

```text
TSK-HARD-000|evidence/schemas/hardening/tsk_hard_000.schema.json
TSK-HARD-001|evidence/schemas/hardening/tsk_hard_001.schema.json
TSK-HARD-002|evidence/schemas/hardening/tsk_hard_002.schema.json
TSK-HARD-010|evidence/schemas/hardening/tsk_hard_010.schema.json
TSK-HARD-011|evidence/phase1/hardening/tsk_hard_011.json;evidence/schemas/hardening/tsk_hard_011.schema.json
TSK-HARD-011A|evidence/schemas/hardening/tsk_hard_011a.schema.json
TSK-HARD-011B|evidence/schemas/hardening/tsk_hard_011b.schema.json
TSK-HARD-012|evidence/phase1/hardening/tsk_hard_012.json;evidence/schemas/hardening/tsk_hard_012.schema.json
TSK-HARD-013|evidence/schemas/hardening/tsk_hard_013.schema.json
TSK-HARD-013B|evidence/phase1/hardening/tsk_hard_013b.json;evidence/schemas/hardening/tsk_hard_013b.schema.json
TSK-HARD-014|evidence/phase1/hardening/tsk_hard_014.json;evidence/schemas/hardening/tsk_hard_014.schema.json
TSK-HARD-015|evidence/schemas/hardening/tsk_hard_015.schema.json
TSK-HARD-016|evidence/schemas/hardening/tsk_hard_016.schema.json
TSK-HARD-017|evidence/phase1/hardening/tsk_hard_017.json;evidence/schemas/hardening/tsk_hard_017.schema.json
TSK-HARD-020|evidence/schemas/hardening/tsk_hard_020.schema.json
TSK-HARD-021|evidence/schemas/hardening/tsk_hard_021.schema.json
TSK-HARD-022|evidence/schemas/hardening/tsk_hard_022.schema.json
TSK-HARD-023|evidence/schemas/hardening/tsk_hard_023.schema.json
TSK-HARD-024|evidence/schemas/hardening/tsk_hard_024.schema.json
TSK-HARD-025|evidence/schemas/hardening/tsk_hard_025.schema.json
TSK-HARD-026|evidence/schemas/hardening/tsk_hard_026.schema.json
TSK-HARD-030|evidence/phase1/hardening/tsk_hard_030.json;evidence/schemas/hardening/tsk_hard_030.schema.json
TSK-HARD-031|evidence/schemas/hardening/tsk_hard_031.schema.json
TSK-HARD-032|evidence/schemas/hardening/tsk_hard_032.schema.json
TSK-HARD-033|evidence/schemas/hardening/tsk_hard_033.schema.json
TSK-HARD-040|evidence/schemas/hardening/tsk_hard_040.schema.json
TSK-HARD-041|evidence/schemas/hardening/tsk_hard_041.schema.json
TSK-HARD-042|evidence/schemas/hardening/tsk_hard_042.schema.json
TSK-HARD-050|evidence/phase1/hardening/tsk_hard_050.json;evidence/schemas/hardening/tsk_hard_050.schema.json
TSK-HARD-051|evidence/schemas/hardening/tsk_hard_051.schema.json
TSK-HARD-052|evidence/phase1/hardening/tsk_hard_052.json;evidence/schemas/hardening/tsk_hard_052.schema.json
TSK-HARD-053|evidence/schemas/hardening/tsk_hard_053.schema.json
TSK-HARD-054|evidence/schemas/hardening/tsk_hard_054.schema.json
TSK-HARD-060|evidence/schemas/hardening/tsk_hard_060.schema.json
TSK-HARD-061|evidence/phase1/hardening/tsk_hard_061.json;evidence/schemas/hardening/tsk_hard_061.schema.json
TSK-HARD-062|evidence/schemas/hardening/tsk_hard_062.schema.json
TSK-HARD-070|evidence/schemas/hardening/tsk_hard_070.schema.json
TSK-HARD-071|evidence/schemas/hardening/tsk_hard_071.schema.json
TSK-HARD-072|evidence/phase1/hardening/tsk_hard_072.json;evidence/schemas/hardening/tsk_hard_072.schema.json
TSK-HARD-073|evidence/schemas/hardening/tsk_hard_073.schema.json
TSK-HARD-074|evidence/schemas/hardening/tsk_hard_074.schema.json
TSK-HARD-080|evidence/schemas/hardening/tsk_hard_080.schema.json
TSK-HARD-081|evidence/schemas/hardening/tsk_hard_081.schema.json
TSK-HARD-082|evidence/schemas/hardening/tsk_hard_082.schema.json
TSK-HARD-090|evidence/schemas/hardening/tsk_hard_090.schema.json
TSK-HARD-091|evidence/schemas/hardening/tsk_hard_091.schema.json
TSK-HARD-092|evidence/phase1/hardening/tsk_hard_092.json;evidence/schemas/hardening/tsk_hard_092.schema.json
TSK-HARD-093|evidence/schemas/hardening/tsk_hard_093.schema.json
TSK-HARD-094|evidence/phase1/hardening/tsk_hard_094.json;evidence/schemas/hardening/tsk_hard_094.schema.json
TSK-HARD-095|evidence/phase1/hardening/tsk_hard_095.json;evidence/schemas/hardening/tsk_hard_095.schema.json
TSK-HARD-096|evidence/schemas/hardening/tsk_hard_096.schema.json
TSK-HARD-097|evidence/schemas/hardening/tsk_hard_097.schema.json
TSK-HARD-098|evidence/phase1/hardening/tsk_hard_098.json;evidence/schemas/hardening/tsk_hard_098.schema.json
TSK-HARD-099|evidence/schemas/hardening/tsk_hard_099.schema.json
TSK-HARD-100|evidence/phase1/hardening/tsk_hard_100.json;evidence/schemas/hardening/tsk_hard_100.schema.json
TSK-HARD-101|evidence/phase1/hardening/tsk_hard_101.json;evidence/schemas/hardening/tsk_hard_101.schema.json
TSK-HARD-102|evidence/schemas/hardening/tsk_hard_102.schema.json
```

## PERF

```text
PERF-001|evidence/phase1/perf_001_engine_metrics_capture.json
PERF-002|evidence/phase1/perf_002_regression_detection_warmup.json
PERF-003|evidence/phase1/perf_003_rebaseline_sha_lock.json
PERF-005|evidence/phase1/perf_005__regulatory_timing_compliance_gate.json
PERF-005A|evidence/phase1/perf_005a_finality_seam_stub.json
PERF-006|evidence/phase1/perf_006__operational_risk_framework_translation_layer.json
```

## R

```text
R-000|evidence/security_remediation/r_000_containment.json
R-001|evidence/security_remediation/r_001_signing_keys.json
R-002|evidence/security_remediation/r_002_tenant_allowlist.json
R-003|evidence/security_remediation/r_003_supervisor_param_queries.json
R-004|evidence/security_remediation/r_004_token_transport.json
R-005|evidence/security_remediation/r_005_secure_equals.json
R-006|evidence/security_remediation/r_006_rate_limits.json
R-007|evidence/security_remediation/r_007_openbao_hardening.json
R-008|evidence/security_remediation/r_008_ci_image_pins.json
R-009|evidence/security_remediation/r_009_allowed_hosts.json
R-010|evidence/security_remediation/r_010_tls_docs.json
R-011|evidence/security_remediation/r_011_repo_hygiene.json
R-012|evidence/security_remediation/r_012_dev_header_gate.json
R-013|evidence/security_remediation/r_013_git_secret_audit.json
R-014|evidence/security_remediation/r_014_refactor.json
R-015|evidence/security_remediation/r_015_tests_bootstrap.json
R-016|evidence/security_remediation/r_016_runtime_selftests_extracted.json
R-018|evidence/security_remediation/r_018_policy_enforcement_map.json
R-019|evidence/security_remediation/r_019_lint_coverage.json
R-020|evidence/security_remediation/r_020_semgrep_rules.json
R-021|evidence/security_remediation/r_021_ci_sql_guard.json
R-022|evidence/security_remediation/r_022_scan_scope.json
```

## Out of Immediate Batch Scope

- The current inventory also includes Phase-0, OPS, CLEAN, and other legacy
  families not covered by the Phase-1 AWC cleanup batches above.
- `TSK-HARD-*` entries often mix concrete outputs with schema-reference paths
  under `evidence/schemas/**`; that split should be preserved during cleanup.
