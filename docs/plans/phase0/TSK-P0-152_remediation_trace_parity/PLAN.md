# Remediation Plan

failure_signature: CI.REMEDIATION_TRACE.PARITY_MISMATCH
origin_task_id: TSK-P0-152
first_observed_utc: 2026-02-09T15:30:00Z

## production-affecting surfaces
- scripts/audit/verify_remediation_trace.sh
- scripts/dev/pre_ci.sh
- docs/plans/phase0/TSK-P0-152_remediation_trace_parity/PLAN.md

## repro_command
bash scripts/audit/verify_remediation_trace.sh

## scope_boundary
In scope: ensure the remediation trace gate computes its diff range against the real integration baseline (`rewrite/dotnet10-core`/PR base) and runs commit-range diffs both locally and in CI so the gate never sees different file sets.
Out of scope: changing marker requirements, adding new remediation docs, or altering the gate trigger list.

## proposed_tasks
- Update `scripts/audit/verify_remediation_trace.sh` to derive `BASE_REF` from `${GITHUB_BASE_REF}`/upstream/origin/rewrite/dotnet10-core, fetch it if missing, and always diff `merge-base(BASE,HEAD)...HEAD`.
- Update `scripts/dev/pre_ci.sh` to export the same base ref before invoking the gate so pre-push runs the same baseline as CI.

## acceptance
- `bash scripts/audit/verify_remediation_trace.sh` reports `diff_mode: range` and the computed base matches `rewrite/dotnet10-core` or the PR base.
- Pre-CI (`scripts/dev/pre_ci.sh`) invokes the gate and exits 0.
