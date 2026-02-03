0. Phase-0 Definition of Done (DoD)

- All Phase-0 invariants in `docs/invariants/INVARIANTS_MANIFEST.yml` are either implemented with mechanical checks or explicitly marked roadmap with a blocking gate or task.
- CI produces evidence artifacts under `./evidence/` for schema hash + git hash anchoring, N-1 gate, DDL lock-risk lint, idempotency zombie simulation, OpenBao auth smoke, and batching/rollback invariants.
- N-1 compatibility gate and lock-risk DDL lint gate are enforced in CI and fail-closed.
- Evidence schema and generator are in place; evidence artifacts are uploaded in CI and not committed to git.
- OpenBao dev parity harness (compose + bootstrap + deny test) exists and is verified by CI.
- Repo structure and agents structure are enforced by a mechanical checker and referenced by docs.
- Phase-0 task metadata files exist for all tasks (`tasks/TSK-P0-###/meta.yml`), including assigned role/model and required evidence outputs.

Completion checklist (per task)

- Update `tasks/<TASK_ID>/meta.yml`:
  - set `status: "completed"`
  - update `verification:` to the exact commands you ran
  - ensure `evidence:` matches artifacts produced under `./evidence/`
  - keep `assigned_agent` and `model` set to the executor
- (Optional) Add a short completion note in `docs/tasks/PHASE0_TASKS.md` for the task.

1. Repo Findings (Evidence-based)

- Top-level directories: `.github/` (workflow: `.github/workflows/invariants.yml`), `docs/`, `infra/`, `schema/`, `scripts/`, `AGENTS.md`, `AGENT.md`.
- Invariants source of truth: `docs/invariants/INVARIANTS_MANIFEST.yml`.
- Invariants gates/scripts: `scripts/audit/run_invariants_fast_checks.sh`, `scripts/audit/enforce_change_rule.sh`, `scripts/db/verify_invariants.sh`, `scripts/db/ci_invariant_gate.sql`.
- Security fast checks: `scripts/audit/run_security_fast_checks.sh`, `scripts/security/lint_privilege_grants.sh`, `scripts/security/lint_sql_injection.sh`.
- CI workflow: `.github/workflows/invariants.yml` (mechanical invariants, DB verify, security checks).
- Phase-0 docs exist: `docs/phase-0/phase-0-foundation.md`.
- Architecture docs exist: `docs/architecture/*` including `SDD.md`, `ARCHITECTURE_DIAGRAM.md`, `ROADMAP.md`.
- No .NET 10 `src/` or `tests/` layout exists at repo root (NOT FOUND).
- No OpenBao compose or scripts exist (NOT FOUND).
- No evidence harness (`./evidence/`, schema, generator) exists (NOT FOUND).
- No N-1 compatibility gate or DDL lock-risk linting gate exists (NOT FOUND).
- No batching invariant definition or verification hook exists (NOT FOUND).

2. Phase-0 Task List (Ordered)

TASK ID: TSK-P0-001
Title: Establish repo structure verifier and agents layout
Owner Role: ARCHITECT
Depends On: none
Touches: `scripts/audit/verify_repo_structure.sh`, `.github/workflows/invariants.yml`, `docs/agents/ARCHITECT_PHASE0_PROMPT.md`, `docs/phase-0/phase-0-foundation.md`, `tasks/TSK-P0-001/meta.yml`
Invariant(s): NEW INV-019 (Repo structure enforced)
Work:
- Define required directories for .NET 10-friendly layout: `src/`, `tests/`, `tools/`, `infra/`, `scripts/`, `docs/`, `docs/agents/`, `docs/architecture/`, `docs/invariants/`, `docs/tasks/`.
- Create `scripts/audit/verify_repo_structure.sh` that fails if required dirs are missing or if docs were moved without updates.
- Wire the script into `.github/workflows/invariants.yml` (mechanical_invariants job).
- Update Phase-0 docs to reference the verifier.
Acceptance Criteria:
- CI fails if any required directory is missing.
- Verifier emits a machine-readable report under `./evidence/`.
Verification Commands:
- `scripts/audit/verify_repo_structure.sh`
Evidence Artifact(s):
- `./evidence/phase0/repo_structure.json`
Failure Modes:
- Missing required directory or stale doc reference must fail the job.
Notes:
- Include `tasks/TSK-P0-001/meta.yml` with assigned role/model and must-read files.

