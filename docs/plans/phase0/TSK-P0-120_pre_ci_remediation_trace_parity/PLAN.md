# Implementation Plan (TSK-P0-120)

failure_signature: CI.REMEDIATION_TRACE.NOT_ENFORCED_LOCALLY
origin_task_id: TSK-P0-105
repro_command: bash scripts/audit/verify_remediation_trace.sh

## Goal
Make local `scripts/dev/pre_ci.sh` catch the same remediation-trace failures that CI enforces, so fixes to production-affecting surfaces cannot land without an auditable remediation casefile.

## Background
CI runs `scripts/audit/verify_remediation_trace.sh` and fails if the PR touches production-affecting surfaces (e.g. `scripts/**`, `.github/workflows/**`, `schema/**`, `infra/**`, `src/**`, `packages/**`) but does not include an in-diff remediation trace casefile (`docs/plans/**/REM-*/{PLAN.md,EXEC_LOG.md}`) or an explicit fix task plan/log (`docs/plans/**/TSK-*/{PLAN.md,EXEC_LOG.md}`) containing required remediation markers.

Local `pre_ci.sh` previously did not run this gate, so the first time a missing remediation trace was detected was in CI.

## Scope
In scope:
- Wire the remediation trace verifier into `scripts/dev/pre_ci.sh`.
- Fail closed locally when the verifier would otherwise silently SKIP due to missing `BASE_REF` in range mode.

Out of scope:
- Change CI diff-range semantics or introduce automatic git fetching.
- Change remediation marker policy beyond existing `scripts/audit/remediation_trace_lib.py`.

## Tasks
- TSK-P0-120: Add remediation trace gate invocation to local pre-CI runner and fail-closed when base ref is missing.

## Acceptance Criteria
- `scripts/dev/pre_ci.sh` runs `scripts/audit/verify_remediation_trace.sh`.
- In a clean index/worktree, if `BASE_REF` is missing, `scripts/dev/pre_ci.sh` fails with an actionable message (preventing local SKIP while CI fails).
- When remediation docs are present in the change, the local runner passes the gate and emits `evidence/phase0/remediation_trace.json`.

## Verification Commands
- `bash scripts/audit/verify_remediation_trace.sh`
- `bash scripts/dev/pre_ci.sh`

verification_commands_run:
- bash scripts/audit/verify_remediation_trace.sh
- bash scripts/dev/pre_ci.sh

final_status: PASS
