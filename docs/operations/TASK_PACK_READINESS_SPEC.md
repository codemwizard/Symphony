# Task Pack Readiness Spec

This document defines the checks required before a task pack may be treated as
execution-ready.

Task meta schema conformance is necessary, but it is not sufficient. A task can
be schema-valid and still be unsafe to hand to an agent for implementation.

## Purpose

Use this spec to answer a narrower question than `verify_task_meta_schema.sh`:

`Is this task pack concrete enough, phase-correct enough, and verifier-backed
enough to start implementation without agents filling in critical gaps?`

## Readiness Classes

`schema-valid`
- Required keys exist and legacy-key posture is acceptable.
- Checked by `scripts/audit/verify_task_meta_schema.sh`.

`execution-ready`
- The task has concrete work, acceptance criteria, verification depth, and
  phase/path alignment sufficient to begin implementation.
- Checked by `scripts/audit/verify_task_pack_readiness.sh`.

## Execution-Ready Rules

### 1. Plan and Log Resolution

- `implementation_plan` must exist.
- `implementation_log` must exist.
- Both paths must match the declared lifecycle phase:
  - `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/...`
  - `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/...`
  - `phase: '2'` -> `docs/plans/phase2/<TASK_ID>/...`
  - `phase: '3'` -> `docs/plans/phase3/<TASK_ID>/...`
  - `phase: '4'` -> `docs/plans/phase4/<TASK_ID>/...`

### 2. Work Specificity

- `work` must be non-empty.
- `work` must not contain injected intent markers such as `[INTENT-*]`.
- `work` must describe actions, not just outcome slogans.

### 3. Acceptance Criteria Depth

Minimum criteria count:

- `DOCS_ONLY` tasks: at least `2`
- All other tasks: at least `3`

These criteria must describe observable pass conditions, not just artifact
existence.

### 4. Verification Depth

Minimum verification command count:

- `DOCS_ONLY` tasks: at least `2`
- All other tasks: at least `3`

Additional rule:

- Non-`DOCS_ONLY` tasks must include at least one task-specific verifier command
  that executes under `scripts/`, not only `test -f`, `rg`, or evidence schema
  validation.

### 5. Evidence-Only Anti-Pattern

A task is not execution-ready if its verification block is effectively:

- artifact existence only
- grep-only prose checks
- evidence validation without a task-specific verifier

### 6. Phase Correctness

- Lifecycle phase must use a valid integer-string key per
  `docs/operations/PHASE_LIFECYCLE.md`.
- The declared phase must match the implementation path family.
- If a task is intentionally non-lifecycle work, it must be explicitly
  namespaced elsewhere; unqualified `phase` remains lifecycle phase.

### 7. Bundle Uniformity

For zipped rollout packs:

- every archive must unpack under a single top-level root directory
- that root directory must equal the zip stem

This prevents ingestion drift and path-dependent automation failures.

## Use

Run this verifier before declaring any planned task or external task bundle
execution-ready:

```bash
bash scripts/audit/verify_task_pack_readiness.sh --task TASK-ID
```

For multiple tasks:

```bash
bash scripts/audit/verify_task_pack_readiness.sh \
  --task TASK-A \
  --task TASK-B \
  --task TASK-C
```

For a rollout bundle zip:

```bash
bash scripts/audit/verify_task_pack_readiness.sh --zip path/to/Bundle.zip
```

## Policy

- Do not say `ready to implement` unless both schema validation and readiness
  validation pass.
- Do not approve major later-wave/sprint tasks with empty acceptance criteria or
  evidence-only verification.
