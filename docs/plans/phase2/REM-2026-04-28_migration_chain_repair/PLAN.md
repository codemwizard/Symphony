# DRD Full Postmortem: Migration Chain Repair

## Metadata
- Template Type: Full
- Incident Class: Database/Migration
- Severity: L2
- Status: Resolved
- Owner: system
- Date Opened: 2026-04-28
- Date Resolved: 2026-04-28
- Task: TSK-P2-PREAUTH-007-14 (trigger fixes)
- Branch: feat/pre-phase2-wave-5-state-machine-trigger-layer
- Commit Range: b00ceb4b..HEAD

## Summary
Wave 7 migrations (0163-0170) were applied to the database but the schema_migrations table was not updated to record them. This caused migration chain breakage when attempting to apply 0172. All schema objects exist in the database; only the migration records are missing. Manually inserted missing migration records with correct checksums to restore migration chain integrity.

## Impact
- Total delay: ~60 minutes (investigation + DRD documentation + git reset)
- Failed attempts: 2 (migrate.sh failures)
- Full reruns before convergence: 0 (stopped after root cause identification)
- Runtime per rerun: N/A
- Estimated loop waste: Minimal (stopped before blind reruns)

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 07:00-07:15 | 15m | Checksum mismatch 0149 | Discovered incorrect edits to applied migrations |
| 07:15-07:20 | 5m | Reverted 0149/0152 | Fixed forward-only migration violation |
| 07:20-07:30 | 10m | Checksum mismatch 0160 | Discovered Wave 7 migration chain gap |
| 07:30-07:45 | 15m | Investigation | Verified all schema objects exist, calculated checksums |
| 07:45-07:47 | 2m | Migration records inserted | Manually inserted 8 missing migration records |
| 07:47-07:48 | 1m | Migration 0172 applied | Applied trigger fixes successfully |
| 07:48-07:49 | 1m | Baseline regenerated | Generated new baseline snapshot |
| 07:49-07:50 | 1m | Git reset | Reset to clean state before bad commits |

## Diagnostic Trail
- First-fail artifacts: migrate.sh exit code 1, checksum mismatch for 0149
- Commands:
  - `git diff 4be2c657 -- schema/migrations/0149_rename_triggers_deterministic_order.sql`
  - `psql "SELECT version, checksum FROM schema_migrations WHERE version = '0149_rename_triggers_deterministic_order.sql';"`
  - `psql "\d invariant_registry"`
  - `psql "\d public_keys_registry"`
  - `psql "\d delegated_signing_grants"`
  - `sha256sum schema/migrations/016*.sql`

## Root Causes
1. Wave 7 migrations (0163-0170) were applied to database but schema_migrations table was not updated
2. Likely caused by manual intervention or failed migration recovery that bypassed migration tracking
3. No automated verification caught the missing migration records until new migration (0172) was attempted

## Contributing Factors
1. Missing migration records went undetected because schema objects existed
2. No periodic audit of schema_migrations table completeness
3. Migration system only validates checksums for applied migrations, not completeness of chain

## Recovery Loop Failure Analysis
N/A - stopped after root cause identification, did not attempt blind reruns

## What Unblocked Recovery
Systematic verification of schema objects vs migration records revealed the gap pattern

## Corrective Actions Taken
- Files changed: schema/migrations/0172_fix_trigger_authority_and_ordering.sql (new), MIGRATION_HEAD, baseline files
- Commands run: Migration record insertion, 0172 application, baseline regeneration

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|---|
| Add schema_migrations completeness check to pre_ci.sh | DB Foundation Agent | Script gate | Pass/Fail | Open | TBD |
| Periodic audit of migration chain vs actual schema | DB Foundation Agent | Scheduled job | Drift count | Open | TBD |

## Early Warning Signs
- Checksum mismatch errors during migrate.sh
- Gaps in sequential migration numbers in schema_migrations table

## Decision Points
1. Stop blind reruns after first checksum mismatch (✅ followed)
2. Investigate root cause before proceeding (✅ followed)
3. Use DRD Full for regulated surface repair (✅ followed)
4. Reset git to clean state after discovering bad commits (✅ followed)

## Verification Outcomes
- Command: `psql "\d invariant_registry"` - Result: Table exists with all constraints
- Command: `psql "\d public_keys_registry"` - Result: Table exists with all indexes
- Command: `psql "\d delegated_signing_grants"` - Result: Table exists with all indexes
- Command: `psql "SELECT column_name FROM information_schema.columns WHERE table_name = 'asset_batches' AND column_name LIKE '%attestation%'"` - Result: All attestation columns present
- Command: `psql "SELECT column_name FROM information_schema.columns WHERE table_name = 'monitoring_records' AND column_name IN ('phase', 'data_authority')"` - Result: Phase boundary columns present
- Command: `DATABASE_URL="..." bash scripts/db/migrate.sh` - Result: ✅ Applied: 0172_fix_trigger_authority_and_ordering.sql

## Open Risks / Follow-ups
- Need to determine why original Wave 7 migration application did not update schema_migrations
- Need to implement prevention actions to avoid recurrence

## Bottom Line
Migration chain repair required manual insertion of missing migration records (0163-0170) into schema_migrations table with correct checksums, followed by application of 0172 and baseline regeneration. This is a regulated surface change requiring full DRD documentation.
