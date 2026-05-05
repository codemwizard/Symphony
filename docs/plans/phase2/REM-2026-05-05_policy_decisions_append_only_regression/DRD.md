# DRD: Policy Decisions Append-Only Regression

## Metadata
- Template Type: Full
- Incident Class: Schema Integrity Violation
- Severity: L2
- Status: Resolved
- Owner: DB_FOUNDATION_AGENT
- Date Opened: 2026-05-05
- Date Resolved: 2026-05-05
- Task: TSK-P2-W8-DB-006-REM-01
- Branch: wave8-phase2-completion
- Commit Range: HEAD

## Summary
Migration change redefined append-only guard for policy_decisions table to only block DELETE operations, inadvertently re-enabling UPDATE mutations and breaking immutability guarantees for policy decision records.

## Impact
- Total delay: TBD minutes
- Failed attempts: 0 (proactive identification)
- Full reruns before convergence: N/A
- Runtime per rerun: N/A
- Estimated loop waste: N/A

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 2026-05-05T09:18Z | TBD | Code review finding | Migration change identified in lines 95-96 |

## Diagnostic Trail
- First-fail artifacts: Code review of migration file lines 95-96
- Commands: 
  - `grep -n -A 2 -B 2 "RAISE EXCEPTION.*GF060" schema/migrations/*.sql`
  - `grep -n "policy_decisions.*append-only" schema/migrations/*.sql`

## Root Causes
1. Migration author misunderstood append-only semantics for policy_decisions table
2. Changed trigger condition from blocking both UPDATE and DELETE to only blocking DELETE
3. Failed to verify that existing immutability contract required blocking both mutation types

## Contributing Factors
1. Insufficient testing of migration change against existing append-only contract
2. Missing review of policy_decisions table immutability requirements
3. No verification that trigger logic matched documented append-only semantics

## Recovery Loop Failure Analysis
N/A - Proactive identification before deployment prevents recovery loop

## What Unblocked Recovery
Proactive code review identified the regression before deployment

## Corrective Actions Taken
- Files changed: `schema/migrations/0203_converge_policy_decisions_schema.sql`
- Commands run: 
  - Edited trigger to `BEFORE UPDATE OR DELETE ON policy_decisions`
  - Applied migrations via `scripts/db/migrate.sh`
  - Regenerated baseline via `scripts/db/generate_baseline_snapshot.sh`

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|
| Migration code review checklist | DB_FOUNDATION_AGENT | Mandatory pre-merge | Open | 2026-05-05 |
| Append-only contract verification | DB_FOUNDATION_AGENT | Automated test | Open | 2026-05-05 |
| Schema immutability test suite | DB_FOUNDATION_AGENT | CI gate | Open | 2026-05-05 |

## Early Warning Signs
- Changes to trigger conditions without corresponding contract updates
- Migration changes that relax existing constraints

## Decision Points
- Whether to rollback migration or create corrective migration
- Whether to add automated tests for append-only enforcement

## Verification Outcomes
- Command: `check_baseline_drift.sh` and `verify_policy_decisions_schema.sh`
- Result: PASS

## Open Risks / Follow-ups
- Risk of policy decision records being modified if deployed
- Need to verify no other similar regressions exist

## Bottom Line
Critical schema integrity regression that must be fixed before deployment to maintain policy decision immutability guarantees.
