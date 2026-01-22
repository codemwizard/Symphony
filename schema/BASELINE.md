# Symphony Schema Baseline Contract

**Status:** Authoritative  
**Last Updated:** 2026-01-22

## Overview

Symphony uses a **baseline + migration** approach for database schema management:

- `schema/baseline.sql` — Canonical snapshot for fresh DB creation
- `schema/migrations/` — Forward-only migrations for production-safe evolution
- `public.schema_migrations` — Ledger tracking applied migrations with checksums

## Contract (Environment-Specific)

### Development / CI (pre-staging)

Reset freely to avoid red tape, not to avoid correctness:

```bash
# Full reset + apply
npm run db:reset

# Or explicitly
scripts/db/reset_and_migrate.sh
```

This gives deterministic rebuilds and keeps the migration path continuously exercised.

### Staging / Production (data-preserving)

Resetting is **not allowed**. The only supported evolution path is:

```bash
scripts/db/migrate.sh
```

- Apply forward-only migrations (no destructive reset)
- Verify invariants + proofs
- Preserve all data

## File Purposes

| File | Purpose |
|------|---------|
| `schema/baseline.sql` | Snapshot for fresh DB (mirrors result of all migrations) |
| `schema/migrations/*.sql` | Forward-only evolution (authoritative for prod) |
| `scripts/db/migrate.sh` | Apply new migrations with ledger tracking |
| `scripts/db/reset_and_migrate.sh` | Reset + migrate (dev/CI only) |
| `scripts/db/reset_db.sh` | Reset + apply baseline (dev helper) |
| `scripts/db/apply_baseline.sh` | Apply baseline only (fresh DB) |

## Migration Immutability

Once a migration is merged and applied:

- The file is **immutable**
- Any edit triggers checksum mismatch and fails CI
- Fixes require a new migration file

## Legacy Reference

`_archive/schema/v1/` contains the legacy schema files for reference only.  
These are **never applied** by CI or scripts.
