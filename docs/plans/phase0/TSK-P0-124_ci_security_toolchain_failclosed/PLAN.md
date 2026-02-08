# Implementation Plan (TSK-P0-124)

failure_signature: CI.SECURITY.TOOLCHAIN.DRIFT_SEMGREP_NOT_ENFORCED
origin_gate_id: SEC-G06
repro_command: bash scripts/audit/verify_ci_toolchain.sh

## Goal
Fail closed in CI if the pinned security toolchain (including Semgrep) is missing or drifted.

## Problem Statement
Historically, the security evidence job could emit `semgrep_sast.json` as `SKIPPED` (semgrep missing) without failing CI.
Tier-1 parity requires CI to be authoritative: pinned toolchain must be present and verified.

## Scope
In scope:
- Extend `scripts/audit/verify_ci_toolchain.sh` to verify Semgrep presence/version when pinned.
- Ensure CI security_scan runs the toolchain verifier.
- Make Semgrep SAST fail in CI when Semgrep is missing (no silent SKIPPED).

Out of scope:
- Changing rule selection or severity policy for Semgrep findings.

## Acceptance Criteria
- In CI, missing Semgrep fails the security job (not SKIPPED).
- `phase0-evidence-security` includes `ci_toolchain.json` as PASS.
- `semgrep_sast.json` is PASS when Semgrep is installed, FAIL when not.

## Verification Commands
- `bash scripts/audit/verify_ci_toolchain.sh`
- `bash scripts/security/run_semgrep_sast.sh`

verification_commands_run:
- bash scripts/audit/verify_ci_toolchain.sh
- bash scripts/security/run_semgrep_sast.sh

final_status: OPEN

