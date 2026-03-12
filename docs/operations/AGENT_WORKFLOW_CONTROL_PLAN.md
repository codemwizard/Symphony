# Symphony Agent Workflow Control Plan

Status: Implementation-ready

## Purpose

This plan closes the current prompt-to-execution workflow gaps for repo-aware
agents and makes the startup path binding from repository bootstrap surfaces.

## Activation Rule

Any repo-scoped prompt activates this process.

The first required read is `AGENT_ENTRYPOINT.md`.

If `AGENT_ENTRYPOINT.md` is missing or unreadable, stop and ask the human
for guidance before doing any work.

Mode selection may use non-mutating inspection only.

## Approval Determination

Historical note for the original `TASK-GOV-AWC1` / `TASK-GOV-AWC2` execution:
Under the repo's current mechanical approval enforcement, this exact change
set does not require approval artifacts.

This determination is based on:
- `docs/operations/REGULATED_SURFACE_PATHS.yml`
- `scripts/audit/lib/approval_requirement.py`

None of the files changed by this plan match the currently enforced
approval-trigger patterns.

This determination differed from the broader written contract in `AGENTS.md`
and the operation manual at the time of execution. That mismatch is now closed
by subsequent regulated-surface alignment work.

## Known Execution Anomaly

`TASK-GOV-AWC1` and `TASK-GOV-AWC2` were executed before the mechanical
approval rules were aligned with the broader written regulated-surface
contract. A retroactive approval package was created on 2026-03-12 to close
that late-approval gap and explicitly document the anomaly rather than
rewriting history.

## Changes

### Change 1 — Replace `AGENT_ENTRYPOINT.md`

Replace the file with:

```md
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
```

### Change 2 — Create `docs/operations/AGENT_PROMPT_ROUTER.md`

Create the file with:

```md
# Agent Prompt Router

Status: Canonical
Owner: Operations / Governance

## Purpose

This document defines the decision procedure for classifying an incoming prompt
and selecting the execution path that follows.

The agent must identify exactly one mode from the five modes below.
If no mode matches unambiguously after non-mutating inspection of repo state:
STOP and ask the human which mode applies.

## Activation Rule

Any repo-scoped prompt activates this process.
The first required read is `AGENT_ENTRYPOINT.md`.

If `AGENT_ENTRYPOINT.md` is missing or unreadable: STOP and ask the human
for guidance before doing any work.

## Mode 1 — CREATE-TASK

### Trigger

The prompt explicitly asks to create or define a new task, and no existing
task pack is being resumed for the same work item.

### Required inputs before creating files

All of the following must be present in the prompt or confirmed by the human.
If any are absent: STOP and report the missing inputs. Do not begin file creation.

1. Task title
2. Lifecycle phase (`0`, `1`, `2`, `3`, or `4`)
3. At least one observable acceptance criterion
4. At least one deterministic verifier command or concrete evidence output

### Execution path

Follow `docs/operations/TASK_CREATION_PROCESS.md` in exact order.

After the task pack is created, but before implementation begins, run:

```bash
bash scripts/audit/verify_task_meta_schema.sh --mode strict --allow-legacy
bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>
```

If either fails: STOP. Fix the task pack before implementation.

## Mode 2 — RESUME-TASK

### Trigger

`tasks/<TASK_ID>/meta.yml` exists and the task status is not `completed`
or `deferred`.

### Inspection algorithm

Run in order and stop on first failure.

1. Meta readable:
   If missing or unreadable, report `STATE: stub-only` and STOP.
2. Plan present:
   If `implementation_plan` does not resolve, report `STATE: plan-missing` and STOP.
3. Log present:
   If `implementation_log` does not resolve, report `STATE: log-missing` and STOP.
4. Pack ready:
   Run `bash scripts/audit/verify_task_pack_readiness.sh --task <TASK_ID>`.
   If it fails, report `STATE: not-ready` and STOP with the readiness output.
5. Dependencies satisfied:
   Every task in `depends_on` must be `completed`.
   If not, report `STATE: blocked` and list the blocking tasks.
6. If all pass:
   Report `STATE: resume-ready` and continue to IMPLEMENT-TASK mode.

The agent must not implement from any state other than `resume-ready`.

## Mode 3 — IMPLEMENT-TASK

### Trigger

The task is already `resume-ready`.

### Pre-flight rules

1. Branch must not be `main`.
2. Read the task's `touches` list.
3. If intended modifications fall outside `touches`, STOP and report scope drift.
   Return to task-pack repair instead of silently expanding scope.
4. Every concrete evidence path declared under `evidence:` must also appear in
   `touches`. Evidence outputs complete scope but do not determine
   `assigned_agent`.
5. If the task touches regulated surfaces, satisfy the repo's active approval
   and approval-metadata requirements before writing those files. Use the same
   enforced approval logic the repo uses for conformance checks.

### Execution path

Run:

1. `scripts/audit/verify_agent_conformance.sh`
2. `scripts/dev/pre_ci.sh`
3. `scripts/agent/run_task.sh <TASK_ID>`

## Mode 4 — REMEDIATE

### Trigger

A verification step, CI run, pre-CI run, or implementation attempt failed and
the failure meets remediation or DRD thresholds.

### Required steps before code changes

1. Identify the failing task or verifier.
2. Check for an active remediation trace or remediation-marked task casefile.
3. If none exists, create the required remediation artifact before modifying files.
4. Severity classification is mandatory. Do not default silently to L0.

### Scope rule

Changes are limited to:
- the failing task's declared scope, and
- the remediation artifact set

If the fix requires additional files outside the current task scope, STOP and
escalate as scope drift.

### After the fix

Re-run the targeted failing verifier first, then broader parity checks.
Update the remediation trace before closing.

## Mode 5 — PUSH-READY-CHECK

### Trigger

The human asks whether the branch is ready to push, or the agent is preparing
to push after task completion.

### Required pass conditions

1. Branch is not `main`.
2. Every modified task pack is readiness-valid.
3. Every modified task is `completed`.
4. Every declared verifier for each modified task passes.
5. Every declared evidence artifact exists and is fresh enough for the repo's
   current freshness semantics.
6. `scripts/dev/pre_ci.sh` passes.
7. `scripts/audit/verify_agent_conformance.sh` passes.
8. Any required approvals and approval metadata for regulated-surface changes exist.

If any item fails: STOP and report the failing item and required remediation.

## Hard Stop Conditions

The agent must stop and report to the human when:

- the prompt does not map to exactly one mode after non-mutating inspection
- CREATE-TASK required inputs are missing
- RESUME-TASK state is anything other than `resume-ready`
- intended file changes exceed the active task scope
- regulated-surface changes lack required approval prerequisites
- work would occur directly on `main`
- two full fix attempts have failed without convergence and DRD escalation is now required
```

