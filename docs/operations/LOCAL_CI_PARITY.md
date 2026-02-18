# Local CI Parity Runner (Destructive)

This document defines the **local CI parity** workflow. It is intentionally destructive: it wipes the local Symphony database to ensure a clean, CI-equivalent run.

## Requirements

- Postgres 18 running (same major version as CI).
- Docker container `symphony-postgres` is up.
- `DATABASE_URL` points to the local DB.
- You must set `CI_WIPE=1`.

## Run

```bash
CI_WIPE=1 DATABASE_URL=postgres://symphony_admin:symphony_pass@127.0.0.1:5432/symphony \
  scripts/ci/run_ci_locally.sh
```

## What it does

1. Wipes and recreates the `symphony` database.
2. Runs the same steps and order as CI:
   - `scripts/audit/run_invariants_fast_checks.sh`
   - `scripts/db/verify_invariants.sh`
   - `scripts/db/n_minus_one_check.sh`
   - `scripts/db/tests/test_db_functions.sh`
   - `scripts/audit/run_security_fast_checks.sh`
   - `CI_ONLY=1 scripts/ci/check_evidence_required.sh`
3. Emits evidence `./evidence/phase0/local_ci_parity.json`.

## Safety

This is destructive by design. If you want a non-destructive run, do **not** set `CI_WIPE=1`.
