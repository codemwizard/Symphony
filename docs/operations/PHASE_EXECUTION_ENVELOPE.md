# PHASE_EXECUTION_ENVELOPE.md
# Root Control Artifact — All AI Agents Must Read This First

<!--
  MANDATORY PRE-READ FOR ALL AGENTS.
  Before generating any architecture, specification, task, plan, migration,
  verifier, or evidence artifact: read this document in full.

  Nothing produced by an agent is admissible if it contradicts this envelope.
  If any lower-order artifact conflicts with this file, this file wins unless
  the human operator records a newer governing approval artifact.
-->

---

## SECTION 1 — Current Governing State

The repository has moved from a stale Phase-2-only envelope posture into a
human-authorized Phase-3 activation posture.

This revision is authorized by:

- `approvals/2026-05-16/BRANCH-chore-phase3-planning-followup.md`
- `approvals/2026-05-16/BRANCH-chore-phase3-planning-followup.approval.json`
- `approvals/2026-05-16/PHASE3-OPENING.md`
- `approvals/2026-05-16/PHASE3-OPENING.approval.json`

This envelope does **not** claim that all Phase-3 runtime implementation is
open. It claims that **Phase-3 activation governance is now the active
execution surface** and that the repository must complete the remaining
activation sequence before broader Phase-3 runtime implementation is admitted.

---

## SECTION 2 — Current Lifecycle Phase

| Field | Value |
|-------|-------|
| **Lifecycle phase key** | `3` |
| **Phase name** | Constraint and Legitimacy Engine |
| **Phase status** | OPEN — activation sequence complete |
| **Opening artifact** | `approvals/2026-05-16/PHASE3-OPENING.md` |
| **Opening sidecar** | `approvals/2026-05-16/PHASE3-OPENING.approval.json` |
| **Machine contract** | `docs/PHASE3/phase3_contract.yml` |
| **Human contract** | `docs/PHASE3/PHASE3_CONTRACT.md` |
| **Policy guard** | `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md` |
| **Contract verifier** | `scripts/audit/verify_phase3_contract.sh` |
| **Evidence namespace** | `evidence/phase3/**` |
| **Gate flag** | `RUN_PHASE3_GATES=1` |

**What OPEN means and does NOT mean:**

- MEANS: Phase-3 lifecycle artifacts and opening approval artifacts exist.
- MEANS: Phase-3 activation tasks are the current legal execution surface.
- MEANS: `evidence/phase3/**` is an admissible namespace for verifier-generated
  activation evidence.
- DOES NOT MEAN: all Phase-3 runtime implementation is already complete.
- DOES NOT MEAN: Phase-2 or Phase-3 closeout has been claimed.

---

## SECTION 3 — Current Activation Sequence

| Task | Role | Status | Note |
|------|------|--------|------|
| `TSK-P3-ACT-001` | SECURITY_GUARDIAN | Completed | Lifecycle artifact set created and verified. |
| `TSK-P3-ACT-002` | ARCHITECT | Completed | Formal Phase-3 opening approval artifact set created and verified. |
| `TSK-P3-ACT-003` | ARCHITECT | Completed | Root execution envelope rewritten for active Phase-3 activation status. |
| `TSK-P3-ACT-004` | ARCHITECT | Completed | Legality layer and dependent Phase-3 planning posture reconciled. |
| `TSK-P3-ACT-005` | ARCHITECT | Completed | Historical Phase-3 plans and evidence explicitly classified for opened-phase use. |

**Activation outcome:**
The Phase-3 activation sequence is complete. Phase-3 runtime task creation may
now proceed under the active envelope, task DAG, approval discipline, and task
pack readiness rules.

---

## SECTION 4 — Current Phase Objective

Phase-3 establishes the **Constraint and Legitimacy Engine**:

1. Typed dependency graph lineage and traversal.
2. Recursive legitimacy evaluation.
3. Contradiction detection and quarantine.
4. Failure composition and evidence continuity.
5. Authority scope and delegation enforcement.
6. Regulator-aware arbitration mechanics.
7. Conflict-of-interest enforcement.
8. Spatial constraint and DNSH gates.

**Current activation objective within Phase-3:**

Bring the lifecycle artifacts, opening approvals, root execution envelope,
legality layer, and historical evidence posture into one admissible,
internally consistent constitutional state.

The activation objective is complete when the activation sequence is fully
verified. That condition is now satisfied.

---

## SECTION 5 — Explicit Allowed Capabilities

Only the following are permitted. Default answer for anything not listed is NO.

### 5.1 Phase-3 Runtime Task Creation And Execution

- Create new Phase-3 runtime task packs for implementation-plan nodes whose
  dependencies are satisfied by `docs/PHASE3/PHASE3_TASK_DAG.md` and
  `docs/PHASE3/phase3_task_dag.yml`.
- The next eligible node is `TSK-P3-WP-001`. Downstream nodes remain gated by
  DAG dependencies until predecessor nodes are created and completed.
