# GreenTech4CE Demo Provisioning Sample Pack

This sample pack gives operators one fixed GreenTech4CE demo configuration set for end-to-end rehearsal and signoff-threshold checking.

This pack does not change runtime behavior. It reduces operator ambiguity.

This sample pack does not by itself grant full-demo signoff.

This pack does not by itself grant full-demo signoff.

## Fixed Sample Configuration

### Tenant

- `tenant_id`: `11111111-1111-1111-1111-111111111111`
- `tenant_display_name`: `GreenTech4CE Zambia Demo Tenant`
- `jurisdiction_code`: `ZM`
- `plan`: `pilot-demo`

### Programme and Policy

- `program_id`: `PGM-ZAMBIA-GRN-001`
- `policy_version`: `v1.0.0`

### Suppliers

- `supplier_id`: `SUP-ECOTECH-001`
  - `supplier_name`: `EcoTech Supplies Ltd`
  - `payout_target`: `demo-payout://greentech4ce-zm/ecotech-supplies-ltd`
  - `active`: `true`
  - allowlist outcome: `ALLOW`
- `supplier_id`: `SUP-SOLARFIX-001`
  - `supplier_name`: `SolarFix Field Services`
  - `payout_target`: `demo-payout://greentech4ce-zm/solarfix-field-services`
  - `active`: `true`
  - allowlist outcome: `ALLOW`
- `supplier_id`: `SUP-BLOCKED-001`
  - `supplier_name`: `Blocked Supplier Test`
  - `payout_target`: `demo-payout://greentech4ce-zm/blocked-supplier-test`
  - `active`: `true`
  - allowlist outcome: `DENY`

The payout targets above are demo sample payout targets. They are not production banking truth.

### Reporting and Evidence Routing Identifiers

- `reporting_target_id`: `demo-report-target-greentech4ce-zm`
- `evidence_routing_target_id`: `demo-evidence-target-greentech4ce-zm`

## Repo-Backed Provisioning Steps

The following steps are repo-backed and use real endpoints on this branch.

### Prerequisites

Set the operator environment:

```bash
export BASE_URL="http://127.0.0.1:8080"
export ADMIN_API_KEY="${ADMIN_API_KEY:?set ADMIN_API_KEY}"
export READ_API_KEY="${INGRESS_API_KEY:?set INGRESS_API_KEY or other evidence-read key}"
export SAMPLE_TENANT_ID="11111111-1111-1111-1111-111111111111"
export SAMPLE_PROGRAM_ID="PGM-ZAMBIA-GRN-001"
```

### 1. Tenant onboarding

Endpoint:
- `POST /v1/admin/tenants`

Command:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/tenants" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "display_name": "GreenTech4CE Zambia Demo Tenant",
  "jurisdiction_code": "ZM",
  "plan": "pilot-demo"
}
JSON
```

Expected verification outcome:
- HTTP `200`
- response contains `tenant_id`
- response contains `created_at`

### 2. Supplier registry upsert

Endpoint:
- `POST /v1/admin/suppliers/upsert`

Command for `SUP-ECOTECH-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/suppliers/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "supplier_id": "SUP-ECOTECH-001",
  "supplier_name": "EcoTech Supplies Ltd",
  "payout_target": "demo-payout://greentech4ce-zm/ecotech-supplies-ltd",
  "registered_latitude": -15.3875,
  "registered_longitude": 28.3228,
  "active": true
}
JSON
```

Command for `SUP-SOLARFIX-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/suppliers/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "supplier_id": "SUP-SOLARFIX-001",
  "supplier_name": "SolarFix Field Services",
  "payout_target": "demo-payout://greentech4ce-zm/solarfix-field-services",
  "registered_latitude": -15.4167,
  "registered_longitude": 28.2833,
  "active": true
}
JSON
```

Command for `SUP-BLOCKED-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/suppliers/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "supplier_id": "SUP-BLOCKED-001",
  "supplier_name": "Blocked Supplier Test",
  "payout_target": "demo-payout://greentech4ce-zm/blocked-supplier-test",
  "registered_latitude": -15.4000,
  "registered_longitude": 28.3000,
  "active": true
}
JSON
```

Expected verification outcome for each supplier upsert:
- HTTP `200`
- response contains `upserted: true`

### 3. Programme-scoped supplier allowlist upsert

Endpoint:
- `POST /v1/admin/program-supplier-allowlist/upsert`

Command for `SUP-ECOTECH-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/program-supplier-allowlist/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "program_id": "PGM-ZAMBIA-GRN-001",
  "supplier_id": "SUP-ECOTECH-001",
  "allowed": true
}
JSON
```

Command for `SUP-SOLARFIX-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/program-supplier-allowlist/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "program_id": "PGM-ZAMBIA-GRN-001",
  "supplier_id": "SUP-SOLARFIX-001",
  "allowed": true
}
JSON
```

Command for `SUP-BLOCKED-001`:

```bash
curl -sS -X POST "$BASE_URL/v1/admin/program-supplier-allowlist/upsert" \
  -H "content-type: application/json" \
  -H "x-admin-api-key: $ADMIN_API_KEY" \
  --data @- <<'JSON'
{
  "tenant_id": "11111111-1111-1111-1111-111111111111",
  "program_id": "PGM-ZAMBIA-GRN-001",
  "supplier_id": "SUP-BLOCKED-001",
  "allowed": false
}
JSON
```

Expected verification outcome for each allowlist write:
- HTTP `200`
- response contains `updated: true`

### 4. Supplier policy verification

Endpoint:
- `GET /v1/programs/{programId}/suppliers/{supplierId}/policy`

Command for `SUP-ECOTECH-001`:

```bash
curl -sS "$BASE_URL/v1/programs/PGM-ZAMBIA-GRN-001/suppliers/SUP-ECOTECH-001/policy" \
  -H "x-api-key: $READ_API_KEY" \
  -H "x-tenant-id: 11111111-1111-1111-1111-111111111111"
