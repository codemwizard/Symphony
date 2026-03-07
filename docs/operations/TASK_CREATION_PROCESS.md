# Task Creation Process (Symphony)

This repo treats tasks as **mechanical contracts**: a task is only “real” if it has verifiable checks and evidence artifacts. Use this process whenever creating new tasks.

## 0) Remediation trace requirement (bugfix discipline)

If the change touches production-affecting surfaces (schema/scripts/workflows/runtime code, or enforcement/policy docs), the change must include a durable remediation trace:
- either a remediation casefile under `docs/plans/**/REM-*`, or
- an explicitly-marked fix plan/log under `docs/plans/**/TSK-*` (with required remediation markers).

See: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`.

DRD policy (severity-based incident documentation) is canonical at:
- `.agent/policies/debug-remediation-policy.md`

If a task or debugging effort meets DRD thresholds:
- `L1`: create DRD Lite.
- `L2/L3`: create DRD Full.

Do not require DRD for `L0` trivial fixes.

## 1) Requirements analysis

1. **Read invariants first**
   - Source of truth: `docs/invariants/INVARIANTS_MANIFEST.yml`
   - If a requirement is not mechanically verifiable, it must remain `roadmap`.
2. **Inventory existing gates/scripts**
   - Identify any scripts/tests/workflows that already enforce the requirement.
   - If none exist, the task must add a verifier or fail‑closed placeholder.
3. **Check structural change rules**
   - If the change is structural, update the manifest or add a timeboxed exception.
4. **Fail‑closed bias**
   - Never mark “implemented” without enforcement + verification evidence.

## 2) Mandatory 7-Step Task Creation Sequence

Follow this exact order. Do not skip or reorder steps.

### Step 1 — Create minimal meta stub
- Path: `tasks/<TASK_ID>/meta.yml`
- Minimum fields: `schema_version`, `phase`, `task_id`, `title`, `owner_role`, `status: planned`

### Step 2 — Validate lifecycle phase key
- Confirm phase key is valid per `docs/operations/PHASE_LIFECYCLE.md` (`0`,`1`,`2`,`3`,`4` only).
- Dotted or named phase values are invalid for lifecycle phase.

### Step 3 — Create plan
- Path mapping:
  - `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/PLAN.md`
  - `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/PLAN.md`
- Required sections: mission, constraints, verification commands, approval references, evidence paths.

### Step 4 — Populate meta fully
- Add: `depends_on`, `touches`, `invariants`, `work`, `acceptance_criteria`, `verification`, `evidence`, `failure_modes`, `must_read`, `implementation_plan`, `implementation_log`, `client`, `assigned_agent`, `model`.

### Step 5 — Create execution log
- Path mapping mirrors Step 3:
  - `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/EXEC_LOG.md`
  - `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/EXEC_LOG.md`
- Log is append-only from this point.

### Step 6 — Register in human task index
- Add task to the phase-appropriate index (for example `docs/tasks/PHASE0_TASKS.md` or `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`).
- Include required human fields: task id, title, owner, depends on, touches, invariants, work, acceptance criteria, verification, evidence, failure modes.

### Step 7 — Begin implementation
- Implementation may begin only after Steps 1-6 exist and meta paths resolve.
- Use the task meta template from `tasks/_template/meta.yml`.

## 3) Agent assignment (permissions + roles)

Assignment is determined by **Allowed paths** in `AGENTS.md` and `.codex/agents/*.md`, with explicit editable vs regulated split:

- **DB Foundation**
  - Editable: `schema/migrations/**`, `scripts/db/**`, `infra/docker/**`
  - Regulated: `schema/migrations/**`, `scripts/db/**`
- **Security Guardian**
  - Editable: `scripts/security/**`, `scripts/audit/**`, `.github/workflows/**`
  - Regulated: `scripts/security/**`, `scripts/audit/**`, `.github/workflows/**`, `docs/operations/**`
- **Invariants Curator**
  - Editable: `docs/invariants/**`
  - Regulated: `docs/invariants/**`, `docs/operations/**`
- **QA Verifier**
  - Editable: `scripts/db/tests/**`, `scripts/audit/tests/**`, `docs/operations/**`
  - Regulated: `scripts/audit/**`, `docs/operations/**`, `evidence/**`
- **Architect**
  - Editable: ADRs, architecture docs, planning
  - Regulated: `docs/operations/**`, `docs/tasks/**`

**Rule:** If `Touches` span multiple agent surfaces, split into multiple tasks with explicit dependencies.

## 4) Verification and evidence

Every task must:
- Run a deterministic verification command
- Produce evidence under `./evidence/phase0/...`
- Fail if verification or evidence is missing
- Include a **failure mode** explicitly stating: `Evidence file missing`
- Ensure the verification command **writes** the declared evidence (not just checks text)

**Mark completion** in `tasks/<TASK_ID>/meta.yml`:
- `status: "completed"`
- `verification:` includes commands actually run
- `evidence:` lists actual evidence artifacts

**Guardrails (enforced):**
- Completed tasks without evidence are rejected by `scripts/ci/check_evidence_required.sh`.
- Task definitions missing the “Evidence file missing” failure mode are rejected by `scripts/audit/verify_task_evidence_contract.sh`.
- Tasks that declare evidence but don’t use a script to emit it must remain `planned`.

## 5) Workflow wiring

- The task must be referenced in `docs/tasks/PHASE0_TASKS.md`.
- The verification command must be wired into CI (directly or through existing fast/DB/security checks).
- Evidence must be included in `scripts/ci/check_evidence_required.sh` expectations.

## 6) Common pitfalls (avoid)

- Marking a roadmap invariant as implemented without a gate
- Allowing tasks to touch files outside the assigned agent’s allowed paths
- Failing to emit evidence artifacts
- Missing `Depends On` when a verifier relies on earlier work

## 7) Document placement (for task touch lists)

When listing `Touches`, place new documents in canonical locations:
- Phase-0 governance/contracts docs: `docs/PHASE0/**`
- Authoritative ADRs: `docs/decisions/**`
- Task plans/logs: `docs/plans/phase0/**`

Lifecycle plan path mapping:
- `phase: '0'` -> `docs/plans/phase0/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`
- `phase: '1'` -> `docs/plans/phase1/<TASK_ID>/PLAN.md` and `EXEC_LOG.md`

Legacy locations still exist but are not default targets for new documents:
- `docs/phase-0/**`
- `docs/architecture/adrs/**`

See `docs/operations/DOCUMENT_PLACEMENT.md`.
