# Task Meta Schema (Canonical)

This schema is **normative** for all `tasks/**/meta.yml` files.

## Required Keys
- `phase` (string, e.g. "0")
- `task_id` (string, e.g. "TSK-P0-056")
- `title` (string)
- `owner_role` (string)
- `status` (string: planned | in_progress | completed)
- `implementation_plan` (string; required when status is in_progress|completed)
- `implementation_log` (string; required when status is in_progress|completed)

## List Keys (arrays only)
- `depends_on`
- `touches`
- `invariants`
- `work`
- `acceptance_criteria`
- `verification`
- `evidence`
- `failure_modes`
- `must_read`

## Conventions
- Keys must be **lower_snake_case**.
- Paths must be **repo‑relative**.
- Evidence paths must be **gate‑scoped**, not task‑scoped.
- `implementation_plan` and `implementation_log` must point to existing files for in‑progress or completed tasks.

## Reference Template
See `tasks/_template/meta.yml` for canonical structure.
