# ADR-0011: Day-Zero Rebaseline for Tenant/Member Schema

## Status
Accepted (Phase-0)

## Context
Phase-0 introduced tenant/client/member rails after initial schema creation. That required `ALTER TABLE` on hot tables (ingress and outbox) and governance exceptions in the lock-risk lint. In a greenfield, day-zero design, these columns and constraints would have been present from the start, avoiding lock-risk DDL on hot tables.

We are still in development (no production data). This allows a controlled **rebaseline** to align the schema with the intended day-zero model while preserving forward-only migration history for audit.

## Decision
Adopt a **Day-Zero Rebaseline** strategy for new environments:

1) Create a baseline snapshot of the current schema that already includes tenant/client/member rails.
2) Use a migration strategy flag to **apply the baseline** for fresh environments, instead of replaying all historical migrations.
3) Preserve all existing migrations (forward-only). Do not edit or delete applied migrations.
4) Maintain lock-risk linting with explicit, auditable exceptions for historical migrations (governance, not weakening).

## Implementation Details
- Baseline snapshot file stored at:
  - `schema/baselines/<YYYY-MM-DD>/0001_baseline.sql`
  - `schema/baselines/current/0001_baseline.sql` (latest)
  - `schema/baseline.sql` (drift check anchor)
- Baseline cutoff file stored at:
  - `schema/baselines/<YYYY-MM-DD>/baseline.cutoff`
  - `schema/baselines/current/baseline.cutoff`
- Snapshot generator:
  - `scripts/db/generate_baseline_snapshot.sh`
- Canonicalization helper:
  - `scripts/db/canonicalize_schema_dump.sh`
- Migration runner supports:
  - `SCHEMA_MIGRATION_STRATEGY=migrations|baseline|baseline_then_migrations`
  - `SCHEMA_BASELINE_PATH` override
  - `SCHEMA_BASELINE_CUTOFF` override

## Consequences
- New environments can initialize from the baseline without lock-risk DDL on hot tables.
- Existing environments continue to apply migrations (no data rewrite).
- Lock-risk lint remains strict; allowlist remains for legacy migrations.
- Baseline drift remains governed and auditable.

## Risks
- Misuse of baseline on non-empty DBs could lead to conflicts.
  - Mitigation: migrate.sh fails if baseline is applied to non-empty schema_migrations unless explicitly allowed.

## References
- `docs/decisions/Rebaseline-Decision.md`
- `docs/decisions/ADR-0010-baseline-policy.md`
