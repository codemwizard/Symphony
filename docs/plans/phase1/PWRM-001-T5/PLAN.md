# PWRM-001-T5 PLAN — Add /pilot-demo/api/evidence-links/issue proxy route with worker_id GPS injection and supplier_type guard

Task: PWRM-001-T5
Owner: IMPLEMENTER
Depends on: PWRM-001-T1, PWRM-001-T2, PWRM-001-T4
failure_signature: phase1.pwrm001.t5.gps_injection_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Add app.MapPost("/pilot-demo/api/evidence-links/issue") with operator cookie gate, worker_id
registry lookup, supplier_type == "WORKER" guard (rejecting null and any other value), caller GPS
discard, and registry GPS injection with max_distance = 250m. Done when self-test cases 4–8 all
pass: registry GPS injected (case 4), caller GPS discarded (case 5, FIX F13), SUPPLIER rejected
(case 6), null rejected (case 7, FIX F15), nonexistent worker 404 (case 8). The generic
/v1/evidence-links/issue route is unchanged.

---

## Architectural Context

This is the highest-risk task in PWRM-001. Without this proxy, a caller can supply arbitrary GPS
coordinates and receive a GPS-locked token bound to attacker-controlled coordinates (FIX F13
violation). The supplier_type guard (FIX F15) closes the null-type ambiguity class entirely —
null must be treated as an error, not as legacy-compatible. The proxy is the security perimeter;
the submit handler trusts the token's embedded GPS unconditionally.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### FIX F13: GPS locked at issuance, immutable

The pilot-demo proxy injects GPS from the worker registry into the issue request. The token carries
this GPS. The submit handler reads GPS from the token only. No re-query of the worker registry
occurs at submit time.

Sequence:
```
POST /pilot-demo/api/evidence-links/issue { worker_id, submitter_class }
│
▼
Proxy: look up worker registry by worker_id
→ check supplier_type == "WORKER" (not null, not other)
→ discard any caller-provided GPS
→ inject registry GPS + max_distance=250
│
▼
EvidenceLinkIssueHandler.HandleAsync(enriched request)
→ token created with embedded GPS
│
▼
POST /api/public/evidence-links/submit { artifact_type, artifact_ref, latitude, longitude }
│
▼
EvidenceLinkSubmitHandler: validate submitted GPS against TOKEN-EMBEDDED GPS only
(no worker registry access here)
```

### FIX F15: null supplier_type rejected in pilot-demo worker flow

```csharp
var entry = SupplierRegistry.TryGet(workerId);
if (entry is null)
    return 404 WORKER_NOT_FOUND;
if (entry.SupplierType != "WORKER")   // null, "SUPPLIER", anything else → rejected
    return 400 INVALID_SUPPLIER_TYPE;
// proceed — GPS injection
```

### FIX F11: structured_payload required at proxy too

The recipient landing page form for WASTE_COLLECTOR MUST always supply structured_payload.
The UI has no "skip payload" path for WASTE_COLLECTOR.

### Proxy route definition (from design.md)

```csharp
record PilotDemoEvidenceLinkIssueRequest(
    string? worker_id,
    string tenant_id,
    string instruction_id,
    string program_id,
    string submitter_class,
    string submitter_msisdn,
    int? expires_in_seconds
    // NOTE: expected_latitude, expected_longitude, max_distance_meters are NOT
    // accepted from client when worker_id is set — they come from registry only
);

app.MapPost("/pilot-demo/api/evidence-links/issue", async (
    PilotDemoEvidenceLinkIssueRequest req, HttpContext ctx, CancellationToken ct) =>
{
    if (!TryValidatePilotDemoOperatorCookie(ctx, null, out var ec, out var errs))
        return Results.Json(new { error_code = ec, errors = errs }, statusCode: 401);

    decimal? lat = null, lon = null, maxDist = null;

    if (req.worker_id is not null)
    {
        var entry = SupplierRegistry.TryGet(req.worker_id);
        if (entry is null)
            return Results.Json(new { error_code = "WORKER_NOT_FOUND" }, statusCode: 404);

        if (entry.SupplierType != "WORKER")
            return Results.Json(new { error_code = "INVALID_SUPPLIER_TYPE" }, statusCode: 400);

        lat = entry.RegisteredLatitude;
        lon = entry.RegisteredLongitude;
        maxDist = 250.0m;
    }

    var issueReq = new EvidenceLinkIssueRequest(
        req.tenant_id, req.instruction_id, req.program_id,
        req.submitter_class, req.submitter_msisdn,
        lat, lon, maxDist, req.expires_in_seconds);

    var result = await EvidenceLinkIssueHandler.HandleAsync(issueReq, logger, ct);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});
```

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### US-3: worker_id issues GPS-locked token — null supplier_type rejected (FIX F13 + F15)

