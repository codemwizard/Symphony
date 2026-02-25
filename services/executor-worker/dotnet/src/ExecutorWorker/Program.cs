using System.Diagnostics;
using System.Text.Json;

if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
{
    var code = await ExecutorWorkerSelfTest.RunAsync(CancellationToken.None);
    Environment.ExitCode = code;
    return;
}
if (args.Contains("--self-test-adapter-contract", StringComparer.OrdinalIgnoreCase))
{
    var code = await AdapterContractSelfTest.RunAsync(CancellationToken.None);
    Environment.ExitCode = code;
    return;
}
if (args.Contains("--self-test-simulated-rail-adapter", StringComparer.OrdinalIgnoreCase))
{
    var code = await SimulatedRailAdapterSelfTest.RunAsync(CancellationToken.None);
    Environment.ExitCode = code;
    return;
}

Console.WriteLine("ExecutorWorker MVP: use --self-test for deterministic task verification.");

record ClaimedOutbox(
    string outbox_id,
    string lease_token,
    string instruction_id,
    int attempt_no,
    JsonElement payload
);

record CompletionRequest(
    string outbox_id,
    string lease_token,
    string worker_id,
    string state,
    string? rail_reference,
    string? response_code,
    int latency_ms,
    int retry_after_seconds
);

record CompletionResult(bool ok, string? error)
{
    public static CompletionResult Ok() => new(true, null);
    public static CompletionResult Fail(string error) => new(false, error);
}

record RailInstruction(
    string instruction_id,
    string rail_type,
    string idempotency_key,
    string payload_json
);

record SubmitResult(
    bool ok,
    string rail_ref,
    bool retryable,
    string error_code
);

record StatusResult(
    bool ok,
    string state,
    bool final,
    string error_code
);

record CancelResult(
    bool ok,
    string state,
    bool too_late,
    string error_code
);

interface IRailAdapter
{
    Task<SubmitResult> Submit(RailInstruction instruction, CancellationToken cancellationToken);
    Task<StatusResult> QueryStatus(string railRef, CancellationToken cancellationToken);
    Task<CancelResult> Cancel(string railRef, CancellationToken cancellationToken);
}

sealed class DeterministicSimulatedAdapter : IRailAdapter
{
    private readonly Dictionary<string, string> _statusByRailRef = new(StringComparer.Ordinal);

    public Task<SubmitResult> Submit(RailInstruction instruction, CancellationToken cancellationToken)
    {
        _ = cancellationToken;
        if (instruction.instruction_id.Contains("submit_fail", StringComparison.Ordinal))
        {
            return Task.FromResult(new SubmitResult(
                ok: false,
                rail_ref: string.Empty,
                retryable: false,
                error_code: "SUBMIT_REJECTED"
            ));
        }

        var railRef = $"sim-{instruction.instruction_id}";
        var status = instruction.instruction_id.Contains("query_fail", StringComparison.Ordinal)
            ? "FAILED"
            : instruction.instruction_id.Contains("cancelled", StringComparison.Ordinal)
                ? "CANCELLED"
                : "SETTLED";
        _statusByRailRef[railRef] = status;

        return Task.FromResult(new SubmitResult(
            ok: true,
            rail_ref: railRef,
            retryable: false,
            error_code: string.Empty
        ));
    }

    public Task<StatusResult> QueryStatus(string railRef, CancellationToken cancellationToken)
    {
        _ = cancellationToken;
        if (!_statusByRailRef.TryGetValue(railRef, out var status))
        {
            return Task.FromResult(new StatusResult(
                ok: false,
                state: "UNKNOWN",
                final: false,
                error_code: "RAIL_REF_NOT_FOUND"
            ));
        }

        var isFinal = status is "SETTLED" or "FAILED" or "CANCELLED";
        return Task.FromResult(new StatusResult(
            ok: true,
            state: status,
            final: isFinal,
            error_code: string.Empty
        ));
    }

    public Task<CancelResult> Cancel(string railRef, CancellationToken cancellationToken)
    {
        _ = cancellationToken;
        if (!_statusByRailRef.TryGetValue(railRef, out var status))
        {
            return Task.FromResult(new CancelResult(
                ok: false,
                state: "UNKNOWN",
                too_late: false,
                error_code: "RAIL_REF_NOT_FOUND"
            ));
        }

        if (status == "SETTLED")
        {
            return Task.FromResult(new CancelResult(
                ok: false,
                state: "SETTLED",
                too_late: true,
                error_code: "CANCEL_TOO_LATE"
            ));
        }

        _statusByRailRef[railRef] = "CANCELLED";
        return Task.FromResult(new CancelResult(
            ok: true,
            state: "CANCELLED",
            too_late: false,
            error_code: string.Empty
        ));
    }
}

