# Remediation Plan: R-001 Fail hard on missing signing keys

## Goal
Remove fallback logic `?? "dev-signing-key"` and enforce strict signature capabilities. Ensures reporting does not emit unsigned data gracefully.

## Steps
1. Add `RegulatoryErrors.SigningCapabilityMissing` constant.
2. Unify `/health` to expose `signing_key_present`.
3. Centralize HTTP mapping from RegulatoryHandler success failures.
4. Replace fallbacks with exact 503 HTTP refusal in `RegulatoryIncidentReportHandler` and `RegulatoryReportHandler`.
5. Execute Semgrep structural validation ban on literals.
6. Verify via `scripts/audit/test_missing_signing_key_fails_closed.sh`.
