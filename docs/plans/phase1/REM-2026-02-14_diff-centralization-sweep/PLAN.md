# Remediation Plan: diff centralization sweep

failure_signature: PHASE1.DIFF.CENTRALIZATION.SWEEP
origin_task_id: TSK-P1-021
origin_gate_id: GOV-G02

## Problem
- Multiple scripts and workflow jobs implemented git diff/merge-base logic independently, risking parity drift.

## Reproduction
- repro_command: `rg -n "\\bgit\\s+diff\\b|\\bgit\\s+merge-base\\b" scripts .github/workflows -S`

## Remediation
- Introduce canonical helper surfaces for range/staged/worktree diff generation.
- Migrate parity-critical scripts and workflow diff-prep steps to shared helper entrypoints.
- Extend parity verifier scope to include additional scripts.

## Verification
- verification_commands_run:
  - `scripts/audit/verify_diff_semantics_parity.sh`
  - `scripts/audit/verify_remediation_trace.sh`
  - `scripts/dev/pre_ci.sh`

## Status
- final_status: in_progress