- Create or update `tasks/TSK-P3-WP-*/**`, support-node task packs, and their
  corresponding `docs/plans/phase3/<TASK_ID>/**` artifacts only through the
  repo's `CREATE-TASK`, `RESUME-TASK`, and `IMPLEMENT-TASK` procedures.
- Update `docs/tasks/PHASE3_ACTIVATION_TASKS.md` only for historical activation
  traceability; it is no longer the sole active execution surface.

### 5.2 Envelope, Policy, And Verifier Alignment

- Update `docs/operations/PHASE_EXECUTION_ENVELOPE.md` under `TSK-P3-ACT-003`.
- Create or update task-specific verifier scripts under `scripts/agent/**`
  needed to validate activation artifacts and emit evidence.
- Create or update approval artifacts under `approvals/YYYY-MM-DD/**` when
  regulated-surface edits require them.

### 5.3 Runtime-Governed Phase-3 Planning And Evidence

- Use the artifact classification produced by `TSK-P3-ACT-005` when deciding
  whether a prior Phase-3 artifact is admissible, historical, or regenerate-required.
- Runtime implementation proof must be emitted by the new task's declared
  verifier and must not rely on historical pre-opening evidence.

### 5.4 Evidence Emission

- Emit verifier-generated evidence to `evidence/phase3/**` only.
- Activation evidence must be generated by the declared verifier script and must
  include at minimum:
  - `task_id`
  - `git_sha`
  - `timestamp_utc`
  - `status`
  - `checks`
  - `observed_paths`
  - `observed_hashes`
  - `command_outputs`
  - `execution_trace`

### 5.5 Historical Artifact Classification

- Historical artifact classification is now authoritative via:
  - `docs/plans/phase3/phase3_artifact_classification_manifest.json`
  - `docs/plans/phase3/PHASE3_OPENED_PHASE_ARTIFACT_CLASSIFICATION.md`
- No historical Phase-3 artifact may be silently treated as opened-phase
  delivery proof.

---

## SECTION 6 — Explicit Forbidden Capabilities

These are absolute prohibitions.

### 6.1 Future-Phase Boundary Violations

- Do not create or open Phase-4 artifacts or evidence.
- Do not use language claiming "Phase-3 complete", "Phase complete",
  "Phase ready", or equivalent closeout language.
- Do not open future-phase execution surfaces by implication.

### 6.2 False Completion

- Do not treat the existence of `docs/PHASE3/phase3_contract.yml` alone as
  proof that Phase-3 runtime implementation is complete.
- Do not treat the opening approval artifact alone as proof that the legality
  layer or historical evidence posture is reconciled.
- Do not hand-author evidence JSON without running the declared verifier.

### 6.3 Activation Scope Drift

- Do not implement broader Phase-3 runtime capability tasks outside the task
  DAG, task-pack, approval, and verifier process.
- Do not modify surfaces outside the active task's `touches` list.
- Do not rewrite the legality matrix under `TSK-P3-ACT-003`; that work belongs
  to `TSK-P3-ACT-004`.
- Do not normalize historical evidence under `TSK-P3-ACT-003`; that work
  belongs to `TSK-P3-ACT-005`.

### 6.4 Approval And Authority Violations

- Do not edit regulated surfaces without prior approval metadata.
- Do not backdate approval artifacts.
- Do not expand the allowed capabilities in this envelope without a human
  approval artifact authorizing the expansion.

---

## SECTION 7 — Required Evidence Classes

### 7.1 Baseline (all activation tasks)

```text
task_id          string   exact task ID from meta.yml
git_sha          string   current commit SHA at time of verification
timestamp_utc    string   ISO-8601 UTC
status           string   "PASS" | "FAIL" or "pass" | "fail"
checks           array    list of check names with pass/fail result
```

### 7.2 Activation Evidence Extension

```text
observed_paths   array    file paths inspected during verification
observed_hashes  object   {path: sha256_hex} for each observed path
command_outputs  array    ordered command/status summary entries
execution_trace  array    ordered trace of verification decisions
```

Evidence missing any required field for its class is inadmissible.

---

## SECTION 8 — Closure Rules

### 8.1 Activation Task Completion

An activation task is complete only when:

1. All deliverables declared in its task pack exist.
2. The task-specific verifier exists, is executable, and exits 0.
3. The evidence artifact exists and validates.
4. Any required approval metadata existed before the first regulated edit.
5. `EXEC_LOG.md` contains the required remediation-trace markers.
6. No forbidden overclaim or future-phase expansion was introduced.
7. Task-pack readiness passes.

### 8.2 Phase-3 Activation Sequence Completion

The activation sequence is now complete. The envelope, legality matrix,
dependent Phase-3 planning docs, and historical artifact classification are in
agreement on the active posture.

### 8.3 Phase-3 Closeout

Phase-3 closeout is **not** in scope for this envelope revision.

---

## SECTION 9 — Inherited Constraints

These remain in force:

- No runtime DDL on production paths.
- Forward-only migrations; never edit applied migrations.
- `SECURITY DEFINER` functions must explicitly set
  `search_path = pg_catalog, public`.
