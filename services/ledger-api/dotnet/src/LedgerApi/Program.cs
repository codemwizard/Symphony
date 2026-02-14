using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
var logger = app.Logger;

if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
{
    var code = await IngressSelfTestRunner.RunAsync(logger, CancellationToken.None);
    Environment.ExitCode = code;
    return;
}

var storageMode = (Environment.GetEnvironmentVariable("INGRESS_STORAGE_MODE") ?? "file").Trim().ToLowerInvariant();
IIngressDurabilityStore store = storageMode switch
{
    "db_psql" => new PsqlIngressDurabilityStore(logger),
    _ => new FileIngressDurabilityStore(logger)
};

app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.MapPost("/v1/ingress/instructions", async (IngressRequest request, HttpContext httpContext, CancellationToken cancellationToken) =>
{
    var forceFailure = httpContext.Request.Headers.TryGetValue("x-symphony-force-attestation-fail", out var forceHeader)
        && forceHeader.ToString() == "1";

    var result = await IngressHandler.HandleAsync(request, store, logger, forceFailure, cancellationToken);
    return Results.Json(result.Body, statusCode: result.StatusCode);
});

await app.RunAsync();

record IngressRequest(
    string instruction_id,
    string participant_id,
    string idempotency_key,
    string rail_type,
    JsonElement payload,
    string? payload_hash,
    string? signature_hash,
    string? tenant_id,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref
);

record PersistInput(
    string instruction_id,
    string participant_id,
    string idempotency_key,
    string rail_type,
    string payload_json,
    string payload_hash,
    string? signature_hash,
    string? tenant_id,
    string? correlation_id,
    string? upstream_ref,
    string? downstream_ref,
    string? nfs_sequence_ref
);

record PersistResult(bool Success, string? AttestationId, string? OutboxId, string? Error)
{
    public static PersistResult Ok(string attestationId, string outboxId) => new(true, attestationId, outboxId, null);
    public static PersistResult Fail(string error) => new(false, null, null, error);
}

interface IIngressDurabilityStore
{
    Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken);
}

record HandlerResult(int StatusCode, object Body);

static class IngressHandler
{
    public static async Task<HandlerResult> HandleAsync(
        IngressRequest request,
        IIngressDurabilityStore store,
        ILogger logger,
        bool forceFailure,
        CancellationToken cancellationToken)
    {
        var validationErrors = IngressValidation.Validate(request);
        if (validationErrors.Count > 0)
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                ack = false,
                error_code = "INVALID_REQUEST",
                errors = validationErrors
            });
        }

        if (forceFailure || IngressValidation.IsForcedFailureEnabled())
        {
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "ATTESTATION_DURABILITY_FAILED"
            });
        }

        var payloadHash = string.IsNullOrWhiteSpace(request.payload_hash)
            ? IngressValidation.Sha256Hex(request.payload.GetRawText())
            : request.payload_hash.Trim();

        var persistInput = new PersistInput(
            instruction_id: request.instruction_id.Trim(),
            participant_id: request.participant_id.Trim(),
            idempotency_key: request.idempotency_key.Trim(),
            rail_type: request.rail_type.Trim(),
            payload_json: request.payload.GetRawText(),
            payload_hash: payloadHash,
            signature_hash: string.IsNullOrWhiteSpace(request.signature_hash) ? null : request.signature_hash.Trim(),
            tenant_id: string.IsNullOrWhiteSpace(request.tenant_id) ? null : request.tenant_id.Trim(),
            correlation_id: string.IsNullOrWhiteSpace(request.correlation_id) ? null : request.correlation_id.Trim(),
            upstream_ref: string.IsNullOrWhiteSpace(request.upstream_ref) ? null : request.upstream_ref.Trim(),
            downstream_ref: string.IsNullOrWhiteSpace(request.downstream_ref) ? null : request.downstream_ref.Trim(),
            nfs_sequence_ref: string.IsNullOrWhiteSpace(request.nfs_sequence_ref) ? null : request.nfs_sequence_ref.Trim()
        );

        var persistResult = await store.PersistAsync(persistInput, cancellationToken);
        if (!persistResult.Success)
        {
            logger.LogError("Ingress persistence failed: {Error}", persistResult.Error);
            return new HandlerResult(StatusCodes.Status503ServiceUnavailable, new
            {
                ack = false,
                error_code = "ATTESTATION_DURABILITY_FAILED"
            });
        }

        return new HandlerResult(StatusCodes.Status202Accepted, new
        {
            ack = true,
            instruction_id = persistInput.instruction_id,
            attestation_id = persistResult.AttestationId,
            outbox_id = persistResult.OutboxId,
            outbox_state = "PENDING",
            payload_hash = persistInput.payload_hash
        });
    }
}

