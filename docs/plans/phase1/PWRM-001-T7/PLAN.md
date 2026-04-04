# PWRM-001-T7 PLAN — Create WorkerOnboardingSelfTestRunner.cs with 8 fully isolated adversarial cases

Task: PWRM-001-T7
Owner: IMPLEMENTER
Depends on: PWRM-001-T1, PWRM-001-T2, PWRM-001-T3, PWRM-001-T4, PWRM-001-T5, PWRM-001-T6
failure_signature: phase1.pwrm001.t7.self_test_missing
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Create `Demo/WorkerOnboardingSelfTestRunner.cs` registered as `--self-test-worker-onboarding`
with 8 adversarial test cases covering: WASTE_COLLECTOR allowlist (case 1), invalid class rejection
(case 2), GET policy (case 3), GPS-locked issuance (case 4), caller GPS discard/FIX F13 (case 5),
SUPPLIER type rejection (case 6), null type rejection/FIX F15 (case 7), worker not found (case 8).
Done when `dotnet run --self-test-worker-onboarding` exits 0 with all 8 PASS and
`evidence/phase1/pwrm_worker_onboarding.json` is written.

---

## Architectural Context

This is the acceptance gate for the entire PWRM-001 feature. It is the machine-verifiable proof
that FIX F13 (GPS immutability) and FIX F15 (null supplier_type rejection) are actually enforced
end-to-end, not just declared. The isolation design (separate tenant, namespaced GUIDs, deleted
NDJSON files, sequential await) is non-negotiable — the runner must produce consistent results on
a fresh process with no prior state.

---

## Design Reference (from .kiro/specs/pwrm-001-worker-onboarding/design.md)

### FIX F15: null supplier_type rejected in pilot-demo worker flow

Any registry entry that is not explicitly supplier_type = "WORKER" (including null) is rejected
with 400 INVALID_SUPPLIER_TYPE. Rationale: eliminates the ambiguity class entirely.

### FIX F13: GPS locked at issuance, immutable

GPS is injected from the worker registry at issuance. The submit handler reads GPS from the token
only. No re-query of the worker registry occurs at submit time.

### Self-test runner setup (from design.md)

```csharp
var runnerSuffix = "pwrm001-selftest";
var tenantId     = "22222222-2222-2222-2222-222222222222";  // different from demo tenant
var programId    = $"PGM-SELFTEST-{runnerSuffix}";
var worker001Id  = CreateStableGuid($"worker-chunga-001-{runnerSuffix}").ToString();
var worker002Id  = CreateStableGuid($"worker-chunga-002-{runnerSuffix}").ToString();

var submissionsPath = $"/tmp/pwrm001_selftest_submissions.ndjson";
var smsLogPath      = $"/tmp/pwrm001_selftest_sms.ndjson";
File.Delete(submissionsPath);
File.Delete(smsLogPath);
Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionsPath);
Environment.SetEnvironmentVariable("EVIDENCE_LINK_SMS_DISPATCH_FILE", smsLogPath);
Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "pwrm001-selftest-key");

// Seed with explicit supplier_type values
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker001Id, "Test Worker 001", "MMO:+260971100001",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, worker002Id, "Test Worker 002", "MMO:+260971100002",
    -15.4167m, 28.2833m, true, supplier_type: "WORKER"));

// SUPPLIER entry for case 6
var supplierFakeId = CreateStableGuid($"supplier-fake-{runnerSuffix}").ToString();
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, supplierFakeId, "Fake Supplier", "MMO:+260971199999",
    null, null, true, supplier_type: "SUPPLIER"));

// null-type entry for case 7
var nullTypeId = CreateStableGuid($"supplier-null-type-{runnerSuffix}").ToString();
await SupplierRegistryUpsertHandler.HandleAsync(new SupplierRegistryUpsertRequest(
    tenantId, nullTypeId, "Null Type Entry", "MMO:+260971188888",
    null, null, true, supplier_type: null));

await ProgramSupplierAllowlistUpsertHandler.HandleAsync(
    new ProgramSupplierAllowlistUpsertRequest(tenantId, programId, worker001Id, true));
```

### 8 test cases