Acceptance criteria:
- Worker not found → 404 WORKER_NOT_FOUND.
- supplier_type == null → 400 INVALID_SUPPLIER_TYPE.
- supplier_type is non-null and not "WORKER" → 400 INVALID_SUPPLIER_TYPE.
- supplier_type == "WORKER" → proceed.
- Server sets expected_latitude, expected_longitude from registry; max_distance_meters = 250.0.
- ANY expected_latitude/expected_longitude in the caller's request body are silently discarded.
- Token embeds the registry GPS; caller-provided GPS is NEVER embedded.
- worker_id is NOT accepted on /v1/evidence-links/issue.

### US-4: GPS is immutable after issuance (FIX F13)

Acceptance criteria:
- WHEN a token is validated at submit time, GPS is read from the token's embedded fields,
  NOT re-queried from the worker registry.
- The submit handler performs no worker registry lookup.

### US-6: Self-test — 8 cases, fully isolated

Acceptance criteria:
- dotnet run --self-test-worker-onboarding exits 0, all 8 cases PASS.

---

## Pre-conditions

- [ ] PWRM-001-T1 is status=completed (WASTE_COLLECTOR allowlist guard exists on generic route).
- [ ] PWRM-001-T2 is status=completed (supplier_type field exists and is retrievable).
- [ ] PWRM-001-T4 is status=completed (workers are seeded for the demo tenant).
- [ ] This PLAN.md has been reviewed before any code is written.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/Program.cs` | MODIFY | Add PilotDemoEvidenceLinkIssueRequest record and proxy route |
| `tasks/PWRM-001-T5/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If any client-supplied GPS field is forwarded to the issue handler when worker_id is set** → STOP (FIX F13 regression)
- **If entry.SupplierType != "WORKER" check uses != null instead of == "WORKER"** → STOP (null passes through)
- **If worker_id parameter is added to the generic /v1/evidence-links/issue route** → STOP
- **If operator cookie gate is absent** → STOP
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Define PilotDemoEvidenceLinkIssueRequest record

**What:** `[ID pwrm001_t5_work_item_01]` Define the request record with no GPS fields.
**How:** Add the record definition to Program.cs. The record must NOT include expected_latitude,
expected_longitude, or max_distance_meters fields — those come from the registry only.
**Done when:** Record compiles; no GPS fields are present on the client-facing type.

### Step 2: Add the proxy route with operator cookie gate and non-worker path

**What:** `[ID pwrm001_t5_work_item_02]` Add app.MapPost route. When worker_id is null, pass
null lat/lon/maxDist to the generic handler (non-worker issuance path is preserved).
**How:** Follow the route definition from design.md exactly. Add cookie gate as the first check.
**Done when:** Route exists; 401 returned when cookie is absent.

### Step 3: Implement worker_id lookup with supplier_type guard and GPS injection

**What:** `[ID pwrm001_t5_work_item_03]` When worker_id is non-null: TryGet, null-check,
supplier_type guard (entry.SupplierType != "WORKER"), then inject GPS from registry.
**How:** Follow FIX F15 lookup logic from design.md exactly. maxDist = 250.0m. Discard any GPS
in req body by not reading it.
**Done when:** WORKER entry proceeds; null type and SUPPLIER type both return 400; nonexistent
worker returns 404.

### Step 4: Confirm generic route is unchanged

**What:** `[ID pwrm001_t5_work_item_04]` Verify /v1/evidence-links/issue does not accept worker_id.
**How:** Review the generic route definition and confirm no worker_id parameter was added.
**Done when:** Generic route signature is unchanged from before this task.

### Step 5: Emit evidence

**What:** `[ID pwrm001_t5_work_item_03]` Run self-test and capture evidence.
**How:**
```bash
dotnet run --self-test-worker-onboarding || exit 1
```
**Done when:** Cases 4–8 all PASS; evidence/phase1/pwrm_worker_onboarding.json status = "PASS".

---

## Verification

```bash
# [ID pwrm001_t5_work_item_01] [ID pwrm001_t5_work_item_02] [ID pwrm001_t5_work_item_03] [ID pwrm001_t5_work_item_04]
dotnet run --self-test-worker-onboarding || exit 1

python3 scripts/audit/validate_evidence.py --task PWRM-001-T5 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T5"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of check objects
- `f13_caller_gps_discarded_confirmed`: true
- `f15_null_supplier_type_rejected_confirmed`: true
- `worker_not_found_404_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Remove the PilotDemoEvidenceLinkIssueRequest record from Program.cs.
2. Remove the /pilot-demo/api/evidence-links/issue route from Program.cs.
3. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Caller GPS forwarded to handler when worker_id is set | CRITICAL_FAIL (FIX F13 regression) | GPS variables declared as null and only set from registry |
| supplier_type = null allowed through | CRITICAL_FAIL (FIX F15 regression) | Use `!= "WORKER"` not `== null` as the guard |
| worker_id added to generic route | CRITICAL_FAIL | Review generic route after change; confirm signature unchanged |
| Operator cookie gate absent | CRITICAL_FAIL | Gate must be first check; test 401 path explicitly |