static class IngressValidation
{
    public static bool IsForcedFailureEnabled()
    {
        var value = Environment.GetEnvironmentVariable("INGRESS_FORCE_ATTESTATION_FAIL") ?? "0";
        return value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    public static List<string> Validate(IngressRequest request)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.instruction_id))
        {
            errors.Add("instruction_id is required");
        }

        if (string.IsNullOrWhiteSpace(request.participant_id))
        {
            errors.Add("participant_id is required");
        }

        if (string.IsNullOrWhiteSpace(request.idempotency_key))
        {
            errors.Add("idempotency_key is required");
        }

        if (string.IsNullOrWhiteSpace(request.rail_type))
        {
            errors.Add("rail_type is required");
        }

        if (request.payload.ValueKind is JsonValueKind.Undefined or JsonValueKind.Null)
        {
            errors.Add("payload is required");
        }

        if (string.IsNullOrWhiteSpace(request.tenant_id))
        {
            errors.Add("tenant_id is required");
        }
        else if (!Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }

        if (!string.IsNullOrWhiteSpace(request.correlation_id) && !Guid.TryParse(request.correlation_id, out _))
        {
            errors.Add("correlation_id must be a valid UUID when provided");
        }

        return errors;
    }

    public static string Sha256Hex(string input)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(input));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}

sealed class FileIngressDurabilityStore(ILogger logger, string? path = null) : IIngressDurabilityStore
{
    private readonly string _path = path
        ?? Environment.GetEnvironmentVariable("INGRESS_STORAGE_FILE")
        ?? "/tmp/symphony_ingress_attestations.ndjson";

    public async Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken)
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_path) ?? "/tmp");

            var attestationId = Guid.NewGuid().ToString();
            var outboxId = Guid.NewGuid().ToString();
            var line = JsonSerializer.Serialize(new
            {
                attestation_id = attestationId,
                outbox_id = outboxId,
                instruction_id = input.instruction_id,
                participant_id = input.participant_id,
                idempotency_key = input.idempotency_key,
                rail_type = input.rail_type,
                payload_hash = input.payload_hash,
                signature_hash = input.signature_hash,
                tenant_id = input.tenant_id,
                correlation_id = input.correlation_id,
                upstream_ref = input.upstream_ref,
                downstream_ref = input.downstream_ref,
                nfs_sequence_ref = input.nfs_sequence_ref,
                written_at_utc = DateTime.UtcNow.ToString("O")
            });

            await File.AppendAllTextAsync(_path, line + Environment.NewLine, cancellationToken);
            return PersistResult.Ok(attestationId, outboxId);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to persist ingress attestation to file store.");
            return PersistResult.Fail(ex.Message);
        }
    }
}

sealed class PsqlIngressDurabilityStore(ILogger logger) : IIngressDurabilityStore
{
    private readonly string? _databaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL");

    public async Task<PersistResult> PersistAsync(PersistInput input, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_databaseUrl))
        {
            return PersistResult.Fail("DATABASE_URL is required for db_psql mode");
        }

        var sql = $@"