| # | Input | Expected |
|---|-------|----------|
| 1 | submitter_class = "WASTE_COLLECTOR" on generic route | 200 |
| 2 | submitter_class = "UNKNOWN_CLASS" | 400 INVALID_SUBMITTER_CLASS |
| 3 | GET policy for worker001Id | decision = "ALLOW" |
| 4 | Pilot-demo issue with worker_id = worker001Id + WASTE_COLLECTOR | 200; token has lat=-15.4167, lon=28.2833 |
| 5 | Pilot-demo issue with worker_id = worker001Id + caller provides wrong GPS | 200; token has REGISTRY GPS not caller GPS |
| 6 | Pilot-demo issue with worker_id = supplierFakeId (supplier_type = "SUPPLIER") | 400 INVALID_SUPPLIER_TYPE |
| 7 | Pilot-demo issue with worker_id = nullTypeId (supplier_type = null) | 400 INVALID_SUPPLIER_TYPE |
| 8 | Pilot-demo issue with worker_id = "nonexistent-guid" | 404 WORKER_NOT_FOUND |

---

## Requirements Reference (from .kiro/specs/pwrm-001-worker-onboarding/requirements.md)

### US-1: Submitter class validation

Acceptance criteria:
- WHEN submitter_class is WASTE_COLLECTOR → 200 (case 1).
- WHEN submitter_class is not in the allowlist → 400 INVALID_SUBMITTER_CLASS (case 2).

### US-3: worker_id issues GPS-locked token — null supplier_type rejected (FIX F13 + F15)

Acceptance criteria:
- Worker not found → 404 WORKER_NOT_FOUND (case 8).
- supplier_type == null → 400 INVALID_SUPPLIER_TYPE (case 7).
- supplier_type non-null and not "WORKER" → 400 INVALID_SUPPLIER_TYPE (case 6).
- supplier_type == "WORKER" → proceed (cases 4, 5).
- ANY caller GPS silently discarded (case 5).

### US-4: GPS is immutable after issuance (FIX F13)

- Token GPS equals registry GPS even when caller provides different GPS (case 5).

### US-6: Self-test — 8 cases, fully isolated

- dotnet run --self-test-worker-onboarding exits 0, all 8 cases PASS.
- Runner deletes its own NDJSON files before starting.
- Runner uses namespaced IDs; does not rely on Program.cs startup seeding.
- Runner does NOT use Task.WhenAll on sequential appends.

---

## Pre-conditions

- [ ] PWRM-001-T1 through T6 are all status=completed.
- [ ] This PLAN.md has been reviewed before any code is written.
- [ ] services/ledger-api solution builds cleanly.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `services/ledger-api/Demo/WorkerOnboardingSelfTestRunner.cs` | CREATE | 8-case isolated self-test runner |
| `services/ledger-api/Demo/DemoSelfTestEntryPoint.cs` | MODIFY | Register --self-test-worker-onboarding |
| `tasks/PWRM-001-T7/meta.yml` | MODIFY | Update status to completed |

---

## Stop Conditions

- **If runner uses DemoTenantId "11111111-1111-1111-1111-111111111111"** → STOP
- **If Task.WhenAll is used for any sequential append operation** → STOP
- **If fewer than 8 test cases are implemented** → STOP
- **If case 5 does not assert caller GPS is discarded** → STOP (FIX F13 unverified)
- **If case 7 does not assert null type rejection** → STOP (FIX F15 unverified)
- **If evidence is static or self-declared instead of derived** → STOP

---

## Implementation Steps

### Step 1: Create runner file with isolated setup

**What:** `[ID pwrm001_t7_work_item_01]` Create Demo/WorkerOnboardingSelfTestRunner.cs with
namespaced tenant, program, and worker IDs. Delete NDJSON files at startup. Set env vars.
**How:** Use tenantId = "22222222-2222-2222-2222-222222222222" and runnerSuffix = "pwrm001-selftest"
for all IDs. Delete both NDJSON paths before any seeding.
**Done when:** File compiles; env vars are set before any handler call.

### Step 2: Seed all test fixtures with sequential await

**What:** `[ID pwrm001_t7_work_item_02]` Seed worker001 (WORKER), worker002 (WORKER), supplierFake
(SUPPLIER), nullType (null). Add worker001 to program allowlist only.
**How:** Sequential await for each upsert and allowlist call. Never Task.WhenAll.
**Done when:** All four registry entries exist with correct SupplierType values; worker001 is on
the allowlist; worker002, supplierFake, nullType are not.

