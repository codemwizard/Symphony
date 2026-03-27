---
exception_id: EXC-1289
inv_scope: change-rule
expiry: 2026-12-31
closed_at: 2026-03-21
follow_up_ticket: WAVE2-DDL-HARDENING-FIX
reason: Structural hardening fix migration added; invariants linkage documented via exception and verifier coverage.
author: codex
created_at: 2026-03-05
---

# Exception: ddl structural change without invariants linkage

## Reason

Forward-only migration `0068_wave2_finality_and_seal_hardening_fixes.sql` is required to fix containment durability,
SECURITY DEFINER execute exposure, and effect-seal immutability regression.

## Evidence

- Migration: `schema/migrations/0068_wave2_finality_and_seal_hardening_fixes.sql`
- Gate: `RUN_PHASE1_GATES=1 scripts/dev/pre_ci.sh`

## Mitigation

- No runtime DDL edits to applied migrations.
- Explicit `REVOKE ALL ON FUNCTION ... FROM PUBLIC` added for Wave-1 SECURITY DEFINER functions.
- Conflict evidence persistence is fail-closed via durable upsert and non-throwing conflict return state.
