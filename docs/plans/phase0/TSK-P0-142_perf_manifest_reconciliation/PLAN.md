# Implementation Plan (TSK-P0-142)

failure_signature: P0.PERF.MANIFEST_RECONCILIATION.MISMATCH
origin_task_id: TSK-P0-142
repro_command: rg -n "INV-031" docs/invariants/INVARIANTS_MANIFEST.yml docs/invariants/INVARIANTS_IMPLEMENTED.md docs/invariants/INVARIANTS_ROADMAP.md

## Purpose
Formally reconcile existing Phase-0 performance invariants (notably `INV-031`) so that manifest, implemented list, and evidence expectations are semantically consistent.

## Scope
In scope:
- Documentation and invariant bookkeeping only.
- Cross-check:
  - `docs/invariants/INVARIANTS_MANIFEST.yml`
  - `docs/invariants/INVARIANTS_IMPLEMENTED.md`
  - `docs/invariants/INVARIANTS_ROADMAP.md`
- Update `INVARIANTS_IMPLEMENTED.md` entries if any enforced/implemented invariant is missing or mis-described.

Out of scope:
- No runtime code changes.
- No schema changes.
- No new invariants, gates, or evidence generation semantics.

## Deliverables
- `INVARIANTS_IMPLEMENTED.md` includes `INV-031` and any other already enforced Phase-0 performance invariants with concrete enforcement links.
- Phase-0 performance invariants are explicitly described as mechanical/enforced (not aspirational).

verification_commands_run:
- "PENDING: manual cross-check (manifest vs implemented vs roadmap)"

final_status: OPEN

