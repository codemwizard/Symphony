---
exception_id: EXC-577
inv_scope: change-rule
expiry: 2026-12-31
follow_up_ticket: NONE
reason: "GF-W1-SCH-002A: structural changes detected from regenerating the schema baseline to include migrations 0097 and 0098."
author: architect
created_at: 2026-03-29
---

# Exception: migration_file_added_or_deleted structural change without invariants linkage

This exception was auto-generated because a structural change was detected,
but invariants linkage (manifest/docs with INV-###) was not included in the same commit.

## Reason

The schema baseline snapshot was regenerated to include migrations 0097 (projects) and 0098 (methodology_versions). This triggers the structural change detector.


## Evidence

structural_change: True
confidence_hint: 0.7
primary_reason: migration_file_added_or_deleted
reason_types: migration_file_added_or_deleted

Matched files:
- schema/baselines/2026-03-29/baseline.normalized.sql

Top matches:
- ddl | schema/baselines/2026-03-29/0001_baseline.sql | +: CREATE TABLE public.projects
- ddl | schema/baselines/2026-03-29/0001_baseline.sql | +: CREATE TABLE public.methodology_versions

## Mitigation

This is a canonical schema baseline update matching verified migrations 0097 and 0098.
