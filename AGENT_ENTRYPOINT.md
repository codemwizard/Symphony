# Agent Entrypoint (Canonical)

Read this file first on every session start, before modifying repository files.

## Step 1 — Determine the operating mode

Before writing any file, determine which mode applies.
See: `docs/operations/AGENT_PROMPT_ROUTER.md`

Permitted modes:
- CREATE-TASK
- RESUME-TASK
- IMPLEMENT-TASK
- REMEDIATE
- PUSH-READY-CHECK

Mode selection may use non-mutating inspection of the repository to resolve
discoverable facts, such as whether `tasks/<TASK_ID>/meta.yml` exists or
whether a referenced task is already partially created.

If the prompt still does not map to exactly one mode after non-mutating
inspection: STOP. Ask the human which mode applies. Do not guess.

## Step 2 — Execute the selected mode

Follow `docs/operations/AGENT_PROMPT_ROUTER.md` for the selected mode.
The boot sequence below applies only to IMPLEMENT-TASK mode.

## Boot Sequence (IMPLEMENT-TASK mode only)

1. Stop if current branch is `main`.
2. Run conformance gate:
   `scripts/audit/verify_agent_conformance.sh`
3. Run local parity gate:
   `scripts/dev/pre_ci.sh`
4. Run task:
   `scripts/agent/run_task.sh <TASK_ID>`

If any step fails: stop immediately and open or update remediation trace.
Do not retry without remediation discipline.

## Canonical References

- `docs/operations/AGENT_PROMPT_ROUTER.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/POLICY_PRECEDENCE.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
