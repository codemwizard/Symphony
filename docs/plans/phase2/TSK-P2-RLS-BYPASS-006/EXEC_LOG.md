# TSK-P2-RLS-BYPASS-006 EXEC_LOG
Plan: docs/plans/phase2/TSK-P2-RLS-BYPASS-006/PLAN.md


Append-only. Never delete or rewrite existing entries.

failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-006.BASELINE_REFRESH_FAIL
origin_task_id: TSK-P2-RLS-BYPASS-006
repro_command: bash scripts/db/verify_rls_bypass_baseline_refresh.sh

| # | Timestamp UTC | Action | Result | Notes |
|---|---|---|---|---|
| 1 | 2026-05-08T04:39:40Z | Confirm 004+005 evidence | PASS | evidence/phase2/rls_bypass_policy_migration.json: PASS; evidence/phase2/rls_no_app_bypass_policies.json: PASS |
| 2 | 2026-05-08T04:44:01Z | Apply migration 0204 | PASS | Migration applied via scripts/db/migrate.sh with DATABASE_URL=postgresql://symphony_admin:symphony_pass@localhost:55432/symphony. Migration head now 0204. |
| 3 | 2026-05-08T04:45:37Z | Regenerate baseline | PASS | scripts/db/generate_baseline_snapshot.sh produced schema/baselines/2026-05-08/. normalized_schema_sha256=453190457697c25a732cd3c1078f4355e9a60bf02f3e7579eaaa7595d6c917a9. pg_dump_version=pg_dump (PostgreSQL) 18.3. dump_source=container:symphony-postgres. |
| 4 | 2026-05-08T04:45:52Z | Verify clean baseline | PASS | grep -c bypass_rls returns 0 for baseline.sql, current/0001_baseline.sql, and 2026-05-08/0001_baseline.sql. |
| 5 | 2026-05-08T05:02:33Z | Copy normalized baseline | PASS | baseline.normalized.sql copied to schema/baselines/current/ for INV-045 compliance. |
| 6 | 2026-05-08T05:02:52Z | Update ADR-0010 | PASS | Added baseline update log entry per ADR-0010 governance rule 2: "If schema/baseline.sql changes, this ADR must be updated." |
| 7 | 2026-05-08T05:03:12Z | check_baseline_drift.sh | PASS | Baseline drift check passed. Evidence: evidence/phase0/baseline_drift.json |
| 8 | 2026-05-08T05:03:30Z | Run verifier | PASS | scripts/db/verify_rls_bypass_baseline_refresh.sh emitted evidence/phase2/rls_bypass_baseline_refresh.json with status=PASS |

## Baseline Refresh Explanation

Migration 0204_remove_app_bypass_rls_from_policies.sql dropped and recreated 3 RLS
policies (tenant_registry, programme_registry, programme_policy_binding) without the
`app.bypass_rls` escape hatch. The canonical baseline must be regenerated to reflect
these terminal policy definitions. Previous baseline (cutoff 0203) contained
`bypass_rls` in policy USING clauses. New baseline (cutoff 0204) has 0 bypass_rls
references in policy definitions.

## Governance Compliance

- ADR-0010 updated with baseline log entry (rule 2) ✅
- Migration 0204 in same diff (rule 1) ✅
- Container pg_dump used (dump_source=container:symphony-postgres) ✅
- check_baseline_drift.sh passed (INV-004/INV-045) ✅
- baseline.normalized.sql in current/ ✅

verification_commands_run: bash scripts/db/verify_rls_bypass_baseline_refresh.sh; bash scripts/db/check_baseline_drift.sh
final_status: PASS

## Final Summary

Task TSK-P2-RLS-BYPASS-006 is completed and verified. Evidence generated and validated in evidence/phase2/.

