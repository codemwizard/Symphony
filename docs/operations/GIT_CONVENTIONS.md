# Git Conventions (Canonical)

This is the only normative source for branch and commit naming.

## Lifecycle Key Rules

- Valid lifecycle keys: `0`, `1`, `2`, `3`, `4`
- Invalid lifecycle keys: dotted values (`0.1`, `0.2`, `0.5`) and named values (`Hardening`)
- Wave identifiers are separate from lifecycle phase keys.

## Branch Format

Task-linked branch format:
- `<category>/<lifecycle_key>-<kebab-name>`

Wave-linked branch format:
- `<category>/wave-<wave_number>-<kebab-name>`

Examples (valid):
- `fix/1-agent-conformance-two-stage`
- `security/1-dependency-audit-gate`
- `ops/wave-2-governance-closeout`

Invalid examples (forbidden, explanatory only):
- `security/0.2-emergency-code-fixes`
- `fix/Hardening-runtime`

## Commit Header Format

Task-linked:
- `Phase <lifecycle_key>: <short description>`

Wave-linked:
- `Wave <wave_key>: <short description>`

Housekeeping-only (non task-linked):
- `<type>(<scope>): <short description>`
- Include task reference in footer when related.
