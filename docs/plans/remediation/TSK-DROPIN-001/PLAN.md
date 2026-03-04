# TSK-DROPIN-001 PLAN

origin_task_id: TSK-DROPIN-001
origin_gate_id: R-018,R-019,R-020

## Title
Drop-in: deterministic agent scripts, semgrep parity, and SQLi lint hardening

## Scope
Introduce the Symphony agent drop-in layer (scripts/agent/, agent_manifest.yml,
IDE_AGENT_ENTRYPOINT.md) and apply additive improvements to three existing security
scripts:

- scripts/agent/bootstrap.sh            (new)
- scripts/agent/run_task.sh             (new)
- agent_manifest.yml                    (new)
- IDE_AGENT_ENTRYPOINT.md               (new)
- security/semgrep/parity.yml           (new)
- scripts/security/verify_semgrep_parity.sh  (new)
- scripts/security/lint_app_sql_injection.sh (additive: nosec-sqli suppression, extra find exclusions)
- scripts/audit/verify_semgrep_languages.sh  (additive: jq → python3, --metrics off)

## failure_signature
- run_task.sh stub (3 lines) would have been dropped in; rejected and replaced with full implementation.
- lint_app_sql_injection.sh drop-in would have regressed 17 C# patterns and removed parameterized-query
  verification; rejected and merged as additive patch instead.
- parity.yml was delivered with empty rule ID arrays; rule IDs backfilled from rules.yml before drop-in.
- verify_semgrep_languages.sh used jq which is absent from the bootstrapped toolchain, causing silent
  false-pass on machines without jq; replaced with python3 parser.

## repro_command
bash scripts/agent/bootstrap.sh

## Implementation Plan
1. Review all eight uploaded drop-in files against existing Symphony implementation.
2. Write safe files (agent_manifest.yml, IDE_AGENT_ENTRYPOINT.md, security/semgrep/parity.yml,
   scripts/agent/bootstrap.sh, scripts/agent/run_task.sh, scripts/security/verify_semgrep_parity.sh).
3. Apply additive patch to scripts/security/lint_app_sql_injection.sh (nosec-sqli suppression,
   additional find exclusions; preserve all 17 C# patterns and 20 Python patterns).
4. Apply additive patch to scripts/audit/verify_semgrep_languages.sh (remove jq dependency).
5. Fix run_task.sh: accept legacy meta (no schema_version), export TASK_ID for JSONL linkage.
6. Create this casefile to satisfy the remediation trace gate.

## Verification
- scripts/agent/bootstrap.sh (smoke-run gate sequence)
- scripts/security/lint_app_sql_injection.sh (no regressions on pattern count)
- scripts/security/run_lint_fixtures.sh --suite app_sql_injection
- scripts/audit/verify_semgrep_languages.sh
