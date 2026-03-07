# Agent Entrypoint (Canonical)

This is the only normative startup contract for agent execution.

## Boot Sequence

1. Stop if current branch is `main`.
2. Run conformance gate:
   - `scripts/audit/verify_agent_conformance.sh`
3. Run local parity gate:
   - `scripts/dev/pre_ci.sh`
4. Run task:
   - `scripts/agent/run_task.sh <TASK_ID>`

If any step fails, stop and open remediation trace.

## Canonical References

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/POLICY_PRECEDENCE.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
