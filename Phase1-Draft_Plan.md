# Phase-1 Draft Plan (Aligned to PHASE1_CODEX_PROMPT_PACK_v2 + Rebuttal)

## Scope and Alignment Rules
- Source alignment: `PHASE1_CODEX_PROMPT_PACK_v2.md` is the task flow authority.
- Rebuttal alignment from `Codex-prompt-rebuttal.txt` is applied as mandatory constraints:
  - INV-111/112/113 are truth-sync promotions only (manifest/docs), not new implementation.
  - Do not move INV-111/112/113 evidence from `evidence/phase0/**` to `evidence/phase1/**`.
  - Replace ambiguous "zero-lock" language with: lock-risk constrained + lock-time bounded + expand/contract discipline.
  - `docs/PHASE1/phase1_contract.yml`, `scripts/audit/verify_phase1_contract.sh`, and INT-G28 are net-new deliverables.
  - Gate ID allocation is strict and non-colliding: INT-G25..INT-G28 reserved for Phase-1 additions.
- No Phase-1 ordered runner is introduced.
- Phase-0 gates remain non-regressive and mandatory.

## Phase-1 DB Change Guardrails
- No runtime DDL in production paths.
- Forward-only migrations only; never edit applied migrations.
- No destructive DDL (`DROP COLUMN`, destructive rewrites on hot paths).
- Lock-risk constrained and lock-time bounded migration posture must be preserved.
- SECURITY DEFINER hardening remains mandatory (`SET search_path = pg_catalog, public`).

## Gate Mapping (Pinned)
- INT-G25 -> INV-114 verifier (`scripts/db/verify_instruction_finality_invariant.sh`)
- INT-G26 -> INV-115 verifier (`scripts/db/verify_pii_decoupling_hooks.sh`)
- INT-G27 -> INV-116 verifier (`scripts/db/verify_rail_sequence_truth_anchor.sh`)
- INT-G28 -> Phase-1 contract verifier (`scripts/audit/verify_phase1_contract.sh`)

## Delivery Phases
1. P0: Truth-Sync Audit (read-only)
2. P1: Close governance tasks TSK-P1-001..004
3. P2: Truth-sync promotion for INV-111/112/113 (docs+manifest only)
4. P3: Phase-1 contract + phase1 evidence schema coverage + INT-G28
5. P4: Implement INV-114 (instruction finality)
6. P5: Implement INV-115 (PII decoupling)
7. P6: Implement INV-116 (rail sequence continuity)
8. P7: Phase-1 closeout verification and CI/pre-CI parity wiring

## Task List (Primary)

### TSK-P1-001 — Phase-1 Agent System Rollout (close)
- Status target: `completed`
- Deliverables:
  - Canonical references aligned across `AGENTS.md`, `.codex/agents/**`, `.cursor/agents/**`, and `docs/operations/**`.
  - Evidence: `evidence/phase1/agent_role_mapping.json` (schema-conformant).
  - Enforcement path: required by Phase-1 contract and validated through INT-G28.
- Verification:
  - `scripts/audit/verify_agent_conformance.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-002 — Phase-1 Evidence + Approval Metadata (close)
- Status target: `completed`
- Deliverables:
  - Regulated-surface evidence metadata wiring (`ai_prompt_hash`, `model_id`, `approver_id`, approval refs).
  - Evidence: `evidence/phase1/approval_metadata.json` (schema-conformant).
  - Enforcement path: required by Phase-1 contract and validated through INT-G28.
- Verification:
  - `scripts/audit/verify_evidence_harness_integrity.sh`
  - `scripts/audit/verify_remediation_trace.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-003 — Agent Conformance Verification (close)
- Status target: `completed`
- Deliverables:
  - Deterministic `scripts/audit/verify_agent_conformance.sh`.
  - Wired into pre-CI and CI paths.
  - Evidence: `evidence/phase1/agent_conformance.json` (schema-conformant).
  - Enforcement path: required by Phase-1 contract and validated through INT-G28.
