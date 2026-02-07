# Remediation Trace Workflow (Mechanical, Tier-1)

This repo treats remediation as a **mechanical process**. If a change touches production-affecting surfaces, the change must carry a durable, searchable trace of the debugging and remediation work that led to the fix.

This workflow is enforced by a verifier gate (see `scripts/audit/verify_remediation_trace.sh`) and is intended to apply to **any fix** (CI-only failures, local failures, correctness bugs, policy/gate drift, documentation that changes enforcement semantics).

## Definitions

### Remediation casefile
A remediation casefile is a folder that contains:
- `PLAN.md` (scope, reproduction, hypotheses, derived tasks)
- `EXEC_LOG.md` (append-only execution log: errors, fixes, verification outcomes)

Naming:
- `docs/plans/<phase>/REM-<YYYY-MM-DD>_<slug>/PLAN.md`
- `docs/plans/<phase>/REM-<YYYY-MM-DD>_<slug>/EXEC_LOG.md`

### Production-affecting surfaces (Option 2)
Remediation trace is required only when the change touches any of:
- `schema/**`
- `scripts/**`
- `.github/workflows/**`
- `src/**`
- `packages/**`
- `infra/**`
- `docs/PHASE0/**`, `docs/invariants/**`, `docs/control_planes/**` (docs that change enforcement semantics)
- `docs/security/**` when it is policy/contract/control content (not general narrative)

## Required fields (minimum)

Whichever artifact satisfies the remediation trace requirement (REM casefile or an explicit fix task plan/log) must contain these strings (case-insensitive):
- `failure_signature`
- `origin_task_id` (or `origin_gate_id`)
- `repro_command`
- `verification_commands_run`
- `final_status`

## Workflow (mandatory)

### 1) When an error occurs
Create a remediation casefile `REM-*` and record:
- `failure_signature`: stable taxonomy key (example: `CI.EVIDENCE_GATE.MISSING_ARTIFACTS`)
- `first_observed_utc`
- `where`: CI job, script, or local command
- `origin_task_id` and/or `origin_gate_id`: what work introduced or exposed the failure
- `repro_command`: single canonical repro command
- `scope_boundary`: explicit in-scope and out-of-scope
- `initial_hypotheses`

### 2) Plan drives task decomposition
From the remediation plan, create the required number of tasks.

Rules:
- Tasks must be split by agent surface (see `AGENTS.md`).
- The remediation plan determines the number of tasks, not the other way around.
- Every derived task must reference the remediation plan/log in its `implementation_plan` and `implementation_log`.

### 3) Execute and log (append-only)
During remediation, update `EXEC_LOG.md` for each significant event:
- failing command + error excerpt
- root cause (when known)
- exact fix applied (file + intent)
- verification commands run + results
- evidence artifacts produced/updated

### 4) Closeout (plan updated with final fix)
Update the remediation `PLAN.md` with:
- final root cause
- final solution summary (what changed, why it works)
- verification commands run
- final status (`final_status: PASS` or `FAIL`)
- list of derived tasks and their completion state

Optionally extract stable “next time” learnings into `docs/operations/troubleshooting/**` as curated guidance. The remediation casefile remains the authoritative audit trace.

## Allowed alternatives (noise reduction)

To avoid forcing everything into `REM-*`, the remediation trace gate is satisfied by either:
1. A remediation casefile `docs/plans/**/REM-*/{PLAN.md,EXEC_LOG.md}`, or
2. A normal task plan/log `docs/plans/**/TSK-*/{PLAN.md,EXEC_LOG.md}` that includes the required remediation fields above (meaning the work is explicitly tracked as a fix, not feature-only).