- Runtime roles remain revoke-first.
- Outbox attempts remain append-only.
- No direct pushes to `main`.

---

## SECTION 10 — Active DRDs

**`.agent/rejection_context.md` does not currently exist.**

No DRD lockout is active at this envelope revision.

If a new DRD is raised during activation work, register it at
`.agent/rejection_context.md` and stop implementation until the remediation
trace rules are satisfied.

---

## SECTION 11 — Known Drifted Artifacts

The following artifacts were produced before the envelope and legality layer
were fully reconciled and must be interpreted carefully:

- Historical non-activation plans and evidence remain intentionally classified
  as `historical_planning_only` or `regenerate_required` by the Phase-3 artifact
  classification manifest. That is managed state, not ungoverned drift.

---

## SECTION 12 — Known Inadmissible Artifacts

The following are currently inadmissible:

- Any hand-authored evidence file under `evidence/phase3/**`.
- Any Phase-3 historical evidence or plan artifact not explicitly classified by
  `TSK-P3-ACT-005`.
- Any artifact claiming broader Phase-3 runtime execution is open merely
  because `PHASE3-OPENING.md` exists.
- Any artifact claiming Phase-3 closeout or full runtime completion.

The following activation evidence is admissible when verifier-generated:

- `evidence/phase3/tsk_p3_act_001_lifecycle_artifacts.json`
- `evidence/phase3/tsk_p3_act_002_opening_approval.json`
- `evidence/phase3/tsk_p3_act_003_envelope_alignment.json`

---

## SECTION 13 — Current Authoritative Execution Surface

### 13.1 The Next Eligible Runtime Node

```text
TSK-P3-WP-001  ← Eligible for CREATE-TASK and downstream implementation flow.
```

### 13.2 Writable Surfaces Right Now

| Surface | Allowed operation | Condition |
|---------|-------------------|-----------|
| `tasks/TSK-P3-WP-001/**` and downstream runtime task packs | Create and implement per DAG dependencies | After task pack creation and readiness |
| `docs/plans/phase3/<runtime-task>/**` | PLAN.md and EXEC_LOG.md updates | Matching runtime task scope only |
| `docs/tasks/PHASE3_ACTIVATION_TASKS.md` | Historical activation trace only | Activation artifact maintenance |
| `approvals/YYYY-MM-DD/**` | Approval metadata artifacts | Before touching regulated surfaces |

### 13.3 Non-Executable Surfaces Right Now

| Surface | Reason |
|---------|--------|
| Any runtime surface whose DAG dependencies are unsatisfied | Dependency-gated by Phase 3 task DAG |
| Any Phase-4 artifact or evidence surface | Future phase not open |

---

## SECTION 14 — Document Precedence Chain

When any source contradicts this envelope, apply this order:

1. **This file** (`PHASE_EXECUTION_ENVELOPE.md`)
2. `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
3. `docs/operations/PHASE_LIFECYCLE.md`
4. `approvals/2026-05-16/PHASE3-OPENING.md`
5. `approvals/2026-05-16/PHASE3-OPENING.approval.json`
6. `docs/PHASE3/phase3_contract.yml`
7. `docs/PHASE3/PHASE3_CONTRACT.md`
8. `docs/operations/AGENTIC_SDLC_PHASE3_POLICY.md`
9. Individual `tasks/TSK-P3-ACT-00*/meta.yml`

The opening approval set authorizes this activation posture.
Task packs do not expand permissions beyond what this envelope states.

---

## SECTION 15 — Agent Operating Rules

Before starting any session:

1. Read this file in full.
2. Check `.agent/rejection_context.md`.
3. Confirm the task is listed in Section 13.
4. Confirm the surfaces to be touched are listed in Section 13.2.

Before writing any file:

1. Check Section 6 for prohibited actions.
2. If touching a regulated surface, confirm approval metadata already exists.
3. Confirm the task pack `touches` list includes the target file.

Before claiming a task complete:

1. Run the task-specific verifier.
2. Validate evidence.
3. Run task-pack readiness.
4. Confirm no future-phase or full-runtime overclaim was introduced.

When uncertain whether an action is permitted:

Default answer: **NO**.

---

## SECTION 16 — Envelope Maintenance

This document remains the root control artifact.

An AI agent may update this envelope **only** when:

1. a human approval artifact explicitly authorizes the change, and
2. the edit is inside a declared activation or governance task scope.

This revision is authorized by the 2026-05-16 Phase-3 opening approval set.

Update this envelope when:

- a new Phase-3 runtime task becomes the active implementation surface;
- a new DRD is opened or closed;
- a new human approval artifact supersedes this posture;
- Phase-3 closeout is later triggered.

---

*Envelope revised: 2026-05-16*  
*Current phase: `3` — Constraint and Legitimacy Engine*  
*Current posture: Phase 3 is active; activation completed and runtime task creation may proceed under the DAG and task-pack rules*  
*Next required action: Create the task pack for `TSK-P3-WP-001`*
