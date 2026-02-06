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

Reference:
- Template: `tasks/_template/meta.yml`
