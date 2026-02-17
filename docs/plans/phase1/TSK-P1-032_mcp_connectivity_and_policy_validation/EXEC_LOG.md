# TSK-P1-032 Execution Log

## 2026-02-16
- Planned connectivity and policy validation workflow.
- Ran `bash scripts/dev/pre_ci.sh` and captured fail-closed remediation loop:
  1. Failure: YAML parse error in governance preflight (`verify_task_plans_present.sh`) due backticks in task meta list items.
     - Remediation: removed markdown backticks from `tasks/TSK-P1-031/meta.yml` and `tasks/TSK-P1-032/meta.yml`.
  2. Failure: Docker postgres bind error on host port `5432` (already in use by local PostgreSQL 18/main).
     - Remediation:
       - made DB host port configurable in `infra/docker/docker-compose.yml` via `${HOST_POSTGRES_PORT:-5432}`.
       - updated `scripts/dev/pre_ci.sh` to auto-fallback to `55432` when `5432` is occupied.
  3. Failure: fallback conflict when rerunning (`5432` and `55432` both in use) while `symphony-postgres` already owned `55432`.
     - Remediation: updated `scripts/dev/pre_ci.sh` port selector to treat ports owned by `symphony-postgres` as reusable.
  4. Failure: baseline drift check connection refused on `localhost:55432` when `check_baseline_drift.sh` switched to `docker exec pg_dump`.
     - Root cause: container-local `localhost` is not host `localhost`.
     - Remediation: updated `scripts/db/check_baseline_drift.sh` to keep host `pg_dump` when `DATABASE_URL` host is loopback (`localhost`, `127.0.0.1`, `::1`).
- Re-ran `bash scripts/dev/pre_ci.sh` after each remediation until full PASS.
- Final status: `✅ Pre-CI local checks PASSED.`
