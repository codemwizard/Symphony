# Style Guide (YAML + Tasks)

## YAML Conventions (Repo‑Wide)
- Use **lower_snake_case** for keys in repo‑authored YAML (tasks, governance docs).
- Avoid duplicate keys (duplicates are treated as errors).
- Use spaces, not tabs.
- Prefer lists for multi‑valued fields (no comma‑joined strings).
- Paths must be repo‑relative and use forward slashes.

## Task Meta (`tasks/**/meta.yml`)
Canonical schema is defined in `docs/tasks/TASK_META_SCHEMA.md`.

Required rules:
- Keys must be **lower_snake_case**.
- Required keys must exist (see schema).
- List fields must be YAML arrays, not strings.
- No legacy key variants (e.g., `Depends On`, `Evidence Artifact(s)`).
- For **in_progress|completed** tasks, `implementation_plan` and `implementation_log` must be present and point to existing files.
- EXEC_LOG must reference the PLAN (either exact path or `Plan: PLAN.md`).
- PLAN.md and EXEC_LOG.md must mention the `task_id`.

Reference:
- Template: `tasks/_template/meta.yml`

## Document Placement
- Canonical document placement rules are defined in `docs/operations/DOCUMENT_PLACEMENT.md`.
- Use `docs/PHASE0/**` for new Phase-0 governance/contracts docs.
- Use `docs/decisions/**` for new authoritative ADRs.
- Treat `docs/phase-0/**` and `docs/architecture/adrs/**` as legacy unless a migration task explicitly requires edits there.