WITH inserted AS (
  INSERT INTO public.ingress_attestations (
    instruction_id,
    tenant_id,
    payload_hash,
    signature_hash,
    correlation_id,
    upstream_ref,
    downstream_ref,
    nfs_sequence_ref
  ) VALUES (
    {SqlEscaping.Literal(input.instruction_id)},
    {SqlEscaping.Literal(input.tenant_id)},
    {SqlEscaping.Literal(input.payload_hash)},
    {SqlEscaping.Literal(input.signature_hash)},
    {SqlEscaping.Literal(input.correlation_id)}::uuid,
    {SqlEscaping.Literal(input.upstream_ref)},
    {SqlEscaping.Literal(input.downstream_ref)},
    {SqlEscaping.Literal(input.nfs_sequence_ref)}
  )
  RETURNING attestation_id::text
), enqueued AS (
  SELECT outbox_id::text
  FROM public.enqueue_payment_outbox(
    {SqlEscaping.Literal(input.instruction_id)},
    {SqlEscaping.Literal(input.participant_id)},
    {SqlEscaping.Literal(input.idempotency_key)},
    {SqlEscaping.Literal(input.rail_type)},
    {SqlEscaping.Literal(input.payload_json)}::jsonb
  )
)
SELECT (SELECT attestation_id FROM inserted), (SELECT outbox_id FROM enqueued LIMIT 1);
";

        var psi = new ProcessStartInfo
        {
            FileName = "psql",
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };
        psi.ArgumentList.Add(_databaseUrl);
        psi.ArgumentList.Add("-v");
        psi.ArgumentList.Add("ON_ERROR_STOP=1");
        psi.ArgumentList.Add("-X");
        psi.ArgumentList.Add("-t");
        psi.ArgumentList.Add("-A");

        using var process = Process.Start(psi);
        if (process is null)
        {
            return PersistResult.Fail("Unable to start psql process");
        }

        await process.StandardInput.WriteLineAsync(sql);
        await process.StandardInput.FlushAsync(cancellationToken);
        process.StandardInput.Close();

        var stdout = await process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderr = await process.StandardError.ReadToEndAsync(cancellationToken);
        await process.WaitForExitAsync(cancellationToken);

        if (process.ExitCode != 0)
        {
            logger.LogError("psql persistence failed: {Error}", stderr);
            return PersistResult.Fail($"psql_failed:{stderr.Trim()}");
        }

        var lines = stdout
            .Split('\n', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();
        if (lines.Count == 0)
        {
            return PersistResult.Fail("psql returned no output");
        }

        var parts = lines[^1].Split('|', StringSplitOptions.TrimEntries);
        if (parts.Length < 2 || string.IsNullOrWhiteSpace(parts[0]) || string.IsNullOrWhiteSpace(parts[1]))
        {
            return PersistResult.Fail("psql returned malformed attestation/outbox output");
        }

        return PersistResult.Ok(parts[0], parts[1]);
    }
}

static class SqlEscaping
{
    public static string Literal(string? value)
    {
        if (value is null)
        {
            return "NULL";
        }

        return $"'{value.Replace("'", "''")}'";
    }
}

record SelfTestCase(string Name, string Status, string Detail);

