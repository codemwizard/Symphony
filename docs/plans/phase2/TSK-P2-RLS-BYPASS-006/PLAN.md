# TSK-P2-RLS-BYPASS-006 PLAN — Regenerate baseline with provenance

Task: TSK-P2-RLS-BYPASS-006
Owner: DB_FOUNDATION
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-006.BASELINE_REFRESH_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Regenerate schema/baseline.sql and current baseline artifacts from the migrated
database (post-0204) using the repo-approved baseline generation script, and emit
evidence with provenance (pg_dump_version, pg_server_version, dump_source,
normalized_schema_sha256, migration_head).

## Pre-conditions

- TSK-P2-RLS-BYPASS-004 (migration 0204) applied and evidence PASS
- TSK-P2-RLS-BYPASS-005 (terminal policy verifier) evidence PASS
- Database accessible via DATABASE_URL with migration 0204 applied

## Implementation Steps

1. Confirm 004 and 005 evidence pass
2. Apply migration 0204 to live database
3. Regenerate baseline via scripts/db/generate_baseline_snapshot.sh
4. Create verifier scripts/db/verify_rls_bypass_baseline_refresh.sh
5. Emit evidence/phase2/rls_bypass_baseline_refresh.json

## Verification

```bash
bash scripts/db/verify_rls_bypass_baseline_refresh.sh
```
