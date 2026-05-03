# Pre-Phase2-Bug-Fixes (REM-002)

## Goal Description
The goal of this task is to clean up the worktree according to the Evidence Churn Cleanup Policy (v3.3) and commit the final set of changes on the `feat/fix-pre-phase2-bugs` branch following the successful convergence of the CI pipeline (`pre_ci.sh`). This includes cleaning up ephemeral test outputs and compiled objects, staging governance and remediation casefiles, and preparing the canonical proof artifacts for commit.

## User Review Required
> [!IMPORTANT]
> Please review the cleanup plan below and approve so I can proceed with creating the final Task.md and executing the commit.

## Open Questions
None.

## Proposed Changes
The following actions will be performed:
1. **Worktree Cleanup:**
   - Delete compiled objects in `src/db/extensions/wave8_crypto/` (`.bc`, `.o`, `.so`).
   - Leave intact all generated or modified governance evidence files, execution logs, and plans under `evidence/`, `docs/plans/`, and `.toolchain/`.
2. **Staging:** 
   - Stage all the tracked modifications (evidence files, casefiles).
3. **Commit:** 
   - Generate `Pre-Phase2-Bug-Fixes/REM-002-task_Pre-Phase2-Bug-Fixes.md`.
   - Commit the changes using the content of the approved `Task.md` as the commit message, prepended with the Phase Name `Pre-Phase2-Bug-Fixes`.

## Verification Plan
### Automated Tests
- `git status --short` to verify a clean and staged working tree after cleanup.
- `git log -1` to verify the commit message format.

### Manual Verification
- User review of the committed files and commit message structure.
