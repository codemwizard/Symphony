---
exception_id: EXC-20260420-EXEC-TRUTH-REM02
inv_scope: change-rule
expiry: 2026-10-20
follow_up_ticket: TSK-P2-PREAUTH-003-REM-04
reason: Forward migration 0132 tightens five execution_records columns to NOT NULL and installs the determinism UNIQUE constraint (contract phase of INV-EXEC-TRUTH-001). Invariant linkage (INVARIANTS_MANIFEST.yml + INVARIANTS_IMPLEMENTED.md) is deferred to REM-04, which must run after REM-05 evidence lands (bug-fix constraint B4).
author: db_foundation
created_at: 2026-04-20
---

# Exception: ddl structural change without invariants linkage (REM-02 contract phase)

## Reason

Migration `0132_execution_records_determinism_constraints.sql` is the contract half of the expand/contract pair implementing INV-EXEC-TRUTH-001. It performs five `ALTER COLUMN ... SET NOT NULL` and adds `execution_records_determinism_unique UNIQUE (tenant_id, input_hash, interpretation_version_id, runtime_version)` (tenant-scoped to preserve multi-tenant audit isolation). Per REM-04's stop_conditions, the invariant status may not flip to `implemented` until REM-05 evidence exists (B4 constraint carried from PR #187 merge cycle). This exception covers the gap between structural change (this commit) and invariant registration (REM-04, later in the same PR).

## Evidence

structural_change: true
confidence_hint: 1.0
primary_reason: ddl
reason_types: ddl, migration_file_added_or_deleted

Matched files:
- schema/migrations/0132_execution_records_determinism_constraints.sql

## Mitigation

- No edit to applied migrations 0118 or 0131 (forward-only preserved).
- GF059 backfill precondition INLINED into 0132 (B6 — no `\i`; migrate.sh checksums only the migration file).
- No top-level BEGIN/COMMIT in 0132 (B5).
- Negative-test harness proves SQLSTATE 23502 (NOT NULL) on NULL input_hash and NULL runtime_version, and catalog-level UNIQUE presence.
- Proof-carrying verifier emits `evidence/phase2/tsk_p2_preauth_003_rem_02.json` with observed_paths, observed_hashes, and command_outputs.

## Closure Criteria

- `docs/invariants/INVARIANTS_MANIFEST.yml` contains an `INV-EXEC-TRUTH-001` block with `status: implemented`.
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` contains the matching row.
- `evidence/phase2/tsk_p2_preauth_003_rem_04.json` present with `manifest_present=true`, `enforcement_path_resolves=true`, `verification_evidence_fresh=true`.
