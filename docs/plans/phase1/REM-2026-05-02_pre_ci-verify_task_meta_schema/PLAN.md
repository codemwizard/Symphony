# REMEDIATION PLAN

Canonical-Reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

failure_signature: PRECI.GOVERNANCE.TASK_META_SCHEMA

origin_gate_id: pre_ci.verify_task_meta_schema
repro_command: scripts/dev/pre_ci.sh
verification_commands_run: scripts/dev/pre_ci.sh
final_status: PASS

## Scope
- Identify the strict v1 schema requirements missing from the 6 meta.yml files.
- Patch `tasks/TSK-P1-REM-080/meta.yml`, `tasks/TSK-P1-SEC-010/meta.yml`, `tasks/TSK-P2-PREAUTH-004-REM-01/meta.yml`, `tasks/TSK-P2-W5-REM-01/meta.yml`, `tasks/TSK-P2-W5-REM-02/meta.yml`, `tasks/TSK-RLS-ARCH-REM-001/meta.yml`.
- Ensure the pre_ci pipeline succeeds.

## Initial Hypotheses
- Several task definitions were scaffolded without required placeholder lists (`depends_on: []`, `invariants: []`, etc.) which violates the strict `TASK-META-SCHEMA` governance rule.
