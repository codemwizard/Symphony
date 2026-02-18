# Implementation Plan (TSK-P0-140)

failure_signature: P0.PERF.DOCS_ALIGNMENT.IMPLEMENTED_INVARIANT_MISSING_FROM_IMPLEMENTED_MD
origin_task_id: TSK-P0-140
repro_command: python3 scripts/audit/check_docs_match_manifest.py

## Goal
Guarantee that `docs/invariants/INVARIANTS_IMPLEMENTED.md` remains an accurate, mechanically enforced view of invariants that are `status: implemented` in `docs/invariants/INVARIANTS_MANIFEST.yml`.

## Scope
In scope:
- Detect and fail on any invariant that is implemented in the manifest but missing from implemented.md.
- Close any current gaps (if present).

Out of scope:
- Changing invariant semantics or owners.

## Acceptance
- CI fails if an implemented manifest invariant is missing from implemented.md.
- `scripts/audit/run_invariants_fast_checks.sh` includes the check (directly or indirectly).

verification_commands_run:
- "PENDING: python3 scripts/audit/check_docs_match_manifest.py"

final_status: OPEN

