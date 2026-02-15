# Phase-0 Performance Posture (Mechanical Safety)

Phase-0 performance is treated as **safety**, not optimization.
The goal is to prevent obvious performance foot-guns (migration lock incidents, missing hot-path indexes, runaway sessions) using **mechanical checks + evidence artifacts**.

Non-goals (Phase-0):
- No load tests, soak tests, or numeric latency SLO enforcement.
- No production benchmarking.
- No runtime observability stack requirements (Grafana/Prometheus/etc).

## Table Classes (Phase-0)

These classes are used to define what must be mechanically verifiable today, and what is deferred.

- **Hot-path queue/outbox**
  - Example tables: `payment_outbox_pending`, `payment_outbox_attempts`
  - Properties: high churn, frequently claimed, must avoid blocking DDL patterns.

- **Ingress/attestation**
  - Example tables: `ingress_attestations`
  - Properties: append-only posture, indexed for lookup/reconciliation.

- **Evidence/ledger**
  - Example tables: `evidence_packs`, `evidence_pack_items`, `billing_usage_events`
  - Properties: append-only posture, queryable by identifiers and time, must avoid accidental inline-blob bloat.

- **Reference/control tables**
  - Example tables: participants/tenants/clients/members
  - Properties: lower churn; constraints and indexes still required but may be less latency-sensitive.

## Required Index Posture (Phase-0)

Phase-0 requires that critical hot-path access patterns are supported by indexes and/or uniqueness constraints.
This is verified via catalog checks (preferred) or targeted DB tests.

### Outbox hot path (required)

- Pending claim index posture (canonical Phase-0 performance invariant):
  - Evidence: `evidence/phase0/outbox_pending_indexes.json` (INT plane, `INT-G22`, `INV-031`)
  - Verifier: `scripts/db/tests/test_outbox_pending_indexes.sh`

### Correlation and reconciliation paths (required shape)

For any hot-path table that includes a `tenant_id` and/or `correlation_id`, Phase-0 expects at least one index that supports the expected lookup pattern.
The exact index set is enforced by later catalog verifiers (planned), but the posture must be documented now to avoid drift.

## DB Timeout Posture (Fail-Fast) (Phase-0)

Phase-0 requires a documented, mechanical “fail-fast” posture to prevent:
- stuck DDL locks,
- runaway queries,
- idle-in-transaction sessions.

Expected Postgres settings (enforced later by a verifier; documented now):
- `statement_timeout`
- `lock_timeout`
- `idle_in_transaction_session_timeout`

Where to apply (Phase-0 acceptable options):
- DB-level defaults in CI/local parity environments, or
- role-level defaults for runtime roles used by the migrator and application.

## Migration Performance Guardrails (Phase-0)

Phase-0 migration safety is enforced as structural guardrails:
- Avoid long blocking operations on hot-path tables.
- Use `CONCURRENTLY` for index creation where supported and governed by the repo’s no-tx discipline.

Planned static/categorized checks (Phase-0 appropriate, deterministic):
- Disallow `VACUUM FULL`, `CLUSTER`, `REINDEX` in migrations.
- Flag `ALTER TABLE ... SET NOT NULL` and type changes on large/hot tables unless waived.
- Require no-tx marker and/or filename conventions for concurrent index migrations.

## Waiver Format (Machine-Detectable)

Any waiver MUST be explicit and tied to an ADR reference.

Canonical marker format:

`-- symphony:perf_waiver adr=ADR-XXXX reason="..." expires=YYYY-MM-DD`

Rules:
- `adr=` is required.
- `reason=` is required and must be a quoted string.
- `expires=` is required to prevent permanent waivers.
- Waivers are reviewed as part of baseline governance and drift controls.

## Evidence Artifacts (Phase-0)

Phase-0 performance evidence is structural:
- It proves the presence of guardrails and the shape of the schema.
- It does not claim throughput.

Current Phase-0 performance evidence:
- `evidence/phase0/outbox_pending_indexes.json` (INV-031)
- `evidence/phase0/db_timeout_posture.json` (INV-117)

Planned evidence artifacts (future tasks):
- `evidence/phase0/index_posture.json`
- `evidence/phase0/migration_performance_risks.json`
