# Execution Log: REM-2026-04-29_baseline_postgis_regen

## 2026-04-29T01:30:00Z - Investigation Started
- CI failure `DB verify_invariants.sh` detected on PR #197 (Wave 8 task pack repair)
- Error: `Baseline drift detected` from `check_baseline_drift.sh`
- Confirmed failure is pre-existing (affects all PRs to main, not just #197)

## 2026-04-29T01:35:00Z - Root Cause Identified
- PR #196 (commit `20a4d30a`) added `postgresql-18-postgis-3` to CI
- Migration `0125_postgis_extension.sql` now loads PostGIS into `public` schema
- Baseline was last regenerated at `a4db318a` without PostGIS, creating schema divergence

## 2026-04-29T02:00:00Z - Baseline Regeneration
- Started `postgis/postgis:18-3.6` Docker container (PG 18.3 + PostGIS 3.6.3)
- Applied all 172 migrations via `scripts/db/migrate.sh` — all applied successfully
- Generated new baseline via `pg_dump --schema-only --no-owner --no-privileges --no-comments --schema=public`
- Replaced both `schema/baseline.sql` and `schema/baselines/current/0001_baseline.sql`

## 2026-04-29T02:05:00Z - Verification
- Ran `check_baseline_drift.sh` against PostGIS-enabled container: PASS
- Confirmed both baseline files are identical
- Net diff: -118 lines removed, +42 lines added (function removals, constraint renames, trigger reordering)

## 2026-04-29T02:10:00Z - PR Created
- Branch: `devin/1777429592-baseline-postgis-regen`
- PR #198 opened against main