### Change 3 — Insert readiness gate into `scripts/agent/run_task.sh`

Immediately after:

```bash
[[ -f "$IMPLEMENTATION_PLAN" ]] || die "Missing implementation plan: $IMPLEMENTATION_PLAN"
[[ -f "$IMPLEMENTATION_LOG"  ]] || die "Missing implementation log:  $IMPLEMENTATION_LOG"
```

insert:

```bash
hr
echo "==> Pack readiness gate"
if ! bash scripts/audit/verify_task_pack_readiness.sh --task "$TASK_ID"; then
  die "Task $TASK_ID is schema-valid but not execution-ready. Fix the task pack before running."
fi
echo "Pack readiness: PASS"
```

### Change 4 — Correct `docs/operations/TASK_CREATION_PROCESS.md`

Add phases 2, 3, and 4 to all three lifecycle path mapping sections.

For plan paths, replace the current 0/1-only block with:

```
  - `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/PLAN.md`
  - `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/PLAN.md`
  - `phase: '2'` -> `docs/plans/phase2/<TASK_ID>/PLAN.md`
  - `phase: '3'` -> `docs/plans/phase3/<TASK_ID>/PLAN.md`
  - `phase: '4'` -> `docs/plans/phase4/<TASK_ID>/PLAN.md`
```

For log paths, replace the current 0/1-only block with:

```
  - `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/EXEC_LOG.md`
  - `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/EXEC_LOG.md`
  - `phase: '2'` -> `docs/plans/phase2/<TASK_ID>/EXEC_LOG.md`
  - `phase: '3'` -> `docs/plans/phase3/<TASK_ID>/EXEC_LOG.md`
  - `phase: '4'` -> `docs/plans/phase4/<TASK_ID>/EXEC_LOG.md`
```

For the summary mapping section, replace the current 0/1-only block with:

```
- `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
- `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
- `phase: '2'` -> `docs/plans/phase2/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
- `phase: '3'` -> `docs/plans/phase3/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
- `phase: '4'` -> `docs/plans/phase4/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
```

Replace the current phase0-only evidence wording with:

```
- Produce evidence under `./evidence/phase<N>/...` where `<N>` matches the
  task's declared lifecycle phase key.
