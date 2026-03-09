# Symphony Invariant Enforcement Matrix

## Purpose
This document converts Symphony invariants into execution controls that are immediately usable by agents, reviewers, and operators.

It provides three aligned layers:
1. `Invariant -> Automated Verification` (exact scripts/tests)
2. `Invariant -> CI Enforcement` (which workflow/job blocks merge)
3. `Invariant -> Regulator Evidence` (what artifact proves control effectiveness)

## Why This Adds Value
1. Eliminates ambiguity between "documented" and "enforced" by linking each invariant to a concrete verifier command.
2. Makes CI gating auditable by showing exactly which job enforces which invariant.
3. Creates regulator-ready proof mapping from invariant to evidence artifact.
4. Improves agent execution quality: any agent can run the same commands and produce the same evidence paths.
5. Reduces false closeout: invariants cannot be claimed complete without verifier + CI + evidence alignment.

## Canonical Sources
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/invariants/INVARIANTS_MANIFEST.yml`
- `.github/workflows/invariants.yml`
- `scripts/dev/pre_ci.sh`
- `docs/architecture/COMPLIANCE_MAP.md`

## Usage (Agent Quickstart)
1. Pick invariant IDs from `INVARIANTS_MANIFEST.yml`.
2. Run the command listed in the `Automated Verification` column.
3. Confirm the corresponding CI job exists and is blocking in `.github/workflows/invariants.yml`.
4. Confirm evidence artifact path is generated and schema-valid.
5. Only then move status to `implemented`.

This matrix is the domain-canonical source for exact verifier commands and evidence paths. Governance baselines such as `docs/governance/invariant-register-v1.md`, `docs/governance/ci-gate-spec-v1.md`, and `docs/governance/regulator-evidence-pack-template-v1.md` must defer to this file instead of restating contradictory command or evidence semantics.

## A) Invariant -> Automated Verification

| Invariant | Control Objective | Automated Verification (Exact Command/Hook) | Expected Evidence |
|---|---|---|---|
| INV-009 | SECURITY DEFINER avoids dynamic SQL/user-controlled identifiers | `TODO` in manifest (no mechanical check yet) | N/A (must not be marked implemented until verifier exists) |
| INV-039 | Fail-closed under DB exhaustion | `TODO` in manifest (no mechanical check yet) | N/A |
| INV-048 | Proxy/alias resolution before dispatch | `bash scripts/audit/verify_proxy_resolution_invariant.sh` | `evidence/phase0/proxy_resolution_invariant.json` |
| INV-060 | Phase-0 contract governs evidence gate | `bash scripts/audit/verify_phase0_contract.sh` | `evidence/phase0/phase0_contract.json` |
| INV-071 | Three-pillar control plane documented/enforced | `bash scripts/audit/verify_three_pillars_doc.sh` | `evidence/phase0/three_pillars_doc.json` |
| INV-072 | Control-plane gates declared/drift-checked | `bash scripts/audit/verify_control_planes_drift.sh` | `evidence/phase0/control_planes_drift.json` |
| INV-073 | Security guardrails enforced | `bash scripts/audit/run_security_fast_checks.sh` | `evidence/phase0/security_*.json` |
| INV-077 | Evidence schema canonical/validated | `bash scripts/audit/validate_evidence_schema.sh` | `evidence/phase0/evidence_validation.json` |
| INV-080 | Phase-0 evidence status semantics enforced | `bash scripts/audit/verify_phase0_contract_evidence_status.sh` | `evidence/phase0/phase0_contract_evidence_status.json` |
| INV-093 | Evidence pack primitives exist/append-only | `bash scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` |
| INV-103 | Evidence packs include signing/anchoring hooks | `bash scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` |
| INV-104 | PUBLIC has no business-table privileges | `bash scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` |
| INV-105 | Remediation trace required | `bash scripts/audit/verify_remediation_trace.sh` | `evidence/phase0/remediation_trace.json` |
| INV-108 | SDLC/SAST readiness emits evidence | `bash scripts/audit/verify_sdlc_sast_readiness.sh` | `evidence/phase0/sdlc_sast_readiness.json` |
| INV-109 | ISO-20022 contract registry declared | `bash scripts/audit/verify_iso20022_contract_registry.sh` | `evidence/phase0/iso20022_contract_registry.json` |
| INV-111 | BoZ observability role read-only | `bash scripts/db/verify_boz_observability_role.sh` | `evidence/phase0/boz_observability_role.json` |
| INV-112 | PII leakage payload lint fail-closed | `bash scripts/audit/lint_pii_leakage_payloads.sh` | `evidence/phase0/pii_leakage_payloads.json` |
| INV-113 | Anchor-sync hooks + operational invariant | `bash scripts/db/verify_anchor_sync_hooks.sh && bash scripts/db/verify_anchor_sync_operational_invariant.sh` | `evidence/phase0/anchor_sync_hooks.json`, `evidence/phase1/anchor_sync_operational_invariant.json` |
| INV-114 | Instruction finality/irrevocability | `bash scripts/db/verify_instruction_finality_invariant.sh && bash scripts/db/tests/test_instruction_finality.sh` | `evidence/phase1/instruction_finality_invariant.json` |
| INV-115 | PII decoupling + purge survivability | `bash scripts/db/verify_pii_decoupling_hooks.sh && bash scripts/db/tests/test_pii_decoupling.sh` | `evidence/phase1/pii_decoupling_invariant.json` |
| INV-116 | Rail truth-anchor sequence continuity | `bash scripts/db/verify_rail_sequence_truth_anchor.sh && bash scripts/db/tests/test_rail_sequence_continuity.sh` | `evidence/phase1/rail_sequence_truth_anchor.json` |
| INV-119 | Agent conformance + approval trace integrity | `bash scripts/audit/verify_agent_conformance.sh && bash scripts/audit/verify_invproc_06_ci_wiring_closeout.sh && bash scripts/audit/verify_human_governance_review_signoff.sh` | `evidence/phase1/agent_conformance_*.json`, `evidence/phase1/invproc_06_ci_wiring_closeout.json`, `evidence/phase1/human_governance_review_signoff.json` |
| INV-127 | Escrow state machine + atomic transitions | `bash scripts/db/verify_tsk_p1_esc_001.sh --evidence evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json` | `evidence/phase1/tsk_p1_esc_001__escrow_state_machine_atomic_reservation_semantics.json` |
| INV-128 | Escrow ceiling + cross-tenant protection | `bash scripts/db/verify_tsk_p1_esc_002.sh --evidence evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json` | `evidence/phase1/tsk_p1_esc_002__escrow_invariants_cross_tenant_protections.json` |
| INV-130 | Admin bind localhost | `bash scripts/audit/verify_supervisor_bind_localhost.sh` | `evidence/phase1/inv130_admin_bind_localhost.json` |
| INV-131 | Admin auth required | `bash scripts/audit/test_admin_endpoints_require_key.sh` | `evidence/phase1/inv131_admin_auth_required.json` |
| INV-132 | Fail-closed on missing secrets | `bash scripts/security/scan_secrets.sh` (partial), plus runtime fail-closed test required | `evidence/phase1/inv132_fail_closed_missing_secrets.json` |
| INV-133 | Tenant allowlist default-deny | `bash scripts/audit/test_tenant_allowlist_deny_all.sh` | `evidence/phase1/inv133_tenant_allowlist_default_deny.json` |
| INV-134 | Dependency vulnerability gate fail-closed | `bash scripts/security/dotnet_dependency_audit.sh` | `evidence/phase0/security_dotnet_deps_audit.json` |

## B) Invariant -> CI Enforcement Rules

| Invariant Set | CI Workflow Job | Blocking Rule |
|---|---|---|
| Phase-0 mechanical invariants (docs/manifest/rule gates) | `mechanical_invariants` in `.github/workflows/invariants.yml` | Fail if any gate script fails (change-rule, promotion gate, exception template, task plan presence, ordered checks) |
| Security invariants (SEC plane incl. INV-073, INV-108, INV-134) | `security_scan` in `.github/workflows/invariants.yml` | Fail-closed on security script failures and semgrep/dependency/secret issues |
| DB-backed invariants (outbox, roles, hooks, finality, escrow, anchor-sync) | `db_verify_invariants` in `.github/workflows/invariants.yml` | Fail if DB verification/migration or DB invariant scripts fail |
| Phase-0 evidence contract semantics (INV-060/INV-080 linkage) | `phase0_evidence_gate` in `.github/workflows/invariants.yml` | Fail if required evidence is missing, malformed, or status-invalid |
| Local parity preflight for all above before push | `scripts/dev/pre_ci.sh` | Must run ordered checks + DB verify + phase gates where applicable |

## C) Invariant -> Regulator Verification Checklist

| Regulator Question | Invariant Coverage | Required Evidence to Present |
|---|---|---|
| Are settlement/finality controls tamper-resistant? | INV-114, INV-127, INV-128 | `instruction_finality_invariant.json`, `tsk_p1_esc_001__*.json`, `tsk_p1_esc_002__*.json` |
| Is sensitive data handling fail-closed and auditable? | INV-112, INV-115, INV-132 | `pii_leakage_payloads.json`, `pii_decoupling_invariant.json`, missing-secret fail-closed evidence |
| Are control-plane and security gates continuously enforced? | INV-071, INV-072, INV-073, INV-108 | `three_pillars_doc.json`, `control_planes_drift.json`, `security_*`, `sdlc_sast_readiness.json` |
| Is tenant isolation/allowlist posture enforced? | INV-133, INV-128 | `inv133_tenant_allowlist_default_deny.json`, escrow cross-tenant evidence |
| Is external/system integrity traceable end-to-end? | INV-077, INV-093, INV-103, INV-113, INV-116 | evidence schema validation, business hooks evidence, anchor-sync evidence, rail sequence evidence |
| Is dependency/supply-chain risk gated? | INV-134 | `security_dotnet_deps_audit.json` |
| Are admin/debug surfaces constrained? | INV-130, INV-131 | admin bind and auth evidence artifacts |

## D) Current Gaps (Must Not Be Claimed Implemented)
1. `INV-009` has no mechanical verifier yet (`status: roadmap`).
2. `INV-039` has no mechanical verifier yet (`status: roadmap`).
3. `INV-132` currently has repo secret scan hook, but requires explicit runtime fail-closed verifier to be complete.
4. `INV-130..133` are still `roadmap` in current manifest and require full verifier + CI + evidence closure before promotion.

## E) Promotion Rule (Non-Negotiable)
Only promote `roadmap -> implemented` when all are true:
1. Verifier command exists and fails closed.
2. Verifier is wired into blocking CI job.
3. Evidence artifact path is deterministic and schema-validated.
4. `scripts/dev/pre_ci.sh` exercises the same path locally.
5. Contract/manifest/docs are synchronized.
