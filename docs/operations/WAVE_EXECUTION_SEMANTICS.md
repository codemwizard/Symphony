# Wave Execution Semantics

Status: Canonical
Owner: Operations / Governance
Applies to: Phase-linked task execution scheduling

## 1. Purpose

This document defines what a Wave means in Symphony task execution.

A Wave is not a thematic grouping.
A Wave is not an independent phase boundary.
A Wave is not permission to reorder tasks.

A Wave is a named execution batch derived from the canonical linear task sequence.

## 2. Core Rule

The canonical linear order of tasks is primary.

Waves are formed by taking consecutive slices of that linear order.

Therefore:

1. Waves must preserve the exact canonical task order.
2. Tasks must not be moved across wave boundaries for readability or topic grouping.
3. A later wave must never contain a task that should execute before an unfinished task in an earlier wave.

## 3. Dependency Rule

Dependency truth is mandatory inside and across waves.

This means:

1. Every wave must be dependency-safe.
2. If Task B depends on Task A, then Task A must appear earlier in the same wave sequence or in an earlier wave.
3. A wave definition is invalid if it groups tasks in a way that obscures or breaks predecessor relationships.
4. Topic similarity is never a reason to violate dependency order.

## 4. Relationship Between Linear Order and Waves

The correct construction rule is:

1. Define the canonical linear task sequence.
2. Validate dependency order across that sequence.
3. Partition the validated sequence into consecutive execution groups.
4. Name those groups Wave A, Wave B, Wave C, and so on.

The wrong construction rule is:

1. Group tasks by theme.
2. Assign wave names.
3. Infer execution order from those groups.

Symphony does not allow that second approach.

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

## 5. Operational Meaning

A Wave is a batching label only.

A Wave does not:

- change task dependencies
- override canonical order
- grant permission to skip ahead
- create a separate contract from the parent phase

A Wave does:

- provide a named checkpoint in an already-defined execution sequence
- group consecutive tasks for implementation planning
- help branch, review, and reporting discipline

## 6. Execution Rule

When using Waves for implementation:

1. Complete Wave A before Wave B.
2. Complete Wave B before Wave C.
3. Continue in sequence until the final wave.
4. Do not reorder tasks within a wave.
5. If a task inside a wave is blocked by an unmet dependency, later tasks in that wave do not leapfrog it unless explicitly approved and dependency-safe.

## 7. Example Principle

If the canonical order is:

- `INT-009A`
- `STOR-001`
- `INT-009B`

then any valid wave schedule must preserve:

- `INT-009A` before `STOR-001`
- `STOR-001` before `INT-009B`

Any wave schedule that violates that order is invalid, even if it looks cleaner thematically.

## 8. Canonical Interpretation

The correct mental model is:

- linear order tells you what comes next
- dependencies tell you what is allowed to run
- waves are named consecutive dependency-safe batches of that order

Therefore the governing rule is:

Waves are derived from the canonical sequence.
The canonical sequence is never derived from the waves.

## 9. Enforcement Expectation

Any agent or operator preparing an execution schedule must:

1. start from the canonical task sequence
2. confirm dependency safety
3. only then assign wave labels

If those three conditions are not met, the schedule must be treated as non-canonical.
