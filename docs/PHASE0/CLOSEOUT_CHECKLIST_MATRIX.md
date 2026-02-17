# Phase-0 Closeout Checklist Matrix (Checklist -> Gate/Invariant/Task)

Purpose: provide a single, auditor-friendly index that maps Phase-0 closeout checklist items to concrete mechanical enforcement in this repo.

Source references:
- Control planes and gate IDs: `docs/control_planes/CONTROL_PLANES.yml`
- Invariants source of truth: `docs/invariants/INVARIANTS_MANIFEST.yml`
- Closeout plan: `docs/PHASE0/PHASE0_AUDIT_GAP_CLOSEOUT_IMPLEMENTATION.md`
- Closeout task cluster: `docs/plans/phase0/TSK-P0-090_audit_gap_closeout/PLAN.md`

Status semantics:
- `ENFORCED`: implemented and mechanically gated now (fail-closed).
- `PLANNED`: covered by a planned closeout task but not yet implemented.

## A) Migration and Deployment Safety (Expand/Contract)

| Checklist Item | Status | Gates (CONTROL_PLANES) | Invariants | Primary Script(s) | Evidence | Task(s) |
| --- | --- | --- | --- | --- | --- | --- |
| Forward-only migrations; applied migrations immutable (checksum ledger) | ENFORCED | INT-G17 (via fast checks), DB gate in CI flow | INV-001, INV-003 | `scripts/db/migrate.sh` | `public.schema_migrations` checksums + DB verify evidence | N/A |
| Migrations must not contain top-level BEGIN/COMMIT | ENFORCED | INT-G17 (via fast checks), DB gate in CI flow | INV-002 | `scripts/db/lint_migrations.sh` | evidence emitted by invariant harness | N/A |
| Baseline snapshot must not drift | ENFORCED | INT-G05 | INV-004 | `scripts/db/check_baseline_drift.sh`, `scripts/audit/verify_baseline_change_governance.sh` | `evidence/phase0/baseline_governance.json` | N/A |
| N-1 compatibility for blue/green rollout | ENFORCED | DB gate in CI flow | INV-021 | `scripts/db/n_minus_one_check.sh` | `evidence/phase0/n_minus_one.json` | N/A |
| No-tx discipline documented and enforced for CONCURRENTLY | ENFORCED | INT-G10 | INV (covered by migration runner + docs gate) | `scripts/db/migrate.sh`, `scripts/audit/verify_no_tx_docs.sh` | `evidence/phase0/no_tx_docs.json` | N/A |
| Blocking DDL guarded (lock-risk lint + allowlist governance) | ENFORCED | SEC-G02, SEC-G04 | INV-022 | `scripts/security/lint_ddl_lock_risk.sh`, `scripts/security/verify_ddl_allowlist_governance.sh` | `evidence/phase0/ddl_lock_risk.json`, `evidence/phase0/ddl_allowlist_governance.json` | N/A |
| Expand/Transition forbids destructive DDL (DROP/TRUNCATE/contract ops) | ENFORCED | DB verify job (CI) | INV-097 | `scripts/db/lint_expand_contract_policy.sh` | `evidence/phase0/migration_expand_contract_policy.json` | TSK-P0-093, TSK-P0-096, TSK-P0-097 |
| Phase-0 forbids any `ADD COLUMN ... NOT NULL` | ENFORCED | DB verify job (CI) | INV-097 | `scripts/db/lint_expand_contract_policy.sh` | `evidence/phase0/migration_expand_contract_policy.json` | TSK-P0-093, TSK-P0-096, TSK-P0-097 |
| Phase-0 forbids `-- symphony:contract_cleanup` marker | ENFORCED | DB verify job (CI) | INV-097 | `scripts/db/lint_expand_contract_policy.sh` | `evidence/phase0/migration_expand_contract_policy.json` | TSK-P0-093, TSK-P0-096, TSK-P0-097 |
| PK/FK type stability (no ALTER COLUMN TYPE without ADR waiver) | ENFORCED | DB verify job (CI) | INV-098 | `scripts/db/lint_pk_fk_type_changes.sh` | `evidence/phase0/pk_fk_type_stability.json` | TSK-P0-094, TSK-P0-096, TSK-P0-097 |

## B) Core Integrity and Exception Containment

| Checklist Item | Status | Gates (CONTROL_PLANES) | Invariants | Primary Script(s) | Evidence | Task(s) |
| --- | --- | --- | --- | --- | --- | --- |
| Deny-by-default privileges; revoke-first posture | ENFORCED | DB gate in CI flow | INV-005 | `schema/migrations/0004_privileges.sql`, `scripts/db/ci_invariant_gate.sql` | DB gate evidence | N/A |
| No runtime DDL (PUBLIC/runtime roles have no CREATE on public schema) | ENFORCED | DB gate in CI flow | INV-006 | `scripts/db/ci_invariant_gate.sql` | DB gate evidence | N/A |
| SECURITY DEFINER hardening: pinned `search_path` | ENFORCED | SEC-G03 | INV-008 | `scripts/db/lint_search_path.sh` | `evidence/phase0/security_definer_dynamic_sql.json` (plus DB verifier outputs) | N/A |
| Outbox idempotency and lease-fencing semantics | ENFORCED | DB gate in CI flow | INV-011, INV-012, INV-013, INV-014 | `schema/migrations/0002_outbox_functions.sql`, `scripts/db/verify_invariants.sh` | DB verifier evidence outputs | N/A |
| Revocation tables exist and are append-only | ENFORCED | DB gate in CI flow | INV-036 | `schema/migrations/0012_revocation_tables.sql`, `scripts/db/verify_invariants.sh` | `evidence/phase0/revocation_tables.json` | N/A |
| Table-class conventions for ledger/txn tables (idempotency_key + lineage by class) | ENFORCED | DB verify job (CI) | INV-099 | `scripts/db/verify_table_conventions.sh` | `evidence/phase0/table_conventions.json` | TSK-P0-095, TSK-P0-096, TSK-P0-097 |

