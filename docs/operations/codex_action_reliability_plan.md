# Codex Action Reliability: Implementation Plan and Tasks

## Goal
Make Codex advisory jobs in CI reliable and non-blocking by ensuring a fresh, writable `CODEX_HOME` and guarding against fork PRs with missing secrets.

## What the process is trying to achieve
The Codex jobs are advisory and should provide review artifacts without breaking CI. The process should:
- Avoid flaky failures caused by missing/locked Codex server info files.
- Keep advisory jobs from blocking CI if Codex infrastructure flakes.
- Avoid running Codex when secrets are unavailable (fork PRs).

## Scope
Patches covered:
- `.github/workflows/invariants.yml`

## Non-Goals
- Changing Codex prompt content or review logic.
- Changing mechanical gates or DB verification jobs.
- Modifying repository security or permissions policies.

## Implementation Plan
1) **Prepare a fresh Codex home directory per job**
   - Create `${{ runner.temp }}/codex-home` before each Codex step.
   - Use `CODEX_HOME` env on each Codex step.

2) **Make Codex steps non-blocking**
   - Add `continue-on-error: true` to each Codex step.
   - Keep artifact upload and PR comment steps as `if: always()`.

3) **Guard Codex jobs for fork PRs**
   - Only run Codex jobs when the PR head repo matches the base repo.
   - Ensure secrets are available for Codex Action.

4) **Align DB policy test with CI seeding behavior**
   - CI runs DB tests with `SKIP_POLICY_SEED=1`, so the policy table may have zero ACTIVE rows.
   - Update the DB function test to assert the real invariant: **no more than one ACTIVE** row.
   - Keep CI deterministic without forcing policy seed.

## Tasks List
### A) Workflow updates
- [ ] Add a "Prepare Codex home" step before each Codex step.
- [ ] Add `env: CODEX_HOME: ${{ runner.temp }}/codex-home` to each Codex step.
- [ ] Add `continue-on-error: true` to each Codex step.
- [ ] Guard Codex jobs to skip fork PRs (`head.repo.full_name == github.repository`).

### B) Verification
- [ ] Validate YAML syntax by running CI locally or using a linter (optional).
- [ ] Confirm Codex jobs skip on fork PRs and run on same-repo PRs.
- [ ] Confirm Codex failures do not fail the workflow.
- [ ] Confirm DB function tests pass in CI when `SKIP_POLICY_SEED=1`.

## Success Criteria
- Codex steps no longer fail with missing server-info file errors.
- Advisory Codex jobs are non-blocking in CI.
- Codex jobs do not run on fork PRs without secrets.
- DB function tests do not fail when policy seeding is intentionally skipped.