- Verification:
  - `scripts/audit/verify_agent_conformance.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-004 — Verify Agent Conformance Spec (close)
- Status target: `completed`
- Deliverables:
  - `docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md` finalized.
  - Approval schemas and integration points documented.
  - Evidence: `evidence/phase1/verify_agent_conformance_spec.json`.
  - Enforcement path: required by Phase-1 contract and validated through INT-G28.
- Verification:
  - `scripts/audit/verify_task_plans_present.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-005 — Truth-Sync INV-111/112/113
- Depends on: none (must remain independent docs/manifest truth-sync work)
- Deliverables:
  - Promote INV-111/112/113 to `implemented` in manifest only after mechanical pre-checks pass.
  - Update `INVARIANTS_IMPLEMENTED.md`, `INVARIANTS_ROADMAP.md`, and regenerate quick docs.
  - Keep existing gate IDs and phase0 evidence paths unchanged.
- Verification:
  - `scripts/db/verify_boz_observability_role.sh` (INT-G23)
  - `scripts/audit/lint_pii_leakage_payloads.sh` (SEC-G17)
  - `scripts/db/verify_anchor_sync_hooks.sh` (INT-G24)
  - `scripts/audit/check_docs_match_manifest.py`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-006 — Phase-1 Contract + Evidence Schema Coverage
- Depends on: TSK-P1-001
- Deliverables:
  - Create `docs/PHASE1/phase1_contract.yml` and `docs/PHASE1/PHASE1_CONTRACT.md`.
  - Create `scripts/audit/verify_phase1_contract.sh` and wire INT-G28.
  - Extend schema validation to include `evidence/phase1/**`.
  - Add control-plane entry for INT-G28.
  - Evidence: `evidence/phase1/phase1_contract_status.json`.
  - Contract semantics (must be explicit):
    - Contract rows carry `required`, `status`, `gate_id`, `invariant_id`, `evidence_path`, and `verifier`.
    - Required entries fail when evidence is missing or schema-invalid.
    - Deferred/optional entries are explicitly marked and excluded from fail-closed required checks.
    - Phase-1 contract evidence paths are constrained to `evidence/phase1/**`.
    - Phase-1 closeout with `RUN_PHASE1_GATES=1` disallows SKIPPED outcomes for required entries.
    - `RUN_PHASE1_GATES=0`: required Phase-1 rows are not evaluated (Phase-0 non-regression mode).
    - Evidence schema/provenance envelope is mandatory for phase1 artifacts:
      - `schema_version`
      - `check_id`
      - `timestamp_utc`
      - `git_sha`
      - `status`
      - `gate_id`
      - `schema_fingerprint`
