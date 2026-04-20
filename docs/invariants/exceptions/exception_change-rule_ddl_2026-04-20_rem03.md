---
exception_id: EXC-20260420-EXEC-TRUTH-REM03
inv_scope: change-rule
expiry: 2026-10-20
follow_up_ticket: TSK-P2-PREAUTH-003-REM-04
reason: Forward migration 0133 installs two BEFORE triggers on execution_records (append-only GF056 + temporal-binding GF058) — enforcement surfaces #3 and #4 of INV-EXEC-TRUTH-001. Full invariant linkage (INVARIANTS_MANIFEST.yml + INVARIANTS_IMPLEMENTED.md) is deferred to REM-04 per its stop_condition that REM-05 evidence must land first.
author: db_foundation
created_at: 2026-04-20
---

# Exception: ddl structural change without invariants linkage (REM-03 triggers)

## Reason

Migration `0133_execution_records_triggers.sql` installs two SECURITY DEFINER trigger functions with hardened `search_path` and attaches them as BEFORE triggers on `public.execution_records`:

1. `execution_records_append_only_trigger` (BEFORE UPDATE OR DELETE) — raises `SQLSTATE GF056`.
2. `execution_records_temporal_binding_trigger` (BEFORE INSERT) — raises `SQLSTATE GF058` when the supplied `interpretation_version_id` does not match `resolve_interpretation_pack(NEW.project_id, NEW.execution_timestamp)`.

These are enforcement surfaces #3 and #4 of INV-EXEC-TRUTH-001. The invariant cannot be registered as `status: implemented` until REM-05 emits self-certifying evidence covering all four surfaces (per bug-fix constraint B4 carried from PR #187 merge cycle — flipping the invariant to `implemented` before REM-05 evidence is an explicit anti-pattern).

## Evidence

structural_change: true
confidence_hint: 1.0
primary_reason: ddl
reason_types: ddl, migration_file_added_or_deleted

Matched files:
- schema/migrations/0133_execution_records_triggers.sql

## Mitigation

- No edit to 0118/0131/0132 (forward-only preserved).
- Both functions are SECURITY DEFINER with `SET search_path = pg_catalog, public` (AGENTS.md hardening).
- EXECUTE revoked from PUBLIC on both functions.
- No `BEGIN/COMMIT` at file top-level (B5 constraint).
- Proof-carrying verifier `scripts/db/verify_execution_records_triggers.sh` inspects `pg_trigger.tgtype`, `pg_proc.prosecdef`, `pg_proc.proconfig`, EXECUTE grants, and drives both negative-test helpers.
- Negative-test harnesses validate `GF056` + `GF058` SQLSTATEs (append-only test degrades to catalog-level verification when no seeded row exists; temporal-binding test uses synthetic UUIDs so the IS DISTINCT FROM comparison fires before any FK check).
- Invariant linkage will be registered via `TSK-P2-PREAUTH-003-REM-04` in this same PR once REM-05 evidence lands.

## Closure Criteria

- `docs/invariants/INVARIANTS_MANIFEST.yml` contains an `INV-EXEC-TRUTH-001` block with `status: implemented` referencing both trigger names.
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` contains the matching row.
- `evidence/phase2/tsk_p2_preauth_003_rem_04.json` present with `manifest_present=true`, `enforcement_path_resolves=true`, `verification_evidence_fresh=true`.
