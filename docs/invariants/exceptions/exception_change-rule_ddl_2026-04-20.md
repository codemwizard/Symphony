---
exception_id: EXC-20260420-EXEC-TRUTH-REM01
inv_scope: change-rule
expiry: 2026-10-20
follow_up_ticket: TSK-P2-PREAUTH-003-REM-04
reason: Forward migration 0131 adds nullable determinism columns to execution_records (expand phase of INV-EXEC-TRUTH-001). Full invariant linkage (INVARIANTS_MANIFEST.yml + INVARIANTS_IMPLEMENTED.md) is deferred to REM-04 per its stop_condition that REM-05 evidence must land first. Exception covers the expand-then-contract DAG; invariant block will be registered in the same PR.
author: db_foundation
created_at: 2026-04-20
---

# Exception: ddl structural change without invariants linkage (REM-01 expand phase)

## Reason

Migration `0131_execution_records_determinism_columns.sql` is the expand half of the expand/contract pair that implements INV-EXEC-TRUTH-001 (execution-truth anchor). The invariant cannot be registered in `docs/invariants/INVARIANTS_MANIFEST.yml` as `status: implemented` until:

1. REM-02 contract migration (0132) tightens the four columns + `interpretation_version_id` to `NOT NULL` and adds the determinism UNIQUE constraint.
2. REM-03A (0133) and REM-03B (0134) install the append-only (GF056) and temporal-binding (GF058) triggers.
3. REM-05 verifier emits self-certifying evidence including the invariant's enforcement surface SHAs.

Per REM-04's `stop_conditions`, flipping the invariant status to `implemented` before REM-05 evidence exists is an explicit anti-pattern (bug-fix constraint B4 carried from PR #187 merge cycle). This exception is the mechanism used elsewhere in the repo (see `exception_change-rule_ddl_2026-03-05_7.md`, `exception_change-rule_ddl_2026-03-12.md`) to allow the migration commit to land while the invariant linkage is authored in a later commit within the same PR.

## Evidence

structural_change: true
confidence_hint: 1.0
primary_reason: ddl
reason_types: ddl, migration_file_added_or_deleted

Matched files:
- schema/migrations/0131_execution_records_determinism_columns.sql

## Mitigation

- No edit to the applied migration 0118 (forward-only preserved).
- Migration 0131 contains only `ADD COLUMN IF NOT EXISTS` statements (idempotent, no destructive DDL).
- No `BEGIN/COMMIT` at file top-level (B5 constraint).
- Invariant linkage will be registered via `TSK-P2-PREAUTH-003-REM-04` in this same PR once REM-05 evidence lands.
- Proof-carrying verifier `scripts/db/verify_execution_records_determinism_columns.sh` inspects `information_schema.columns` and emits `evidence/phase2/tsk_p2_preauth_003_rem_01.json`.
- Negative-test harness `scripts/db/tests/test_execution_records_determinism_columns_negative.sh` demonstrates fail-closed behaviour on column removal and MIGRATION_HEAD drift.

## Closure Criteria

- `docs/invariants/INVARIANTS_MANIFEST.yml` contains an `INV-EXEC-TRUTH-001` block with `status: implemented`.
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` contains the matching row.
- `evidence/phase2/tsk_p2_preauth_003_rem_04.json` present with `manifest_present=true`, `enforcement_path_resolves=true`, `verification_evidence_fresh=true`.
