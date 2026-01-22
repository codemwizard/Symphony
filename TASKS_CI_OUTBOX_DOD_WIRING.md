# Tasks List: CI Wiring for Outbox Lease DoD Sweep

## A) Regression gate
1) Add a post-test query gate in `.github/workflows/ci-security.yml`:
   - `SELECT COUNT(*) FROM public.payment_outbox_attempts WHERE state = 'DISPATCHING';`
2) Run after integration tests when present.
3) Print the count and fail CI if the count is non-zero (use `psql -tA`).

## B) Outbox evidence generation
1) Add a step to run `scripts/reports/generate-outbox-evidence.sh`.
2) Export `OUTBOX_EVIDENCE_DB_URL=$DATABASE_URL` for clarity (optional).
3) Ensure the script is executable (`chmod +x` if needed).
4) Run with `if: always()` for best-effort evidence on failures.

## C) Outbox evidence artifact upload
1) Upload `reports/outbox-evidence/` as `outbox-evidence`.
2) Use `if: always()` so artifacts upload on failure.
3) Set retention days (default 14 unless policy overrides).

## D) Acceptance criteria
1) CI fails when DISPATCHING attempts exist.
2) Outbox evidence bundle is generated during CI.
3) Outbox evidence artifact is available on both success and failure.
