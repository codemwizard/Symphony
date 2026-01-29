# Structural Preflight + Exception Workflow

**Owner:** TBD  
**Date:** 2026-01-28  
**Status:** Draft

## Goal
Shift structural change detection left (pre-commit) so Rule 1 failures are resolved locally, while keeping CI enforcement intact. Include the optional enhancement to classify detection reasons and surface evidence in CI logs.

## Scope
- Local preflight on staged diffs
- Auto-generation of exception stubs when Rule 1 linkage is missing
- Hardened exception validation (no placeholders)
- Optional enhancement: detector reason metadata + CI evidence logging

## Non-Goals
- Changing Rule 1 semantics
- Weakening CI gating
- Altering invariant requirements or DDL policy

## Proposed Changes (Implementation Plan)
1. Add a staged preflight script mirroring CI logic to detect structural changes and enforce Rule 1 before commit.
2. Add an auto-exception generator that writes a standards-compliant exception file with evidence.
3. Add a local git hook installer for pre-commit wiring.
4. Harden exception validation to reject placeholder metadata and skip the template itself.
5. Optional enhancement: extend detector output with reason metadata and update the generator + CI logs to use it.

## Tasks
- [ ] Add `scripts/audit/preflight_structural_staged.sh` (staged diff, Rule 1 checks, auto-exception on failure).
- [ ] Add `scripts/audit/auto_create_exception_from_detect.py` (exception stub generator).
- [ ] Add `scripts/dev/install_git_hooks.sh` (installs pre-commit hook).
- [ ] Add `scripts/dev/pre_ci.sh` (pre-push local test runner).
- [ ] Update `scripts/audit/verify_exception_template.sh` to:
  - ignore `EXCEPTION_TEMPLATE.md`
  - reject placeholder values (e.g., `EXC-000`, `PLACEHOLDER-*`)
- [ ] Add `docs/invariants/structural_preflight_walkthrough.md` (developer walkthrough).
- [ ] Optional enhancement (detector metadata):
  - Update `scripts/audit/detect_structural_changes.py` to emit `reason_types`, `primary_reason`, `matched_files`, `match_counts`.
  - Update exception generator to use `primary_reason` in filename/title and include matched files.
  - Patch `.github/workflows/invariants.yml` to log evidence and emit annotations.
- [ ] Add detector/exception generator tests under `scripts/audit/tests/` and wire into fast checks.

## Verification Plan
- Run security fast checks after changes:
  - `scripts/audit/run_security_fast_checks.sh`
- Manual test flow:
  1. Stage a change containing a security keyword (e.g., `GRANT`).
  2. Attempt commit; verify exception stub is created and staged.
  3. Fill required fields and re-commit; verify pass.
  4. Push and confirm CI logs include detector evidence.

## Risks & Mitigations
- **Risk:** Developers ignore local hooks.  
  **Mitigation:** CI remains the source of truth; preflight reduces reruns but does not weaken enforcement.
- **Risk:** Exceptions created with placeholders.  
  **Mitigation:** Hardened validator rejects placeholders.

## Dependencies
- None (local scripts + CI workflow update only).

## Acceptance Criteria
- Pre-commit preflight creates and stages exception when Rule 1 linkage is missing.
- Validator rejects placeholder metadata in exceptions.
- Optional enhancement: detector emits reason metadata and CI logs show structural evidence.
