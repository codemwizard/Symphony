# Environment Divergence Optimization Log

Purpose: record issues where **the same repo code behaves differently across environments**
(local vs CI, different shells, different tooling, different file permissions, different Docker state),
and track the remediation plus any follow-up hardening work.

This is not a bug tracker replacement. It is a **high-signal engineering log** for:
- non-determinism sources
- environment-sensitive failure modes
- mitigations that improve parity and reduce CI noise

## Entry Template

### ID
- `ENV-DIV-YYYY-MM-DD-<slug>`

### Symptom
- What failed and where (local vs CI). Include the exact command and exit code.

### Root Cause
- The mechanism causing divergence (toolchain, OS, shell semantics, Docker, git diff base, etc.).

### Repro Notes
- How to reproduce in each environment.

### Fix Applied
- What was changed (files/scripts), and why it eliminates divergence.

### Verification
- Commands run to confirm parity.

### Follow-ups
- Optional hardening items (tests, lints, doc updates, guardrails).

---

## Entries

### ENV-DIV-2026-02-12-printf-broken-pipe

#### Symptom
- CI failed running `scripts/security/lint_ddl_lock_risk.sh` with:
  - `printf: write error: Broken pipe`
  - exit code `1`
- Local runs did not reproduce.

#### Root Cause
- The script used a `pipefail`-sensitive pattern: `printf ... | python3 - <<PY ...`.
- In CI the consumer (Python) exited early, closing the pipe; the producer (`printf`) received `SIGPIPE`,
  which becomes fatal under `set -euo pipefail`.
- Locally the match set was empty/small enough that the pipe did not trigger the failure.

#### Repro Notes
- Environment-sensitive: occurs when the producer writes while the consumer has already terminated.

#### Fix Applied
- Removed the pipe by writing the filtered match list to a temp file and having Python read it.
- This prevents `SIGPIPE` and ensures any Python failure surfaces as the real error.
- Changed file: `scripts/security/lint_ddl_lock_risk.sh`.

#### Verification
- `bash scripts/security/lint_ddl_lock_risk.sh`
- `bash scripts/audit/run_phase0_ordered_checks.sh`

#### Follow-ups
- Prefer temp-file handoff over pipelines for evidence generation in shell scripts that run under
  `set -euo pipefail`, unless the consumer is guaranteed to read fully.
- Add a regression-style check: a small unit test that exercises the evidence emitter with non-empty input.

