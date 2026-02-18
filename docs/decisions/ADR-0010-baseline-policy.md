# ADR-0010: Baseline Governance Policy

## Status
Accepted (Phase-0)

## Context
Schema baseline snapshots are used for drift detection and auditability. Without governance, baselines can be updated without a corresponding migration or rationale, which erodes integrity.

## Decision
Baseline updates are **governed** and **fail-closed**:

1) If `schema/baseline.sql` changes, **at least one migration** must change in the same diff.
2) If `schema/baseline.sql` changes, this ADR **must be updated** with a human-readable note.
3) Baseline generation should use a deterministic, container-based `pg_dump` when possible.

### Governance Note (2026-02-17)
This ADR remains the authoritative governance reference for baseline change checks when integrating branch histories.

## Consequences
- Baseline updates are explicit, auditable, and tied to migrations.
- CI/local checks will fail if governance requirements are not met.

## Baseline Update Log
- 2026-02-05: Baseline regenerated after tenant/client/member migrations (0014–0019).
- 2026-02-07: Baseline regenerated after Phase-0 audit gap closeout migrations (0022–0024).
- 2026-02-09: Baseline regenerated after business foundation delta tightening (0025–0027).
- 2026-02-13: Baseline regenerated after INV-114 instruction finality migration (0028).
- 2026-02-13: Baseline regenerated after INV-115 pii decoupling migration (0029).
- 2026-02-13: Baseline regenerated after follow-up fix migration for pii purge executor (0030).
- 2026-02-13: Baseline regenerated after INV-116 rail sequence truth-anchor migration (0031).
- 2026-02-18: Baseline regenerated after timeout posture + anchor-sync operational restoration migrations (0032, 0033, 0034).