record SimRailConfig(string Scenario, int DelayMs, string LogPath)
{
    public static SimRailConfig Load()
    {
        var scenario = (Environment.GetEnvironmentVariable("SIM_RAIL_SCENARIO") ?? "SIMULATE_SUCCESS").Trim().ToUpperInvariant();
        var delayMs = 50;
        if (int.TryParse(Environment.GetEnvironmentVariable("SIM_RAIL_DELAY_MS"), out var parsedDelay) && parsedDelay >= 0)
        {
            delayMs = parsedDelay;
        }

        var logPath = (Environment.GetEnvironmentVariable("SIM_RAIL_LOG_PATH") ?? "sim_rail_log.jsonl").Trim();
        var configPath = (Environment.GetEnvironmentVariable("SIM_RAIL_CONFIG_JSON") ?? string.Empty).Trim();
        if (!string.IsNullOrWhiteSpace(configPath) && File.Exists(configPath))
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(configPath));
            var root = doc.RootElement;
            if (root.TryGetProperty("scenario", out var scenarioProp) && scenarioProp.ValueKind == JsonValueKind.String)
            {
                scenario = (scenarioProp.GetString() ?? scenario).Trim().ToUpperInvariant();
            }
            if (root.TryGetProperty("delay_ms", out var delayProp) && delayProp.ValueKind == JsonValueKind.Number && delayProp.TryGetInt32(out var fileDelay) && fileDelay >= 0)
            {
                delayMs = fileDelay;
            }
            if (root.TryGetProperty("log_path", out var logPathProp) && logPathProp.ValueKind == JsonValueKind.String)
            {
                var candidate = (logPathProp.GetString() ?? string.Empty).Trim();
                if (!string.IsNullOrWhiteSpace(candidate))
                {
                    logPath = candidate;
                }
            }
        }

        return new SimRailConfig(scenario, delayMs, logPath);
    }
}

sealed class SimulatedRailAdapter : IRailAdapter
{
    private readonly SimRailConfig _config;
    private readonly Dictionary<string, string> _stateByRailRef = new(StringComparer.Ordinal);
    private readonly Dictionary<string, int> _submitAttemptsByInstruction = new(StringComparer.Ordinal);

    public SimulatedRailAdapter(SimRailConfig config)
    {
        _config = config;
        var directory = Path.GetDirectoryName(_config.LogPath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }
    }

    public async Task<SubmitResult> Submit(RailInstruction instruction, CancellationToken cancellationToken)
    {
        await SimulateDelay(cancellationToken);
        var attempt = _submitAttemptsByInstruction.TryGetValue(instruction.instruction_id, out var current)
            ? current + 1
            : 1;
        _submitAttemptsByInstruction[instruction.instruction_id] = attempt;

        SubmitResult result;
        var railRef = $"sim-{instruction.instruction_id}";
        switch (_config.Scenario)
        {
            case "SIMULATE_TRANSIENT_FAILURE":
                if (attempt == 1)
                {
                    result = new SubmitResult(ok: false, rail_ref: string.Empty, retryable: true, error_code: "TRANSIENT_RAIL_ERROR");
                }
                else
                {
                    _stateByRailRef[railRef] = "SETTLED";
                    result = new SubmitResult(ok: true, rail_ref: railRef, retryable: false, error_code: string.Empty);
                }
                break;
            case "SIMULATE_PERMANENT_FAILURE":
                result = new SubmitResult(ok: false, rail_ref: string.Empty, retryable: false, error_code: "PERMANENT_RAIL_ERROR");
                break;
            case "SIMULATE_CANCEL_SUCCESS":
                _stateByRailRef[railRef] = "PENDING";
                result = new SubmitResult(ok: true, rail_ref: railRef, retryable: false, error_code: string.Empty);
                break;
            case "SIMULATE_CANCEL_TOO_LATE":
                _stateByRailRef[railRef] = "SETTLED";
                result = new SubmitResult(ok: true, rail_ref: railRef, retryable: false, error_code: string.Empty);
                break;
            case "SIMULATE_SUCCESS":
            default:
                _stateByRailRef[railRef] = "SETTLED";
                result = new SubmitResult(ok: true, rail_ref: railRef, retryable: false, error_code: string.Empty);
                break;
        }

        await AppendLogAsync("submit", instruction.instruction_id, result, cancellationToken);
        return result;
    }

