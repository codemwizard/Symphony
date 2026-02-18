# Audit Logging Plan (Phase‑0 → Phase‑1)

## Purpose
Establish an auditable, **swap‑friendly** logging posture that supports:
- **Secrets access audit** (OpenBao audit device)
- **Instruction/ingress audit** (Postgres append‑only ledger)
- **Operational logs** (services, workers, CI)

This plan keeps **Phase‑0 parity** with dev while enabling **production‑grade backends**.

---

## Scope & Requirements

### Required audit sources
1) **OpenBao audit logs** (secrets access/auth events)
2) **Ingress ledger** (append‑only Postgres `ingress_attestations`)
3) **Application/service logs** (API, worker, scheduler, policy engine)

### Must‑have properties
- **Fail‑closed evidence**: audit log creation should be mechanically verifiable.
- **Environment portability**: dev/staging/prod share the same logical pipeline, only sink changes.
- **Tamper evidence**: logs should be write‑once or immutable at rest where possible.

---

## Environment Detection & Swappable Design

Use a single environment switch to select sinks:

```
SYMPHONY_ENV=dev|staging|prod
AUDIT_LOG_BACKEND=opensearch|loki|graylog|wazuh
```

**Design pattern:**
- **Collector layer** is always the same (Fluent Bit / Vector / OpenTelemetry Collector).
- **Sink layer** changes by environment (OpenSearch for prod, Loki for dev, etc.).

This mirrors the KMS approach: **runtime reads environment and swaps the sink**, not the pipeline.

---

## Recommended FOSS Options (Dev & Prod)

### Option A — **OpenSearch Stack** (Recommended for prod)
- OpenSearch is an open‑source search and analytics suite; OpenSearch Dashboards is the visualization UI.
- Strong fit for audit trails, structured JSON logs, and compliance review workflows.
- Deploy self‑managed in prod; can run locally in Docker for parity.

### Option B — **Grafana Loki** (Lightweight dev + can scale)
- Loki is a log aggregation system that indexes labels (metadata) instead of full text.
- Good for dev/staging; can scale with object storage in prod.

### Option C — **Graylog Open**
- Centralized log management with search, dashboards, and alerting.
- Suitable for teams that want a single, self‑hosted log UI.

### Option D — **Wazuh** (Security‑oriented)
- Open‑source SIEM/XDR focused on security telemetry, compliance reporting, and incident response.

### Collectors / Agents (FOSS)
- **OpenTelemetry Collector** (vendor‑agnostic telemetry pipeline).
- **Fluent Bit** (lightweight log shipping).
- **Vector** (high‑performance log pipeline).

**Recommendation:**
- **Dev:** Loki + OpenTelemetry Collector (or Fluent Bit)
- **Prod:** OpenSearch + OpenTelemetry Collector

---

## OpenBao Audit Logging (Secrets Access)

OpenBao supports **declarative audit device configuration**; audit devices can be defined in server config (preferred over API enablement for safety).

**Current implementation:**
- `infra/openbao/openbao.hcl` declares a file audit device (`/openbao/audit.log`).
- `infra/openbao/docker-compose.yml` mounts this config and starts OpenBao with `-config=...`.
- `scripts/security/openbao_smoke_test.sh` verifies that the audit log exists and is non‑empty.

---

## Ingress Audit Ledger (Postgres)

- The **ingress attestation ledger** is the authoritative, append‑only audit trail for instructions.
- This is **separate** from operational/audit logs and should not be replaced by a log sink.
- If stricter DB audit logging is required, consider **pgaudit** for statement‑level audit (Phase‑1/2).

---

## Production‑Grade Swappable Topology

```
[OpenBao Audit] -> File -> Collector -> (OpenSearch | Loki | Wazuh)
[Service Logs]  -> stdout/file -> Collector -> (OpenSearch | Loki | Graylog)
[Postgres Logs] -> log files -> Collector -> (OpenSearch | Loki)
```

**Swap rules** (by environment):
- **dev**: local file + Loki
- **staging**: OpenSearch (single node)
- **prod**: OpenSearch cluster + WORM storage (if required)

---

## Evidence & Verification

Phase‑0 evidence is produced by:
- `scripts/security/openbao_smoke_test.sh` → `evidence/phase0/openbao_audit_log.json`
- `scripts/security/openbao_smoke_test.sh` → `evidence/phase0/openbao_smoke.json`

Evidence requirement is enforced by the Phase‑0 contract.

---

## Action Plan (Phase‑0)

1) **Declarative OpenBao audit config** (DONE)
2) **Audit logging plan doc** (THIS DOC)
3) **Audit evidence verification** (DONE via smoke test)

---

## References (for implementation)
- OpenSearch Documentation (core + Dashboards)
- Grafana Loki Documentation
- OpenTelemetry Collector Documentation
- Fluent Bit Documentation
- Vector Documentation
- Graylog Open Documentation
- Wazuh Documentation
- OpenBao Audit Devices Documentation / RFC

## Action Plan (Phase‑1)

- Add collector configuration for chosen backend.
- Add retention and immutability policy (WORM or object‑store) for production audit.
- Add alerting rules for audit gaps.
