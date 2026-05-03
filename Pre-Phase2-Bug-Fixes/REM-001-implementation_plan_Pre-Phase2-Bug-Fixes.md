# Pre-Phase2-Bug-Fixes

## Goal Description
The goal of this task is to clean up the worktree according to the Evidence Churn Cleanup Policy (v3.3) and commit the remaining changes on the `feat/fix-pre-phase2-bugs` branch. The cleanup ensures that only canonical proof artifacts, approval-linked artifacts, and intentional changes are committed, removing any incidental or unreferenced local churn.

## User Review Required
> [!IMPORTANT]
> Please review the cleanup results and approve this plan so I can proceed with creating the final Task.md and executing the commit.

## Open Questions
None at this time.

## Proposed Changes
The following actions will be performed:
1. **Worktree Cleanup:**
   - Delete incidental files such as `fix_meta_*.py`, `harden_meta_yaml.py`, `pre_ci.stderr`, `pre_ci.stdout`, `scratch/`, `schema/rollbacks/`, and compiled `wave8_crypto` objects.
   - Retain all tracked evidence files, approval artifacts, and modified verification scripts.
2. **Staging:** Stage all remaining modified, deleted, and untracked files that form the keep-set for this branch.
3. **Commit:** Commit the changes using the content of the approved `Task.md` as the commit message.

## Verification Plan
### Automated Tests
- `git status --short` to verify a clean working tree after commit.
- `git log -1` to verify the commit message format.

### Manual Verification
- User review of the committed files and commit message.
