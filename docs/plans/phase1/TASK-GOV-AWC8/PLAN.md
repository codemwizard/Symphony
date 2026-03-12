# PLAN — TASK-GOV-AWC8

## Mission

Clarify `docs/operations/WAVE_EXECUTION_SEMANTICS.md` so that agents deriving
a schedule from task metadata use:

1. dependency / blocked truth first
2. numeric task order only as the tie-break among runnable tasks
3. serial runnable-set recomputation after each completed task

## Scope

This task is limited to:
- `docs/operations/WAVE_EXECUTION_SEMANTICS.md`
- `docs/operations/WAVE_ORDERING_CLARIFICATION_PLAN.md`
- approval metadata and approval artifact records for this regulated change
- its own task pack files

## Non-Goals

- Do not change the definition of a phase.
- Do not redefine waves as parallel batches.
- Do not alter task metadata outside this task pack.
- Do not add new approval-policy rules here.

## Exact Change

In `docs/operations/WAVE_EXECUTION_SEMANTICS.md`, insert a new section
immediately after `## 4. Relationship Between Linear Order and Waves`
and immediately before `## 5. Operational Meaning`.

Insert this exact section:

```md
## 4A. Serial Derivation Rule

When no separate canonical sequence document exists for the active task set,
derive the canonical execution order from task metadata using serial
dependency-first scheduling.

Construction rule:

1. Exclude tasks whose status is explicitly non-runnable (`blocked`,
   `deferred`, `completed`).
2. Determine the currently runnable set: tasks whose `depends_on`
   entries are already satisfied.
3. If multiple tasks are currently runnable, choose the numerically or
   canonically lowest task ID next.
4. After that task completes, recompute the runnable set.
5. Repeat until the serial order is fully derived.
6. Only after the serial order is derived may wave boundaries be assigned.
7. Wave boundaries must not reorder that derived serial order.

This means waves are not parallel dependency layers.
A newly unblocked lower-number task may come immediately next in the same
wave or serial run.

Example:

- `INT-001` has no dependencies
- `INT-002` depends on `INT-001`
- `INT-003` depends on `INT-002`
- `INT-004` depends on `INT-001`

Valid serial order:

1. `INT-001`
2. `INT-002`
3. `INT-003`
4. `INT-004`

Reason:

- after `INT-001`, both `INT-002` and `INT-004` are runnable, so numeric
  order selects `INT-002`
- after `INT-002`, both `INT-003` and `INT-004` are runnable, so numeric
  order selects `INT-003`

Therefore `INT-003` may correctly appear before `INT-004` even though
`INT-004` became runnable earlier.
```

No other semantic changes are required in the wave document.

## Verification Commands

```bash
rg -n "## 4A\\. Serial Derivation Rule" docs/operations/WAVE_EXECUTION_SEMANTICS.md
rg -n "currently runnable set|recompute the runnable set|numeric or canonical|Wave boundaries must not reorder" docs/operations/WAVE_EXECUTION_SEMANTICS.md
rg -n "INT-001|INT-002|INT-003|INT-004" docs/operations/WAVE_EXECUTION_SEMANTICS.md
bash scripts/audit/verify_agent_conformance.sh
```

## Evidence

- `evidence/phase1/task_gov_awc8_wave_ordering_clarification.json`

## Remediation Markers

```text
failure_signature: GOV.AWC8.WAVE_ORDERING_DERIVATION
origin_task_id: TASK-GOV-AWC8
repro_command: rg -n "## 4A\\. Serial Derivation Rule" docs/operations/WAVE_EXECUTION_SEMANTICS.md
verification_commands_run: pending
final_status: PENDING
```
