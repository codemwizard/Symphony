# Invariants System — Technical Specification (SDD)

## 1. Purpose

This document specifies the design of the Invariants System: a deterministic, developer-friendly set of
gates and tooling that (1) detects structural changes, (2) enforces invariant documentation updates
(or recorded exceptions), (3) verifies DB invariants, and (4) optionally runs Codex-based advisory reviews.

The system is explicitly designed to be explainable: when something fails, the developer should be able
to (a) see what failed, (b) see why, and (c) know exactly what to change to fix it.

## 2. Background and Problem Statement

The repo introduced a "change-rule" gate that blocks merges when structural changes occur without
corresponding invariant documentation updates.

Two real problems were observed:

- Local vs CI drift: developers could run local scripts and pass, then fail in CI because pre-push
  hooks weren't installed or local workflows didn't run the same gates.
- Non-deterministic or opaque failures in Codex steps: GitHub would show a green check for the Codex
  job while the Codex action logs contained an underlying failure (exit code 1), making it hard to trust
  the pipeline.

The project work so far focused on making the system more deterministic and aligned between local and CI.

## 3. Goals

### 3.1 Determinism goals

- Structural-change detection is deterministic on a given diff.
- Rule enforcement is deterministic and fails closed.
- Failures are explainable from logs and artifacts (no "mystery red").
- Local pre-CI catches the same issues CI will catch.

### 3.2 Phase-1 gating goals

If structural changes are detected, the PR must include either:

- An update to `docs/invariants/**` and/or `docs/invariants/INVARIANTS_MANIFEST.yml` that references
  `INV-###` tokens, or
- A timeboxed exception file in `docs/invariants/exceptions/`.

### 3.3 Policy seeding Phase-1 goals (DB)

- Exactly one ACTIVE policy.
- Idempotent seeding when ACTIVE version/checksum match.
- Fail closed if a different ACTIVE version exists.
- Tests validate failure modes and assert no side effects.

## 4. Non-Goals

- Phase-2 policy rotation (GRACE/RETIRED flows).
- Altering schema/migration logic beyond Phase-1 invariants.
- Using Codex output as a hard requirement for merge (Codex is advisory).

## 5. System Overview

The system is composed of:

- Detector: parses a unified diff and reports whether the change is structural.
- Change-rule gate (Rule 1): if structural, requires docs/manifest update or exception.
- Promotion gate: ensures invariant docs are "promoted" properly (no bypass patterns).
- Fast checks: quick invariants/security checks that run without a DB.
- DB verification: runs migrations and verifies DB invariants and functions.
- Codex advisory reviews: generates human-readable summaries/patch suggestions and comments on the PR.

### 5.1 Architecture diagram (conceptual)

Developer workstation                      GitHub Actions (CI)
---------------------                      ------------------
(pre-commit/pre-push)                      Phase I: Mechanical gates
   |                                           |
   v                                           v
pre_ci.sh (local)                         detect_structural_changes.py
   |                                           |
   +--> preflight_structural_staged.sh          +--> enforce_change_rule.sh (Rule 1)
   +--> fast invariants/security checks         +--> promotion + templates + QUICK drift
   +--> DB function tests                       |
   +--> policy seed checksum tests              +--> upload detector artifacts


                                             Phase II (optional/advisory)
                                               codex-action (invariants)
                                               codex-action (security)
                                               codex-action (compliance)


                                             DB verify job
                                               verify_invariants.sh + DB tests

## 6. Components (Design)

### 6.1 Structural Change Detector

Primary module: `scripts/audit/detect_structural_changes.py`

Responsibilities:

- Read a unified diff (`git diff --unified=0`) from a file.
- Extract per-line context: file, sign (+/-), and the changed line.
- Match against a set of keywords/patterns for:
  - DDL / schema changes (e.g., CREATE TABLE, ALTER, REFERENCES, indexes)
  - Privilege/security changes (e.g., GRANT, REVOKE, SECURITY DEFINER, SET ROLE, search_path)
  - Migration additions/deletions (filename-level)
- Produce a JSON report:
  - `structural_change: boolean`
  - `confidence_hint: float` (heuristic)
  - `matches[]`: list of match objects `{type, pattern, file, sign, line}`
  - Optional metadata fields (reason types, primary reason, matched files, counts)

Inputs:

- `--diff-file`: unified diff

Outputs:

- JSON file (for example `/tmp/invariants_ai/detect.json` in CI)

Determinism and Observability:

- Deterministic on the diff.
- Debuggable because `matches[]` and optional metadata explain why it classified structural.

