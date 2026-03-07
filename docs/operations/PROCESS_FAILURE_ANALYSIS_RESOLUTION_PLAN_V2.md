# Symphony Process Failure Analysis and Resolution Plan (V2)

## Executive Summary

Symphony's agent governance has strong mechanical tooling (`bootstrap.sh`, `run_task.sh`, conformance gates), but deterministic compliance fails when that tooling is not mandatory at task start. The highest-impact gap is entry-point enforcement, followed by policy precedence conflicts and a pre-PR approval metadata deadlock.

This plan defines a documentation-only, implementation-ready policy baseline. It does **not** implement scripts or CI changes.

---

## 1. Confirmed Root Cause

### 1.1 Missing Mandatory Entry Point

Agents can start work directly from conversational instructions without a forced preflight path. As a result, required controls (task scaffolding, conformance checks, approvals, remediation traces) are bypassable.

### 1.2 Why Existing Tooling Did Not Prevent Failure

- `scripts/agent/bootstrap.sh` exists and is sound, but is not currently enforced as the first mandatory step.
- `scripts/agent/run_task.sh <TASK_ID>` is a deterministic executor, but assumes task artifacts already exist and is not guaranteed as the only execution path.

---

## 2. Contradictions and Detailed Resolutions

## C1. Authority Contradiction (Critical)

### Problem

Multiple documents claim top authority (operation manual, `.agent` policy, and policy/playbook language), creating undefined behavior on conflicts.

### Resolution

Create and adopt a single precedence contract:

`docs/operations/POLICY_PRECEDENCE.md`

Proposed order:
1. `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
2. `docs/operations/AGENTIC_SDLC_PHASE1_POLICY.md`
3. `docs/operations/TASK_CREATION_PROCESS.md`
4. `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
5. `.agent/**` mirrors/workflows/policies
6. `.codex/**` role/rule contracts
7. `DEV_WORKFLOW.md` and examples

All lower-priority documents must explicitly state they defer to `POLICY_PRECEDENCE.md`.
This must include a direct content change in `.agent/README.md`: remove or replace any statement that `.agent/` is apex authority, and point to `POLICY_PRECEDENCE.md` instead.
This precedence update and `.agent/README.md` authority-claim removal must land in the same change set.

---

## C2. Commit Format Contradiction (High)

### Problem

Different docs prescribe incompatible commit formats.

### Resolution

Define one canonical commit format in:

`docs/operations/GIT_CONVENTIONS.md`

Every other document must reference it (no duplicate format definitions). Existing example commands in workflow docs must be updated to exactly match the canonical format.
`.agent/workflows/git-conventions.md` must be explicitly retired or rewritten to defer to `docs/operations/GIT_CONVENTIONS.md` (not independently normative).
Canonical decision to encode in `GIT_CONVENTIONS.md`:
1. Phase/Wave format is mandatory for task-linked implementation/remediation commits.
   Example: `Phase 0.2: declare INV-134 for SEC-G08 dependency audit`
2. Conventional-commit format is permitted only for housekeeping/non-phase work (`chore`, `docs`, `ci`, `build`, `refactor`) and must include a task or issue reference in the body/footer.

---

## C3. Branch Naming Contradiction (High)

### Problem

Branch naming examples conflict with stricter phase/wave branch policy.

### Resolution

Define one canonical branch naming regex in:

`docs/operations/GIT_CONVENTIONS.md`

All examples in other docs must be rewritten to match the same regex. No alternative branch formats should remain in policy text.
As above, `.agent/workflows/git-conventions.md` must be retired or rewritten as a non-authoritative pointer to `docs/operations/GIT_CONVENTIONS.md`.
Canonical decision to encode in `GIT_CONVENTIONS.md`:
1. Task-linked implementation/remediation branches require phase/wave key:
   `<category>/<phase-or-wave-key>-<short-kebab-desc>`
   Example: `security/0.2-inv-134-dependency-audit`
