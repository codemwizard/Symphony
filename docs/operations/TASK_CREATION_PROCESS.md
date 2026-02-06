# Task Creation Process (Symphony)

This repo treats tasks as **mechanical contracts**: a task is only “real” if it has verifiable checks and evidence artifacts. Use this process whenever creating new tasks.

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

## 2) Task creation (structure + templates)

Tasks exist in **two places**:

### A) Human plan
- File: `docs/tasks/PHASE0_TASKS.md`
- Required fields per task:
  - `TASK ID`, `Title`, `Owner Role`, `Depends On`
  - `Touches` (explicit file paths)
  - `Invariant(s)`
  - `Work` (step-by-step)
  - `Acceptance Criteria` (testable)
  - `Verification Commands`
  - `Evidence Artifact(s)`
  - `Failure Modes`

### B) Machine meta
- File: `tasks/<TASK_ID>/meta.yml`
- Required fields:
  - `phase`, `task_id`, `title`, `owner_role`
  - `Depends On`, `Touches`, `Invariant(s)`
  - `Work`, `Acceptance Criteria`, `Verification Commands`
  - `Evidence Artifact(s)`, `Failure Modes`
  - `must_read`, `evidence`, `verification`, `status`
  - `client`, `assigned_agent`, `model`

Use the meta template from the repo instructions and keep the `Touches` list aligned with the assigned agent’s allowed paths.

## 3) Agent assignment (permissions + roles)

Assignment is determined by **Allowed paths** in `AGENTS.md` and `.codex/agents/*.md`:

- **DB Foundation**: `schema/migrations/**`, `scripts/db/**`, `infra/docker/**`
- **Security Guardian**: `scripts/security/**`, `scripts/audit/**`, `docs/security/**`, `.github/workflows/**`
- **Invariants Curator**: `docs/invariants/**`
- **QA Verifier**: `scripts/db/tests/**`, `scripts/audit/tests/**`, `docs/operations/**`
- **Architect**: ADRs, architecture docs, planning

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

Legacy locations still exist but are not default targets for new documents:
- `docs/phase-0/**`
- `docs/architecture/adrs/**`

See `docs/operations/DOCUMENT_PLACEMENT.md`.
