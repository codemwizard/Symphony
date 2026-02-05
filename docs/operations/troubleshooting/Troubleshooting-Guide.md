# Troubleshooting Guide

## Continuous Integration (CI)

### Evidence Gate Failures (Phase 0)

#### Genesis: what the issue was
The Phase‑0 evidence gate failed even though upstream jobs uploaded artifacts. The gate reported dozens of “Missing evidence artifacts,” which turned out to be **false negatives** caused by **path mismatches and artifact extraction layout**, not by missing evidence generation. The checker was looking for evidence under `evidence/phase0/`, while the downloaded artifacts were unpacked under different nested paths.

#### Final Workflow Order (current invariants.yml)
1) Download evidence artifacts  
2) Debug & normalize artifact layout  
3) Require Phase‑0 evidence

#### Step‑by‑step troubleshooting

1) **Identify the failing job**
   - Look for:
     ```
     Phase 0 — Evidence gate (cross-job)
     CI_ONLY=1 scripts/ci/check_evidence_required.sh evidence/phase0
     Missing evidence artifacts: ...
     ```

2) **Confirm artifacts downloaded**
   - The job must run:
     ```
     actions/download-artifact@v4
     pattern: phase0-evidence*
     merge-multiple: true
     path: evidence/phase0
     ```

3) **Use the debug + normalize step output**
   - This step prints:
     - workspace listing
     - evidence* directories
     - any `TSK-P0-*` files
     - final `evidence/phase0` contents
   - If you see `No TSK-P0-* files found`, the issue is upstream evidence production.

4) **Verify canonical evidence location**
   - After normalization, evidence must live here:
     ```
     evidence/phase0/*.json
     ```

5) **Map missing files to producer scripts**
   - Use:
     ```bash
     rg -n "evidence/phase0" scripts
     ```
   - Examples:
     - `repo_structure.json` → `scripts/audit/verify_repo_structure.sh`
     - `baseline_drift.json` → `scripts/db/check_baseline_drift.sh`
     - `ddl_lock_risk.json` → `scripts/security/lint_ddl_lock_risk.sh`

6) **Confirm producers run in the correct job**
   - mechanical_invariants → audit/docs scripts  
   - db_verify_invariants → DB scripts/tests  
   - security_scan → security scripts/OpenBao

7) **Confirm evidence upload in each job**
   - Each job must upload:
     ```
     evidence/**
     ```

8) **Validate locally with CI parity**
   - Run:
     ```bash
     CI_WIPE=1 DATABASE_URL=postgres://symphony_admin:symphony_pass@127.0.0.1:5432/symphony \
       scripts/ci/run_ci_locally.sh
     ```

#### Notes from GitHub-specific troubleshooting
- Artifact extraction layout is not guaranteed; use the **debug + normalize step**.
- Diagnostic loop must use `nullglob` (no `compgen` + `|| true`).
- If no `TSK-P0-*` files exist after normalization, producers didn’t emit evidence.
- Placeholder evidence is an emergency‑only mitigation and should be removed once producers are fixed.