### 6.2 Change-rule Gate (Rule 1)

Module: `scripts/audit/enforce_change_rule.sh`

Responsibilities:

- Compute or receive a diff range (CI uses committed refs; local can use staged preflight).
- Run the detector to determine `structural_change`.
- If `structural_change=false`: exit success.
- If `structural_change=true`: enforce Rule 1 linkage:
  - PR must include invariants docs/manifest updates or a valid exception.
- Emit a clear error explaining what is missing and how to fix it.

Key behaviors:

- Supports env overrides (`BASE_REF`, `HEAD_REF`, sometimes `STRUCTURAL_CHANGE`).
- Must fail closed when structural and no linkage/exception exists.

### 6.3 Local Structural Preflight (Staged)

Module: `scripts/audit/preflight_structural_staged.sh`

Why this exists:

- CI gates use committed refs (for example `origin/main...HEAD`).
- Locally, developers often iterate with uncommitted or staged changes.
- If the gate only inspects committed diffs, it cannot "see" an uncommitted exception file or doc update.

Responsibilities:

- If no staged changes: skip.
- Else generate diff from staged index and run detector/gate logic.
- Provide the same signal as CI, but for local "what you're about to commit/push".

### 6.4 Invariant Documentation System

Primary docs: `docs/invariants/**`

Key artifacts:

- `INVARIANTS_MANIFEST.yml`: machine-readable list of invariants and enforcement points.
- `INVARIANTS_IMPLEMENTED.md`: invariants already implemented.
- `INVARIANTS_ROADMAP.md`: planned invariants.
- `INVARIANTS_QUICK.md`: generated snapshot for fast scanning.
- `exceptions/`: timeboxed exception records.
- `exceptions/EXCEPTION_TEMPLATE.md`: required template for consistent parsing.

Manifest design (high level). Each invariant entry typically includes:

- `id: INV-###`
- `title`
- `status: implemented | roadmap`
- `implemented_in`: code/docs locations
- `verified_by`: scripts/tests
- `enforced_by`: CI gates
- Optional: `owner`, `risk`, `notes`, `exceptions_policy`

### 6.5 Fast Invariants Checks

Module: `scripts/audit/run_invariants_fast_checks.sh`

Responsibilities:

- Run shell + python syntax checks.
- Run detector unit tests.
- Validate manifest correctness.
- Verify docs/manifest consistency.
- Verify exception templates.
- Regenerate QUICK and fail if drift.

Design principle:

- Deterministic and cheap.
- Intended to run pre-push and in CI Phase I.

### 6.6 Security Fast Checks

Modules: `scripts/security/lint_sql_injection.sh`, `scripts/security/lint_privilege_grants.sh`
(and wrapper fast-check script)

Responsibilities:

- Enforce security posture in migrations (for example, SECURITY DEFINER hardening/search_path,
  revoke-first posture).
- Prevent privilege regressions (for example, CREATE grants on public schema).

### 6.7 DB Verification and Function Tests

Modules:

- `scripts/db/verify_invariants.sh`
- `scripts/db/tests/test_db_functions.sh`
- Policy seed scripts + tests

Responsibilities:

- Apply migrations idempotently.
- Verify DB invariants.
- Run DB function tests.

Notable invariant:

- "Exactly one ACTIVE policy exists" (Phase-1 policy seeding logic).

### 6.8 Policy Seeding Phase-1

Modules:

- `schema/seeds/ci/seed_policy_from_env.sh`
- `scripts/db/tests/test_seed_policy_checksum.sh`

Responsibilities:

- Read existing ACTIVE policy row.
- Fail closed on different ACTIVE version.
- Succeed idempotently when version/checksum match.
- Insert ACTIVE only when none exists.
- Tests assert specific failure mode and no side effects.

### 6.9 Codex Advisory Reviews (Optional)

Workflow jobs:

- Phase II: invariants authoring
- Phase II.5: security review
- Phase II.6: compliance review

Responsibilities:

- Run Codex on the PR diff.
- Produce:
  - `codex_final_message.md`
  - `ai_confidence.json`
  - `codex_summary.md`
  - Patch artifact (`codex-*.patch`)
- Comment summary onto PR.

Determinism requirement: Codex is an external dependency; therefore:

- It must be advisory / non-blocking for merges.
- Failures must be surfaced clearly with actionable causes (missing secret, quota exceeded, 401/429/402,
  network timeout).
- Artifacts must still upload when possible.

## 7. CI Workflow (invariants.yml)

Workflow name: Invariants (Mechanical + Codex + DB Verify)

### 7.1 Phase I — Mechanical gates

Runs:

