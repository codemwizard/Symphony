# Parity Gaps (Local vs CI)

This document tracks **known differences** between local runs and CI runs that can cause checks to pass locally but fail in CI (or vice‑versa). Each gap should be closed with a concrete mitigation.

## PG‑001: Evidence artifact layout (CI merge vs local paths)

**Symptom**
- CI runs `actions/download-artifact` with `merge-multiple: true` into `evidence/phase0`.
- Artifacts may unpack with nested paths like:
  - `evidence/phase0/evidence/phase0/*.json`
- Local runs usually write evidence to `evidence/phase0/*.json` directly.
- Result: evidence validators can report “missing evidence” in CI even though artifacts are present.

**Why it wasn’t caught locally**
- Local runs do not emulate the CI artifact merge/unpack layout.
- Validators looked in repo‑root paths only.

**Fix already applied**
- `scripts/audit/verify_phase0_contract_evidence_status.sh` now supports an `EVIDENCE_ROOT` and nested layout fallback.
- CI sets `EVIDENCE_ROOT="evidence/phase0"` before running the verifier.

**Residual risk**
- Local checks still do not simulate CI artifact layout.

**Mitigation (planned)**
- Extend `scripts/ci/run_ci_locally.sh` to:
  1. Copy evidence into a simulated `evidence/phase0/` merge directory
  2. Run `verify_phase0_contract_evidence_status.sh` with `EVIDENCE_ROOT` set
- Add a local “artifact‑merge simulator” helper (e.g., `scripts/ci/simulate_artifact_merge.sh`).

**Status**: Mitigated in CI, pending local parity simulation.

---

## PG‑002: CI toolchain pinning vs local environment

**Symptom**
- `scripts/audit/verify_ci_toolchain.sh` checks pinned versions (PyYAML/jsonschema/rg).
- Local environments can differ (e.g., distro‑pinned versions, missing pip).
- This can fail locally while CI passes.

**Why it wasn’t caught locally**
- Local machines may not have CI‑pinned dependencies installed.

**Mitigation**
- Ordered checks skip toolchain verification locally (`SYMPHONY_SKIP_TOOLCHAIN_CHECK=1`).
- CI remains authoritative.

**Planned parity improvement**
- Document a local `venv` setup with pinned versions.
- Add a `scripts/ci/bootstrap_local_toolchain.sh` helper to align local versions.

**Status**: CI authoritative; local parity pending.

---

## PG‑003: Docker daemon access (OpenBao + DB)

**Symptom**
- Local tests may fail due to Docker socket permissions (OpenBao bootstrap, DB connectivity).
- CI has Docker access; local user may not.

**Mitigation**
- Document required local Docker setup (group membership or sudo). 
- For CI‑only checks, allow `verification_mode: ci` in contract where appropriate.

**Status**: Documented; parity depends on local Docker permissions.

---

## How to add a new parity gap

When a CI failure cannot be reproduced locally, add a new `PG‑###` entry with:
- Symptom
- Why it wasn’t caught locally
- Fix applied (if any)
- Residual risk
- Planned mitigation
- Status