- Verification:
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/audit/verify_control_planes_drift.sh`
  - `scripts/audit/validate_evidence_schema.sh` (extended)
  - `scripts/dev/pre_ci.sh`

### TSK-P1-007 — INV-114 Instruction Finality
- Depends on: TSK-P1-002, TSK-P1-006
- Deliverables:
  - New migration(s) and trigger semantics for finality + reversal-only flow.
  - `scripts/db/verify_instruction_finality_invariant.sh`.
  - Control-plane gate INT-G25.
  - SQLSTATE registry update with P7003.
  - Tests and runtime evidence.
- Evidence:
  - `evidence/phase1/instruction_finality_invariant.json`
  - `evidence/phase1/instruction_finality_runtime.json`
- Verification:
  - `scripts/db/verify_instruction_finality_invariant.sh`
  - `scripts/db/tests/test_instruction_finality.sh`
  - `scripts/audit/check_sqlstate_map_drift.sh`
  - `scripts/audit/verify_control_planes_drift.sh`
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-008 — INV-115 PII Decoupling
- Depends on: TSK-P1-002, TSK-P1-006
- Deliverables:
  - `pii_vault` + `pii_purge_requests` expand-first migrations and append-only semantics.
  - `scripts/db/verify_pii_decoupling_hooks.sh`.
  - Control-plane gate INT-G26.
  - SQLSTATE registry update with P7004.
  - SEC-G17 compatibility (`symphony:pii_ok` markers where required).
- Evidence:
  - `evidence/phase1/pii_decoupling_invariant.json`
  - `evidence/phase1/pii_decoupling_runtime.json`
- Verification:
  - `scripts/db/verify_pii_decoupling_hooks.sh`
  - `scripts/db/tests/test_pii_decoupling.sh`
  - `scripts/audit/lint_pii_leakage_payloads.sh`
  - `scripts/audit/check_sqlstate_map_drift.sh`
  - `scripts/audit/verify_control_planes_drift.sh`
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-009 — INV-116 Rail Sequence Continuity
- Depends on: TSK-P1-002, TSK-P1-006
- Deliverables:
  - Two-step migration: expand (`rail_participant_id`, `rail_profile`) then constrain uniqueness/dispatch trigger.
  - `scripts/db/verify_rail_sequence_truth_anchor.sh`.
  - Control-plane gate INT-G27.
  - SQLSTATE registry update with P7005.
- Evidence:
  - `evidence/phase1/rail_sequence_truth_anchor.json`
  - `evidence/phase1/rail_sequence_runtime.json`
- Verification:
  - `scripts/db/verify_rail_sequence_truth_anchor.sh`
  - `scripts/db/tests/test_rail_sequence_continuity.sh`
  - `scripts/audit/check_sqlstate_map_drift.sh`
  - `scripts/audit/verify_control_planes_drift.sh`
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-010 — Phase-1 Closeout
- Depends on: TSK-P1-007, TSK-P1-008, TSK-P1-009, TSK-P1-015, TSK-P1-016, TSK-P1-017, TSK-P1-018, TSK-P1-019, TSK-P1-020, TSK-P1-024, TSK-P1-025, TSK-P1-026
- Deliverables:
  - Closeout verification across INV-111..116.
  - Deferred list explicitly retained: INV-039, INV-048.
  - CI/post-Phase0 wiring for Phase-1 verifiers.
  - Pre-CI opt-in flag wiring: `RUN_PHASE1_GATES=1`.
  - Evidence: `evidence/phase1/phase1_closeout.json`.
  - Regulator/tier-1 demo-proof claims are validated against deterministic machine evidence.
- Verification:
  - `scripts/audit/verify_control_planes_drift.sh`
  - `scripts/audit/validate_evidence_schema.sh`
  - `scripts/audit/verify_phase1_contract.sh`
  - `scripts/audit/check_docs_match_manifest.py`
  - `scripts/audit/check_sqlstate_map_drift.sh`
  - `scripts/audit/verify_remediation_trace.sh`
  - `scripts/audit/verify_ci_order.sh`
  - `scripts/dev/pre_ci.sh`
  - `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Delta Additions Required vs Earlier Current-State Summary
The earlier current-state summary identified five near-term gaps. The following tasks must be added so this plan also addresses those items:

These are platform parity hardening prerequisites, not Phase-1 business invariant implementation tasks.

### TSK-P1-011 — Fast-Checks Contract Evidence Ordering Fix
- Why: `scripts/audit/run_invariants_fast_checks.sh` runs `verify_phase0_contract_evidence_status.sh` too early when used standalone.
- Deliverables:
  - Reorder or guard contract-evidence-status execution so it runs only after relevant evidence producers.
  - Keep behavior aligned with `scripts/audit/run_phase0_ordered_checks.sh`.
- Verification:
  - `scripts/audit/run_invariants_fast_checks.sh`
  - `scripts/audit/verify_phase0_contract_evidence_status.sh`

### TSK-P1-012 — Phase-1 Task Plan/Log Enforcement Gate
- Why: plan/log enforcement currently targets `TSK-P0-*` only.
- Deliverables:
  - Extend verifier coverage to `TSK-P1-*` (or add explicit Phase-1 counterpart) with same enforcement semantics.
- Verification:
  - `scripts/audit/verify_task_plans_present.sh` (extended)
  - `scripts/dev/pre_ci.sh`