```

Command for `SUP-SOLARFIX-001`:

```bash
curl -sS "$BASE_URL/v1/programs/PGM-ZAMBIA-GRN-001/suppliers/SUP-SOLARFIX-001/policy" \
  -H "x-api-key: $READ_API_KEY" \
  -H "x-tenant-id: 11111111-1111-1111-1111-111111111111"
```

Command for `SUP-BLOCKED-001`:

```bash
curl -sS "$BASE_URL/v1/programs/PGM-ZAMBIA-GRN-001/suppliers/SUP-BLOCKED-001/policy" \
  -H "x-api-key: $READ_API_KEY" \
  -H "x-tenant-id: 11111111-1111-1111-1111-111111111111"
```

Expected verification outcomes:
- `SUP-ECOTECH-001` returns `decision: "ALLOW"`
- `SUP-SOLARFIX-001` returns `decision: "ALLOW"`
- `SUP-BLOCKED-001` returns `decision: "DENY"`

## Operator-Confirmed Non-Repo-Backed Signoff State

The following state must be confirmed by the operator for signoff analysis. This branch does not provide one canonical repo-backed command that applies all of it end to end.

- programme context is confirmed as `PGM-ZAMBIA-GRN-001` for reveal, export, and evidence-link issuance flows
- active policy version is confirmed as `v1.0.0` in seeded runtime state
- reporting target is confirmed as `demo-report-target-greentech4ce-zm`
- evidence routing target is confirmed as `demo-evidence-target-greentech4ce-zm`

These are operator-confirmed signoff prerequisites, not claims of a fully repo-backed routing control plane.

## What This Pack Proves

This sample pack proves:
- operators have one fixed tenant, programme, policy, supplier, and routing sample set
- tenant onboarding can be executed deterministically
- supplier registry upserts can be executed deterministically
- programme-scoped allowlist writes can be executed deterministically
- supplier policy reads can prove `ALLOW` and `DENY` behavior

This sample pack does not by itself prove full-demo signoff.

## Full-Demo Signoff Threshold

Do not classify a run as full-demo signoff unless all of these are true:

1. tenant onboarding applied successfully
2. supplier registry entries applied successfully
3. programme allowlist entries applied successfully
4. allowlisted suppliers read as `ALLOW`
5. blocked supplier reads as `DENY`
6. programme context is confirmed as `PGM-ZAMBIA-GRN-001`
7. active policy version is confirmed as `v1.0.0`
8. reporting target is confirmed as `demo-report-target-greentech4ce-zm`
9. evidence routing target is confirmed as `demo-evidence-target-greentech4ce-zm`
10. OpenBao / INF-006 signoff posture passes
