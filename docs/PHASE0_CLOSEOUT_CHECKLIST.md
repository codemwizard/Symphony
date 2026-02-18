# Phase‑0 Close‑out Checklist

> All items must be **mechanically verifiable** and produce evidence where specified.

## A) Invariants + Docs
- [x] `scripts/audit/run_invariants_fast_checks.sh` passes
- [x] `docs/invariants/INVARIANTS_MANIFEST.yml` updated for all Phase‑0 invariants
- [x] `docs/invariants/INVARIANTS_IMPLEMENTED.md` and `INVARIANTS_ROADMAP.md` match manifest
- [x] `docs/invariants/INVARIANTS_QUICK.md` regenerated and staged
- [x] Evidence: `./evidence/phase0/invariants_docs_match.json`

## B) DB Gates + Tests
- [x] `scripts/db/verify_invariants.sh` passes
- [x] `scripts/db/tests/test_db_functions.sh` passes
- [x] `scripts/db/tests/test_idempotency_zombie.sh` passes
- [x] `scripts/db/tests/test_no_tx_migrations.sh` passes
- [x] `scripts/db/tests/test_outbox_pending_indexes.sh` passes
- [x] Evidence: `baseline_drift.json`, `outbox_pending_indexes.json`, `outbox_mvcc_posture.json`

## C) Security Gates
- [x] `scripts/audit/run_security_fast_checks.sh` passes
- [x] `scripts/security/lint_ddl_lock_risk.sh` passes
- [x] Evidence: `ddl_lock_risk.json`, `ddl_blocking_policy.json`, `core_boundary.json`

## D) OpenBao Dev Parity
- [x] `scripts/security/openbao_bootstrap.sh` succeeds
- [x] `scripts/security/openbao_smoke_test.sh` succeeds
- [x] Evidence: `openbao_smoke.json`, `openbao_audit_log.json`

## E) Evidence Pipeline
- [x] `scripts/audit/generate_evidence.sh` passes
- [x] `scripts/audit/validate_evidence_schema.sh` passes
- [x] CI uploads `phase0-evidence` artifact

## F) Proxy Resolution (Roadmap Declaration)
- [x] INV‑048 is present in manifest as `roadmap`
- [x] ADR + schema design hook docs exist
- [x] Evidence: `proxy_resolution_invariant.json`

## G) Governance Controls
- [x] Baseline change governance enforced (migration + explanation)
- [x] DDL allowlist governance enforced (fingerprints + expiry + security review)
- [x] Local/CI parity guardrail passes

## H) Documentation
- [x] `docs/Phase_0001-0005/implementation_plan.md` reflects current Phase‑0 state
- [x] `docs/operations/DEV_WORKFLOW.md` contains pre‑implementation checklist
- [x] `docs/operations/TASK_CREATION_PROCESS.md` present and referenced

## I) Rebaseline Strategy
- [x] ADR-0011 and Rebaseline Decision are present
- [x] Baseline snapshot generator + canonicalization helper exist
- [x] migrate.sh supports baseline strategy for new environments
