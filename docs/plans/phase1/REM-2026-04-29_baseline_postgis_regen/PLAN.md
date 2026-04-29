# REM-2026-04-29: Baseline Regeneration for PostGIS-Enabled CI

failure_signature: DB.BASELINE_DRIFT
origin_gate_id: pre_ci.db_verify_invariants
repro_command: DATABASE_URL=postgresql://symphony:symphony@localhost:55432/symphony bash scripts/db/check_baseline_drift.sh
verification_commands_run: check_baseline_drift.sh PASS (PostGIS-enabled PG18 container)
final_status: PASS

## Root Cause

PR #196 added `postgresql-18-postgis-3` to CI apt installation, enabling
migration `0125_postgis_extension.sql` to fully load PostGIS into `public`
schema. The baseline files (`schema/baseline.sql`,
`schema/baselines/current/0001_baseline.sql`) were last regenerated without
PostGIS loaded, so `check_baseline_drift.sh` detected schema divergence on
every subsequent PR.

## Fix

Regenerated both baseline files from a fresh PostgreSQL 18.3 + PostGIS 3.6.3
instance (`postgis/postgis:18-3.6` Docker image) with all 172 migrations
applied through `0172_fix_trigger_authority_and_ordering.sql`.

## Verification

```bash
# Start PostGIS-enabled PG18
docker run -d --name symphony-postgres \
  -e POSTGRES_USER=symphony -e POSTGRES_PASSWORD=symphony \
  -e POSTGRES_DB=symphony -p 55432:5432 postgis/postgis:18-3.6

# Apply all migrations
DATABASE_URL=postgresql://symphony:symphony@localhost:55432/symphony \
  bash scripts/db/migrate.sh

# Verify baseline drift check passes
DATABASE_URL=postgresql://symphony:symphony@localhost:55432/symphony \
  bash scripts/db/check_baseline_drift.sh
# Result: PASS
```

## Files Changed

- `schema/baseline.sql` — regenerated
- `schema/baselines/current/0001_baseline.sql` — regenerated (identical to above)