2. Housekeeping branches may omit phase/wave key:
   `<category>/<short-kebab-desc>`
   Allowed categories limited to: `chore`, `docs`, `ops`, `ci`.

---

## C4. DRD Trigger Contradiction (Medium)

### Problem

One policy uses time/attempt triggers; another uses severity-only phrasing.

### Resolution

Unify in `docs/operations/REMEDIATION_TRACE_WORKFLOW.md` with dual-axis triggers:
1. Severity axis: L1 => DRD Lite, L2/L3 => DRD Full.
2. Time/attempt axis: blocked >15 min, 2 failed attempts, or material push delay >30 min => DRD Lite minimum.

`AI_AGENT_OPERATION_MANUAL.md` should reference this table directly rather than re-describing thresholds.

---

## C5. Scope vs Approval Ambiguity (Medium)

### Problem

Role documents imply editable scope, while regulated-surface controls require approval metadata. This is often interpreted as conflicting permission semantics.

### Resolution

For each role document, split path declarations into:
1. `editable_paths`
2. `regulated_paths_requiring_approval_metadata`

This clarifies: a path can be editable and still require approval artifacts.

---

## C6. INVARIANTS_QUICK Regeneration Gap (Low)

### Problem

Regeneration is required in one workflow doc but inconsistently specified elsewhere.

### Resolution

Make one canonical rule in invariants policy text:
- If `docs/invariants/INVARIANTS_MANIFEST.yml` changes, regenerate and stage `docs/invariants/INVARIANTS_QUICK.md` using the canonical generator command.

All references elsewhere should link to this rule instead of duplicating logic.

---

## 3. Ordering Conflicts and Detailed Resolutions

## O1. Task Scaffolding vs PLAN Ordering

### Problem

Current language makes it unclear whether `meta.yml` or `PLAN.md` is created first.

### Resolution

Declare canonical order:
1. Reserve/create task skeleton (`tasks/<TASK_ID>/meta.yml` minimal stub)
2. Create `PLAN.md`
3. Populate `meta.yml` references to `PLAN.md`/`EXEC_LOG.md`
4. Create `EXEC_LOG.md`
5. Register in task index doc

This order must be codified now in `docs/operations/TASK_CREATION_PROCESS.md` as an explicit numbered canonical sequence (even before `create_task.sh` exists).
`create_task.sh` should then implement that documented sequence.

---

## O2. Approval Metadata Circular Dependency (Critical)

### Problem

Pre-merge gates require approval metadata, while artifact conventions require PR numbers not available pre-push.

### Resolution

Adopt two-phase approval references:
1. Pre-PR artifact: `change_ref: branch/<branch_name>`, PR fields nullable.
2. Post-PR finalization: `change_ref: pr/<number>`, PR metadata completed before merge.

Conformance checks should validate phase-appropriate completeness:
- Pre-push/pre-PR: branch-linked approval present.
- Merge gate: PR-linked approval finalized.

Implementation dependency note:
- This resolution is policy-complete but not mechanically active until `verify_agent_conformance.sh` and merge-gate logic are updated.
- Therefore, documentation updates must explicitly create a follow-on implementation task to update conformance scripts/CI checks for two-phase approval validation.

---

## O3. Boot Sequence Ordering Conflict

### Problem

Different docs prescribe different command order for planning checks, conformance, and pre-CI.

### Resolution

Define one canonical startup chain and only reference the orchestrator script in docs:
1. Branch guard
2. Task-plan presence check
3. Agent conformance check
4. Pre-CI check

Document this as the contract for `scripts/agent/bootstrap.sh`.

---

## O4. Remediation Trace Trigger Ambiguity

### Problem

Some docs imply remediation trace is change-surface based; others imply failure-only.

### Resolution

Split into two explicit artifacts:
1. Change Trace: required when touching production-affecting/regulated surfaces.
2. Failure Trace (DRD): required when blockers/failures meet DRD thresholds.

A task may require one or both.

---

