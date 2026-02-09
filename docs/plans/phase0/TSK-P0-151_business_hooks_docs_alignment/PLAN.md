# Implementation Plan (TSK-P0-151)

failure_signature: P0.BIZ.HOOKS.DOCS_DRIFT
origin_task_id: TSK-P0-151
repro_command: bash scripts/audit/run_invariants_fast_checks.sh

## Goal
Align “auditably billable + stitchable” Phase-0 documentation with the repo’s actual implementation and the delta-tightening decisions.

## Scope
In scope:
- Place the Phase-0 business hooks spec under `docs/PHASE0/` per repo convention.
- Ensure documentation matches the actual schema/verifier behavior:
  - new-row enforcement via NOT VALID CHECK constraints
  - correlation set-if-null triggers
  - external proofs payer attribution (direct billability, new rows)
  - explicit deferment of backfill/VALIDATE to Phase-1+

Out of scope:
- Changing invariants contract semantics
- Backfill/validation operations

## Acceptance
- `docs/PHASE0/BUSINESS_FOUNDATION_HOOKS.md` exists and matches implemented semantics.
- Any legacy/root-level doc is either removed or replaced by a short pointer.

## Verification
verification_commands_run:
- "bash scripts/audit/run_invariants_fast_checks.sh"

final_status: OPEN

