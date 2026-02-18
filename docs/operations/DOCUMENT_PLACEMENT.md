# Document Placement Conventions

This repo has legacy and current documentation locations. Use the rules below for **new** documents.

## Canonical locations (use for new docs)

- Phase-0 governance/contracts/plans (phase-wide): `docs/PHASE0/**`
- Task registry: `docs/tasks/PHASE0_TASKS.md`
- Task machine metadata: `tasks/<TASK_ID>/meta.yml`
- Task execution plan/log: `docs/plans/phase0/<task-folder>/{PLAN.md,EXEC_LOG.md}`
- Invariants registry/docs: `docs/invariants/**`
- Security controls and policy docs: `docs/security/**`
- Architecture decisions (ADRs): `docs/decisions/**`
- Architecture overviews/specs: `docs/architecture/**`
- Developer workflow/process docs: `docs/operations/**`
- Product-facing requirement/context docs: `docs/product/**`
- System overview/glossary/vision: `docs/overview/**`

## Legacy locations (read/update only when required by existing checks)

- `docs/phase-0/**` is legacy for older Phase-0 foundation docs.
- `docs/architecture/adrs/**` is legacy/planning ADR space.

Do not place new Phase-0 governance docs in `docs/phase-0/**`.
Do not place new authoritative ADRs in `docs/architecture/adrs/**`.

## ADR policy

- All new authoritative ADRs must be created under `docs/decisions/`.
- If a legacy ADR in `docs/architecture/adrs/**` is still referenced by scripts, keep it until a dedicated migration task moves references safely.

## Naming guidance

- Use uppercase `PHASE0` directory where already canonical (`docs/PHASE0/**`).
- Keep file names descriptive and stable; avoid temporary suffixes like `_v2`, `_final`.
- Use repo-relative paths when referencing documents in tasks/meta/gates.
