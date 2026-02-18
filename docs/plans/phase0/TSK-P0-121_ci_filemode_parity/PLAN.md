# Implementation Plan (TSK-P0-121)

failure_signature: CI.REMEDIATION_TRACE.FALSE_TRIGGER.FILEMODE_CHMOD
origin_gate_id: REMEDIATION-TRACE
repro_command: bash scripts/audit/verify_remediation_trace.sh

## Goal
Prevent CI from falsely triggering the remediation trace gate due to workflow `chmod +x` steps creating a dirty worktree (filemode-only changes) before the verifier runs.

## Background
The CI workflow (`.github/workflows/invariants.yml`) performs `chmod +x scripts/audit/*.sh` prior to `scripts/audit/run_phase0_ordered_checks.sh`.

If any targeted scripts are committed as non-executable (`100644`), the `chmod` step changes filemode in the worktree, making `git diff --name-only` non-empty inside CI.

`scripts/audit/verify_remediation_trace.sh` prefers:
1) staged diff, else
2) worktree diff, else
3) range diff (`BASE_REF...HEAD_REF`).

So in CI, a filemode-only dirty worktree forces `diff_mode=worktree`, causing the remediation gate to treat workflow chmod effects as "production-affecting changes" and fail unless remediation docs are also present in that same worktree diff.

## Scope
In scope:
- Ensure scripts that CI chmods are committed with executable bit (`100755`) so CI remains clean and the verifier uses range diff.

Out of scope:
- Removing chmod steps from CI (may be considered later).
- Changing remediation-trace policy (markers, trigger surfaces).

## Tasks
- TSK-P0-121: Set executable bits in git for scripts that CI chmods (at minimum: remediation verifier scripts) to avoid worktree diffs in CI.

## Acceptance Criteria
- In CI, after workflow chmod steps, `git diff --name-only` remains empty for `scripts/audit/*.sh`.
- `scripts/audit/verify_remediation_trace.sh` runs in `diff_mode=range` in CI unless there are true PR changes.
- Remediation trace gate no longer fails with `missing_remediation_trace_doc` due to filemode-only changes.

## Verification Commands
- `bash scripts/audit/verify_remediation_trace.sh`
- (CI) observe `evidence/phase0/remediation_trace.json` reports `diff_mode: range` when the worktree is otherwise clean.

verification_commands_run:
- bash scripts/audit/verify_remediation_trace.sh

final_status: PASS