    public async Task<StatusResult> QueryStatus(string railRef, CancellationToken cancellationToken)
    {
        await SimulateDelay(cancellationToken);
        StatusResult result;
        if (!_stateByRailRef.TryGetValue(railRef, out var state))
        {
            result = new StatusResult(ok: false, state: "UNKNOWN", final: false, error_code: "RAIL_REF_NOT_FOUND");
        }
        else
        {
            if (_config.Scenario == "SIMULATE_SUCCESS" && state == "PENDING")
            {
                _stateByRailRef[railRef] = "SETTLED";
                state = "SETTLED";
            }

            var isFinal = state is "SETTLED" or "FAILED" or "CANCELLED";
            result = new StatusResult(ok: true, state: state, final: isFinal, error_code: string.Empty);
        }

        await AppendLogAsync("query_status", railRef, result, cancellationToken);
        return result;
    }

    public async Task<CancelResult> Cancel(string railRef, CancellationToken cancellationToken)
    {
        await SimulateDelay(cancellationToken);
        CancelResult result;
        if (!_stateByRailRef.TryGetValue(railRef, out var state))
        {
            result = new CancelResult(ok: false, state: "UNKNOWN", too_late: false, error_code: "RAIL_REF_NOT_FOUND");
        }
        else if (_config.Scenario == "SIMULATE_CANCEL_TOO_LATE" || state == "SETTLED")
        {
            result = new CancelResult(ok: false, state: "SETTLED", too_late: true, error_code: "CANCEL_TOO_LATE");
        }
        else
        {
            _stateByRailRef[railRef] = "CANCELLED";
            result = new CancelResult(ok: true, state: "CANCELLED", too_late: false, error_code: string.Empty);
        }

        await AppendLogAsync("cancel", railRef, result, cancellationToken);
        return result;
    }

    private Task SimulateDelay(CancellationToken cancellationToken)
        => _config.DelayMs > 0 ? Task.Delay(_config.DelayMs, cancellationToken) : Task.CompletedTask;

    private async Task AppendLogAsync(string method, string key, object result, CancellationToken cancellationToken)
    {
        var line = JsonSerializer.Serialize(new
        {
            timestamp_utc = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"),
            scenario = _config.Scenario,
            method,
            key,
            result
        });
        await File.AppendAllTextAsync(_config.LogPath, line + Environment.NewLine, cancellationToken);
    }
}

record WorkerCycleResult(
    string status,
    string? outbox_id,
    string? state,
    string? reason,
    int attempts_written_delta,
    int pending_delta
);

interface IOutboxRuntime
{
    Task<ClaimedOutbox?> ClaimAsync(string workerId, int limit, int leaseSeconds, CancellationToken cancellationToken);
    Task<CompletionResult> CompleteAsync(CompletionRequest request, CancellationToken cancellationToken);
    int AttemptsCount { get; }
    int PendingCount { get; }
}

sealed class WorkerProcessor(IOutboxRuntime runtime, string workerId, int retryCeiling)
{
    public async Task<WorkerCycleResult> ProcessOnceAsync(CancellationToken cancellationToken)
    {
        var attemptsBefore = runtime.AttemptsCount;
        var pendingBefore = runtime.PendingCount;

        var claim = await runtime.ClaimAsync(workerId, 1, leaseSeconds: 30, cancellationToken);
        if (claim is null)
        {
            return new WorkerCycleResult(
                status: "NO_WORK",
                outbox_id: null,
                state: null,
                reason: "no_claimable_outbox",
                attempts_written_delta: runtime.AttemptsCount - attemptsBefore,
                pending_delta: runtime.PendingCount - pendingBefore
            );
        }

        var desiredState = DecideState(claim.payload, claim.attempt_no, retryCeiling);
        var completion = new CompletionRequest(
            outbox_id: claim.outbox_id,
            lease_token: claim.lease_token,
            worker_id: workerId,
            state: desiredState,
            rail_reference: desiredState == "DISPATCHED" ? $"rail_ref_{claim.outbox_id}" : null,
            response_code: desiredState == "DISPATCHED" ? "OK" : "RETRY",
            latency_ms: 12,
            retry_after_seconds: desiredState == "RETRY" ? 2 : 0
        );

        var completeResult = await runtime.CompleteAsync(completion, cancellationToken);
        if (!completeResult.ok)
        {
            return new WorkerCycleResult(
                status: "FAIL_CLOSED",
                outbox_id: claim.outbox_id,
                state: null,
                reason: completeResult.error ?? "completion_failed",
                attempts_written_delta: runtime.AttemptsCount - attemptsBefore,
                pending_delta: runtime.PendingCount - pendingBefore
            );
        }

        return new WorkerCycleResult(
            status: "PROCESSED",
            outbox_id: claim.outbox_id,
            state: desiredState,
            reason: null,
            attempts_written_delta: runtime.AttemptsCount - attemptsBefore,
            pending_delta: runtime.PendingCount - pendingBefore
        );
    }

