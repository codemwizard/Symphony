using System.Text.Json;

static class SupervisoryRevealReadModelHandler
{
    public static HandlerResult Handle(string tenantId, string programId)
    {
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(programId))
        {
            return InvalidRequest();
        }

        var model = SupervisoryProofModel.BuildProgrammeModel(tenantId, programId);
        var payload = new
        {
            tenant_id = tenantId,
            program_id = programId,
            programme_summary = new
            {
                evidence_submissions = model.Submissions.Length,
                exception_count = model.Exceptions.Length,
                timeline_events = model.Timeline.Length
            },
            timeline = model.Timeline,
            evidence_completeness = model.EvidenceCompleteness,
            exception_log = model.ExceptionLog,
            proof_rows = model.ProofRows,
            as_of_utc = DateTimeOffset.UtcNow.ToString("O"),
            read_only = true
        };

        return new HandlerResult(StatusCodes.Status200OK, payload);
    }

    private static HandlerResult InvalidRequest()
        => new(StatusCodes.Status400BadRequest, new
        {
            error_code = "INVALID_REQUEST",
            errors = new[] { "tenant/program context required" }
        });
}

static class SupervisoryInstructionDetailReadModelHandler
{
    public static HandlerResult Handle(string tenantId, string instructionId)
    {
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(instructionId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "tenant/instruction context required" }
            });
        }

        var detail = SupervisoryProofModel.BuildInstructionDetail(tenantId, instructionId);
        if (detail is null)
        {
            return new HandlerResult(StatusCodes.Status404NotFound, new
            {
                error_code = "INSTRUCTION_NOT_FOUND",
                instruction_id = instructionId
            });
        }

        return new HandlerResult(StatusCodes.Status200OK, detail);
    }
}