- Detector unit tests
- Compute diff + detect structural change
- Enforce Rule 1 if structural
- Promotion gate
- Exception template validation
- QUICK regeneration drift check
- Upload detector artifacts

### 7.2 Phase I.5 — Security fast checks

Runs cheap deterministic security lints.

### 7.3 Phase II — Codex authoring (docs/manifest only)

Runs when:

- Event is `pull_request`
- Phase I detected `structural_change=true`

Produces advisory PR comment and artifact bundle.

### 7.4 DB verification job

Runs migrations + `verify_invariants.sh` + DB tests.

### 7.5 Scheduled jobs

- Research scout (scheduled only)
- Exception audit (scheduled/manual)

## 8. Failure Modes and Remedies

### 8.1 Change-rule failures

Symptom: CI fails in Phase I with Rule 1 enforcement.

Fix options:

- Update `docs/invariants/**` and/or `INVARIANTS_MANIFEST.yml` with correct `INV-###` tokens.
- Add a timeboxed exception in `docs/invariants/exceptions/` using the template.

### 8.2 Local vs CI mismatch

Symptom: `pre_ci.sh` passes locally but CI fails.

Primary fixes implemented:

- Ensure hooks are installed.
- Ensure `pre_ci.sh` runs the same invariants and security fast checks as CI.
- Add staged structural preflight to catch issues before pushing.

### 8.3 Codex step failures (401/402/429/network)

Symptom: Codex job logs show Quota exceeded or 401 Unauthorized and required output files are missing.

Deterministic remediation path:

- Make Codex job non-blocking.
- Add explicit diagnostics:
  - List `/tmp/invariants_ai` and `$CODEX_HOME`.
  - Fail with "missing output file" and name the file.
  - Capture Codex stdout/stderr in artifacts.
  - Detect quota/auth strings and print a targeted error message.

## 9. Testing Strategy

### 9.1 Unit tests

- `scripts/audit/tests/test_detect_structural_changes.py`
- `scripts/audit/tests/test_detect_structural_sql_changes.py`

### 9.2 Integration tests

- `scripts/db/tests/test_db_functions.sh`
- `scripts/db/tests/test_seed_policy_checksum.sh`

### 9.3 Determinism checks

- QUICK regeneration drift check (`generate_invariants_quick` + `git diff --exit-code`)
- Exception template validation
- Explicit error strings in tests

## 10. Operational Guidance (Developer Workflow)

Doc: `docs/operations/DEV_WORKFLOW.md`

Key expectations:

- Install hooks once per clone.
- Run `scripts/dev/pre_ci.sh` before pushing.
- If the staged preflight gate fails, fix it before commit/push.
- Treat Codex results as advisory; do not block on them.

## 11. Roadmap (Next Phases to Completion)

Phase A — Finish Codex as fully deterministic advisory:

- Make Codex jobs continue-on-error (non-blocking), but always:
  - Upload artifacts
  - Comment summary (or "Codex failed: ...") on PR
- Add a dedicated "Codex diagnostics" step that:
  - Captures Codex logs
  - Classifies failures (missing secret vs quota vs auth vs network)
  - Prints exact actionable remediation

Phase B — Structural detector scoping (fairness):

- Restrict what qualifies as "structural" to eligible paths (migrations/security/workflows).
- Keep `matches[]` for debugging across all files.
- Lock behavior with unit tests: docs-only keywords != structural.

Phase C — Invariants Curator automation:

- Add/enable the "Invariants Curator" agent prompt for humans and/or Codex.
- Provide a standard local command that:
  - Runs detector
  - Suggests which `INV-###` to update
  - Generates a candidate exception or doc patch (never auto-merge)

Phase D — Policy seeding Phase-2:

- Implement policy rotation semantics (GRACE/RETIRED).
- Expand tests accordingly.

Phase E — Hardening + productization:

- Add timeouts/backoff for networked steps.
- Add stable formatting of CI logs and PR comments.
- Ensure branch protections require Phase I + DB verify, but not Codex.

## 12. Open Questions

- Final eligible-path list for "structural" classification (docs vs configs vs scripts).
- Whether `docs/security/SECURITY_MANIFEST.yml` should satisfy Rule 1 as an alternative linkage (optional).
- Whether Codex jobs should run only on demand (`workflow_dispatch`) for cost control.

## 13. Appendix

- Example exception file template: `docs/invariants/exceptions/EXCEPTION_TEMPLATE.md`
- Example invariant IDs: `INV-###`
- Key scripts: `scripts/audit/*`, `scripts/security/*`, `scripts/db/*`