### Step 3: Implement all 8 test cases

**What:** `[ID pwrm001_t7_work_item_03]` Implement cases 1–8 as specified in tasks.md and design.md.
**How:**
- Case 1: Call generic issue handler with WASTE_COLLECTOR; assert 200.
- Case 2: Call generic issue handler with UNKNOWN_CLASS; assert 400 INVALID_SUBMITTER_CLASS.
- Case 3: Call GET policy for worker001Id; assert decision = "ALLOW".
- Case 4: Call pilot-demo proxy with worker_id = worker001Id + WASTE_COLLECTOR; assert 200; decode
  token and assert lat = -15.4167, lon = 28.2833.
- Case 5: Call pilot-demo proxy with worker_id = worker001Id + caller body containing wrong GPS;
  assert 200; decode token and assert lat/lon equals REGISTRY GPS, not caller GPS (FIX F13).
- Case 6: Call pilot-demo proxy with worker_id = supplierFakeId; assert 400 INVALID_SUPPLIER_TYPE.
- Case 7: Call pilot-demo proxy with worker_id = nullTypeId; assert 400 INVALID_SUPPLIER_TYPE (FIX F15).
- Case 8: Call pilot-demo proxy with worker_id = "nonexistent-guid"; assert 404 WORKER_NOT_FOUND.
**Done when:** All 8 cases produce the expected result in a single run from a fresh state.

### Step 4: Register in DemoSelfTestEntryPoint

**What:** `[ID pwrm001_t7_work_item_04]` Add "--self-test-worker-onboarding" to SelfTests dictionary.
**How:** Map the key to WorkerOnboardingSelfTestRunner in DemoSelfTestEntryPoint.SelfTests.
**Done when:** `dotnet run --self-test-worker-onboarding` is a valid invocation that executes the runner.

### Step 5: Write evidence file

**What:** `[ID pwrm001_t7_work_item_05]` Write evidence/phase1/pwrm_worker_onboarding.json.
**How:** At the end of the runner, write JSON with task_id, git_sha, timestamp_utc, status, and
per-case check results.
**Done when:** evidence file exists; status = "PASS"; cases_passed = 8; cases_failed = 0.

---

## Verification

```bash
# [ID pwrm001_t7_work_item_01] [ID pwrm001_t7_work_item_02] [ID pwrm001_t7_work_item_03]
# [ID pwrm001_t7_work_item_04] [ID pwrm001_t7_work_item_05]
dotnet run --self-test-worker-onboarding || exit 1

# [ID pwrm001_t7_work_item_05]
test -f evidence/phase1/pwrm_worker_onboarding.json && grep '"status"' evidence/phase1/pwrm_worker_onboarding.json || exit 1

python3 scripts/audit/validate_evidence.py --task PWRM-001-T7 --evidence evidence/phase1/pwrm_worker_onboarding.json || exit 1

RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract

File: `evidence/phase1/pwrm_worker_onboarding.json`

Required fields:
- `task_id`: "PWRM-001-T7"
- `git_sha`: commit sha at time of evidence emission
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of 8 check objects, one per test case
- `cases_passed`: 8
- `cases_failed`: 0
- `f13_gps_immutability_confirmed`: true
- `f15_null_type_rejected_confirmed`: true

---

## Rollback

If this task must be reverted:
1. Delete Demo/WorkerOnboardingSelfTestRunner.cs.
2. Remove "--self-test-worker-onboarding" registration from DemoSelfTestEntryPoint.
3. Restore status to 'ready' in meta.yml.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Fewer than 8 test cases | FAIL | Count cases before marking done |
| Task.WhenAll used for sequential appends | FAIL — race condition risk | Use sequential await exclusively |
| Demo tenant ID reused | FAIL — isolation violation, stale state | Use "22222222-2222-2222-2222-222222222222" only |
| Case 5 does not verify caller GPS discarded | CRITICAL_FAIL — FIX F13 unverified | Decode token and compare lat/lon against REGISTRY values |
| Case 7 does not verify null type rejected | CRITICAL_FAIL — FIX F15 unverified | Assert 400 INVALID_SUPPLIER_TYPE specifically for null type entry |
