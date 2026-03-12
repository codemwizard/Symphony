# PLAN — TASK-GOV-AWC1

## Mission

Save the canonical governance artifacts and startup-binding changes required to
make the Symphony agent workflow control process explicit, binding, and
retrievable by later implementation agents.

## Scope

This task creates and wires the governance documents and startup-surface
changes that lower-capability implementing agents will rely on:
- `docs/operations/AGENT_ASSIGNMENT_PROCESS.md`
- `docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md`
- `AGENT_ENTRYPOINT.md`
- `AGENTS.md`
- `agent_manifest.yml`
- `docs/operations/AGENT_PROMPT_ROUTER.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/POLICY_PRECEDENCE.md`
- `docs/operations/PHASE_LIFECYCLE.md`

## Non-Goals

- Do not modify `scripts/agent/run_task.sh` in this task.
- Do not execute the workflow-control implementation yet.
- Do not broaden approval-trigger patterns in this task.

## Ordered Steps

1. Save `docs/operations/AGENT_ASSIGNMENT_PROCESS.md`.
2. Save `docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md`.
3. Replace `AGENT_ENTRYPOINT.md` with the canonical workflow-control version
   defined in `docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md` Change 1.
4. Update `AGENTS.md`:
   - add the startup binding instruction to `## Non-Negotiables`
   - add entrypoint/router to `## Canonical References`
   - extend Architect allowed paths with `AGENT_ENTRYPOINT.md`, `agent_manifest.yml`, and `scripts/agent/**`
5. Update `agent_manifest.yml` canonical docs and mandatory boot sequence
   per Change 6 in `docs/operations/AGENT_WORKFLOW_CONTROL_PLAN.md`.
6. Create `docs/operations/AGENT_PROMPT_ROUTER.md` using content from Change 2.
7. Correct `docs/operations/TASK_CREATION_PROCESS.md` per Change 4.
8. Wire `docs/operations/WAVE_EXECUTION_SEMANTICS.md` into:
   - `docs/operations/POLICY_PRECEDENCE.md` per Change 5A
   - `docs/operations/PHASE_LIFECYCLE.md` per Change 5B

## Verification Commands

```bash
test -f docs/operations/AGENT_PROMPT_ROUTER.md
grep -q "AGENT_PROMPT_ROUTER" AGENT_ENTRYPOINT.md
grep -q "Before any action, read" AGENTS.md
grep -q "AGENT_ENTRYPOINT.md" agent_manifest.yml
grep -q "AGENT_PROMPT_ROUTER.md" agent_manifest.yml
grep -q "phase: '2'" docs/operations/TASK_CREATION_PROCESS.md
grep -q "phase<N>" docs/operations/TASK_CREATION_PROCESS.md
grep -q "WAVE_EXECUTION_SEMANTICS" docs/operations/POLICY_PRECEDENCE.md
grep -q "expectations for wave schedules" docs/operations/PHASE_LIFECYCLE.md
bash scripts/audit/verify_agent_conformance.sh
```

## Evidence

- `evidence/phase1/task_gov_awc1.json`

## Remediation Markers

```
failure_signature: GOV.AWC1.STARTUP_BINDING
origin_task_id: TASK-GOV-AWC1
repro_command: bash scripts/audit/verify_agent_conformance.sh
verification_commands_run: task-local verification block plus bash scripts/audit/verify_agent_conformance.sh
final_status: PENDING
```