### TSK-P1-013 — Local Gate Runtime Parity Hardening (Semgrep/Docker)
- Why: local `pre_ci` can fail from environment-level blockers (`~/.semgrep` permissions, Docker socket access).
- Deliverables:
  - Deterministic local behavior and actionable failure messaging.
  - Explicit handling/documentation for Semgrep log path and Docker dependency checks.
- Verification:
  - `scripts/dev/pre_ci.sh`
  - `scripts/audit/verify_ci_toolchain.sh`

### TSK-P1-014 — Policy Seed Phase-1 Plan Closeout
- Why: `docs/operations/policy_seed_phase1_plan.md` checklist remains open despite major code changes.
- Deliverables:
  - Complete checklist with evidence-backed results.
  - Confirm deterministic outcomes and no side effects for seed checksum tests.
- Verification:
  - `bash -x scripts/db/tests/test_seed_policy_checksum.sh`
  - `scripts/db/tests/test_db_functions.sh`
  - `scripts/dev/pre_ci.sh`

### TSK-P1-015 — Ingress API MVP (Pilot-ready Surface)
- Why: convert Phase-1 controls into an actual customer integration point.
- Deliverables:
  - Minimal ingress API contract and implementation path for instruction intake.
  - Durable attestation written before ACK (fail-closed ACK discipline).
  - Deterministic request/response semantics for pilot participants.
  - Required invariants: INV-011, INV-012, INV-013, INV-028, INV-029, INV-062, INV-063, INV-064, INV-065, INV-066, INV-092, INV-105.
  - Required evidence:
    - `evidence/phase1/ingress_api_contract_tests.json`
    - `evidence/phase1/ingress_ack_attestation_semantics.json`
- Verification:
  - Contract tests for ACK-after-attestation behavior.
  - Negative test: ACK must fail closed when durable attestation write fails.
  - Evidence artifacts proving ingress acceptance/rejection paths.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-016 — Executor Worker MVP (Deterministic Dispatch Path)
- Why: make orchestration customer-visible, not just schema/gate-complete.
- Deliverables:
  - Minimal worker path from pending outbox to dispatch attempt recording.
  - Deterministic retry/failure handling with append-only attempt semantics.
  - Integration with existing outbox lease-fencing/idempotency guarantees.
  - Required invariants: INV-011, INV-012, INV-013, INV-014, INV-031, INV-032, INV-105.
  - Required evidence:
    - `evidence/phase1/executor_worker_runtime.json`
    - `evidence/phase1/executor_worker_fail_closed_paths.json`
- Verification:
  - Runtime tests for dispatch, retry, and terminal attempt behavior.
  - Negative test: failed dispatch paths must remain append-only and deterministic.
  - Evidence artifacts for worker execution outcomes.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-017 — Evidence Pack API (EaaS Customer Endpoint)
- Why: provide direct, monetizable customer-facing Evidence-as-a-Service capability.
- Deliverables:
  - Endpoint to retrieve instruction/exception evidence packs (hash-linked, auditable structure).
  - Stable response schema suitable for bank/MMO/compliance consumers.
  - Access controls aligned with tenant/participant boundaries.
  - Required invariants: INV-028, INV-029, INV-090, INV-091, INV-092, INV-093, INV-094, INV-095, INV-105.
  - Required evidence:
    - `evidence/phase1/evidence_pack_api_contract.json`
    - `evidence/phase1/evidence_pack_api_access_control.json`
- Verification:
  - API contract tests for retrieval/filtering and access control.
  - Negative test: cross-tenant evidence retrieval must fail closed.
  - Evidence proving pack retrieval and schema validity.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-018 — Exception Case Pack Generator (Ops + IPDR Pilot Primitive)
- Why: reduce investigation time and enable dispute-resolution product flow.
- Deliverables:
  - Deterministic generation of case packs for ambiguous/failed flows.
  - Standardized contents: attestation refs, attempt history, reason mapping, recommended next action.
  - Export-ready structure for participant dispute workflows.
  - Required invariants: INV-029, INV-092, INV-093, INV-095, INV-105, INV-116 (once implemented).
  - Required evidence:
    - `evidence/phase1/exception_case_pack_generation.json`
    - `evidence/phase1/exception_case_pack_completeness.json`