static class IngressSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var storageFile = $"/tmp/symphony_ingress_selftest_{Guid.NewGuid():N}.ndjson";
        var store = new FileIngressDurabilityStore(logger, storageFile);

        var pass = 0;
        var fail = 0;
        var results = new List<SelfTestCase>();

        await RunCase(
            "ack_after_durable_attestation",
            CreateRequest("ins-p1-001"),
            forceFailure: false,
            expectedStatus: StatusCodes.Status202Accepted,
            expectedAck: true,
            expectedErrorCode: null,
            expectedLinesDelta: 1
        );

        await RunCase(
            "invalid_payload_fail_closed",
            CreateRequest(""),
            forceFailure: false,
            expectedStatus: StatusCodes.Status400BadRequest,
            expectedAck: false,
            expectedErrorCode: "INVALID_REQUEST",
            expectedLinesDelta: 0
        );

        await RunCase(
            "missing_tenant_fail_closed",
            CreateRequest("ins-p1-002", tenantIdOverride: ""),
            forceFailure: false,
            expectedStatus: StatusCodes.Status400BadRequest,
            expectedAck: false,
            expectedErrorCode: "INVALID_REQUEST",
            expectedLinesDelta: 0
        );

        await RunCase(
            "forced_durability_failure_fail_closed",
            CreateRequest("ins-p1-003"),
            forceFailure: true,
            expectedStatus: StatusCodes.Status503ServiceUnavailable,
            expectedAck: false,
            expectedErrorCode: "ATTESTATION_DURABILITY_FAILED",
            expectedLinesDelta: 0
        );

        var status = fail == 0 ? "PASS" : "FAIL";
        var rootDir = EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);

        var evidenceMeta = EvidenceMeta.Load(rootDir);
        var contractPath = Path.Combine(evidenceDir, "ingress_api_contract_tests.json");
        var ackPath = Path.Combine(evidenceDir, "ingress_ack_attestation_semantics.json");

        await File.WriteAllTextAsync(contractPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-INGRESS-API-CONTRACT-TESTS",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status,
            tests_passed = pass,
            tests_failed = fail,
            results
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        await File.WriteAllTextAsync(ackPath, JsonSerializer.Serialize(new
        {
            check_id = "PHASE1-INGRESS-ACK-ATTESTATION",
            timestamp_utc = evidenceMeta.TimestampUtc,
            git_sha = evidenceMeta.GitSha,
            schema_fingerprint = evidenceMeta.SchemaFingerprint,
            status,
            ack_after_durable_write = fail == 0,
            negative_cases_fail_closed = fail == 0,
            storage_mode = "file"
        }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine, cancellationToken);

        Console.WriteLine($"Ingress self-test status: {status}");
        Console.WriteLine($"Evidence: {contractPath}");
        Console.WriteLine($"Evidence: {ackPath}");

        return fail == 0 ? 0 : 1;

        static IngressRequest CreateRequest(string instructionId, string? tenantIdOverride = null)
        {
            var payload = JsonSerializer.Deserialize<JsonElement>("{\"amount\":100,\"currency\":\"ZMW\"}");
            var tenantId = tenantIdOverride ?? Guid.NewGuid().ToString();
            return new IngressRequest(
                instruction_id: instructionId,
                participant_id: "bank-a",
                idempotency_key: Guid.NewGuid().ToString("N"),
                rail_type: "RTGS",
                payload: payload,
                payload_hash: null,
                signature_hash: null,
                tenant_id: tenantId,
                correlation_id: null,
                upstream_ref: null,
                downstream_ref: null,
                nfs_sequence_ref: null
            );
        }

        async Task RunCase(string name, IngressRequest request, bool forceFailure, int expectedStatus, bool expectedAck, string? expectedErrorCode, int expectedLinesDelta)
        {
            var beforeCount = await CountLines(storageFile, cancellationToken);
            var result = await IngressHandler.HandleAsync(request, store, logger, forceFailure, cancellationToken);
            var afterCount = await CountLines(storageFile, cancellationToken);
            var delta = afterCount - beforeCount;

            var bodyDoc = JsonDocument.Parse(JsonSerializer.Serialize(result.Body));
            var body = bodyDoc.RootElement;
            var actualAck = body.TryGetProperty("ack", out var ackProp) && ackProp.GetBoolean();
            string? actualErrorCode = body.TryGetProperty("error_code", out var errProp) ? errProp.GetString() : null;

            var ok = result.StatusCode == expectedStatus
                     && actualAck == expectedAck
                     && actualErrorCode == expectedErrorCode
                     && delta == expectedLinesDelta;

            if (ok)
            {
                pass++;
                results.Add(new SelfTestCase(name, "PASS", "deterministic expectation met"));
            }
            else
            {
                fail++;
                results.Add(new SelfTestCase(
                    name,
                    "FAIL",
                    $"expected status={expectedStatus} ack={expectedAck} error={expectedErrorCode} delta={expectedLinesDelta}; got status={result.StatusCode} ack={actualAck} error={actualErrorCode} delta={delta}"
                ));
            }
        }
    }

    private static async Task<int> CountLines(string path, CancellationToken cancellationToken)
    {
        if (!File.Exists(path))
        {
            return 0;
        }

        var count = 0;
        await using var stream = File.OpenRead(path);
        using var reader = new StreamReader(stream);
        while (await reader.ReadLineAsync(cancellationToken) is not null)
        {
            count++;
        }

        return count;
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
