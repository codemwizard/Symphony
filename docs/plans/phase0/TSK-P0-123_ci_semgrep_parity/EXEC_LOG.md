# Execution Log (TSK-P0-123)

failure_signature: CI.SECURITY.SEMGREP.SKIPPED_TOOLCHAIN_MISSING
origin_gate_id: SEC-G11
repro_command: run Phase I.5 security_scan and inspect phase0/semgrep_sast.json

Plan: docs/plans/phase0/TSK-P0-123_ci_semgrep_parity/PLAN.md

## Change Applied
- Updated `.github/workflows/invariants.yml` `security_scan` job:
  - Added Python setup.
  - Installed pinned python deps including Semgrep.

## Verification Commands Run
verification_commands_run:
- CI run (Phase I.5 security_scan)

## Status
final_status: OPEN

## Final Summary
- Root cause: security_scan job emitted evidence without installing Semgrep.
- Fix: install pinned Semgrep in security_scan before running security fast checks.
- Verification: expect `phase0-evidence-security/phase0/semgrep_sast.json` to report PASS with correct version.

