# Archived Schema (Reference Only)

> [!CAUTION]
> **DO NOT APPLY** — These files are reference-only.

This directory contains the legacy `schema/v1/` migration chain, preserved for:

- Historical reference
- Debugging legacy behavior
- Understanding schema evolution

## Current Schema Location

The authoritative schema is now:

- **Snapshot:** `schema/baseline.sql`
- **Migrations:** `schema/migrations/`

## Guardrails

CI will fail if:

- Any workflow or script references `schema/v1`
- Any script attempts to apply files from `_archive/schema/`

See `scripts/ci/archive_guardrail.sh` for enforcement.
