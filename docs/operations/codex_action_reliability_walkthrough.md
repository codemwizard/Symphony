# Codex Action Reliability: Walkthrough

## Problem
Codex advisory jobs were intermittently failing with a “server info file missing” error from `openai/codex-action@v1`. This was caused by Codex trying to use a shared default home directory (`/home/runner/.codex`) that can be unwritable or missing the expected runtime file. Additionally, Codex jobs were blocking CI and could run on fork PRs where secrets are not available.

## Steps Taken
1) **Prepare a fresh, writable Codex home for each job**
   - Added a step to create `${{ runner.temp }}/codex-home` before each Codex step.
   - Set `CODEX_HOME` on each Codex step so the action uses this directory.

2) **Make Codex advisory steps non-blocking**
   - Added `continue-on-error: true` to each Codex step.
   - Kept artifact upload and PR comment steps running with `if: always()`.

3) **Prevent Codex from running on fork PRs**
   - Added a guard to Codex jobs so they only run when the PR head repo matches the base repo (secrets available).

## Files Updated
- `.github/workflows/invariants.yml`
- `docs/operations/codex_action_reliability_plan.md`

## Result
Codex advisory jobs now:
- use a fresh, writable `CODEX_HOME`,
- do not block CI on transient Codex failures,
- do not run on fork PRs without secrets.
