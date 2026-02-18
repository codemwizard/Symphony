# Implementation Plan (TSK-P0-144)

task_id: TSK-P0-144
title: Normalize INV-031 evidence emission (deterministic PASS/FAIL)
invariant_id: INV-031
gate_id: INT-G22

## Goal
Ensure `scripts/db/tests/test_outbox_pending_indexes.sh` always emits
`evidence/phase0/outbox_pending_indexes.json` on both PASS and FAIL with a stable schema:
- `status` in {PASS, FAIL, SKIPPED}
- `timestamp_utc`, `git_sha`, `schema_fingerprint`
- `checked_objects` (explicit list of what was evaluated)

## Scope
- Update verifier script output schema and determinism.
- Eliminate duplicate/competing evidence writers for the same evidence file where they differ semantically.

## Verification
- `bash scripts/db/tests/test_outbox_pending_indexes.sh` (with DATABASE_URL set)
- `bash scripts/db/verify_invariants.sh` (with DATABASE_URL set)

## Acceptance
- Evidence JSON is always written and has canonical fields.
- FAIL exits non-zero and writes `status: FAIL` (not "missing evidence").