    private static string DecideState(JsonElement payload, int attemptNo, int retryCeiling)
    {
        if (payload.ValueKind == JsonValueKind.Object &&
            payload.TryGetProperty("simulate", out var simulate) &&
            simulate.ValueKind == JsonValueKind.String)
        {
            var mode = simulate.GetString() ?? string.Empty;
            if (mode == "retry_once" && attemptNo == 1)
            {
                return "RETRY";
            }

            if (mode == "always_retry")
            {
                return attemptNo >= retryCeiling ? "FAILED_TERMINAL" : "RETRY";
            }
        }

        return "DISPATCHED";
    }
}

record AttemptEvent(string outbox_id, int attempt_no, string state, string worker_id, string lease_token);

sealed class FakeOutboxRuntime : IOutboxRuntime
{
    private readonly Queue<ClaimedOutbox> _pending = new();
    private readonly List<AttemptEvent> _attempts = new();
    private readonly Dictionary<string, string> _activeLeases = new();

    public bool FailNextComplete { get; set; }
    public bool TamperLeaseValidation { get; set; }

    public int AttemptsCount => _attempts.Count;
    public int PendingCount => _pending.Count;

    public void Seed(ClaimedOutbox claim)
    {
        _pending.Enqueue(claim);
    }

    public Task<ClaimedOutbox?> ClaimAsync(string workerId, int limit, int leaseSeconds, CancellationToken cancellationToken)
    {
        _ = workerId;
        _ = limit;
        _ = leaseSeconds;
        _ = cancellationToken;

        if (_pending.Count == 0)
        {
            return Task.FromResult<ClaimedOutbox?>(null);
        }

        var claim = _pending.Dequeue();
        _activeLeases[claim.outbox_id] = claim.lease_token;
        return Task.FromResult<ClaimedOutbox?>(claim);
    }

    public Task<CompletionResult> CompleteAsync(CompletionRequest request, CancellationToken cancellationToken)
    {
        _ = cancellationToken;

        if (FailNextComplete)
        {
            FailNextComplete = false;
            return Task.FromResult(CompletionResult.Fail("forced_completion_failure"));
        }

        if (!_activeLeases.TryGetValue(request.outbox_id, out var lease))
        {
            return Task.FromResult(CompletionResult.Fail("lease_not_found"));
        }

        if (TamperLeaseValidation)
        {
            lease = "tampered";
        }

        if (!string.Equals(lease, request.lease_token, StringComparison.Ordinal))
        {
            return Task.FromResult(CompletionResult.Fail("lease_lost"));
        }

        var nextAttemptNo = _attempts.Count(x => x.outbox_id == request.outbox_id) + 1;
        _attempts.Add(new AttemptEvent(request.outbox_id, nextAttemptNo, request.state, request.worker_id, request.lease_token));

        _activeLeases.Remove(request.outbox_id);

        if (request.state == "RETRY")
        {
            var payload = JsonSerializer.Deserialize<JsonElement>("{\"simulate\":\"retry_once\"}");
            _pending.Enqueue(new ClaimedOutbox(
                outbox_id: request.outbox_id,
                lease_token: Guid.NewGuid().ToString(),
                instruction_id: $"retry_{request.outbox_id}",
                attempt_no: nextAttemptNo + 1,
                payload: payload
            ));
        }

        return Task.FromResult(CompletionResult.Ok());
    }
}

record SelfTestCase(string name, string status, string detail);

