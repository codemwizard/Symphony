# Phase‑0 Close‑out Checklist

> All items must be **mechanically verifiable** and produce evidence where specified.

## A) Invariants + Docs
- [ ] `scripts/audit/run_invariants_fast_checks.sh` passes
- [ ] `docs/invariants/INVARIANTS_MANIFEST.yml` updated for all Phase‑0 invariants
- [ ] `docs/invariants/INVARIANTS_IMPLEMENTED.md` and `INVARIANTS_ROADMAP.md` match manifest
- [ ] `docs/invariants/INVARIANTS_QUICK.md` regenerated and staged
- [ ] Evidence: `./evidence/phase0/invariants_docs_match.json`

## B) DB Gates + Tests
- [ ] `scripts/db/verify_invariants.sh` passes
- [ ] `scripts/db/tests/test_db_functions.sh` passes
- [ ] `scripts/db/tests/test_idempotency_zombie.sh` passes
- [ ] `scripts/db/tests/test_no_tx_migrations.sh` passes
- [ ] `scripts/db/tests/test_outbox_pending_indexes.sh` passes
- [ ] Evidence: `baseline_drift.json`, `outbox_pending_indexes.json`, `outbox_mvcc_posture.json`

## C) Security Gates
- [ ] `scripts/audit/run_security_fast_checks.sh` passes
- [ ] `scripts/security/lint_ddl_lock_risk.sh` passes
- [ ] Evidence: `ddl_lock_risk.json`, `ddl_blocking_policy.json`, `core_boundary.json`

## D) OpenBao Dev Parity
- [ ] `scripts/security/openbao_bootstrap.sh` succeeds
- [ ] `scripts/security/openbao_smoke_test.sh` succeeds
- [ ] Evidence: `openbao_smoke.json`, `openbao_audit_log.json`

## E) Evidence Pipeline
- [ ] `scripts/audit/generate_evidence.sh` passes
- [ ] `scripts/audit/validate_evidence_schema.sh` passes
- [ ] CI uploads `phase0-evidence` artifact

## F) Proxy Resolution (Roadmap Declaration)
- [ ] INV‑048 is present in manifest as `roadmap`
- [ ] ADR + schema design hook docs exist
- [ ] Evidence: `proxy_resolution_invariant.json`

## G) Governance Controls
- [ ] Baseline change governance enforced (migration + explanation)
- [ ] DDL allowlist governance enforced (fingerprints + expiry + security review)
- [ ] Local/CI parity guardrail passes

## H) Documentation
- [ ] `docs/Phase_0001-0005/implementation_plan.md` reflects current Phase‑0 state
- [ ] `docs/operations/DEV_WORKFLOW.md` contains pre‑implementation checklist
- [ ] `docs/operations/TASK_CREATION_PROCESS.md` present and referenced

