# Phase-0 Audit Gap Closeout: Implementation Plan

Date: 2026-02-07

Source inputs:
- `Phase0_Audit-Gap_Closeout_Plan_Draft.txt`
- `AuditAnswers.txt` (locked decisions for guardrails)

Related audits:
- `docs/audits/TIER1_GAP_AUDIT_2026-02-06.md`
- `docs/audits/TIER1_GAP_AUDIT_ADDENDUM_2026-02-07.md`

## 1) Objective
Close the remaining Tier-1 gaps identified in the audit (and in `Phase0_Audit-Gap_Closeout_Plan_Draft.txt`) using Phase-0-appropriate work:
- mechanical gates first (scripts + evidence artifacts + CI wiring)
- forward-only migrations only (no “down”)
- no runtime DDL in production paths
- revoke-first privilege posture
- append-only guarantees remain append-only

This plan is specifically designed so Phase-1/2 work is additive, not corrective.

## 2) Locked Decisions (Guardrails)
From `AuditAnswers.txt`:
1. Table classes for conventions gate: explicit allowlist (only registered tables are enforced).
2. Nullability/default: forbid any `ADD COLUMN ... NOT NULL` in Phase-0 (2-step expand/backfill/contract-later pattern).
3. Contract cleanup marker: forbidden in Phase-0 (any `-- symphony:contract_cleanup` is a hard FAIL).
4. SAST baseline: Semgrep, pinned, minimal ruleset; local can emit SKIPPED if tool missing, CI must enforce.
5. Evidence harness integrity: structural checks plus targeted anti-bypass bans (high-signal only).

## 3) Scope (What We Will Implement in Phase-0)
- Policy and governance stubs that are auditor-legible, with mechanical “presence + reference” verifiers.
- Expand/Contract guardrails for migrations (Phase-0 PaC lints).
- Catalog-based table convention verification for Tier-1 baseline consistency (ledger idempotency, lineage columns by table class).
- Evidence harness integrity guardrails (“watch-the-watcher”) for evidence-producing scripts.
- ISO 20022 and Zero Trust posture closeout at Phase-0 level:
  - declare contracts and enforcement hooks
  - do not implement runtime adapters

## 4) Non-Goals
- No claim of compliance or certification (ISO/PCI/NIST).
- No Phase-1/2 runtime services (message adapters, production logging pipelines, HSM/KMS integrations).
- No destructive schema changes to “clean up” now; cleanup is a separate Contract phase later.

## 5) Already Implemented (Verify, Do Not Rebuild)
The closeout plan must not re-introduce work that is already mechanically enforced in this repo. The following exist today and should be treated as prerequisites:
- Evidence schema canonicalization and validation:
  - `docs/architecture/evidence_schema.json`
  - `scripts/audit/validate_evidence_schema.sh` (gate: INT-G01)
- Compliance manifest verification:
  - `scripts/audit/verify_compliance_manifest.sh` (gate: GOV-G01)
- Local CI parity runner:
  - `scripts/ci/run_ci_locally.sh` (task: TSK-P0-036; evidence: `evidence/phase0/local_ci_parity.json`)
- .NET dependency audit:
  - `scripts/security/dotnet_dependency_audit.sh` (gate: SEC-G08)
- DDL lock-risk lint + allowlist governance:
  - `scripts/security/lint_ddl_lock_risk.sh` (gate: SEC-G02)
  - `scripts/security/verify_ddl_allowlist_governance.sh` (gate: SEC-G04)

## 5) Workstreams and Tasks
Implementation is expressed as Phase-0 tasks under `docs/tasks/PHASE0_TASKS.md` and `tasks/TSK-P0-*/meta.yml`, with a single plan/log folder:
- Plan folder: `docs/plans/phase0/TSK-P0-090_audit_gap_closeout/`

### Workstream A: Governance Stubs (Mechanical Presence Gates)
- TSK-P0-090: Key management policy stub + verifier + manifest reference
- TSK-P0-091: Audit logging retention/review policy stub + verifier + manifest reference
- TSK-P0-092: Secure SDLC policy stub + Semgrep SAST baseline gate (pinned) + evidence hook

### Workstream B: Migration Expand/Contract Guardrails (PaC)
- TSK-P0-093: Expand/Transition guardrail lint
  - destructive DDL forbidden in Phase-0
  - contract cleanup marker forbidden in Phase-0
  - nullability/default safety (no `ADD COLUMN ... NOT NULL` in Phase-0)
- TSK-P0-094: PK/FK type stability lint with rare waiver mechanism (marker + ADR ref)

### Workstream C: Table Conventions (Catalog-Based Verification)
- TSK-P0-095: Table conventions spec + verifier
  - explicit table-class allowlist (ledger/txn tables must be registered to be enforced)
  - required columns/constraints verified via pg_catalog
  - enforce via `information_schema`/`pg_catalog` checks after migrations apply

### Workstream D: Evidence Harness Integrity (Watch-the-Watcher)
- TSK-P0-100: Evidence harness integrity verifier (structural + anti-bypass bans)

### Workstream E: Wiring (Make It Real in CI and Pre-CI)
- TSK-P0-096: Invariants registration + docs updates
- TSK-P0-097: Gate wiring into `scripts/dev/pre_ci.sh` and CI workflows

### Workstream F: Business Hooks Governance Closeout
- TSK-P0-098: Reconcile governance status for already-implemented business foundation hooks
  - update Phase-0 task/contract status and evidence references so records match reality

### Workstream F2: Business Hook Completeness (Schema Hooks)
- TSK-P0-101: Participant registry schema hook + verifier (IPDR stitching, legal/rail identity)
- TSK-P0-102: Evidence pack signing/anchoring schema hooks + verifier (detached signature + anchoring metadata)
- TSK-P0-103: Privilege posture closeout for new business tables (explicit REVOKE hygiene)

### Workstream G: ISO 20022 + Zero Trust Closeout (Phase-0 Safe)
- TSK-P0-099: ISO 20022/Zero Trust closeout hooks
  - define message contract registry location and validation expectations
  - add a mechanical registry presence gate (fail-closed) for the contract registry file
  - add mechanical “presence + reference” policy checks only (no adapters)

## 6) Acceptance Criteria (Phase-0 Closeout)
- All new gaps are represented as tasks with:
  - explicit invariants where applicable
  - a verifier script that emits evidence (or a declared Phase-0 doc gate for policy stubs)
  - CI/pre-CI wiring
- No tasks violate hard constraints (runtime DDL, editing applied migrations, privilege broadening, outbox append-only weakening).

## 7) Verification (When Implementing)
When the tasks are implemented, they must pass:
- `scripts/audit/run_invariants_fast_checks.sh`
- `scripts/audit/run_security_fast_checks.sh`
- `scripts/db/verify_invariants.sh`
- `scripts/audit/verify_phase0_contract.sh`
