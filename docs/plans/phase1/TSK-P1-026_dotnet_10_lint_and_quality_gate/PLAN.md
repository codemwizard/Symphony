# TSK-P1-026 Plan

## Mission
Add a deterministic .NET 10 quality lint gate to Phase-1 so customer-facing runtime work cannot bypass formatting and warning-level quality checks.

## Scope
- Add `scripts/security/lint_dotnet_quality.sh`.
- Add test `scripts/security/tests/test_lint_dotnet_quality.sh`.
- Wire security fast checks and control-plane gate `SEC-G18`.
- Add Phase-1 contract row for `.NET` quality evidence.

## Constraints
- Fail-closed when dotnet projects are present and tooling checks fail.
- No new ordered runner.
- Evidence must conform to canonical evidence schema.

## Verification
- `bash scripts/security/tests/test_lint_dotnet_quality.sh`
- `bash scripts/security/lint_dotnet_quality.sh`
- `bash scripts/audit/run_security_fast_checks.sh`
- `RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh`

## Evidence
- `evidence/phase1/dotnet_lint_quality.json`
