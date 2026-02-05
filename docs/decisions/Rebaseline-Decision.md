# Rebaseline Decision (Phase-0)

## Decision Summary
We will rebaseline the schema to a day-zero snapshot that already includes tenant/client/member rails. This aligns the schema with the intended greenfield design and removes the need to replay lock-risk migrations in new environments.

## Rationale
- **Development-only**: There is no production data to preserve.
- **Day-zero alignment**: Tenant/member attribution would have been in the schema from the start if designed initially; rebaseline restores that model.
- **Lock-risk reduction**: New environments avoid `ALTER TABLE` on hot tables by applying a baseline snapshot.
- **Governance preserved**: We keep lock-risk linting strict and maintain allowlisted exceptions for historical migrations.

## ADR Reference
- `docs/architecture/adrs/ADR-0011-rebaseline-dayzero-schema.md`

## Implementation Plan
1) Generate a baseline snapshot and canonicalized hash:
   - `scripts/db/generate_baseline_snapshot.sh`
2) Update migration runner to support baseline strategy:
   - `SCHEMA_MIGRATION_STRATEGY` + baseline path/cutoff
3) Keep baseline drift governance and evidence gates in place.

## Risks & Mitigations
- **Risk:** applying baseline on a non-empty DB.
  - **Mitigation:** migrate.sh fails unless explicitly overridden.
- **Risk:** historical migrations still contain lock-risk DDL.
  - **Mitigation:** keep strict lint + auditable allowlist for legacy files.

## Decision Date
- 2026-02-05