TASK ID: TSK-P0-002
Title: Add evidence schema and generator with anchoring
Owner Role: PLATFORM
Depends On: TSK-P0-001
Touches: `docs/architecture/evidence_schema.json`, `scripts/audit/generate_evidence.sh`, `.gitignore`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-002/meta.yml`
Invariant(s): NEW INV-020 (Evidence anchoring: git + schema hash)
Work:
- Define evidence schema (JSON schema) with required fields: `git_sha`, `schema_hash`, `timestamp`, `producer`, `inputs`.
- Implement `scripts/audit/generate_evidence.sh` to write `./evidence/phase0/evidence.json`, including `git rev-parse HEAD` and deterministic schema hash (from `pg_dump --schema-only` or migration canonical hash).
- Ensure `./evidence/` is ignored by git and only uploaded as CI artifacts.
- Add CI step to run generator after DB verify job.
Acceptance Criteria:
- Evidence file includes git SHA + schema hash and validates against schema.
- Evidence is uploaded in CI and not committed.
Verification Commands:
- `scripts/audit/generate_evidence.sh`
Evidence Artifact(s):
- `./evidence/phase0/evidence.json`
Failure Modes:
- Missing git SHA or schema hash must fail.
Notes:
- Must-read files in meta: `docs/invariants/INVARIANTS_MANIFEST.yml`, `scripts/db/verify_invariants.sh`.

TASK ID: TSK-P0-003
Title: Implement N-1 compatibility gate
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-002
Touches: `scripts/db/n_minus_one_check.sh`, `.github/workflows/invariants.yml`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `tasks/TSK-P0-003/meta.yml`
Invariant(s): NEW INV-021 (N-1 compatibility gate)
Work:
- Create `scripts/db/n_minus_one_check.sh` to validate current migrations against previous schema contract (N-1) by replaying migrations up to N-1 and verifying compatibility (or explicit compatibility assertions).
- Wire into CI (db_verify_invariants job) and fail-closed.
- Add invariant entry with verification command.
Acceptance Criteria:
- CI fails if N-1 compatibility check fails.
- Evidence file written to `./evidence/phase0/n_minus_one.json`.
Verification Commands:
- `scripts/db/n_minus_one_check.sh`
Evidence Artifact(s):
- `./evidence/phase0/n_minus_one.json`
Failure Modes:
- Missing baseline or incompatible migration must hard-fail.
Notes:
- If baseline is missing, create a bootstrap sub-step that fails until baseline exists.

TASK ID: TSK-P0-004
Title: Add DDL lock-risk linting gate for migrations
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-001
Touches: `scripts/security/lint_ddl_lock_risk.sh`, `.github/workflows/invariants.yml`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `tasks/TSK-P0-004/meta.yml`
Invariant(s): NEW INV-022 (DDL lock-risk lint)
Work:
- Implement lint script to scan `schema/migrations/**` for high-risk patterns (e.g., `ALTER TABLE` without safe pattern/CONCURRENTLY or long-lock operations).
- Wire into mechanical_invariants job.
- Add invariant entry with verification command.
Acceptance Criteria:
- CI fails on disallowed DDL patterns.
- Evidence report generated under `./evidence/phase0/ddl_lock_risk.json`.
Verification Commands:
- `scripts/security/lint_ddl_lock_risk.sh`
Evidence Artifact(s):
- `./evidence/phase0/ddl_lock_risk.json`
Failure Modes:
- Any risky DDL must fail.

TASK ID: TSK-P0-005
Title: Idempotency zombie simulation harness
Owner Role: QA_VERIFIER
Depends On: TSK-P0-003
Touches: `scripts/db/tests/test_idempotency_zombie.sh`, `.github/workflows/invariants.yml`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `tasks/TSK-P0-005/meta.yml`
Invariant(s): NEW INV-023 (Idempotency zombie replay safety)
Work:
- Create a DB test harness that simulates duplicate enqueue/ACK loss using existing outbox functions.
- Validate no double-enqueue and no double-complete in attempts ledger.
- Wire into db_verify_invariants job.
Acceptance Criteria:
- Test fails if duplicates are possible.
- Evidence report generated under `./evidence/phase0/idempotency_zombie.json`.
Verification Commands:
- `scripts/db/tests/test_idempotency_zombie.sh`
Evidence Artifact(s):
- `./evidence/phase0/idempotency_zombie.json`
Failure Modes:
- Any duplicate insert/complete must fail.

TASK ID: TSK-P0-006
Title: OpenBao dev parity harness with deny test
Owner Role: PLATFORM
Depends On: TSK-P0-001
Touches: `infra/openbao/docker-compose.yml`, `scripts/security/openbao_bootstrap.sh`, `scripts/security/openbao_smoke_test.sh`, `.github/workflows/invariants.yml`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `tasks/TSK-P0-006/meta.yml`
Invariant(s): NEW INV-024 (OpenBao AppRole auth + deny policy)
Work:
- Add OpenBao docker compose for dev/testing.
- Bootstrap script to enable secrets engine, AppRole, policies, and audit log.
- Smoke test that authenticates via AppRole and asserts forbidden read is denied.
- Wire into CI (dedicated job) and produce evidence.
Acceptance Criteria:
- AppRole auth succeeds for allowed path and fails for forbidden path.
- Evidence report generated under `./evidence/phase0/openbao_smoke.json`.
Verification Commands:
- `scripts/security/openbao_bootstrap.sh`
- `scripts/security/openbao_smoke_test.sh`
Evidence Artifact(s):
- `./evidence/phase0/openbao_smoke.json`
Failure Modes:
- Auth failure or policy bypass must fail.

TASK ID: TSK-P0-007
Title: Blue/Green rollback invariants and routing fallback gate
Owner Role: ARCHITECT
Depends On: TSK-P0-003
Touches: `docs/invariants/INVARIANTS_MANIFEST.yml`, `scripts/audit/verify_routing_fallback.sh`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-007/meta.yml`
Invariant(s): NEW INV-025 (Blue/Green rollback compatibility), NEW INV-026 (Routing fallback invariant)
Work:
- Define invariants for blue/green rollback and routing fallback in manifest.
- Implement `scripts/audit/verify_routing_fallback.sh` that fails until explicit fallback rules are defined (fail-closed placeholder).
- Wire to CI to ensure no silent pass.
Acceptance Criteria:
- CI fails until routing fallback rules are defined and verified.
- Evidence report generated under `./evidence/phase0/routing_fallback.json`.
Verification Commands:
- `scripts/audit/verify_routing_fallback.sh`
Evidence Artifact(s):
- `./evidence/phase0/routing_fallback.json`
Failure Modes:
- Missing fallback rules must hard-fail.

TASK ID: TSK-P0-008
Title: Batching invariant definition and verifier
Owner Role: ARCHITECT
Depends On: TSK-P0-001
Touches: `docs/architecture/batching_rules.yml`, `scripts/audit/verify_batching_rules.sh`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-008/meta.yml`
Invariant(s): NEW INV-027 (Batching rules defined and enforced)
Work:
- Add a canonical batching rules file with size threshold, time threshold, max wait.
- Implement verifier script that ensures all required fields exist and are non-zero.
- Wire into CI as a fail-closed gate.
Acceptance Criteria:
- CI fails if batching rules are missing or invalid.
- Evidence report generated under `./evidence/phase0/batching_rules.json`.
Verification Commands:
- `scripts/audit/verify_batching_rules.sh`
Evidence Artifact(s):
- `./evidence/phase0/batching_rules.json`
Failure Modes:
- Missing or zero thresholds must fail.

TASK ID: TSK-P0-009
Title: Update invariants manifest and QUICK generation for new Phase-0 invariants
Owner Role: INVARIANTS_CURATOR
Depends On: TSK-P0-002, TSK-P0-003, TSK-P0-004, TSK-P0-005, TSK-P0-006, TSK-P0-007, TSK-P0-008
Touches: `docs/invariants/INVARIANTS_MANIFEST.yml`, `docs/invariants/INVARIANTS_QUICK.md`, `tasks/TSK-P0-009/meta.yml`
Invariant(s): INV-019..INV-027
Work:
- Add new invariants to manifest with precise verification commands.
- Regenerate QUICK reference and ensure it matches.
Acceptance Criteria:
- `scripts/audit/generate_invariants_quick` produces no diff.
Verification Commands:
- `scripts/audit/generate_invariants_quick`
Evidence Artifact(s):
- `./evidence/phase0/invariants_quick.json`
Failure Modes:
- Manifest/QUICK drift must fail.

TASK ID: TSK-P0-010
Title: CI evidence artifact upload consolidation
Owner Role: PLATFORM
Depends On: TSK-P0-002..TSK-P0-008
Touches: `.github/workflows/invariants.yml`, `tasks/TSK-P0-010/meta.yml`
Invariant(s): INV-020 (Evidence anchoring)
Work:
- Add CI step to collect `./evidence/**` and upload as artifact in each job.
- Enforce fail-closed if evidence files referenced by tasks are missing.
- Add local evidence checker to validate required evidence globs from task meta.
Acceptance Criteria:
- Local: `scripts/audit/generate_evidence.sh && scripts/ci/check_evidence_required.sh` passes.
- Local: workflow passes `actionlint`.
- Local: workflow contains upload step for `phase0-evidence`.
Verification Commands:
- actionlint .github/workflows/invariants.yml
- scripts/audit/generate_evidence.sh && scripts/ci/check_evidence_required.sh
- rg -n "upload-artifact" .github/workflows/invariants.yml
- rg -n "phase0-evidence" .github/workflows/invariants.yml
Evidence Artifact(s):
- `./evidence/phase0/*.json`
Failure Modes:
- Missing evidence file in CI must fail.

TASK ID: TSK-P0-019
Title: CI artifact upload verification (integration)
Owner Role: PLATFORM
Depends On: TSK-P0-010
Touches: `tasks/TSK-P0-019/meta.yml`
Invariant(s): INV-020 (Evidence anchoring)
Work:
- Run invariants.yml in CI and confirm `phase0-evidence` artifact exists and contains evidence files.
Acceptance Criteria:
- CI run produces artifact `phase0-evidence` with `evidence/**`.
Verification Commands:
- CI: run workflow invariants.yml; confirm phase0-evidence artifact
Evidence Artifact(s):
- `phase0-evidence` (CI artifact)
Failure Modes:
- CI run does not upload phase0-evidence.

TASK ID: TSK-P0-011
Title: Evidence schema validation gate
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-002
Touches: `scripts/audit/validate_evidence_schema.sh`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-011/meta.yml`
Invariant(s): NEW INV-028 (Evidence schema validation)
Work:
- Add validator script to enforce evidence JSON schema correctness.
- Wire into mechanical_invariants job; fail-closed on invalid evidence.
Acceptance Criteria:
- CI fails if evidence JSON does not validate against schema.
- Evidence validation report generated under `./evidence/phase0/evidence_validation.json`.
Verification Commands:
- `scripts/audit/validate_evidence_schema.sh`
Evidence Artifact(s):
- `./evidence/phase0/evidence_validation.json`
Failure Modes:
- Missing or invalid evidence JSON must fail.

TASK ID: TSK-P0-012
Title: Enforce evidence provenance fields
Owner Role: ARCHITECT
Depends On: TSK-P0-002, TSK-P0-011
Touches: `docs/architecture/evidence_schema.json`, `scripts/audit/generate_evidence.sh`, `tasks/TSK-P0-012/meta.yml`
Invariant(s): NEW INV-029 (Evidence provenance required)
Work:
- Extend evidence schema to require `git_sha`, `schema_hash`, `ci_run_id`, `producer`, `inputs`.
- Update evidence generator to emit those fields deterministically.
Acceptance Criteria:
- Evidence file includes required provenance fields and passes schema validation.
Verification Commands:
- `scripts/audit/generate_evidence.sh`
- `scripts/audit/validate_evidence_schema.sh`
Evidence Artifact(s):
- `./evidence/phase0/evidence.json`
Failure Modes:
- Missing provenance field must fail.

TASK ID: TSK-P0-013
Title: Baseline drift gate (schema baseline freshness)
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-002
Touches: `scripts/db/check_baseline_drift.sh`, `scripts/db/verify_invariants.sh`, `tasks/TSK-P0-013/meta.yml`
Invariant(s): INV-004 (Baseline snapshot must not drift)
Work:
- Add baseline drift check script that compares baseline to regenerated schema.
- Wire into `scripts/db/verify_invariants.sh` so CI runs it by default.
Acceptance Criteria:
- CI fails if baseline snapshot does not match regenerated schema.
Verification Commands:
- `scripts/db/check_baseline_drift.sh`
Evidence Artifact(s):
- `./evidence/phase0/baseline_drift.json`
Failure Modes:
- Baseline drift or missing baseline must fail.

TASK ID: TSK-P0-014
Title: SECURITY DEFINER dynamic SQL linter (fail-closed)
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-001
Touches: `scripts/security/lint_security_definer_dynamic_sql.sh`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-014/meta.yml`
Invariant(s): INV-009 (No dynamic SQL in SECURITY DEFINER)
Work:
- Add a linter that fails on dynamic SQL patterns in SECURITY DEFINER functions unless explicitly allowlisted.
- Wire into mechanical_invariants job; fail-closed on violations.
Acceptance Criteria:
- CI fails if a SECURITY DEFINER function uses dynamic SQL without allowlist.
Verification Commands:
- `scripts/security/lint_security_definer_dynamic_sql.sh`
Evidence Artifact(s):
- `./evidence/phase0/security_definer_dynamic_sql.json`
Failure Modes:
- Any dynamic SQL violation must fail.

TASK ID: TSK-P0-015
Title: Routing fallback rules schema + validator (not a paper gate)
Owner Role: ARCHITECT
Depends On: TSK-P0-007
Touches: `docs/architecture/routing_fallback.yml`, `docs/architecture/routing_fallback.schema.json`, `scripts/audit/validate_routing_fallback.sh`, `tasks/TSK-P0-015/meta.yml`
Invariant(s): INV-026 (Routing fallback invariant)
Work:
- Define routing fallback rules file with required fields (SLO thresholds, actions, evidence emission rules).
- Add JSON schema and validator that fails on missing/invalid fields.
- Emit evidence artifact proving validation ran.
Acceptance Criteria:
- CI fails if routing fallback rules are missing or invalid.
- Evidence artifact produced from validator run.
Verification Commands:
- `scripts/audit/validate_routing_fallback.sh`
Evidence Artifact(s):
- `./evidence/phase0/routing_fallback_validation.json`
Failure Modes:
- Missing file, invalid schema, or missing required fields must fail.

TASK ID: TSK-P0-016
Title: Batching rules evidence generator
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-008
Touches: `scripts/audit/verify_batching_rules.sh`, `.github/workflows/invariants.yml`, `tasks/TSK-P0-016/meta.yml`
Invariant(s): INV-027 (Batching rules defined and enforced)
Work:
- Extend batching rules verifier to emit evidence JSON with thresholds and hash.
- Wire to CI as a hard gate.
Acceptance Criteria:
- Evidence JSON is generated and contains thresholds + hash.
Verification Commands:
- `scripts/audit/verify_batching_rules.sh`
Evidence Artifact(s):
- `./evidence/phase0/batching_rules.json`
Failure Modes:
- Missing evidence or invalid thresholds must fail.

TASK ID: TSK-P0-017
Title: Structural change linkage for threat/compliance docs
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-001
Touches: `scripts/audit/enforce_change_rule.sh`, `tasks/TSK-P0-017/meta.yml`
Invariant(s): NEW INV-030 (Threat/compliance docs updated on structural change)
Work:
- Extend change-rule gate to require updates to threat model and compliance map on structural changes.
- Fail-closed when structural_change is true and docs are untouched.
Acceptance Criteria:
- CI fails if structural changes occur without updating required docs.
Verification Commands:
- `scripts/audit/enforce_change_rule.sh`
Evidence Artifact(s):
- `./evidence/phase0/structural_doc_linkage.json`
Failure Modes:
- Structural change without docs update must fail.

TASK ID: TSK-P0-018
Title: OpenBao audit log evidence requirement
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-006
Touches: `scripts/security/openbao_bootstrap.sh`, `scripts/security/openbao_smoke_test.sh`, `tasks/TSK-P0-018/meta.yml`
Invariant(s): INV-024 (OpenBao AppRole auth + deny policy)
Work:
- Require audit logging enabled during OpenBao bootstrap.
- Extend smoke test to verify audit log entry exists and emit evidence.
Acceptance Criteria:
- CI fails if audit logging is disabled or no audit entry is present.
Verification Commands:
- `scripts/security/openbao_bootstrap.sh`
- `scripts/security/openbao_smoke_test.sh`
Evidence Artifact(s):
- `./evidence/phase0/openbao_audit_log.json`
Failure Modes:
- Missing audit log or bypass must fail.

3. GAPS (If any)

- GAP-001: .NET 10-friendly directory structure is NOT FOUND -> Bootstrap task TSK-P0-001.
- GAP-002: Evidence harness is NOT FOUND -> Bootstrap task TSK-P0-002.
- GAP-003: N-1 compatibility gate is NOT FOUND -> Bootstrap task TSK-P0-003.
- GAP-004: DDL lock-risk lint is NOT FOUND -> Bootstrap task TSK-P0-004.
- GAP-005: Idempotency zombie simulation is NOT FOUND -> Bootstrap task TSK-P0-005.
- GAP-006: OpenBao dev parity harness is NOT FOUND -> Bootstrap task TSK-P0-006.
- GAP-007: Blue/Green rollback invariant + routing fallback verifier is NOT FOUND -> Bootstrap task TSK-P0-007.
- GAP-008: Batching invariant definition + verifier is NOT FOUND -> Bootstrap task TSK-P0-008.

4. Non-Goals (Phase-0)

- No Phase-1/Phase-2 runtime services (ingest API, orchestration, ledger core, adapters).
- No production KMS integration (OpenBao only for dev parity).
- No full policy rotation/grace implementation (only Phase-0 gates and invariant definitions).
- No ledger posting schema beyond current DB foundation.
- No PSP/rail adapters or ISO 20022 gateway implementation.

TASK ID: TSK-P0-020
Title: Add due-claim indexes for payment_outbox_pending
Owner Role: DB_FOUNDATION
Depends On: none
Touches: `schema/migrations/0007_outbox_pending_indexes.sql`, `scripts/db/verify_invariants.sh`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `tasks/TSK-P0-020/meta.yml`
Invariant(s): NEW INV-031 (Outbox claim index required)
Work:
- Add migration to create due-claim index on `payment_outbox_pending` for `(next_attempt_at, created_at)`.
- Prefer a partial index matching claim predicate if consistent with query shape.
- Wire invariant verification in CI gate or DB verify.
Acceptance Criteria:
- Index exists with expected definition.
Verification Commands:
- `scripts/db/verify_invariants.sh`
Evidence Artifact(s):
- `./evidence/phase0/outbox_pending_indexes.json`
Failure Modes:
- Missing index or wrong definition.

TASK ID: TSK-P0-021
Title: Enforce terminal uniqueness on outbox attempts (DISPATCHED + FAILED)
Owner Role: DB_FOUNDATION
Depends On: none
Touches: `schema/migrations/0008_outbox_terminal_uniqueness.sql`, `scripts/db/tests/test_db_functions.sh`
Invariant(s): NEW INV-032 (One terminal attempt per outbox_id)
Work:
- Add partial unique index on `payment_outbox_attempts(outbox_id)` where `state IN ('DISPATCHED','FAILED')`.
- Add DB test to assert SQLSTATE 23505 and constraint/index name on duplicate terminal insert.
- Ensure test emits `./evidence/phase0/outbox_terminal_uniqueness.json`.
- Note: terminal set currently `{DISPATCHED, FAILED}`; future terminal states must update the predicate.
Acceptance Criteria:
- Duplicate terminal insert fails at DB level.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/tests/test_db_functions.sh`
Evidence Artifact(s):
- `./evidence/phase0/outbox_terminal_uniqueness.json`
Failure Modes:
- Duplicate terminal attempt succeeds.
- Evidence file missing.
Notes:
- Invariant registration is handled by TSK-P0-009.

TASK ID: TSK-P0-022
Title: Enforce MVCC posture for payment_outbox_pending
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-020
Touches: `schema/migrations/0009_pending_fillfactor.sql`, `scripts/db/verify_invariants.sh`
Invariant(s): NEW INV-033 (Outbox MVCC posture enforced)
Work:
- Set `fillfactor=80` (and optional autovacuum reloptions) for `payment_outbox_pending`.
- Add verification in `scripts/db/verify_invariants.sh` to fail if reloptions missing.
- Ensure verifier emits `./evidence/phase0/outbox_mvcc_posture.json`.
Acceptance Criteria:
- Table reloptions show fillfactor set (and vacuum settings if declared).
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/verify_invariants.sh`
Evidence Artifact(s):
- `./evidence/phase0/outbox_mvcc_posture.json`
Failure Modes:
- Fillfactor/vacuum posture not enforced.
- Evidence file missing.
Notes:
- Documentation updates (if needed) should be handled by ARCHITECT.

TASK ID: TSK-P0-023
Title: Add LISTEN/NOTIFY wakeup hook (wakeup-only semantics)
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-020
Touches: `schema/migrations/0010_outbox_notify.sql`, `scripts/db/tests/test_db_functions.sh`
Invariant(s): NEW INV-034 (Outbox wakeup notification)
Work:
- Emit NOTIFY on enqueue as a wakeup only (minimal/empty payload).
- Emit once per enqueue call (not per inserted row in a batch).
- Add a basic DB test to confirm NOTIFY emission with a short timeout.
- Ensure test emits `./evidence/phase0/outbox_notify.json`.
Acceptance Criteria:
- Notification channel exists and emits on enqueue.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/tests/test_db_functions.sh`
Evidence Artifact(s):
- `./evidence/phase0/outbox_notify.json`
Failure Modes:
- Notification not emitted.
- Evidence file missing.
Notes:
- Documentation updates (if needed) should be handled by ARCHITECT.

TASK ID: TSK-P0-024
Title: Add ingress attestation schema (append-only skeleton)
Owner Role: DB_FOUNDATION
Depends On: none
Touches: `schema/migrations/0011_ingress_attestations.sql`, `scripts/db/verify_invariants.sh`
Invariant(s): NEW INV-035 (Ingress attestation append-only)
Work:
- Create `ingress_attestations` table (hashes/identifiers only; no raw payloads).
- Add indexes on `(instruction_id)` and `(received_at)` (and optional `(tenant_id, received_at)` if multi-tenant).
- Enforce append-only via privileges (REVOKE UPDATE/DELETE); trigger optional.
- Ensure verifier emits `./evidence/phase0/ingress_attestation.json`.
Acceptance Criteria:
- Table exists and is append-only.
- Required indexes exist.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/verify_invariants.sh`
Evidence Artifact(s):
- `./evidence/phase0/ingress_attestation.json`
Failure Modes:
- Table missing or mutable.
- Evidence file missing.
Notes:
- Invariant registration is handled by TSK-P0-009.

TASK ID: TSK-P0-025
Title: Add durable revocation tables (certs + tokens)
Owner Role: DB_FOUNDATION
Depends On: none
Touches: `schema/migrations/0012_revocation_tables.sql`, `scripts/db/verify_invariants.sh`
Invariant(s): NEW INV-036 (Revocation tables present + append-only)
Work:
- Add `revoked_client_certs(cert_fingerprint_sha256 PK, revoked_at, reason_code, revoked_by)`.
- Add `revoked_tokens(token_jti PK, revoked_at, reason_code, revoked_by)`.
- Add optional `expires_at` to both tables for time-bound revocations.
- Enforce append-only via privileges (REVOKE UPDATE/DELETE); trigger optional.
- Ensure verifier emits `./evidence/phase0/revocation_tables.json`.
Acceptance Criteria:
- Tables exist and cannot be updated/deleted.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/verify_invariants.sh`
Evidence Artifact(s):
- `./evidence/phase0/revocation_tables.json`
Failure Modes:
- Mutations allowed or tables missing.
- Evidence file missing.
Notes:
- Invariant registration is handled by TSK-P0-009.

TASK ID: TSK-P0-026
Title: Core boundary guard (no Node in core paths)
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-001
Touches: `scripts/security/lint_core_boundary.sh`, `.github/workflows/invariants.yml`
Invariant(s): NEW INV-037 (Core code boundary enforced)
Work:
- Lint core paths to forbid `.js/.ts/package.json` only inside core directories.
- Pass if core dirs are absent (repo structure gate already enforced).
- Ensure lint emits `./evidence/phase0/core_boundary.json`.
Acceptance Criteria:
- CI fails if Node artifacts exist in core paths.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/security/lint_core_boundary.sh`
Evidence Artifact(s):
- `./evidence/phase0/core_boundary.json`
Failure Modes:
- Forbidden artifacts present.
- Evidence file missing.
Notes:
- Invariant registration is handled by TSK-P0-009.

TASK ID: TSK-P0-027
Title: Phase-0 doc drift cleanup (.NET-only core)
Owner Role: ARCHITECT
Depends On: none
Touches: `docs/overview/architecture.md`, `docs/decisions/ADR-0001-repo-structure.md`, `tasks/TSK-P0-027/meta.yml`
Invariant(s): NEW INV-038 (Architecture doc alignment)
Work:
- Remove Node-as-core references.
- Clarify .NET-only execution core.
Acceptance Criteria:
- Core architecture docs have no Node-as-core references.
Verification Commands:
- `rg -n "node|Node.js" docs/overview/architecture.md docs/decisions/ADR-0001-repo-structure.md`
Evidence Artifact(s):
- `./evidence/phase0/doc_alignment.json`
Failure Modes:
- Node references remain in core docs.

TASK ID: TSK-P0-028
Title: Define DB distress invariant (roadmap only)
Owner Role: INVARIANTS_CURATOR
Depends On: none
Touches: `docs/invariants/INVARIANTS_MANIFEST.yml`, `docs/invariants/INVARIANTS_ROADMAP.md`, `tasks/TSK-P0-028/meta.yml`
Invariant(s): NEW INV-039 (Fail-closed under DB exhaustion — roadmap)
Work:
- Define invariant as roadmap with verification notes.
Acceptance Criteria:
- Invariant listed as roadmap, not implemented.
Verification Commands:
- `scripts/audit/run_invariants_fast_checks.sh`
Evidence Artifact(s):
- `./evidence/phase0/db_fail_closed_roadmap.json`
Failure Modes:
- Marked implemented without tests.

TASK ID: TSK-P0-029
Title: Expand DDL lock-risk lint for blocking operations
Owner Role: SECURITY_GUARDIAN
Depends On: TSK-P0-004, TSK-P0-030
Touches: `scripts/security/lint_ddl_lock_risk.sh`
Invariant(s): NEW INV-040 (Blocking DDL policy enforced)
Work:
- For hot tables, require `CREATE INDEX CONCURRENTLY` and forbid blocking `ALTER` patterns.
- Keep this as migration lint (not runtime privilege gate).
- Ensure lint emits `./evidence/phase0/ddl_blocking_policy.json`.
Acceptance Criteria:
- CI fails on blocked patterns in migrations.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/security/lint_ddl_lock_risk.sh`
Evidence Artifact(s):
- `./evidence/phase0/ddl_blocking_policy.json`
Failure Modes:
- Unsafe DDL passes lint.
- Evidence file missing.
Notes:
- Invariant registration is handled by TSK-P0-009.

TASK ID: TSK-P0-030
Title: Add no-tx migration marker support in migrate.sh
Owner Role: DB_FOUNDATION
Depends On: none
Touches: `scripts/db/migrate.sh`, `scripts/db/tests/test_no_tx_migrations.sh`
Invariant(s): NEW INV-041 (No-tx migrations supported)
Work:
- Implement `-- symphony:no_tx` marker parsing.
- Run marked migrations outside explicit transaction.
- Add a DB test to apply a `CONCURRENTLY` migration via migrate.sh.
- Ensure test emits `./evidence/phase0/no_tx_migrations.json`.
Acceptance Criteria:
- Migrations with marker succeed with `CONCURRENTLY`.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/tests/test_no_tx_migrations.sh`
Evidence Artifact(s):
- `./evidence/phase0/no_tx_migrations.json`
Failure Modes:
- Concurrent index migration fails due to transaction wrapping.
- Evidence file missing.

TASK ID: TSK-P0-031
Title: Enforce no-tx marker for concurrent index migrations
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-030
Touches: `scripts/db/lint_migrations.sh`
Invariant(s): NEW INV-042 (Concurrent index requires no-tx marker)
Work:
- Update migration lint to require marker when `CONCURRENTLY` appears.
- Ensure lint emits `./evidence/phase0/no_tx_marker_lint.json`.
Acceptance Criteria:
- CI fails on missing marker.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/lint_migrations.sh`
Evidence Artifact(s):
- `./evidence/phase0/no_tx_marker_lint.json`
Failure Modes:
- Concurrent index migration without marker passes lint.
- Evidence file missing.

TASK ID: TSK-P0-032
Title: Update outbox index migration to use no-tx marker
Owner Role: DB_FOUNDATION
Depends On: TSK-P0-030, TSK-P0-031
Touches: `schema/migrations/0007_outbox_pending_indexes.sql`, `scripts/db/tests/test_outbox_pending_indexes.sh`
Invariant(s): INV-031 (Outbox claim index required)
Work:
- Add `-- symphony:no_tx` to concurrent index migration.
- Ensure `IF NOT EXISTS` is used.
- Add DB test to verify index exists and emit evidence.
Acceptance Criteria:
- Migration runs successfully via migrate.sh.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/db/tests/test_outbox_pending_indexes.sh`
Evidence Artifact(s):
- `./evidence/phase0/outbox_pending_indexes.json`
Failure Modes:
- Migration fails due to transaction wrapping.
- Evidence file missing.

TASK ID: TSK-P0-033
Title: Document no-tx marker usage
Owner Role: ARCHITECT
Depends On: TSK-P0-030
Touches: `docs/operations/DEV_WORKFLOW.md`, `tasks/TSK-P0-033/meta.yml`
Invariant(s): NEW INV-043 (No-tx migration guidance)
Work:
- Document `-- symphony:no_tx` usage with example.
Acceptance Criteria:
- Guidance present in DEV workflow docs.
Verification Commands:
- `rg -n "symphony:no_tx" docs/operations/DEV_WORKFLOW.md`
Evidence Artifact(s):
- `./evidence/phase0/no_tx_docs.json`
Failure Modes:
- No documentation present.

TASK ID: TSK-P0-034
Title: Enforce invariants docs match manifest
Owner Role: INVARIANTS_CURATOR
Depends On: TSK-P0-009
Touches: `scripts/audit/run_invariants_fast_checks.sh`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `docs/invariants/INVARIANTS_IMPLEMENTED.md`, `docs/invariants/INVARIANTS_ROADMAP.md`, `docs/invariants/INVARIANTS_QUICK.md`, `tasks/TSK-P0-034/meta.yml`
Invariant(s): NEW INV-044 (Docs match manifest)
Work:
- Ensure `scripts/audit/check_docs_match_manifest.py` is run in fast checks.
- Emit evidence `./evidence/phase0/invariants_docs_match.json`.
Acceptance Criteria:
- Fast checks fail if docs drift from manifest.
- Evidence file is written by the verification step.
Verification Commands:
- `scripts/audit/run_invariants_fast_checks.sh`
Evidence Artifact(s):
- `./evidence/phase0/invariants_docs_match.json`
Failure Modes:
- Drift between docs and manifest goes undetected.
- Evidence file missing.

TASK ID: TSK-P0-035
Title: Declare Proxy/Alias Resolution invariant (roadmap) + schema design hooks
Owner Role: INVARIANTS_CURATOR
Depends On: TSK-P0-009
Touches: `docs/invariants/INVARIANTS_MANIFEST.yml`, `docs/architecture/adrs/ADR-0008-proxy-resolution-strategy.md`, `docs/architecture/schema/proxy_resolution_schema.md`, `scripts/audit/verify_proxy_resolution_invariant.sh`, `tasks/TSK-P0-035/meta.yml`
Invariant(s): NEW INV-048 (Proxy/Alias resolution required before dispatch)
Work:
- Add invariant as `roadmap`, explicitly defining resolve point, durable record fields (hash-only), fail-closed rule, and outbox/idempotency linkage.
- ADR documents resolve-before-enqueue vs resolve-before-dispatch decision, failure modes, and evidence requirements.
- Add schema design doc describing `proxy_resolutions` (append-only) and optional `proxy_resolution_current` (cache), including indexes and prohibited fields.
- Verification script performs static checks only (manifest entry + ADR + schema doc exist + references correct) and emits evidence.
Acceptance Criteria:
- Invariant exists with `status: roadmap` and a concrete verification hook.
- ADR + schema design doc exist and are referenced.
- Evidence artifact emitted and passes schema validation/anchoring rules.
Verification Commands:
- `scripts/audit/verify_proxy_resolution_invariant.sh`
Evidence Artifact(s):
- `./evidence/phase0/proxy_resolution_invariant.json`
Failure Modes:
- INV-048 missing or malformed.
- ADR/schema design doc missing.
- Evidence file missing.
