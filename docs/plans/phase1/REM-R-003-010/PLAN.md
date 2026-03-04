# REM-R-003-010 PLAN

failure_signature: PHASE123.REMEDIATION.TRACE.REQUIRED
origin_task_id: R-003,R-004,R-005,R-006,R-007,R-008,R-009,R-010

## repro_command
- `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Scope
- Implement Phase 1, 2, and 3 remediation controls for R-003 through R-010.
- Add missing verifier scripts and evidence artifacts required by the task metadata.

## verification_commands_run
- `bash scripts/security/lint_app_sql_injection.sh`
- `semgrep --config security/semgrep --error`
- `bash scripts/audit/test_supervisor_sql_injection_vectors.sh`
- `bash scripts/audit/test_log_redaction_authorization.sh`
- `bash scripts/audit/test_token_querystring_rejected.sh`
- `bash scripts/audit/test_authorization_bearer_accepted.sh`
- `bash scripts/audit/test_secure_equals_no_length_leak.sh`
- `bash scripts/audit/test_rate_limit_429.sh`
- `bash scripts/audit/test_body_limit_413.sh`
- `bash scripts/audit/verify_openbao_not_dev.sh`
- `bash scripts/audit/verify_container_images_pinned.sh --service openbao`
- `bash scripts/audit/verify_ci_images_pinned_to_digest.sh --image postgres`
- `bash scripts/audit/verify_allowed_hosts_not_wildcard.sh`
- `bash scripts/audit/verify_tls_docs_sections.sh`

## final_status
- completed