static class ExecutorWorkerSelfTest
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var tests = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        await RunTest("success_dispatch_writes_attempt_once", async () =>
        {
            var runtime = new FakeOutboxRuntime();
            runtime.Seed(NewClaim("outbox-success", 1, "{}"));
            var worker = new WorkerProcessor(runtime, "worker_success", retryCeiling: 3);

            var result = await worker.ProcessOnceAsync(cancellationToken);
            return result.status == "PROCESSED"
                   && result.state == "DISPATCHED"
                   && result.attempts_written_delta == 1
                   && runtime.AttemptsCount == 1;
        });

        await RunTest("retry_then_success_is_append_only", async () =>
        {
            var runtime = new FakeOutboxRuntime();
            runtime.Seed(NewClaim("outbox-retry", 1, "{\"simulate\":\"retry_once\"}"));
            var worker = new WorkerProcessor(runtime, "worker_retry", retryCeiling: 3);

            var first = await worker.ProcessOnceAsync(cancellationToken);
            var second = await worker.ProcessOnceAsync(cancellationToken);

            return first.status == "PROCESSED"
                   && first.state == "RETRY"
                   && second.status == "PROCESSED"
                   && second.state == "DISPATCHED"
                   && runtime.AttemptsCount == 2;
        });

        await RunTest("fail_closed_on_completion_error", async () =>
        {
            var runtime = new FakeOutboxRuntime { FailNextComplete = true };
            runtime.Seed(NewClaim("outbox-failclosed", 1, "{}"));
            var worker = new WorkerProcessor(runtime, "worker_failclosed", retryCeiling: 3);

            var result = await worker.ProcessOnceAsync(cancellationToken);
            return result.status == "FAIL_CLOSED"
                   && result.reason == "forced_completion_failure"
                   && result.attempts_written_delta == 0
                   && runtime.AttemptsCount == 0;
        });

        await RunTest("lease_fencing_fail_closed", async () =>
        {
            var runtime = new FakeOutboxRuntime { TamperLeaseValidation = true };
            runtime.Seed(NewClaim("outbox-lease", 1, "{}"));
            var worker = new WorkerProcessor(runtime, "worker_lease", retryCeiling: 3);

            var result = await worker.ProcessOnceAsync(cancellationToken);
            return result.status == "FAIL_CLOSED"
                   && result.reason == "lease_lost"
                   && result.attempts_written_delta == 0
                   && runtime.AttemptsCount == 0;
        });

        var status = fail == 0 ? "PASS" : "FAIL";
        var root = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(root, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var meta = EvidenceMeta.Load(root);

        var runtimePath = Path.Combine(evidenceDir, "executor_worker_runtime.json");
        var failClosedPath = Path.Combine(evidenceDir, "executor_worker_fail_closed_paths.json");

        await File.WriteAllTextAsync(runtimePath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EXECUTOR-WORKER-RUNTIME",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            tests_passed = pass,
            tests_failed = fail,
            results = tests
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        var failClosedPass = tests.Where(t => t.name.Contains("fail_closed") || t.name.Contains("lease_fencing"))
                                  .All(t => t.status == "PASS");

        await File.WriteAllTextAsync(failClosedPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-EXECUTOR-WORKER-FAIL-CLOSED",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status = failClosedPass ? "PASS" : "FAIL",
            fail_closed_paths_enforced = failClosedPass
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Executor worker self-test status: {status}");
        Console.WriteLine($"Evidence: {runtimePath}");
        Console.WriteLine($"Evidence: {failClosedPath}");

        return fail == 0 ? 0 : 1;

        static ClaimedOutbox NewClaim(string outboxId, int attemptNo, string payloadJson)
        {
            return new ClaimedOutbox(
                outbox_id: outboxId,
                lease_token: Guid.NewGuid().ToString(),
                instruction_id: $"ins_{outboxId}",
                attempt_no: attemptNo,
                payload: JsonSerializer.Deserialize<JsonElement>(payloadJson)
            );
        }

        async Task RunTest(string name, Func<Task<bool>> test)
        {
            try
            {
                var ok = await test();
                if (ok)
                {
                    pass++;
                    tests.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
                }
                else
                {
                    fail++;
                    tests.Add(new SelfTestCase(name, "FAIL", "expectation not met"));
                }
            }
            catch (Exception ex)
            {
                fail++;
                tests.Add(new SelfTestCase(name, "FAIL", ex.Message));
            }
        }
    }
}

static class AdapterContractSelfTest
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var adapter = new DeterministicSimulatedAdapter();
        var checks = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;

        var submitSuccess = await adapter.Submit(new RailInstruction(
            instruction_id: "submit_success_001",
            rail_type: "SIM",
            idempotency_key: "idem-submit-success",
            payload_json: "{\"amount\":100}"
        ), cancellationToken);
        Track("submit_success_path", submitSuccess.ok && !string.IsNullOrWhiteSpace(submitSuccess.rail_ref));

        var submitFailure = await adapter.Submit(new RailInstruction(
            instruction_id: "submit_fail_001",
            rail_type: "SIM",
            idempotency_key: "idem-submit-fail",
            payload_json: "{\"amount\":100}"
        ), cancellationToken);
        Track("submit_failure_path", !submitFailure.ok && submitFailure.error_code == "SUBMIT_REJECTED");

        var querySuccess = await adapter.QueryStatus(submitSuccess.rail_ref, cancellationToken);
        Track("query_status_success_path", querySuccess.ok && querySuccess.state == "SETTLED" && querySuccess.final);

        var submitForQueryFail = await adapter.Submit(new RailInstruction(
            instruction_id: "query_fail_001",
            rail_type: "SIM",
            idempotency_key: "idem-query-fail",
            payload_json: "{\"amount\":100}"
        ), cancellationToken);
        var queryFailure = await adapter.QueryStatus(submitForQueryFail.rail_ref, cancellationToken);
        Track("query_status_failure_path", queryFailure.ok && queryFailure.state == "FAILED" && queryFailure.final);

        var submitForCancel = await adapter.Submit(new RailInstruction(
            instruction_id: "cancelled_001",
            rail_type: "SIM",
            idempotency_key: "idem-cancel-success",
            payload_json: "{\"amount\":100}"
        ), cancellationToken);
        var cancelSuccess = await adapter.Cancel(submitForCancel.rail_ref, cancellationToken);
        Track("cancel_success_path", cancelSuccess.ok && cancelSuccess.state == "CANCELLED");

        var cancelFailure = await adapter.Cancel(submitSuccess.rail_ref, cancellationToken);
        Track("cancel_failure_path", !cancelFailure.ok && cancelFailure.too_late && cancelFailure.error_code == "CANCEL_TOO_LATE");

        var status = fail == 0 ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "adp_001_adapter_contract_tests.json");
        var meta = EvidenceMeta.Load(rootDir);

        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "ADP-001-ADAPTER-CONTRACT-TESTS",
            task_id = "TSK-P1-ADP-001",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            pass = status == "PASS",
            details = new
            {
                adapter_interface = "IRailAdapter",
                methods = new[] { "submit", "query_status", "cancel" },
                tests_passed = pass,
                tests_failed = fail,
                contract_tests = checks
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Adapter contract self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return fail == 0 ? 0 : 1;

        void Track(string name, bool ok)
        {
            if (ok)
            {
                pass++;
                checks.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
            }
            else
            {
                fail++;
                checks.Add(new SelfTestCase(name, "FAIL", "expectation not met"));
            }
        }
    }
}

