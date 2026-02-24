# TSK-OPS-DRD-004 EXEC_LOG

verification_commands_run:
- test -f .github/pull_request_template.md
- rg -n "Severity declaration|DRD links|L2/L3" .github/pull_request_template.md

final_status: completed
