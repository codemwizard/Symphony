# R-016 PLAN

Task: R-016
Source of truth: docs/contracts/SECURITY_REMEDIATION_DOD.yml
Canonical reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Scope
- Extract runtime self-test runners from `Program.cs` into dedicated test host code.
- Remove `--self-test*` dispatch from production startup path.
- Keep all existing self-test coverage reachable through audit runner scripts.

## Verification
- Run the task verification command in tasks/R-016/meta.yml.
- Run scripts/dev/pre_ci.sh before task closure.