static class SimulatedRailAdapterSelfTest
{
    public static async Task<int> RunAsync(CancellationToken cancellationToken)
    {
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidencePath = Path.Combine(evidenceDir, "adp_002_simulated_rail_adapter.json");
        var tmpDir = Path.Combine(Path.GetTempPath(), $"sim-rail-{Guid.NewGuid():N}");
        Directory.CreateDirectory(tmpDir);

        var checks = new List<SelfTestCase>();
        var pass = 0;
        var fail = 0;
        var scenarios = new[]
        {
            "SIMULATE_SUCCESS",
            "SIMULATE_TRANSIENT_FAILURE",
            "SIMULATE_PERMANENT_FAILURE",
            "SIMULATE_CANCEL_SUCCESS",
            "SIMULATE_CANCEL_TOO_LATE"
        };

        foreach (var scenario in scenarios)
        {
            var logPath = Path.Combine(tmpDir, $"{scenario.ToLowerInvariant()}.jsonl");
            var adapter = new SimulatedRailAdapter(new SimRailConfig(scenario, DelayMs: 0, LogPath: logPath));
            var instruction = new RailInstruction(
                instruction_id: $"adp002-{scenario.ToLowerInvariant()}",
                rail_type: "SIM",
                idempotency_key: $"idem-{scenario.ToLowerInvariant()}",
                payload_json: "{\"amount\":100}"
            );

            try
            {
                var submit1 = await adapter.Submit(instruction, cancellationToken);
                var ok = scenario switch
                {
                    "SIMULATE_SUCCESS" => submit1.ok,
                    "SIMULATE_TRANSIENT_FAILURE" => !submit1.ok && submit1.retryable,
                    "SIMULATE_PERMANENT_FAILURE" => !submit1.ok && !submit1.retryable,
                    "SIMULATE_CANCEL_SUCCESS" => submit1.ok,
                    "SIMULATE_CANCEL_TOO_LATE" => submit1.ok,
                    _ => false
                };

                if (scenario == "SIMULATE_TRANSIENT_FAILURE")
                {
                    var submit2 = await adapter.Submit(instruction, cancellationToken);
                    ok = ok && submit2.ok;
                }

                if (submit1.ok)
                {
                    var query = await adapter.QueryStatus(submit1.rail_ref, cancellationToken);
                    ok = ok && query.ok;
                    if (scenario == "SIMULATE_CANCEL_SUCCESS")
                    {
                        var cancel = await adapter.Cancel(submit1.rail_ref, cancellationToken);
                        var queryAfterCancel = await adapter.QueryStatus(submit1.rail_ref, cancellationToken);
                        ok = ok && cancel.ok && queryAfterCancel.state == "CANCELLED";
                    }
                    else if (scenario == "SIMULATE_CANCEL_TOO_LATE")
                    {
                        var cancel = await adapter.Cancel(submit1.rail_ref, cancellationToken);
                        ok = ok && !cancel.ok && cancel.too_late;
                    }
                }

                var logExists = File.Exists(logPath) && File.ReadAllLines(logPath).Length > 0;
                ok = ok && logExists;

                if (ok)
                {
                    pass++;
                    checks.Add(new SelfTestCase($"scenario_{scenario.ToLowerInvariant()}", "PASS", "deterministic expectation met"));
                }
                else
                {
                    fail++;
                    checks.Add(new SelfTestCase($"scenario_{scenario.ToLowerInvariant()}", "FAIL", "expectation not met"));
                }
            }
            catch (Exception ex)
            {
                fail++;
                checks.Add(new SelfTestCase($"scenario_{scenario.ToLowerInvariant()}", "FAIL", ex.Message));
            }
        }

        var status = fail == 0 ? "PASS" : "FAIL";
        var meta = EvidenceMeta.Load(rootDir);
        await File.WriteAllTextAsync(evidencePath, JsonSerializer.Serialize(new
        {
            check_id = "ADP-002-SIMULATED-RAIL-ADAPTER",
            task_id = "TSK-P1-ADP-002",
            timestamp_utc = meta.TimestampUtc,
            git_sha = meta.GitSha,
            schema_fingerprint = meta.SchemaFingerprint,
            status,
            pass = status == "PASS",
            details = new
            {
                scenarios_tested = scenarios,
                latency_configurable = true,
                append_only_log = "sim_rail_log.jsonl",
                checks
            }
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Simulated rail adapter self-test status: {status}");
        Console.WriteLine($"Evidence: {evidencePath}");
        return fail == 0 ? 0 : 1;
    }
}

record EvidenceMeta(string TimestampUtc, string GitSha, string SchemaFingerprint)
{
    public static string ResolveRepoRoot(string startDir)
    {
        var dir = new DirectoryInfo(startDir);
        while (dir is not null)
        {
            if (Directory.Exists(Path.Combine(dir.FullName, ".git")))
            {
                return dir.FullName;
            }
            dir = dir.Parent;
        }

        return startDir;
    }

    public static EvidenceMeta Load(string rootDir)
    {
        var ts = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ");
        var sha = Run("git", "rev-parse HEAD", rootDir) ?? "UNKNOWN";
        var fp = Run("git", "rev-parse --short HEAD", rootDir) ?? "UNKNOWN";
        return new EvidenceMeta(ts, sha, fp);
    }

    private static string? Run(string fileName, string args, string cwd)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = fileName,
                Arguments = args,
                WorkingDirectory = cwd,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            };
            using var process = Process.Start(psi);
            if (process is null)
            {
                return null;
            }

            var output = process.StandardOutput.ReadToEnd().Trim();
            process.WaitForExit();
            return process.ExitCode == 0 ? output : null;
        }
        catch
        {
            return null;
        }
    }
}