```

### Change 5 — Wire existing wave semantics into canonical docs

Do not create a new wave semantics file. It already exists.

In `docs/operations/POLICY_PRECEDENCE.md`, immediately after:

```
- Lifecycle taxonomy: `docs/operations/PHASE_LIFECYCLE.md`
```

add:

```
- Wave execution semantics: `docs/operations/WAVE_EXECUTION_SEMANTICS.md`
```

In `docs/operations/PHASE_LIFECYCLE.md`, immediately after:

```
3. Waves do not get separate phase contracts; they deliver against the parent phase contract.
```

and immediately before:

```
## 6) Entry and Exit Rules (Global)
```

insert:

```
For the full construction rule, dependency constraints, and enforcement
expectations for wave schedules, see:
`docs/operations/WAVE_EXECUTION_SEMANTICS.md`
```

### Change 6 — Make the entrypoint/router binding at repo startup

In `AGENTS.md`, add to `## Non-Negotiables`:

```
- Before any action, read `AGENT_ENTRYPOINT.md` and classify the prompt using `docs/operations/AGENT_PROMPT_ROUTER.md`. Do not proceed until exactly one mode is identified.
```

In `AGENTS.md`, add to `## Canonical References`:

```
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AGENT_PROMPT_ROUTER.md`
```

In `AGENTS.md`, replace the Architect allowed paths line.

Find:

```
Allowed paths: `docs/decisions/**`, `docs/architecture/**`, `docs/governance/**`, `docs/invariants/**`, `docs/operations/**`, `docs/tasks/**`, `docs/plans/**`, `approvals/**`, `AGENTS.md`, `.agent/**`, `.codex/**`
```

Replace with:

```
Allowed paths: `docs/decisions/**`, `docs/architecture/**`, `docs/governance/**`, `docs/invariants/**`, `docs/operations/**`, `docs/tasks/**`, `docs/plans/**`, `approvals/**`, `AGENTS.md`, `.agent/**`, `.codex/**`, `AGENT_ENTRYPOINT.md`, `agent_manifest.yml`, `scripts/agent/**`
```

In `agent_manifest.yml`, replace:

```yaml
canonical_docs:
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - AGENTS.md
```

with:

```yaml
canonical_docs:
  - AGENT_ENTRYPOINT.md
  - docs/operations/AGENT_PROMPT_ROUTER.md
  - docs/operations/AI_AGENT_OPERATION_MANUAL.md
  - AGENTS.md
```

Replace:

```yaml
mandatory_boot_sequence:
  - scripts/audit/verify_agent_conformance.sh
  - scripts/dev/pre_ci.sh
```

with:

```yaml
mandatory_boot_sequence:
  - AGENT_ENTRYPOINT.md
  - docs/operations/AGENT_PROMPT_ROUTER.md
  - scripts/audit/verify_agent_conformance.sh
  - scripts/dev/pre_ci.sh
```

## Verification

Run after all changes are applied. Stop on any failure.

```bash
test -f docs/operations/AGENT_PROMPT_ROUTER.md && echo "PASS: router exists"
test -f docs/operations/WAVE_EXECUTION_SEMANTICS.md && echo "PASS: wave doc exists"
grep -q "WAVE_EXECUTION_SEMANTICS" docs/operations/POLICY_PRECEDENCE.md && echo "PASS: precedence wired"
grep -q "phase: '2'" docs/operations/TASK_CREATION_PROCESS.md && echo "PASS: phase mappings extended"
grep -q "phase<N>" docs/operations/TASK_CREATION_PROCESS.md && echo "PASS: evidence namespace fixed"
grep -q "verify_task_pack_readiness" scripts/agent/run_task.sh && echo "PASS: readiness gate wired"
grep -q "AGENT_PROMPT_ROUTER" AGENT_ENTRYPOINT.md && echo "PASS: entrypoint references router"
grep -q "Before any action, read" AGENTS.md && echo "PASS: AGENTS binding added"
grep -q "AGENT_ENTRYPOINT.md" agent_manifest.yml && echo "PASS: manifest entrypoint added"
grep -q "AGENT_PROMPT_ROUTER.md" agent_manifest.yml && echo "PASS: manifest router added"
bash scripts/audit/verify_agent_conformance.sh
bash scripts/audit/verify_task_pack_readiness.sh --task TASK-INVPROC-06
bash scripts/agent/run_task.sh TASK-INVPROC-06
```
