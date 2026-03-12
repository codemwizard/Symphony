# Agent Assignment Process

Status: Canonical
Owner: Operations / Governance

## Purpose

This document defines the deterministic process for setting `assigned_agent`
and `model` in Symphony task packs.

Task assignment must be derived from repository authority, not planner
preference.

## Assignment Rules

### Rule 1 — Start from writable `touches`

Assignment is determined from the task's writable implementation surfaces.
Do not use declared evidence paths as assignment signals.

If the `touches` list is incomplete, stop and complete it before assignment.
Every concrete path listed under `evidence:` must also appear in `touches` so
task scope is closed, but evidence outputs do not determine `assigned_agent`.

### Rule 2 — Match explicit path authority first

Use `AGENTS.md` as the source of truth for agent path authority.

Apply the most specific match first.

| Path pattern | Assigned agent |
|---|---|
| `schema/migrations/**`, `scripts/db/**` | `db_foundation` |
| `docs/invariants/**`, `docs/governance/**`, `docs/PHASE0/**`, `docs/tasks/**`, `.github/codex/prompts/**` | `invariants_curator` |
| `scripts/security/**`, `.github/workflows/**`, `infra/**`, `src/**`, `packages/**`, `Dockerfile` | `security_guardian` |
| `docs/security/**`, `docs/architecture/**` | `compliance_mapper` |
| `scripts/db/tests/**`, `scripts/audit/tests/**`, `.github/pull_request_template.md` | `qa_verifier` |
| `docs/decisions/**`, `docs/architecture/**`, `docs/governance/**`, `docs/invariants/**`, `docs/operations/**`, `docs/tasks/**`, `docs/plans/**`, `approvals/**`, `AGENTS.md`, `.agent/**`, `.codex/**`, `AGENT_ENTRYPOINT.md`, `agent_manifest.yml`, `scripts/agent/**` | `architect` |
| `docs/research/**`, `docs/overview/**` | `research_scout` |

### Rule 3 — Use purpose tiebreakers only when scopes overlap

If a path falls under multiple plausible authorities, use purpose to resolve it.

Current purpose tiebreakers:
- `scripts/audit/**`
- `docs/operations/**`

For governance, bootstrap, workflow-control, and process-enforcement work,
those paths resolve to `architect`.

### Rule 4 — Mixed ownership means split the task

If writable touched paths resolve to more than one agent after applying the
tiebreaker rules, split the task.

Do not assign `supervisor` as a workaround for mixed file-writing scope.

`supervisor` is only valid when the task's purpose is orchestration rather
than direct implementation.

### Rule 5 — Set `assigned_agent`

Use the lowercase snake-case value exactly as used in task metadata.

Valid values:
- `supervisor`
- `db_foundation`
- `invariants_curator`
- `security_guardian`
- `compliance_mapper`
- `qa_verifier`
- `architect`
- `research_scout`

### Rule 6 — Set `model`

`model` records the actual executor model.

For the governance tasks defined in this plan, set:

`model: gpt-5-codex`

If the executing environment differs, set `model` to the actual model string
used. Do not use a placeholder. If unknown, stop and require the operator to
provide it.

## Applied Decisions

### TASK-GOV-AWC1

Writable touched paths:
- `AGENT_ENTRYPOINT.md`
- `AGENTS.md`
- `agent_manifest.yml`
- `docs/operations/AGENT_PROMPT_ROUTER.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/POLICY_PRECEDENCE.md`
- `docs/operations/PHASE_LIFECYCLE.md`

Resolution:
- all writable surfaces resolve to `architect`

Assignment:
- `assigned_agent: architect`
- `model: gpt-5-codex`

### TASK-GOV-AWC2

Writable touched paths:
- `scripts/agent/run_task.sh`

Resolution:
- `scripts/agent/**` resolves to `architect` (bootstrap/control-plane asset,
  explicit path authority added in TASK-GOV-AWC1)

Assignment:
- `assigned_agent: architect`
- `model: gpt-5-codex`

## Verification

Run these checks when preparing new task packs that use this process:

```bash
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy
```

If a task still has unresolved ownership after applying these rules, stop and
fix the task scope or update `AGENTS.md` before implementation.
