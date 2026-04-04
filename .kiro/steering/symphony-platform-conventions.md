# Symphony Platform Conventions

## Runtime profile
All PWRM tasks run under `SYMPHONY_RUNTIME_PROFILE=pilot-demo`. Self-tests
are only permitted under this profile. `DemoSelfTestEntryPoint.TryRunAsync`
gates execution.

## NDJSON append log — write ordering guarantee (FIX F12)
`EvidenceLinkSubmissionLog` appends records via `TamperEvidentChain.AppendJsonAsync`
to the path in `EVIDENCE_LINK_SUBMISSIONS_FILE`. `ReadAll()` returns records in
file-append order.

**CRITICAL: Single-threaded write contract.**
All appends within a self-test runner run synchronously (`await` in sequence,
no `Task.WhenAll` over multiple appends). The append implementation uses a
`static SemaphoreSlim _appendLock = new(1, 1)` to serialise concurrent callers.
This makes append-order a hard guarantee, not an assumption.

Every new PWRM write MUST include a `sequence_number` field (int) = count of
records in the log immediately before the append. "Latest wins" for duplicate
`instruction_id` = highest `sequence_number`. Do NOT sort by any timestamp.

## Exception log
`DemoExceptionLog` appends to `DEMO_EXCEPTION_LOG_FILE`. It is seeded explicitly
in self-test runners (never assumed from other runners). The `instruction_id`
field is the join key for PWRM-004 aggregation.

## Supplier registry — worker_id rules (FIX F15)
`SupplierRegistryUpsertHandler` / `ProgramSupplierAllowlistUpsertHandler` are the
in-memory write surfaces. Workers use `supplier_type = "WORKER"` (exact string).

**For the pilot-demo proxy route only:**
- `supplier_type == "WORKER"` → accepted as worker
- `supplier_type == null` → **REJECTED** with `INVALID_SUPPLIER_TYPE` (pilot policy)
- `supplier_type == any other string` → REJECTED with `INVALID_SUPPLIER_TYPE`

This is stricter than the generic API. Null is not legacy-compatible in the
pilot-demo worker flow. Every seeded worker MUST have `supplier_type = "WORKER"`.

## GPS immutability (FIX F13)
GPS is locked at issuance time and embedded in the token. The submit handler
validates the submitted GPS against the **token-embedded coordinates only**.
It does NOT re-query the worker registry at submit time.
This means: if a worker's registered coordinates change after a token is issued,
the old token still validates against its embedded coordinates. This is intentional
for demo determinism. Worker GPS is only ever read once — at issue time.

## Backend recomputes net_weight_kg (FIX F14)
`Pwrm0001WeighbridgePayloadValidator` does NOT use the `net_weight_kg` field
submitted by the client as the ground truth. It:
1. Reads `gross_weight_kg` and `tare_weight_kg` from the payload
2. Computes `backend_net = gross - tare` using decimal arithmetic
3. Checks that `Math.Abs(submitted_net - backend_net) <= 0.01m` as a sanity check
4. Stores `backend_net` (not `submitted_net`) in the log record as `net_weight_kg`
This eliminates browser float-rounding drift as a source of validation failures.

## C# patterns in use
- Top-level statements in `Program.cs`
- Static handler classes: `static class XxxHandler { public static async Task<HandlerResult> HandleAsync(...) }`
- `record` types for all request/response contracts in `CommandContracts.cs`
- `JsonElement?` for raw JSON pass-through fields (do NOT stringify twice)
- `decimal` (not `double`) for all monetary and weight values
- `CreateStableGuid(string seed)` — deterministic Guid helper already in Program.cs

## Self-test runner pattern
See `SupplierPolicySelfTestRunner.cs` and `SupervisoryReadModelsSelfTestRunner.cs`.
Every runner MUST:
1. Delete its own NDJSON files at start of `RunAsync`
2. Set isolated env var paths (unique to that runner)
3. Use namespaced IDs (program_id, instruction_id, worker_id include runner suffix)
4. Register in `DemoSelfTestEntryPoint.SelfTests` dictionary
5. Write evidence JSON to `evidence/phase1/`
6. Return 0 on all-PASS, 1 on any FAIL
7. NOT use `Task.WhenAll` for sequential appends — always `await` in order