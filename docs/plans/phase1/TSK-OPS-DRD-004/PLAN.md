# TSK-OPS-DRD-004 PLAN

failure_signature: PHASE1.DRD.PR_DECLARATION.MISSING
origin_task_id: TSK-OPS-DRD-004
repro_command: scripts/dev/pre_ci.sh

## Scope
- Add declarative PR template with severity and DRD links.

## verification_commands_run
- test -f .github/pull_request_template.md
- rg -n "Severity declaration|DRD links|L2/L3" .github/pull_request_template.md
