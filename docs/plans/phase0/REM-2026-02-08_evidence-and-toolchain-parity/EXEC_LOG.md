# Remediation Execution Log

failure_signature: CI.PHASE0.PARITY.EVIDENCE_FINGERPRINT_AND_SEMGREP_DRIFT
origin_task_id: TSK-P0-122

## repro_command
- Inspect `phase0-evidence` artifacts for inconsistent `schema_fingerprint`.
- Inspect `phase0-evidence-security` artifacts for `semgrep_sast.json` SKIPPED due to missing semgrep.

## error_observed
- `evidence.json` used a migrations hash as `schema_fingerprint`, while other evidence used baseline hash.
- `phase0-evidence-security` contained `semgrep_sast.json` with `status: SKIPPED` and `errors: ["semgrep_not_installed"]`.

## change_applied
- Updated evidence generation to standardize `schema_fingerprint` to baseline and added `migrations_fingerprint`.
- Updated CI workflow to install pinned Semgrep in `security_scan`.
- Updated CI toolchain verifier to check Semgrep and made Semgrep SAST fail (not SKIPPED) when Semgrep is missing in CI.

## verification_commands_run
- bash scripts/audit/generate_evidence.sh
- bash scripts/audit/verify_ci_toolchain.sh
- bash scripts/security/run_semgrep_sast.sh

## final_status
OPEN (expected PASS after CI reruns and artifacts are inspected)

