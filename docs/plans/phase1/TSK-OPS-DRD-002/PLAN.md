# TSK-OPS-DRD-002 PLAN

failure_signature: PHASE1.DRD.TEMPLATES.MISSING
origin_task_id: TSK-OPS-DRD-002
repro_command: scripts/dev/pre_ci.sh

## Scope
- Add DRD Lite and Full templates under `docs/remediation/templates/`.

## verification_commands_run
- test -f docs/remediation/templates/drd-lite-template.md
- test -f docs/remediation/templates/drd-full-template.md