## C) Security Controls (Phase-0 Appropriate)

| Checklist Item | Status | Gates (CONTROL_PLANES) | Invariants | Primary Script(s) | Evidence | Task(s) |
| --- | --- | --- | --- | --- | --- | --- |
| Secrets leakage scan | ENFORCED | SEC-G07 | (manifested) | `scripts/security/scan_secrets.sh` | `evidence/phase0/security_secrets_scan.json` | N/A |
| Secure configuration lint (infra/workflows) | ENFORCED | SEC-G09 | (manifested) | `scripts/security/lint_secure_config.sh` | `evidence/phase0/security_secure_config_lint.json` | N/A |
| .NET dependency vulnerability audit | ENFORCED | SEC-G08 | (manifested) | `scripts/security/dotnet_dependency_audit.sh` | `evidence/phase0/security_dotnet_deps_audit.json` | N/A |
| Insecure patterns lint (static) | ENFORCED | SEC-G10 | (manifested) | `scripts/security/lint_insecure_patterns.sh` | `evidence/phase0/security_insecure_patterns.json` | N/A |
| Secure SDLC policy stub + Semgrep baseline SAST evidence | ENFORCED | SEC-G11 | INV-101 | `scripts/security/run_semgrep_sast.sh` | `evidence/phase0/semgrep_sast.json` | TSK-P0-092, TSK-P0-097 |

## D) Evidence-Grade Governance

| Checklist Item | Status | Gates (CONTROL_PLANES) | Invariants | Primary Script(s) | Evidence | Task(s) |
| --- | --- | --- | --- | --- | --- | --- |
| Evidence schema enforced (PASS/FAIL/SKIPPED + provenance) | ENFORCED | INT-G01 | INV-028, INV-077 | `docs/architecture/evidence_schema.json`, `scripts/audit/validate_evidence_schema.sh` | `evidence/phase0/evidence_validation.json` | N/A |
| Task evidence contract enforced (definitions are fail-closed) | ENFORCED | INT-G02 | (manifested via gate) | `scripts/audit/verify_task_evidence_contract.sh` | `evidence/phase0/task_evidence_contract.json` | N/A |
| Phase-0 contract is authoritative and validated | ENFORCED | INT-G03 | (manifested via gate) | `scripts/audit/verify_phase0_contract.sh` | `evidence/phase0/phase0_contract.json` | N/A |
| Contract evidence status semantics enforced | ENFORCED | INT-G19 | (manifested via gate) | `scripts/audit/verify_phase0_contract_evidence_status.sh` | `evidence/phase0/phase0_contract_evidence_status.json` | N/A |
| Watch-the-watcher: evidence harness integrity gate | ENFORCED | INT-G21 | INV-100 | `scripts/audit/verify_evidence_harness_integrity.sh` | `evidence/phase0/evidence_harness_integrity.json` | TSK-P0-100, TSK-P0-097 |
| Compliance mapping verified mechanically | ENFORCED | GOV-G01 | (manifested via gate) | `scripts/audit/verify_compliance_manifest.sh` | `evidence/phase0/compliance_manifest_verify.json` | N/A |

## E) Governance Policies and Business Hooks

| Checklist Item | Status | Gates (CONTROL_PLANES) | Invariants | Primary Script(s) | Evidence | Task(s) |
| --- | --- | --- | --- | --- | --- | --- |
| Key management policy exists and is referenced | ENFORCED | SEC-G12 | (policy presence gate) | `scripts/audit/verify_key_management_policy.sh` | `evidence/phase0/key_management_policy.json` | TSK-P0-090, TSK-P0-097 |
| Audit logging retention/review policy exists and is referenced | ENFORCED | SEC-G13 | (policy presence gate) | `scripts/audit/verify_audit_logging_retention_policy.sh` | `evidence/phase0/audit_logging_retention_policy.json` | TSK-P0-091, TSK-P0-097 |
| Business foundation hooks governance status matches enforcement | ENFORCED | INT-G03 (contract validation) | Meta | `scripts/audit/verify_phase0_contract*.sh` | contract evidence | TSK-P0-098 |
| Participant registry schema hook exists | ENFORCED | DB verify job (CI) | INV-102 | `scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` | TSK-P0-101 |
| Evidence pack signing and anchoring schema hooks exist | ENFORCED | DB verify job (CI) | INV-103 | `scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` | TSK-P0-102 |
| Privilege posture explicit REVOKE hygiene for new business tables | ENFORCED | DB verify job (CI) | INV-104 | `scripts/db/verify_business_foundation_hooks.sh` | `evidence/phase0/business_foundation_hooks.json` | TSK-P0-103 |
| ISO 20022 readiness docs + contract registry presence gate | ENFORCED | SEC-G14, SEC-G15 | (docs/registry presence gates) | `scripts/audit/verify_iso20022_readiness_docs.sh`, `scripts/audit/verify_iso20022_contract_registry.sh` | `evidence/phase0/iso20022_readiness.json`, `evidence/phase0/iso20022_contract_registry.json` | TSK-P0-099 |
| Zero Trust posture docs gate | ENFORCED | SEC-G16 | (docs presence gate) | `scripts/audit/verify_zero_trust_posture_docs.sh` | `evidence/phase0/zero_trust_posture.json` | TSK-P0-099 |
