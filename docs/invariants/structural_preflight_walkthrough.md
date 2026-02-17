# Structural Preflight Walkthrough

**Purpose:** Catch structural/security changes before CI by enforcing Rule 1 locally on staged diffs.

## One-time setup
1. Install the pre-commit hook:
   ```bash
   scripts/dev/install_git_hooks.sh
   ```
2. Confirm the hook exists:
   ```bash
   ls -l .git/hooks/pre-commit
   ```
3. Confirm the pre-push hook exists:
   ```bash
   ls -l .git/hooks/pre-push
   ```

## Daily flow (developer)
1. Make changes and stage them:
   ```bash
   git add -A
   ```
2. Commit as usual:
   ```bash
   git commit -m "<message>"
   ```
3. If the staged diff triggers structural detection, the hook will:
   - check Rule 1 linkage (manifest/docs/exception)
   - if missing, auto-create and stage a new exception stub
   - block the commit until placeholders are replaced

## What counts as Rule 1 linkage
Any of the following satisfies Rule 1:
- `docs/invariants/INVARIANTS_MANIFEST.yml` updated, OR
- invariants docs updated with at least one `INV-###` token, OR
- a valid exception file exists under `docs/invariants/exceptions/`

## Auto-exception details
When Rule 1 linkage is missing, the hook writes a new exception file that includes:
- a standard YAML front matter block
- a short auto-generated reason
- evidence from `detect.json` (primary reason, matched files, top matches)

You must replace placeholders before committing:
- `exception_id`: use a real `EXC-###` value
- `expiry`: a future date (YYYY-MM-DD)
- `follow_up_ticket`: real tracker ID (not `PLACEHOLDER-*`)
- `reason`: real justification (not the template default)

Note: `author` is required but the validator does not enforce non-system values.

## Optional enhancement behavior
If the detector includes reason metadata, you will see:
- `primary_reason` (e.g., `security`, `ddl`)
- `reason_types` (one or more categories)
- `matched_files` (files that triggered detection)

These values appear in both the exception stub and CI logs.

## CI behavior (unchanged)
CI still enforces Rule 1. The local hook prevents most reruns by catching missing linkage early.

## Pre-push pre-CI checks
Before pushing, the pre-push hook runs `scripts/dev/pre_ci.sh`, which executes:
- invariants fast checks
- security fast checks
- DB tests against a **fresh ephemeral database** by default (`FRESH_DB=1`), to match CI freshness and avoid “passes locally, fails in CI” drift.

Fresh DB behavior:
- Default: `FRESH_DB=1` (ephemeral database created per run; dropped on exit)
- Optional: `KEEP_TEMP_DB=1` keeps the ephemeral database for debugging
- `FRESH_DB=0` disables ephemeral DB behavior (not recommended for Tier-1 parity)

## Troubleshooting
- If the hook does not run, confirm it is executable:
  ```bash
  chmod +x .git/hooks/pre-commit
  ```
- If you need to bypass the hook temporarily, use:
  ```bash
  git commit --no-verify
  ```
  (CI will still enforce Rule 1.)