file static class SupervisoryProofModel
{
    private static readonly ProofSpec[] ProofSpecs =
    {
        new("PT-001", "Supplier Invoice", "INVOICE"),
        new("PT-002", "Delivery Photo + GPS", "DELIVERY_PHOTO"),
        new("PT-003", "Field Officer Token", "FIELD_OFFICER_TOKEN"),
        new("PT-004", "Borrower ACK", "BORROWER_ACK")
    };

    internal static ProgrammeModel BuildProgrammeModel(string tenantId, string programId)
    {
        var submissions = EvidenceLinkSubmissionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId) && Matches(x, "program_id", programId))
            .ToArray();

        var exceptions = DemoExceptionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId) && Matches(x, "program_id", programId))
            .ToArray();

        var instructionIds = submissions.Select(x => ReadString(x, "instruction_id"))
            .Concat(exceptions.Select(x => ReadString(x, "instruction_id")))
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct(StringComparer.Ordinal)
            .OrderBy(x => x, StringComparer.Ordinal)
            .ToArray();

        var timeline = BuildTimeline(submissions, exceptions, instructionIds);
        var proofRows = instructionIds.Select(id => BuildInstructionProofSummary(id, submissions, exceptions)).ToArray();
        var evidenceCompleteness = BuildEvidenceCompleteness(proofRows);
        var exceptionLog = exceptions.Select(x => new
        {
            instruction_id = ReadString(x, "instruction_id"),
            supplier_id = ReadString(x, "supplier_id"),
            error_code = ReadString(x, "error_code"),
            recorded_at_utc = ReadString(x, "recorded_at_utc")
        }).ToArray();

        return new ProgrammeModel(submissions, exceptions, timeline, evidenceCompleteness, exceptionLog, proofRows);
    }

    public static object? BuildInstructionDetail(string tenantId, string instructionId)
    {
        var submissions = EvidenceLinkSubmissionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId) && Matches(x, "instruction_id", instructionId))
            .ToArray();

        var exceptions = DemoExceptionLog.ReadAll()
            .Where(x => Matches(x, "tenant_id", tenantId) && Matches(x, "instruction_id", instructionId))
            .ToArray();

        if (submissions.Length == 0 && exceptions.Length == 0)
        {
            return null;
        }

        var instructionSummary = BuildInstructionProofSummary(instructionId, submissions, exceptions);
        var firstProgramId = submissions.Select(x => ReadString(x, "program_id"))
            .Concat(exceptions.Select(x => ReadString(x, "program_id")))
            .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x)) ?? string.Empty;
        var supplierId = exceptions.Select(x => ReadString(x, "supplier_id"))
            .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x)) ?? string.Empty;
        var supplierPolicy = BuildSupplierPolicyContext(tenantId, firstProgramId, supplierId);

        return new
        {
            tenant_id = tenantId,
            program_id = firstProgramId,
            instruction_id = instructionId,
            instruction_status = instructionSummary.status,
            proof_rows = instructionSummary.proofs,
            raw_artifacts = submissions.Select(x => new
            {
                artifact_type = ReadString(x, "artifact_type"),
                artifact_ref = ReadString(x, "artifact_ref"),
                submitter_class = ReadString(x, "submitter_class"),
                submitter_msisdn = ReadString(x, "submitter_msisdn"),
                latitude = ReadNullableDecimal(x, "latitude"),
                longitude = ReadNullableDecimal(x, "longitude"),
                submitted_at_utc = ReadString(x, "submitted_at_utc")
            }).ToArray(),
            exception_log = exceptions.Select(x => new
            {
                error_code = ReadString(x, "error_code"),
                supplier_id = ReadString(x, "supplier_id"),
                recorded_at_utc = ReadString(x, "recorded_at_utc")
            }).ToArray(),
            supplier_policy_context = supplierPolicy,
            acknowledgement_state = (string?)null,
            escalation_tier = (int?)null,
            supervisor_interrupt_state = (string?)null,
            ack_interrupt_projection_state = "PENDING_TASK_UI_WIRE_008",
            read_only = true
        };
    }

    private static object[] BuildTimeline(JsonElement[] submissions, JsonElement[] exceptions, string[] instructionIds)
    {
        var rows = new List<object>();
        foreach (var instructionId in instructionIds)
        {
            var instructionSubmissions = submissions.Where(x => Matches(x, "instruction_id", instructionId)).ToArray();
            var instructionExceptions = exceptions.Where(x => Matches(x, "instruction_id", instructionId)).ToArray();
            var summary = BuildInstructionProofSummary(instructionId, instructionSubmissions, instructionExceptions);
            var latestObserved = instructionSubmissions
                .Select(x => ReadString(x, "submitted_at_utc"))
                .Concat(instructionExceptions.Select(x => ReadString(x, "recorded_at_utc")))
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .OrderBy(x => x, StringComparer.Ordinal)
                .LastOrDefault() ?? string.Empty;

            rows.Add(new
            {
                instruction_id = instructionId,
                event_type = summary.status,
                observed_at_utc = latestObserved,
                proofs = $"{summary.present_count}/4",
                proof_status = summary.status,
                drill_instruction_id = instructionId
            });
        }

        return rows
            .OrderByDescending(x => x.GetType().GetProperty("observed_at_utc")?.GetValue(x)?.ToString())
            .ToArray();
    }

    private static object[] BuildEvidenceCompleteness(InstructionProofSummary[] proofRows)
    {
        return ProofSpecs.Select(spec =>
        {
            var statuses = proofRows
                .Select(row => row.GetType().GetProperty("proofs")?.GetValue(row) as Array)
                .Where(arr => arr is not null)
                .SelectMany(arr => arr!.Cast<object>())
                .Where(proof => string.Equals(
                    proof.GetType().GetProperty("proof_type_id")?.GetValue(proof)?.ToString(),
                    spec.ProofTypeId,
                    StringComparison.Ordinal))
                .Select(proof => proof.GetType().GetProperty("status")?.GetValue(proof)?.ToString() ?? string.Empty)
                .ToArray();

            var status = statuses.Contains("FAILED", StringComparer.OrdinalIgnoreCase)
                ? "FAILED"
                : statuses.Contains("FLAGGED", StringComparer.OrdinalIgnoreCase)
                    ? "FLAGGED"
                    : statuses.Contains("PRESENT", StringComparer.OrdinalIgnoreCase)
                        ? "PRESENT"
                        : "MISSING";

            return new
            {
                artifact_type = spec.ArtifactType,
                proof_type_id = spec.ProofTypeId,
                label = spec.Label,
                status
            };
        }).ToArray<object>();
    }

    private static InstructionProofSummary BuildInstructionProofSummary(string instructionId, JsonElement[] submissions, JsonElement[] exceptions)
    {
        var proofRows = ProofSpecs.Select(spec => BuildProofRow(spec, submissions, exceptions)).ToArray();
        var presentCount = proofRows.Count(x => string.Equals(x.status, "PRESENT", StringComparison.Ordinal));
        var status = proofRows.Any(x => string.Equals(x.status, "FAILED", StringComparison.Ordinal))
            ? "FAILED"
            : proofRows.Any(x => string.Equals(x.status, "FLAGGED", StringComparison.Ordinal))
                ? "FLAGGED"
                : proofRows.All(x => string.Equals(x.status, "PRESENT", StringComparison.Ordinal))
                    ? "PRESENT"
                    : "MISSING";

        return new InstructionProofSummary(
            instructionId,
            status,
            presentCount,
            proofRows);
    }

    private static object BuildSupplierPolicyContext(string tenantId, string programId, string supplierId)
    {
        if (string.IsNullOrWhiteSpace(programId) || string.IsNullOrWhiteSpace(supplierId))
        {
            return new
            {
                available = false,
                supplier_id = supplierId,
                decision = "UNAVAILABLE"
            };
        }

        var result = ProgramSupplierPolicyReadHandler.Handle(tenantId, programId, supplierId);
        return result.Body;
    }

    private static ProofRow BuildProofRow(ProofSpec spec, JsonElement[] submissions, JsonElement[] exceptions)
    {
        var submission = submissions
            .LastOrDefault(x => string.Equals(ReadString(x, "artifact_type"), spec.ArtifactType, StringComparison.OrdinalIgnoreCase));
        var hasSubmission = submission.ValueKind != JsonValueKind.Undefined;
        var errorCodes = exceptions.Select(x => ReadString(x, "error_code")).ToArray();

        var status = hasSubmission ? "PRESENT" : "MISSING";
        string? gpsResult = null;
        string? msisdnResult = null;
        string? submitterClass = hasSubmission ? ReadString(submission, "submitter_class") : null;
        string? submittedAtUtc = hasSubmission ? ReadString(submission, "submitted_at_utc") : null;

        if (spec.ProofTypeId == "PT-002")
        {
            gpsResult = hasSubmission && ReadNullableDecimal(submission, "latitude").HasValue && ReadNullableDecimal(submission, "longitude").HasValue
                ? "CAPTURED"
                : hasSubmission ? "NOT_CAPTURED" : "MISSING";
            if (hasSubmission && gpsResult == "NOT_CAPTURED")
            {
                status = "FAILED";
            }
        }

        if (spec.ProofTypeId == "PT-004")
        {
            msisdnResult = hasSubmission && !string.IsNullOrWhiteSpace(ReadString(submission, "submitter_msisdn"))
                ? "PRESENT"
                : hasSubmission ? "MISSING" : "MISSING";
            if (hasSubmission && msisdnResult == "MISSING")
            {
                status = "FAILED";
            }
            if (errorCodes.Contains("SIM_SWAP_FLAG", StringComparer.OrdinalIgnoreCase))
            {
                status = "FLAGGED";
                msisdnResult = "FLAGGED_SIM_SWAP";
            }
        }

        if (spec.ProofTypeId == "PT-003" && hasSubmission && !string.Equals(submitterClass, "FIELD_OFFICER", StringComparison.OrdinalIgnoreCase))
        {
            status = "FLAGGED";
        }

        return new ProofRow(
            spec.ProofTypeId,
            spec.Label,
            status,
            spec.ArtifactType,
            gpsResult,
            msisdnResult,
            submitterClass,
            submittedAtUtc);
    }

    private static bool Matches(JsonElement element, string key, string expected)
        => string.Equals(ReadString(element, key), expected, StringComparison.Ordinal);

    private static string ReadString(JsonElement element, string key)
        => element.TryGetProperty(key, out var value) ? value.GetString() ?? string.Empty : string.Empty;

    private static decimal? ReadNullableDecimal(JsonElement element, string key)
    {
        if (!element.TryGetProperty(key, out var value))
        {
            return null;
        }

        if (value.ValueKind == JsonValueKind.Number && value.TryGetDecimal(out var number))
        {
            return number;
        }

        if (value.ValueKind == JsonValueKind.String && decimal.TryParse(value.GetString(), out var parsed))
        {
            return parsed;
        }

        return null;
    }

    internal sealed record ProgrammeModel(
        JsonElement[] Submissions,
        JsonElement[] Exceptions,
        object[] Timeline,
        object[] EvidenceCompleteness,
        object[] ExceptionLog,
        InstructionProofSummary[] ProofRows);

    private sealed record ProofSpec(string ProofTypeId, string Label, string ArtifactType);

    internal sealed record InstructionProofSummary(
        string instruction_id,
        string status,
        int present_count,
        ProofRow[] proofs);

    internal sealed record ProofRow(
        string proof_type_id,
        string label,
        string status,
        string artifact_type,
        string? gps_result,
        string? msisdn_result,
        string? submitter_class,
        string? submitted_at_utc);
}