- Verification:
  - Tests for case-pack generation on failure classes.
  - Negative test: incomplete lifecycle reference data must fail case-pack generation deterministically.
  - Evidence proving completeness and reproducibility of generated packs.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-019 — Pilot Integration Contract + Sandbox Harness
- Why: shorten time-to-first-customer and de-risk pilot onboarding.
- Deliverables:
  - Published integration contract for pilot participant(s).
  - Sandbox harness with sample payloads, expected outcomes, and runbook.
  - Onboarding checklist covering technical + compliance handoff.
  - Required invariants: INV-028, INV-029, INV-072, INV-081, INV-105.
  - Required evidence:
    - `evidence/phase1/pilot_harness_replay.json`
    - `evidence/phase1/pilot_onboarding_readiness.json`
- Verification:
  - Replayable pilot harness run with deterministic pass/fail outcomes.
  - Negative test: malformed participant payloads must fail with deterministic contract errors.
  - Evidence artifact set for pilot readiness.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-020 — Product KPI Evidence Gate (Commercial Readiness)
- Why: prove customer value with measurable outcomes, not only gate compliance.
- Deliverables:
  - KPI definitions and evidence hooks for pilot metrics:
    - ACK determinism
    - duplicate suppression effectiveness
    - evidence/case-pack generation coverage
    - investigation turnaround indicators
  - Report artifact for product/CEO readiness reviews.
  - Required invariants: INV-028, INV-029, INV-077, INV-081.
  - Required evidence:
    - `evidence/phase1/product_kpi_readiness_report.json`
- Verification:
  - KPI evidence generation in CI/pre-CI compatible format.
  - Negative test: stale KPI report must fail freshness validation.
  - Validation script ensuring KPI report freshness and completeness.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-021 — Canonical Git Diff Library (Parity Determinism)
- Why: eliminate diff-semantics drift across gates and avoid repeated local/CI parity failures.
- Deliverables:
  - Single shared diff helper under `scripts/audit/lib/git_diff.sh`.
  - Standardized interfaces for `range`, `staged`, and `worktree` mode.
  - Refactor diff-consuming scripts to use shared helper.
  - Evidence: `evidence/phase1/git_diff_semantics.json` (mode + merge-base + refs).
- Verification:
  - Parity checks proving consistent changed-file sets across dependent scripts in the same mode.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-022 — Pilot AuthN/AuthZ + Tenant Boundary Enforcement
- Why: convert APIs from demo-safe to pilot-safe for external participants.
- Deliverables:
  - Minimal pilot authentication mode (selected and documented).
  - Tenant/participant authorization boundary enforcement on ingress + evidence APIs.
  - BoZ/read-only boundary behavior documented and verified where applicable.
  - Required invariants: INV-062, INV-063, INV-064, INV-065, INV-066, INV-105.
  - Required evidence:
    - `evidence/phase1/authz_tenant_boundary.json`
    - `evidence/phase1/boz_access_boundary_runtime.json`
- Verification:
  - Positive and negative authz tests (cross-tenant access denied).
  - `scripts/dev/pre_ci.sh`

### TSK-P1-023 — Sandbox Deployability Baseline + Redundancy Proof
- Why: prove deployability in participant VPC environments with deterministic posture checks.
- Deliverables:
  - Minimal deploy manifests for API, worker, DB connectivity, and secrets bootstrap posture.
  - Deterministic linter/check validating baseline redundancy posture and required settings.
  - Required invariants: INV-072, INV-081, INV-105, INV-110.
  - Required evidence:
    - `evidence/phase1/sandbox_deploy_manifest_posture.json`
- Verification:
  - Deploy-manifest posture checker on repo artifacts (no cluster required).
  - `scripts/dev/pre_ci.sh`

