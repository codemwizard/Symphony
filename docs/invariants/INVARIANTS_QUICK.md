# Invariants Quick Reference (Implemented Only)

_Generated from `docs/invariants/INVARIANTS_MANIFEST.yml` (do not edit by hand)._

| ID | Severity | Title | Owners | Verification |
|---|---|---|---|---|
| INV-001 | P0 | Applied migrations are immutable (checksum ledger) | ["team-db"] | scripts/db/migrate.sh checksum check; run via scripts/db/verify_invariants.sh |
| INV-002 | P0 | Migration files must not contain top-level BEGIN/COMMIT | ["team-db"] | scripts/db/lint_migrations.sh; run via scripts/db/verify_invariants.sh |
| INV-003 | P0 | Fix forward only: changes via new migrations, never by editing applied ones | ["team-db"] | scripts/db/migrate.sh checksum immutability (same as INV-001); run via scripts/db/verify_invariants.sh |
| INV-004 | P1 | Baseline snapshot is derived from migrations and must not drift | ["team-db"] | scripts/db/check_baseline_drift.sh |
| INV-005 | P0 | Deny-by-default privileges (revoke-first posture) | ["team-platform"] | schema/migrations/0004_privileges.sql + scripts/db/ci_invariant_gate.sql; run via scripts/db/verify_invariants.sh |
| INV-006 | P0 | No runtime DDL: PUBLIC/runtime roles must not have CREATE on schema public | ["team-platform"] | scripts/db/ci_invariant_gate.sql (schema CREATE privilege check); run via scripts/db/verify_invariants.sh |
| INV-007 | P0 | Runtime roles are NOLOGIN templates; services assume them via SET ROLE | ["team-platform"] | scripts/db/verify_role_login_posture.sh; wired via scripts/db/verify_invariants.sh |
| INV-008 | P0 | SECURITY DEFINER functions must pin search_path to pg_catalog, public | ["team-platform"] | scripts/db/lint_search_path.sh; run via scripts/db/verify_invariants.sh |
| INV-010 | P0 | Runtime roles have no direct DML on core tables; writes happen via DB API functions | ["team-platform"] | scripts/db/ci_invariant_gate.sql (role privilege posture) + schema/migrations/0004_privileges.sql |
| INV-011 | P0 | Outbox enqueue is idempotent on (instruction_id, idempotency_key) | ["team-db"] | scripts/db/tests/test_idempotency_zombie.sh (behavior) + schema/migrations/0002_outbox_functions.sql (definition) |
| INV-012 | P0 | Outbox claim uses FOR UPDATE SKIP LOCKED and only due/unleased or expired rows | ["team-db"] | scripts/db/tests/test_outbox_claim_semantics.sh (behavior + definitional SKIP LOCKED check) |
| INV-013 | P0 | Strict lease fencing: completion requires matching claimed_by + lease_token and non-expired lease | ["team-db"] | scripts/db/tests/test_outbox_lease_fencing.sh (behavioral SQLSTATE P7002 on lease loss) |
| INV-014 | P0 | payment_outbox_attempts is append-only; no UPDATE/DELETE | ["team-db"] | schema/migrations/0001_init.sql append-only trigger + scripts/db/ci_invariant_gate.sql |
| INV-015 | P0 | Outbox retry ceiling is finite | ["team-db"] | schema/migrations/0002_outbox_functions.sql (GUC retry ceiling) + scripts/db/ci_invariant_gate.sql |
| INV-016 | P0 | policy_versions exists and supports boot query shape (is_active=true) | ["team-platform"] | schema/migrations/0005_policy_versions.sql (status/is_active) + scripts/db/ci_invariant_gate.sql |
| INV-017 | P0 | policy_versions.checksum is NOT NULL | ["team-platform"] | schema/migrations/0005_policy_versions.sql (checksum NOT NULL) + scripts/db/ci_invariant_gate.sql |
| INV-018 | P0 | Single ACTIVE policy row enforced by unique predicate index | ["team-platform"] | schema/migrations/0005_policy_versions.sql (single ACTIVE index) + scripts/db/ci_invariant_gate.sql |
| INV-019 | P0 | Repo structure is enforced (required directories + doc references) | ["team-platform"] | scripts/audit/verify_repo_structure.sh |
| INV-020 | P0 | Evidence anchoring: git SHA + schema hash | ["team-platform"] | scripts/audit/generate_evidence.sh |
| INV-021 | P0 | N-1 compatibility gate | ["team-db"] | scripts/db/n_minus_one_check.sh |
| INV-022 | P0 | DDL lock-risk lint (blocking operations) | ["team-security"] | scripts/security/lint_ddl_lock_risk.sh |
| INV-023 | P0 | Idempotency zombie replay safety | ["team-db"] | scripts/db/tests/test_idempotency_zombie.sh |
| INV-024 | P0 | OpenBao AppRole auth + deny policy | ["team-security"] | scripts/security/openbao_smoke_test.sh (after openbao_bootstrap.sh) |
| INV-025 | P0 | Blue/Green rollback compatibility | ["team-platform"] | scripts/audit/verify_routing_fallback.sh |
| INV-026 | P0 | Routing fallback invariant | ["team-platform"] | scripts/audit/validate_routing_fallback.sh |
| INV-027 | P0 | Batching rules defined and enforced | ["team-platform"] | scripts/audit/verify_batching_rules.sh |
| INV-028 | P0 | Evidence schema validation | ["team-platform"] | scripts/audit/validate_evidence_schema.sh |
| INV-029 | P0 | Evidence provenance required | ["team-platform"] | scripts/audit/generate_evidence.sh + scripts/audit/validate_evidence_schema.sh |
| INV-030 | P1 | Threat/compliance docs updated on structural change | ["team-platform"] | scripts/audit/enforce_change_rule.sh |
| INV-031 | P0 | Outbox claim index required | ["team-db"] | scripts/db/tests/test_outbox_pending_indexes.sh |
| INV-032 | P0 | One terminal attempt per outbox_id | ["team-db"] | scripts/db/tests/test_db_functions.sh (terminal uniqueness) |
| INV-033 | P1 | Outbox MVCC posture enforced | ["team-db"] | scripts/db/verify_invariants.sh (reloptions check) |
| INV-034 | P1 | Outbox wakeup notification | ["team-db"] | scripts/db/tests/test_db_functions.sh (NOTIFY emission) |
| INV-035 | P1 | Ingress attestation append-only | ["team-db"] | scripts/db/verify_invariants.sh (ingress_attestations checks) |
| INV-036 | P0 | Revocation tables present + append-only | ["team-security"] | scripts/db/verify_invariants.sh (revocation tables checks) |
| INV-037 | P1 | Core code boundary enforced | ["team-security"] | scripts/security/lint_core_boundary.sh |
| INV-038 | P1 | Architecture doc alignment | ["team-platform"] | rg -n \"node|Node.js\" docs/overview/architecture.md docs/decisions/ADR-0001-repo-structure.md |
| INV-040 | P0 | Blocking DDL policy enforced (hot tables) | ["team-security"] | scripts/security/lint_ddl_lock_risk.sh |
| INV-041 | P0 | No-tx migrations supported | ["team-db"] | scripts/db/tests/test_no_tx_migrations.sh |
| INV-042 | P0 | Concurrent index requires no-tx marker | ["team-db"] | scripts/db/lint_migrations.sh |
| INV-043 | P1 | No-tx migration guidance | ["team-platform"] | rg -n \"symphony:no_tx\" docs/operations/DEV_WORKFLOW.md |
| INV-044 | P0 | Invariants docs match manifest | ["team-platform"] | scripts/audit/check_docs_match_manifest.py |
| INV-060 | P1 | Phase-0 contract governs evidence gate | ["team-platform"] | scripts/audit/verify_phase0_contract.sh |
| INV-061 | P1 | SQLSTATE registry is complete and drift-free | ["team-platform"] | scripts/audit/check_sqlstate_map_drift.sh |
| INV-062 | P1 | Tenant hierarchy tables exist (tenants, tenant_clients, tenant_members) | ["team-db"] | scripts/db/verify_tenant_member_hooks.sh |
| INV-063 | P1 | Ingress attestations require tenant attribution and support client/member linkage | ["team-db"] | scripts/db/verify_tenant_member_hooks.sh |
| INV-064 | P1 | Member/tenant consistency guard enforced on ingress | ["team-db"] | scripts/db/verify_tenant_member_hooks.sh |
| INV-065 | P1 | Outbox tables include tenant/member attribution columns (expand-first) | ["team-db"] | scripts/db/verify_tenant_member_hooks.sh |
| INV-066 | P1 | Ingress attestations are unique per (tenant_id, instruction_id) | ["team-db"] | scripts/db/verify_tenant_member_hooks.sh |
| INV-067 | P1 | Baseline changes require migration + ADR update | ["team-platform"] | scripts/audit/verify_baseline_change_governance.sh |
| INV-068 | P1 | DDL allowlist governance enforced (fingerprints + expiry + review) | ["team-security"] | scripts/security/verify_ddl_allowlist_governance.sh |
| INV-069 | P1 | Phase-0 implementation plan is current | ["team-platform"] | scripts/audit/verify_phase0_impl_plan.sh |
| INV-070 | P1 | Day-zero rebaseline strategy is documented and enforced | ["team-platform", "team-db"] | scripts/audit/verify_rebaseline_strategy.sh |
| INV-071 | P1 | Three-Pillar control-plane model is documented and enforced | ["team-platform"] | scripts/audit/verify_three_pillars_doc.sh |
| INV-072 | P1 | Control-plane gates are declared and drift-checked | ["team-platform"] | scripts/audit/verify_control_planes_drift.sh |
| INV-073 | P1 | Security plane guardrails are enforced (secrets/deps/config/code) | ["team-security"] | scripts/audit/run_security_fast_checks.sh |
| INV-075 | P1 | Compliance manifest is complete and gate-mapped | ["team-compliance"] | scripts/audit/verify_compliance_manifest.sh |
| INV-076 | P1 | Agent scopes align with control-plane ownership | ["team-platform"] | scripts/audit/verify_control_planes_drift.sh |
| INV-077 | P1 | Evidence schema is canonical and validated | ["team-platform"] | scripts/audit/validate_evidence_schema.sh |
| INV-078 | P1 | YAML conventions are normalized and linted | ["team-platform"] | scripts/audit/lint_yaml_conventions.sh |
| INV-079 | P1 | CI toolchain is pinned (PyYAML + ripgrep) | ["team-security"] | scripts/audit/verify_ci_toolchain.sh |
| INV-080 | P1 | Phase-0 contract evidence status semantics enforced | ["team-platform"] | scripts/audit/verify_phase0_contract_evidence_status.sh |
| INV-081 | P1 | Pre-CI and CI run the same ordered Phase-0 checks | ["team-platform"] | scripts/audit/verify_ci_order.sh |
| INV-090 | P1 | Billing usage ledger hook exists and is append-only | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-091 | P1 | External proofs hook exists and is append-only | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-092 | P1 | Correlation stitching hooks exist on ingress and outbox tables | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-093 | P1 | Evidence pack primitives exist and are append-only | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-094 | P1 | Tenant billable hierarchy hooks exist (billable root + parent) | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-095 | P1 | Ingress multi-signature hook exists with safe default | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-096 | P1 | Business foundation hooks are mechanically verified in DB gate | ["team-db", "team-platform"] | scripts/db/verify_business_foundation_hooks.sh; wired via scripts/db/verify_invariants.sh |
| INV-097 | P0 | Phase-0 migration expand/contract policy is enforced (no cleanup marker; no ADD COLUMN NOT NULL) | ["team-db"] | scripts/db/lint_expand_contract_policy.sh; wired via scripts/db/verify_invariants.sh |
| INV-098 | P0 | PK/FK type stability guardrail enforced (ALTER COLUMN TYPE requires waiver) | ["team-db"] | scripts/db/lint_pk_fk_type_changes.sh; wired via scripts/db/verify_invariants.sh |
| INV-099 | P1 | Table conventions are verified from pg_catalog (explicit allowlist) | ["team-db"] | scripts/db/verify_table_conventions.sh; wired via scripts/db/verify_invariants.sh |
| INV-100 | P1 | Evidence harness integrity guardrail enforced (anti-bypass bans) | ["team-platform"] | scripts/audit/verify_evidence_harness_integrity.sh; wired via scripts/audit/run_invariants_fast_checks.sh |
| INV-101 | P1 | Semgrep SAST baseline is enforced (pinned in CI; evidence emitted) | ["team-security"] | scripts/security/run_semgrep_sast.sh; wired via scripts/audit/run_security_fast_checks.sh |
| INV-102 | P1 | Participant registry schema hook exists (participant_id identity) | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-103 | P1 | Evidence packs include signing/anchoring metadata hooks | ["team-db"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-104 | P0 | PUBLIC retains no privileges on business tables (explicit REVOKE hygiene) | ["team-db", "team-security"] | scripts/db/verify_business_foundation_hooks.sh |
| INV-105 | P1 | Production-affecting changes require remediation trace (casefile or explicit fix plan/log) | ["team-security", "team-invariants"] | scripts/audit/verify_remediation_trace.sh; wired via scripts/audit/run_invariants_fast_checks.sh |
| INV-106 | P1 | Key management policy stub present + referenced (governance) | ["team-security", "team-platform"] | scripts/audit/verify_policy_key_management_stub.sh; docs/security/KEY_MANAGEMENT_POLICY.md; referenced in docs/security/SECURITY_MANIFEST.yml |
| INV-107 | P1 | Audit logging retention/review policy stub present + referenced (governance) | ["team-security", "team-platform"] | scripts/audit/verify_policy_audit_logging_stub.sh; docs/security/AUDIT_LOGGING_RETENTION_POLICY.md; referenced in docs/security/SECURITY_MANIFEST.yml |
| INV-108 | P1 | Secure SDLC / SAST readiness gate emits evidence (governance) | ["team-security", "team-platform"] | scripts/audit/verify_sdlc_sast_readiness.sh; docs/security/SECURE_SDLC_POLICY.md; Semgrep baseline wired via scripts/audit/run_security_fast_checks.sh |
| INV-109 | P1 | ISO 20022 contract registry declared + presence validated (Phase-0) | ["team-platform"] | scripts/audit/verify_iso20022_contract_registry.sh; wired via scripts/audit/run_security_fast_checks.sh |
| INV-110 | P0 | Deploy-in-customer-VPC posture declared: data residency boundary and off-domain attestation constraints are documented | ["team-platform", "team-compliance"] | scripts/audit/verify_sovereign_vpc_posture_doc.sh; docs/security/SOVEREIGN_VPC_POSTURE.md; referenced in docs/security/SECURITY_MANIFEST.yml |
