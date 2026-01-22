# Implementation Plan: CI Wiring for Outbox Lease DoD Sweep

## Objective
Wire the lease-model DoD sweep into the existing `security-gates` workflow so regression checks, outbox evidence generation, and artifact uploads are enforced in CI.

## Scope
- Add a DISPATCHING regression gate in CI.
- Generate outbox evidence bundle with the new script (always).
- Upload outbox evidence artifact with `if: always()` so evidence persists on failures.

## Non-goals
- Refactoring other CI stages or the global evidence bundle.
- Changing test contents or database schema.

---

## 1) Regression gate: no DISPATCHING attempts

### File
- `.github/workflows/ci-security.yml`

### Task 1.1 — Add a mandatory regression query
- Place after integration tests (or after unit tests if no integration tests run).
- Run:
  - `SELECT COUNT(*) FROM public.payment_outbox_attempts WHERE state = 'DISPATCHING';`
- Print the count and fail CI if result is non-zero.
- Use a scalar, headerless output (`psql -tA`) to avoid brittle parsing.

### Definition of Done
- CI fails if any DISPATCHING attempts exist.

---

## 2) Generate outbox evidence bundle

### File
- `.github/workflows/ci-security.yml`

### Task 2.1 — Add evidence generation step
- Run `scripts/reports/generate-outbox-evidence.sh`.
- Set `OUTBOX_EVIDENCE_DB_URL` to `DATABASE_URL` explicitly for clarity (optional).
- Ensure the script is executable (chmod if needed).
- Run with `if: always()` so evidence is captured even on failures.

### Definition of Done
- `reports/outbox-evidence/` is created during CI runs.

---

## 3) Upload outbox evidence artifact (always)

### File
- `.github/workflows/ci-security.yml`

### Task 3.1 — Upload artifact with `if: always()`
- Upload `reports/outbox-evidence/` as `outbox-evidence`.
- Use `if: always()` so artifacts persist even on failures.
- Set retention days (default to 14 unless policy overrides).

### Definition of Done
- Outbox evidence artifact is available on both success and failure.

---

## Placement Guidance (recommended order)
1) Unit tests
2) Integration tests (if DB-gated)
3) Regression gate: no DISPATCHING attempts
4) Generate outbox evidence bundle (always)
5) Upload outbox evidence artifact (always)
6) Continue with remaining security/compliance/evidence steps

---

## Open Questions / Decisions Needed
- Confirm whether to run the regression gate after unit tests if integration tests are skipped.
- Confirm retention days for the outbox evidence artifact (if required).
