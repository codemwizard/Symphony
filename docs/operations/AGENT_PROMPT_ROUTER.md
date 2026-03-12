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
4. If the task touches regulated surfaces, satisfy the repo's active approval
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
