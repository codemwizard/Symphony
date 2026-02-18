# CI Pipeline

## Overview

CI enforces invariants via the SQL gate script. All PRs must pass before merge.

## Pipeline Steps

1. **Checkout** - Clone repository
2. **Start Postgres** - Docker service with Postgres 18
3. **Run Migrations** - `scripts/db/migrate.sh`
4. **Verify Invariants** - `scripts/db/verify_invariants.sh`
5. **Lint Migrations** - `scripts/db/lint_migrations.sh`

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | Postgres connection string |
| `CI` | Auto | Set by CI runner |

## Failure Modes

- **Invariant Violation**: Hard fail, PR blocked
- **Migration Checksum Mismatch**: Hard fail, immutability preserved
- **Lint Error**: Hard fail, schema hygiene enforced
