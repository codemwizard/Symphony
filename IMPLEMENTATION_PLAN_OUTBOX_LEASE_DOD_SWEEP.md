# Implementation Plan: Lease Model Definition-of-Done Sweep

## Objective
Make the lease model provably the only operational truth and fully operable in production by gating CI on evidence/guardrails/proofs, adding minimal operational signals, enforcing a regression query, and improving evidence bundle readability.

## Scope
- CI job that runs guardrails, unit proofs, integration proofs (DB-gated), evidence generation, and artifact upload in order.
- Operational signals for lease health and terminal-guard anomalies.
- Mandatory regression query asserting no DISPATCHING attempts.
- Evidence bundle README describing files and proof mappings.
- Release hygiene to remove “zombie” terminology and align config names to lease terminology.

## Non-goals
- Reworking the lease model or DB functions.
- Redesigning existing CI structure beyond adding a required job/step sequence.
- Adding full metrics infrastructure; only minimal logging/hooks.

---

## 1) CI gate: evidence + guardrails + proofs as a single workflow

### Files
- CI workflow file (path to be provided, e.g., `ci/*.yml` or `.github/workflows/*.yml`)

### Task 1.1 — Add a single ordered job
- Run in this order:
  1) guardrails with `ENFORCE_NO_DB_QUERY=1`
  2) unit tests
  3) integration tests (only if DB secret present)
  4) evidence generation
  5) artifact upload (always runs, even on failure)

### Task 1.2 — Make the job required
- Mark the job as a required status check in repo settings.

### Definition of Done
- CI fails if any step fails or is skipped incorrectly.
- Evidence bundle is uploaded as an artifact on every run (success or fail).

---

## 2) Red-flag operational alerting (minimal but high ROI)

### Files
- Worker/relayer logging/metrics modules (to be identified)

### Task 2.1 — Lease health counters
- Add log counters (or metric hooks) for:
  - `expired_lease_count` (from view/query)
  - `repair_requeued_count`
  - `lease_lost_count` (SQLSTATE `P7002`)
  - `terminal_guard_hit_count` (unique index violation `23505` on `payment_outbox_attempts_one_terminal_per_outbox`)

### Task 2.2 — Operational semantics
- Log these as operational signals, not errors.
- Ensure counter increments are deterministic (one per event).
- Rate-limit or aggregate per cycle if volumes spike.
- Log `LEASE_LOST_CONCURRENCY_EVENT` at info/warn for `P7002`.

### Definition of Done
- Logs/metrics surface the four signals without noise.

---

## 3) Regression query gate (mandatory)

### Files
- CI workflow file (same as Section 1)
- Optional: new helper script under `scripts/ci/`

### Task 3.1 — Add post-test invariant check
- Run:
  - `SELECT COUNT(*) FROM payment_outbox_attempts WHERE state='DISPATCHING';`
- Fail CI if result is non-zero.
- DB-gate the check (only run when DB secret is present).
- Run after integration tests (not just after unit tests).

### Definition of Done
- CI fails when any DISPATCHING attempts exist.

---

## 4) Evidence bundle completeness pass

### Files
- `scripts/reports/generate-outbox-evidence.sh`
- `reports/outbox-evidence/00_README.txt` (generated)

### Task 4.1 — Add README in evidence bundle
- Generate `00_README.txt` explaining:
  - contents of each file
  - invariants proven
  - SQLSTATE expectations tied to proofs (include a short mapping list)

### Definition of Done
- Evidence bundle is self-explanatory to auditors without tribal knowledge.

---

## 5) Release hygiene

### Files
- Docs/config/log labels (to be identified)

### Task 5.1 — Remove zombie terminology
- Replace “zombie” with “lease repair” in docs/config/log labels.
- Align config keys to lease naming:
  - `LEASE_SECONDS`
  - `LEASE_REPAIR_BATCH_SIZE`

### Definition of Done
- No user-facing “zombie” terminology remains in current docs/config/log labels.

---

## Open Questions / Decisions Needed
- CI workflow file path and DB secret names (resolved: `.github/workflows/ci-security.yml`, `OUTBOX_EVIDENCE_DB_URL`).
- Preferred location for regression query step (inline vs script).
- Logging vs metrics system for operational counters.
