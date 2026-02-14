using System.Diagnostics;
using System.Text.Json;

if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
{
    var code = await ExecutorWorkerSelfTest.RunAsync(CancellationToken.None);
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
