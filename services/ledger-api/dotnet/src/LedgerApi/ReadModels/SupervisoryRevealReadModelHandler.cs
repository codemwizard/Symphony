using System.Text.Json;

static class SupervisoryRevealReadModelHandler
{
    public static HandlerResult Handle(string tenantId, string programId)
    {
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(programId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "tenant/program context required" }
            });
        }

        var submissions = EvidenceLinkSubmissionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId))
            .ToArray();

        var exceptions = DemoExceptionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId) && Matches(x, "program_id", programId))
            .ToArray();

        var timelines = new List<object>();
        timelines.AddRange(submissions.Select(x => new
        {
            event_type = "EVIDENCE_SUBMITTED",
            instruction_id = ReadString(x, "instruction_id"),
            artifact_type = ReadString(x, "artifact_type"),
            observed_at_utc = ReadString(x, "submitted_at_utc")
        }));
        timelines.AddRange(exceptions.Select(x => new
        {
            event_type = "EXCEPTION",
            instruction_id = ReadString(x, "instruction_id"),
            error_code = ReadString(x, "error_code"),
            observed_at_utc = ReadString(x, "recorded_at_utc")
        }));

        var orderedTimeline = timelines
            .OrderBy(x => x.GetType().GetProperty("observed_at_utc")?.GetValue(x)?.ToString())
            .ToArray();

        var presentTypes = submissions
            .Select(x => ReadString(x, "artifact_type"))
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        var requiredTypes = new[] { "INVOICE", "DELIVERY_PHOTO", "BORROWER_ACK" };
        var completeness = requiredTypes.Select(required => new
        {
            artifact_type = required,
            status = presentTypes.Contains(required) ? "PRESENT" : "MISSING"
        }).ToArray();

        var payload = new
        {
            tenant_id = tenantId,
            program_id = programId,
            programme_summary = new
            {
                evidence_submissions = submissions.Length,
                exception_count = exceptions.Length,
                timeline_events = orderedTimeline.Length
            },
            timeline = orderedTimeline,
            evidence_completeness = completeness,
            exception_log = exceptions.Select(x => new
            {
                instruction_id = ReadString(x, "instruction_id"),
                supplier_id = ReadString(x, "supplier_id"),
                error_code = ReadString(x, "error_code"),
                recorded_at_utc = ReadString(x, "recorded_at_utc")
            }).ToArray(),
            as_of_utc = DateTimeOffset.UtcNow.ToString("O"),
            read_only = true
        };

        return new HandlerResult(StatusCodes.Status200OK, payload);
    }

    private static bool Matches(JsonElement element, string key, string expected)
        => string.Equals(ReadString(element, key), expected, StringComparison.Ordinal);

    private static string ReadString(JsonElement element, string key)
        => element.TryGetProperty(key, out var value) ? value.GetString() ?? string.Empty : string.Empty;
}
