# Wave Ordering Clarification Plan

Status: Implementation-ready
Owner: Operations / Governance

## Purpose

Clarify the missing construction rule in `docs/operations/WAVE_EXECUTION_SEMANTICS.md`
so agents do not confuse:

- dependency-safe serial ordering
- parallel frontier batching
- thematic grouping

The repo already defines that waves are consecutive dependency-safe batches.
What is still under-specified is how to derive the canonical order from task
metadata when the schedule is being constructed from `depends_on` and `status`.

## Required Clarification

When no separate canonical sequence document exists for the active task set,
the canonical execution order must be derived from task metadata using this rule:

1. Exclude tasks whose status is explicitly non-runnable (`blocked`, `deferred`, `completed`).
2. Determine the currently runnable set: tasks whose `depends_on` entries are already satisfied by completed tasks.
3. If multiple tasks are runnable at the same time, select the numerically or canonically lowest task ID next.
4. After each completed task, recompute the runnable set.
5. Continue until all runnable tasks are exhausted.
6. Only after that derived serial order exists may wave boundaries be assigned.
7. Wave boundaries must not reorder that derived serial order.

## Why This Matters

This prevents two recurring errors:

1. Treating waves like parallel dependency layers.
   That mistake incorrectly pushes a newly-unblocked task such as `INT-003`
   behind unrelated runnable tasks such as `INT-004`.

2. Treating downstream dependency importance as a reason to skip numeric order.
   That mistake incorrectly pushes `INT-009A` forward just because `STOR-001`
   depends on it, even when lower-number runnable tasks still exist.

## Canonical Example

Given these task facts:

- `INT-001` has no dependencies
- `INT-002` depends on `INT-001`
- `INT-003` depends on `INT-002`
- `INT-004` depends on `INT-001`

Then the serial order is:

1. `INT-001`
2. `INT-002`
3. `INT-003`
4. `INT-004`

Reason:
- after `INT-001`, both `INT-002` and `INT-004` are runnable
- numeric order selects `INT-002`
- after `INT-002`, both `INT-003` and `INT-004` are runnable
- numeric order selects `INT-003`

So `INT-003` may appear before `INT-004` even though `INT-004` became runnable earlier.

## Exact Edit Required

Update `docs/operations/WAVE_EXECUTION_SEMANTICS.md` to add a new section after
`## 4. Relationship Between Linear Order and Waves` and before
`## 5. Operational Meaning`.

The new section must be titled:

`## 4A. Serial Derivation Rule`

Insert the exact text defined in `TASK-GOV-AWC8`.

## Verification

After editing the wave doc, confirm:

```bash
rg -n "Serial Derivation Rule|currently runnable set|numeric order selects|INT-003|INT-004" docs/operations/WAVE_EXECUTION_SEMANTICS.md
bash scripts/audit/verify_agent_conformance.sh
```

## Expected Outcome

After this clarification:
- agents should stop treating wave definitions as parallel frontiers
- schedules derived from task metadata should be dependency-first
- numeric ordering should be used only as the tie-break among runnable tasks
- wave grouping should be applied only after the serial order is already derived
