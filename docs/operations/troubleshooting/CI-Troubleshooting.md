# CI Troubleshooting

## Quick Checklist (do this first)

1) **Identify the failing job and error**
   - Look for the first red job in the Actions run.
   - If it is the evidence gate, you will see: `Missing evidence artifacts`.

2) **Copy the missing evidence list**
   - Save the exact filenames shown in the CI log (e.g., `repo_structure.json`, `baseline_drift.json`, etc.).

3) **Map each missing file to its producing script**
   - Use `rg -n "evidence/phase0" scripts` to locate which script writes each file.

4) **Map each script to its CI job**
   - Mechanical: docs + audit scripts (no DB)
   - DB: scripts requiring `DATABASE_URL`
   - Security: security lints + OpenBao

5) **Confirm the workflow runs those scripts**
   - Open `.github/workflows/invariants.yml` and verify each script is invoked.

6) **Verify dependencies exist in CI**
   - If a script needs Python deps (pyyaml/jsonschema), ensure they are installed before the script runs.

7) **Confirm evidence artifacts are uploaded**
   - Each job must upload `evidence/**` as an artifact.

8) **Re-run locally**
   - Use `scripts/ci/run_ci_locally.sh` and verify the evidence gate passes.

---

## Detailed Step-by-Step Report

### Problem Summary
- CI failed in the **Phase 0 — Evidence gate** job.
- The error was `Missing evidence artifacts` for many `TSK-P0-XXX` evidence files.
- Root cause: the evidence gate was checking for files that **were not being produced or uploaded** by the upstream CI jobs.

### 1) Identify where the failure occurs
- CI log showed failure in:
  ```
  Phase 0 — Evidence gate (cross-job)
  CI_ONLY=1 scripts/ci/check_evidence_required.sh evidence/phase0
  Missing evidence artifacts: ...
  ```
- This means the final evidence gate ran, but upstream evidence files were not present.

### 2) Confirm how the gate decides “missing”
- The evidence gate runs `scripts/ci/check_evidence_required.sh`.
- It reads every `tasks/*/meta.yml` and expects each **Evidence Artifact(s)** entry to exist under `evidence/phase0`.

### 3) Map each missing file to the script that should produce it
- Use `rg -n "evidence/phase0" scripts` to find the producer for each artifact.
- Example mapping:
  - `repo_structure.json` → `scripts/audit/verify_repo_structure.sh`
  - `evidence.json` → `scripts/audit/generate_evidence.sh`
  - `baseline_drift.json` → `scripts/db/check_baseline_drift.sh`
  - `ddl_lock_risk.json` → `scripts/security/lint_ddl_lock_risk.sh`
  - `openbao_smoke.json` → `scripts/security/openbao_smoke_test.sh`
  - `outbox_pending_indexes.json` → `scripts/db/verify_outbox_pending_indexes.sh`

### 4) Determine which CI job should run each script
- **Mechanical job**: docs + non‑DB audit scripts
- **DB job**: scripts requiring `DATABASE_URL`
- **Security job**: security lints + OpenBao

### 5) Compare workflow steps vs required evidence
- Open `.github/workflows/invariants.yml` and verify the job contains the script for each evidence file.
- If a script is missing from the workflow, the evidence will never exist.

### 6) Fix the workflow to run evidence producers

**Mechanical job fixes**
- Ensure these run:
  - `verify_repo_structure.sh`
  - `generate_evidence.sh`
  - `validate_evidence_schema.sh`
  - `generate_invariants_quick`
  - `verify_batching_rules.sh`
  - `verify_routing_fallback.sh`
  - `validate_routing_fallback.sh`
  - `verify_doc_alignment.sh`
  - `verify_no_tx_docs.sh`
  - `run_invariants_fast_checks.sh`
  - `enforce_change_rule.sh`
- Add Python deps (pyyaml/jsonschema) before scripts that require them.

**DB job fixes**
- Ensure these run:
  - `verify_invariants.sh`
  - `n_minus_one_check.sh`
  - `test_db_functions.sh`
  - `test_idempotency_zombie.sh`
  - `test_no_tx_migrations.sh`

**Security job fixes**
- Ensure these run:
  - `run_security_fast_checks.sh`
  - `lint_ddl_lock_risk.sh`
  - `lint_security_definer_dynamic_sql.sh`
  - `openbao_smoke_test.sh`

### 7) Ensure artifacts are uploaded correctly
- Each job must upload `evidence/**` as an artifact.
- The evidence gate downloads `phase0-evidence*` and merges into repo root.
- The evidence gate then runs:
  ```
  CI_ONLY=1 scripts/ci/check_evidence_required.sh evidence/phase0
  ```

### 8) Verify locally
- Run the same order of steps locally (`scripts/ci/run_ci_locally.sh`).
- Confirm:
  - `evidence/phase0/*.json` files exist
  - `check_evidence_required.sh` passes

### Root Cause (One‑line version)
**CI was enforcing evidence files listed in task metadata, but the workflow didn’t run the scripts that generate them (or lacked dependencies), so evidence artifacts were never created or uploaded.**

## Note: Schema Fingerprints (Baseline vs Migrations)

Phase-0 evidence uses `schema_fingerprint` as a schema anchor. Convention:
- `schema_fingerprint`: hash of `schema/baseline.sql` (canonical Phase-0 schema artifact)
- `migrations_fingerprint`: hash of `schema/migrations/*.sql` in sorted order (migration stream anchor)

If these are mixed under a single field name, evidence becomes semantically inconsistent even if each hash is deterministic.

### How to Fix It Next Time (Summary)
1) Identify the missing artifacts in CI.
2) Map each file to its producer script.
3) Ensure that script runs in the correct CI job.
4) Confirm dependencies are installed.
5) Confirm `evidence/**` is uploaded.
6) Re-run locally and in CI.