## 4. Mandatory Entry Point Policy (Normative Text)

The following wording should be adopted in a root entrypoint document:

0. Read `.git/HEAD`. If value is `refs/heads/main`, stop immediately. Do not run bootstrap. Ask the human which branch to use.
1. Before modifying repository files, run: `scripts/agent/bootstrap.sh`.
2. If bootstrap fails, stop and remediate; do not implement task changes.
3. Task execution must occur through: `scripts/agent/run_task.sh <TASK_ID>`.
4. If run_task fails, stop and remediate; do not bypass gate checks manually.

Important sequencing correction:
- `run_task.sh` is task execution, not a second preflight command.
- The policy trigger is "before file modification," not "before any command."

---

## 5. Required Non-Implementation Follow-Up (Policy/Docs Only)

1. Add `POLICY_PRECEDENCE.md` and update conflicting docs to defer to it.
2. In the same change set, update `.agent/README.md` to remove/replace any apex-authority claim with a pointer to `POLICY_PRECEDENCE.md`.
3. Add `GIT_CONVENTIONS.md` and replace conflicting branch/commit examples.
4. Retire or rewrite `.agent/workflows/git-conventions.md` to defer to `GIT_CONVENTIONS.md`.
5. Update approval artifact policy to support branch-to-PR lifecycle.
6. Add root `AGENT_ENTRYPOINT.md` as the canonical startup policy document with mandatory branch guard + bootstrap/run_task wording; update `IDE_AGENT_ENTRYPOINT.md` to defer to it.
7. Update remediation workflow to dual-axis DRD triggers and dual trace types.
8. Update `TASK_CREATION_PROCESS.md` with the canonical O1 file-creation sequence.
9. Add a follow-on implementation task for `verify_agent_conformance.sh` and CI merge-gate updates required by O2.

---

## 5A. Claude.ai Conversational Agent Protocol

This section defines the required non-shell equivalent of `bootstrap.sh` / `run_task.sh` for conversational agents that cannot execute local scripts.

Before any repository file modification, the agent must provide a preflight checklist and receive explicit human approval:

1. Confirm branch state declaration:
- Agent must read `.git/HEAD` and state its literal value.
- If value is `refs/heads/main`, agent must stop immediately and may not proceed based on intent alone.

2. Confirm mandatory document read set:
- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/TASK_CREATION_PROCESS.md`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `docs/operations/REGULATED_SURFACE_PATHS.yml`

3. Confirm task artifacts exist or will be created before implementation:
- `tasks/<TASK_ID>/meta.yml`
- `docs/plans/<phase>/<TASK_ID>/PLAN.md`
- `docs/plans/<phase>/<TASK_ID>/EXEC_LOG.md`
- task index entry per `TASK_CREATION_PROCESS.md`

4. Confirm regulated-surface impact:
- Agent must declare whether touched paths are regulated and list required approval artifacts for this task phase.

5. Human approval moment (required):
- Agent must stop after checklist and ask for explicit "proceed" approval before making repository changes.

7. Non-compliance consequence (mandatory refusal rule):
- If checklist items are incomplete, or if the human instructs "just proceed" without checklist completion, the agent must decline and restate missing prerequisites.
- Agent may not proceed on human instruction alone when task artifacts are absent, branch state is non-compliant, or regulated-surface status is unconfirmed.

6. Post-change declaration:
- Agent must provide a concise conformance declaration listing which required checks could not be mechanically run in conversation mode.

---

## 6. Risk and Expected Outcome

### If Unresolved

- Continued policy ambiguity and selective compliance.
- Repeated bypass of regulated-surface approval requirements.
- Recurring merge friction from contradictory conventions.

### If Resolved

- Deterministic startup path for agent work.
- Reduced policy interpretation drift.
- Clearer auditability from consistent task, approval, and trace sequencing.

Note: This plan materially reduces violations but cannot guarantee absolute zero violations without mechanical enforcement in scripts/hooks/CI.
