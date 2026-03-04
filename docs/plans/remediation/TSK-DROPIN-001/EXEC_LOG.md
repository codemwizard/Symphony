# TSK-DROPIN-001 EXEC_LOG

origin_task_id: TSK-DROPIN-001
origin_gate_id: R-018,R-019,R-020

## failure_signature
- run_task.sh uploaded stub (echo + exit 1) would have destroyed working implementation.
- lint_app_sql_injection.sh drop-in would have silently removed 17 C# detection patterns and
  parameterized-query verification, regressing R-018/R-019 acceptance criteria.
- parity.yml arrived with empty csharp_rule_ids and python_rule_ids arrays in all six classes;
  only the sqli class was backfilled (the only class with existing rules.yml coverage).
- verify_semgrep_languages.sh used jq for JSON parsing; jq is absent from the bootstrapped
  toolchain, causing json_len to silently return 0 and masking rule-detection failures.

## repro_command
bash scripts/agent/bootstrap.sh

## actions_taken
- Rejected run_task.sh stub; wrote full implementation (meta.yml parsing, schema_version
  backward-compatibility, artifact enforcement, verification loop with JSONL, evidence
  freshness gate, Phase-0 contract gate).
- Fixed P1: removed schema_version from required fields list; legacy meta (no schema_version)
  is now accepted as version "0". Tasks with schema_version: 1 continue to work.
- Fixed P2: added `export TASK_ID` immediately after shell assignment so JSONL records
  capture correct task_id from os.environ rather than empty string.
- Merged lint_app_sql_injection.sh drop-in as additive patch: nosec-sqli windowed suppression
  and four additional find exclusion paths added; all 17 C# patterns, all 20 Python patterns,
  scan_root parameter, and parameterized-query verification preserved verbatim.
- Applied verify_semgrep_languages.sh patch: jq replaced with inline python3 json_len helper;
  --quiet replaced with --metrics off for semgrep telemetry opt-out.
- Wrote all six new files (agent_manifest.yml, IDE_AGENT_ENTRYPOINT.md, parity.yml,
  bootstrap.sh, verify_semgrep_parity.sh) verbatim from uploaded versions.
- Backfilled parity.yml sqli class with the seven rule IDs from rules.yml.

## verification_commands_run
- bash scripts/security/lint_app_sql_injection.sh
- bash scripts/security/run_lint_fixtures.sh --suite app_sql_injection
- bash scripts/audit/verify_semgrep_languages.sh

## final_status
completed
