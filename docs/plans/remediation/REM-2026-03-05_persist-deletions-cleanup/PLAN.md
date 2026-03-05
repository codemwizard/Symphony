# REM-2026-03-05 Persist deletions cleanup PLAN

failure_signature: REM.GOVERNANCE.REPO_NOISE_AND_DEPRECATED_FILES
origin_task_id: CLEANUP-PERSIST-DELETIONS
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## repro_command
- `git status --short`

## scope
- Persist deletion of non-essential root planning/noise files.
- Persist deletion of deprecated scan-scope/fixture scripts and stale remediation evidence files.

## verification_commands_run
- `git status --short`
- `git diff --name-status origin/main...HEAD`
