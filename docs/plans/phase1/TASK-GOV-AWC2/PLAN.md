# PLAN — TASK-GOV-AWC2

## Mission

Enforce task-pack readiness in the deterministic task runner so execution
fails fast before bootstrap when a task pack is schema-valid but not
execution-ready.

## Scope

This task is limited to:
- `scripts/agent/run_task.sh`
- its own task pack files

## Non-Goals

- Do not modify workflow-control governance docs here.
- Do not change approval-trigger rules.
- Do not choose a different verification target than `TASK-INVPROC-06`.

## Exact Change

In `scripts/agent/run_task.sh`, find this exact block:

```bash
[[ -f "$IMPLEMENTATION_PLAN" ]] || die "Missing implementation plan: $IMPLEMENTATION_PLAN"
[[ -f "$IMPLEMENTATION_LOG"  ]] || die "Missing implementation log:  $IMPLEMENTATION_LOG"
```

Immediately after it, insert:

```bash
hr
echo "==> Pack readiness gate"
if ! bash scripts/audit/verify_task_pack_readiness.sh --task "$TASK_ID"; then
  die "Task $TASK_ID is schema-valid but not execution-ready. Fix the task pack before running."
fi
echo "Pack readiness: PASS"
```

Also replace this line:

```bash
scripts/agent/bootstrap.sh
```

with:

```bash
bash scripts/agent/bootstrap.sh
```

No other lines in `run_task.sh` are modified.

## Verification Commands

```bash
grep -q "verify_task_pack_readiness" scripts/agent/run_task.sh
grep -q "bash scripts/agent/bootstrap.sh" scripts/agent/run_task.sh
bash scripts/audit/verify_task_pack_readiness.sh --task TASK-INVPROC-06
bash scripts/agent/run_task.sh TASK-INVPROC-06
```

## Evidence

- `evidence/phase1/task_gov_awc2.json`

## Remediation Markers

```
failure_signature: GOV.AWC2.RUNNER_READINESS
origin_task_id: TASK-GOV-AWC2
repro_command: bash scripts/agent/run_task.sh TASK-INVPROC-06
verification_commands_run: grep readiness insert, grep bootstrap invocation hardening, plus TASK-INVPROC-06 runner verification
final_status: PENDING
```