### TSK-P1-024 — INV-113 Operational Anchor-Sync Enforcement
- Why: close the gap between structural anchor hooks and operationally enforceable anchor state behavior.
- Deliverables:
  - Anchor-sync state machine semantics with deterministic transitions and crash-resume safety.
  - Mechanical enforcement that completion cannot occur unless anchor state is `ANCHORED`.
  - Verifier/test updates proving operational behavior (not just schema presence).
  - Required invariants: INV-113, INV-097, INV-105.
  - Required evidence:
    - `evidence/phase1/anchor_sync_operational_invariant.json`
    - `evidence/phase1/anchor_sync_resume_semantics.json`
- Verification:
  - DB/runtime tests for resume-after-crash and completion gating.
  - Negative test: attempt to complete without anchored state fails deterministically.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-025 — Regulator and Tier-1 Demo-Proof Pack
- Why: convert technical completion into externally defensible demonstration evidence for BoZ and pilot counterparties.
- Deliverables:
  - Scripted demo-proof artifacts for:
    - BoZ read-only seat and write-denial behavior
    - finality mutation denial
    - purge survivability post-PII deletion
    - evidence-pack retrieval API path
    - exception case-pack generation path
  - Executive-facing summary artifact linked to raw evidence.
  - Required invariants: INV-111, INV-112, INV-113, INV-114, INV-115, INV-116, INV-105.
  - Required evidence:
    - `evidence/phase1/regulator_demo_pack.json`
    - `evidence/phase1/tier1_pilot_demo_pack.json`
- Verification:
  - Deterministic replay of all demo scenarios from scripted commands.
  - `scripts/dev/pre_ci.sh`

### TSK-P1-026 — .NET 10 Lint and Quality Gate
- Why: enforce .NET code quality deterministically before customer-facing Phase-1 runtime work lands.
- Deliverables:
  - `scripts/security/lint_dotnet_quality.sh` implementing:
    - `dotnet format --verify-no-changes`
    - `dotnet build -warnaserror`
    - fail-closed behavior when .NET projects exist but toolchain is missing/failing
  - Security fast-check integration and control-plane gate registration (`SEC-G18`).
  - Required invariants: INV-081, INV-105.
  - Required evidence:
    - `evidence/phase1/dotnet_lint_quality.json`
- Verification:
  - `scripts/security/tests/test_lint_dotnet_quality.sh`
  - `scripts/audit/run_security_fast_checks.sh`
  - `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Execution Order (Current State)
Completed tranche:
1. TSK-P1-002, TSK-P1-004, TSK-P1-006, TSK-P1-021, TSK-P1-026

Remaining order:
1. TSK-P1-001, TSK-P1-003
2. TSK-P1-005
3. TSK-P1-011, TSK-P1-012, TSK-P1-013, TSK-P1-014
4. TSK-P1-007, TSK-P1-008, TSK-P1-009, TSK-P1-024
5. TSK-P1-015, TSK-P1-016
6. TSK-P1-017, TSK-P1-022
7. TSK-P1-018, TSK-P1-019, TSK-P1-023
8. TSK-P1-020, TSK-P1-025
9. TSK-P1-010

## Agent Assignment Register
- supervisor:
  - TSK-P1-001
  - TSK-P1-004
  - TSK-P1-010
  - TSK-P1-013
  - TSK-P1-019
  - TSK-P1-025
- invariants_curator:
  - TSK-P1-002
  - TSK-P1-003
  - TSK-P1-005
  - TSK-P1-006
  - TSK-P1-011
  - TSK-P1-012
  - TSK-P1-020
  - TSK-P1-021
- db_foundation:
  - TSK-P1-007
  - TSK-P1-008
  - TSK-P1-009
  - TSK-P1-014
  - TSK-P1-024
- security_guardian:
  - TSK-P1-015
  - TSK-P1-016
  - TSK-P1-017
  - TSK-P1-018
  - TSK-P1-022
  - TSK-P1-023
  - TSK-P1-026

## Non-Negotiables
- No direct push to `main`; PR-only flow.
- No gate-ID reuse/collision.
- No Phase-0 gate regressions.
- No manifest promotion without full mechanical backing.
- Every regulated-surface task must include PLAN.md, EXEC_LOG.md, and approval metadata.
