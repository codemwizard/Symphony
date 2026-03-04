# REM-R-011-015 PLAN

failure_signature: PHASE45.REMEDIATION.TRACE.REQUIRED
origin_task_id: R-011,R-012,R-013,R-014,R-015

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Scope
- Implement Phase 4 cleanup/hygiene tasks: R-011, R-012, R-013.
- Implement Phase 5 code-quality tasks: R-014, R-015.
- Fix ingress request-size enforcement for chunked bodies and proxy-safe rate-limit partitioning.

## verification_commands_run
- `bash scripts/audit/denylist_repo_artifacts.sh --deny bfg.jar`
- `bash scripts/audit/test_dev_headers_rejected_non_dev.sh`
- `bash scripts/audit/verify_history_secret_scan_report_present.sh`
- `bash scripts/audit/run_dotnet_self_tests.sh`
- `dotnet test services/ledger-api/dotnet/tests/LedgerApi.Tests/LedgerApi.Tests.csproj --configuration Release --nologo`
- `bash scripts/audit/record_r015_test_bootstrap_evidence.sh`
- `scripts/dev/pre_ci.sh`

## final_status
- completed
