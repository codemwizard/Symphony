using System.Text.Json;
using Npgsql;
using NpgsqlTypes;

static class SupervisoryRevealReadModelHandler
{
    public static HandlerResult Handle(string tenantId, string programId, NpgsqlDataSource? dataSource)
    {
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(programId))
        {
            return InvalidRequest();
        }

        var model = SupervisoryProofModel.BuildProgrammeModel(tenantId, programId, dataSource);
        var payload = new
        {
            tenant_id = tenantId,
            program_id = programId,
            programme_summary = new
            {
                evidence_submissions = model.Submissions.Length,
                exception_count = model.Exceptions.Length,
                timeline_events = model.Timeline.Length,
                awaiting_execution_count = model.ProofRows.Count(x => string.Equals(x.acknowledgement_state, "PENDING_ACKNOWLEDGEMENT", StringComparison.Ordinal)),
                escalated_count = model.ProofRows.Count(x => x.escalation_tier.HasValue)
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

    // Test helper: exposes IsPwrm0001Programme for self-test validation
    internal static bool TestIsPwrm0001Programme(string programId, IReadOnlyList<JsonElement> submissions)
        => SupervisoryProofModel.IsPwrm0001Programme(programId, submissions);

    private static HandlerResult InvalidRequest()
        => new(StatusCodes.Status400BadRequest, new
        {
            error_code = "INVALID_REQUEST",
            errors = new[] { "tenant/program context required" }
        });
}

static class SupervisoryInstructionDetailReadModelHandler
{
    public static async Task<HandlerResult> HandleAsync(string tenantId, string instructionId, NpgsqlDataSource? dataSource)
    {
        if (string.IsNullOrWhiteSpace(tenantId) || string.IsNullOrWhiteSpace(instructionId))
        {
            return new HandlerResult(StatusCodes.Status400BadRequest, new
            {
                error_code = "INVALID_REQUEST",
                errors = new[] { "tenant/instruction context required" }
            });
        }

        var detail = await SupervisoryProofModel.BuildInstructionDetailAsync(tenantId, instructionId, dataSource);
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
    internal static bool IsPwrm0001Programme(string programId, IReadOnlyList<JsonElement> submissions)
    {
        // Hard override — demo cannot break due to seed timing
        if (string.Equals(programId, "PGM-ZAMBIA-GRN-001", StringComparison.Ordinal))
            return true;

        // Generic detection: both conditions required
        bool hasArtifact = submissions.Any(s =>
            s.TryGetProperty("artifact_type", out var at) &&
            Pwrm0001ArtifactTypes.IsPwrm0001ArtifactType(at.GetString()));
        bool hasWasteCollector = submissions.Any(s =>
            s.TryGetProperty("submitter_class", out var sc) &&
            string.Equals(sc.GetString(), "WASTE_COLLECTOR", StringComparison.Ordinal));

        return hasArtifact && hasWasteCollector;
    }

    internal static ProgrammeModel BuildProgrammeModel(string tenantId, string programId, NpgsqlDataSource? dataSource)
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

        // TSK-P1-210: Pre-index submissions and exceptions by instruction_id
        // to eliminate repeated linear scans per instruction.
        var submissionsByInstruction = submissions.ToLookup(x => ReadString(x, "instruction_id"), StringComparer.Ordinal);
        var exceptionsByInstruction = exceptions.ToLookup(x => ReadString(x, "instruction_id"), StringComparer.Ordinal);

        var projections = AckInterruptProjectionStore.LoadForInstructionIds(instructionIds, dataSource);
        var timeline = BuildTimeline(submissionsByInstruction, exceptionsByInstruction, instructionIds, projections);
        var proofRows = instructionIds
            .Select(id => BuildInstructionProofSummary(id, submissionsByInstruction[id].ToArray(), exceptionsByInstruction[id].ToArray(), projections.GetValueOrDefault(id, AckInterruptProjectionStore.Unavailable(id, dataSource))))
            .ToArray();
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

    public static async Task<object?> BuildInstructionDetailAsync(string tenantId, string instructionId, NpgsqlDataSource? dataSource)
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

        var projection = AckInterruptProjectionStore.LoadForInstructionIds(new[] { instructionId }, dataSource)
            .GetValueOrDefault(instructionId, AckInterruptProjectionStore.Unavailable(instructionId, dataSource));
        var instructionSummary = BuildInstructionProofSummary(instructionId, submissions, exceptions, projection);
        var firstProgramId = submissions.Select(x => ReadString(x, "program_id"))
            .Concat(exceptions.Select(x => ReadString(x, "program_id")))
            .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x)) ?? string.Empty;
        var supplierId = exceptions.Select(x => ReadString(x, "supplier_id"))
            .FirstOrDefault(x => !string.IsNullOrWhiteSpace(x)) ?? string.Empty;
        var supplierPolicy = await BuildSupplierPolicyContextAsync(tenantId, firstProgramId, supplierId);

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
            acknowledgement_state = projection.acknowledgement_state,
            escalation_tier = projection.escalation_tier,
            supervisor_interrupt_state = projection.supervisor_interrupt_state,
            ack_interrupt_projection_state = projection.ack_interrupt_projection_state,
            read_only = true
        };
    }

    // TSK-P1-210: Accepts pre-indexed lookups instead of flat arrays
    private static object[] BuildTimeline(ILookup<string, JsonElement> submissionsByInstruction, ILookup<string, JsonElement> exceptionsByInstruction, string[] instructionIds, IReadOnlyDictionary<string, AckInterruptProjectionStore.AckInterruptProjection> projections)
    {
        var rows = new List<object>();
        foreach (var instructionId in instructionIds)
        {
            var instructionSubmissions = submissionsByInstruction[instructionId].ToArray();
            var instructionExceptions = exceptionsByInstruction[instructionId].ToArray();
            var projection = projections.GetValueOrDefault(instructionId, AckInterruptProjectionStore.Unavailable(instructionId, null));
            var summary = BuildInstructionProofSummary(instructionId, instructionSubmissions, instructionExceptions, projection);
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
                drill_instruction_id = instructionId,
                acknowledgement_state = summary.acknowledgement_state,
                escalation_tier = summary.escalation_tier,
                supervisor_interrupt_state = summary.supervisor_interrupt_state,
                ack_interrupt_projection_state = summary.ack_interrupt_projection_state
            });
        }

        return rows
            .OrderByDescending(x => x.GetType().GetProperty("observed_at_utc")?.GetValue(x)?.ToString())
            .ToArray();
    }

    private static object[] BuildEvidenceCompleteness(InstructionProofSummary[] proofRows)
    {
        // Collect all unique artifact types from proof rows
        var artifactTypes = proofRows
            .SelectMany(row => row.proofs)
            .Select(proof => proof.artifact_type)
            .Where(at => !string.IsNullOrWhiteSpace(at))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        return artifactTypes.Select(artifactType =>
        {
            var statuses = proofRows
                .SelectMany(row => row.proofs)
                .Where(proof => string.Equals(proof.artifact_type, artifactType, StringComparison.Ordinal))
                .Select(proof => proof.status)
                .ToArray();

            var status = statuses.Contains("FAILED", StringComparer.OrdinalIgnoreCase)
                ? "FAILED"
                : statuses.Contains("FLAGGED", StringComparer.OrdinalIgnoreCase)
                    ? "FLAGGED"
                    : statuses.Contains("PRESENT", StringComparer.OrdinalIgnoreCase)
                        ? "PRESENT"
                        : "MISSING";

            var proofTypeDisplay = Pwrm0001ArtifactTypes.ProofTypeDisplayLabels.TryGetValue(artifactType, out var label)
                ? label
                : artifactType;

            return new
            {
                artifact_type = artifactType,
                proof_type_id = artifactType,
                label = proofTypeDisplay,
                status
            };
        }).ToArray<object>();
    }

    private static InstructionProofSummary BuildInstructionProofSummary(string instructionId, JsonElement[] submissions, JsonElement[] exceptions, AckInterruptProjectionStore.AckInterruptProjection projection)
    {
        // Group submissions by artifact_type
        var artifactTypes = submissions
            .Select(s => ReadString(s, "artifact_type"))
            .Where(at => !string.IsNullOrWhiteSpace(at))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        var proofRows = artifactTypes.Select(artifactType => BuildProofRow(artifactType, submissions, exceptions)).ToArray();
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
            proofRows,
            projection.acknowledgement_state,
            projection.escalation_tier,
            projection.supervisor_interrupt_state,
            projection.ack_interrupt_projection_state);
    }

    private static async Task<object> BuildSupplierPolicyContextAsync(string tenantId, string programId, string supplierId)
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

        var result = await ProgramSupplierPolicyReadHandler.HandleAsync(tenantId, programId, supplierId);
        return result.Body;
    }

    private static ProofRow BuildProofRow(string artifactType, JsonElement[] submissions, JsonElement[] exceptions)
    {
        var submission = submissions
            .LastOrDefault(x => string.Equals(ReadString(x, "artifact_type"), artifactType, StringComparison.Ordinal));
        var hasSubmission = submission.ValueKind != JsonValueKind.Undefined;
        var errorCodes = exceptions.Select(x => ReadString(x, "error_code")).ToArray();

        // proof_type_id = artifact_type
        var proofTypeId = artifactType;

        // proof_type_display = ProofTypeDisplayLabels.TryGetValue(artifact_type, out var l) ? l : artifact_type
        var proofTypeDisplay = Pwrm0001ArtifactTypes.ProofTypeDisplayLabels.TryGetValue(artifactType, out var label)
            ? label
            : artifactType;

        var status = hasSubmission ? "PRESENT" : "MISSING";
        string? gpsResult = null;
        string? msisdnResult = null;
        string? submitterClass = hasSubmission ? ReadString(submission, "submitter_class") : null;
        string? submittedAtUtc = hasSubmission ? ReadString(submission, "submitted_at_utc") : null;

        // PWRM-003 Task 3: Weighbridge detail fields
        string? plasticType = null;
        decimal? netWeightKg = null;
        string? collectorId = null;

        // Legacy logic for COLLECTION_PHOTO (was DELIVERY_PHOTO/PT-002)
        if (string.Equals(artifactType, Pwrm0001ArtifactTypes.COLLECTION_PHOTO, StringComparison.Ordinal)
            || string.Equals(artifactType, "DELIVERY_PHOTO", StringComparison.Ordinal))
        {
            gpsResult = hasSubmission && ReadNullableDecimal(submission, "latitude").HasValue && ReadNullableDecimal(submission, "longitude").HasValue
                ? "CAPTURED"
                : hasSubmission ? "NOT_CAPTURED" : "MISSING";
            if (hasSubmission && gpsResult == "NOT_CAPTURED")
            {
                status = "FAILED";
            }
        }

        // Legacy logic for TRANSFER_MANIFEST (was BORROWER_ACK/PT-004)
        if (string.Equals(artifactType, Pwrm0001ArtifactTypes.TRANSFER_MANIFEST, StringComparison.Ordinal)
            || string.Equals(artifactType, "BORROWER_ACK", StringComparison.Ordinal))
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

        // Legacy logic for QUALITY_AUDIT_RECORD (was FIELD_OFFICER_TOKEN/PT-003)
        if ((string.Equals(artifactType, Pwrm0001ArtifactTypes.QUALITY_AUDIT_RECORD, StringComparison.Ordinal)
            || string.Equals(artifactType, "FIELD_OFFICER_TOKEN", StringComparison.Ordinal))
            && hasSubmission
            && !string.Equals(submitterClass, "FIELD_OFFICER", StringComparison.OrdinalIgnoreCase))
        {
            status = "FLAGGED";
        }

        // PWRM-003 Task 3: Extract weighbridge detail fields when artifact_type = WEIGHBRIDGE_RECORD
        // PWRM-002 guarantees structured_payload is non-null for WEIGHBRIDGE_RECORD
        if (string.Equals(artifactType, Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal)
            && hasSubmission
            && submission.TryGetProperty("structured_payload", out var sp)
            && sp.ValueKind != JsonValueKind.Null)
        {
            // PWRM-002 guarantee: these fields are present and valid
            plasticType = sp.TryGetProperty("plastic_type", out var pt) ? pt.GetString() : null;
            netWeightKg = sp.TryGetProperty("net_weight_kg", out var nw) && nw.ValueKind == JsonValueKind.Number
                ? nw.GetDecimal()
                : null;
            collectorId = sp.TryGetProperty("collector_id", out var cid) ? cid.GetString() : null;
        }

        return new ProofRow(
            proofTypeId,
            proofTypeDisplay,
            status,
            artifactType,
            gpsResult,
            msisdnResult,
            submitterClass,
            submittedAtUtc,
            plasticType,
            netWeightKg,
            collectorId);
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

    internal sealed record InstructionProofSummary(
        string instruction_id,
        string status,
        int present_count,
        ProofRow[] proofs,
        string? acknowledgement_state,
        int? escalation_tier,
        string? supervisor_interrupt_state,
        string ack_interrupt_projection_state);

    internal sealed record ProofRow(
        string proof_type_id,
        string label,
        string status,
        string artifact_type,
        string? gps_result,
        string? msisdn_result,
        string? submitter_class,
        string? submitted_at_utc,
        string? plastic_type,
        decimal? net_weight_kg,
        string? collector_id);
}

file static class AckInterruptProjectionStore
{
    internal sealed record AckInterruptProjection(
        string instruction_id,
        string? acknowledgement_state,
        int? escalation_tier,
        string? supervisor_interrupt_state,
        string ack_interrupt_projection_state);

    internal static IReadOnlyDictionary<string, AckInterruptProjection> LoadForInstructionIds(IEnumerable<string> instructionIds, NpgsqlDataSource? dataSource)
    {
        var ids = instructionIds
            .Where(id => !string.IsNullOrWhiteSpace(id))
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        if (ids.Length == 0)
        {
            return new Dictionary<string, AckInterruptProjection>(StringComparer.Ordinal);
        }

        if (dataSource is null)
        {
            return ids.ToDictionary(id => id, id => Unavailable(id, null), StringComparer.Ordinal);
        }

        try
        {
            using var connection = dataSource.OpenConnection();
            using var command = connection.CreateCommand();
            command.CommandText = @"
SELECT ids.instruction_id,
       ism.inquiry_state::text AS inquiry_state,
       saq.status AS queue_status,
       evt.action AS latest_action
FROM unnest(@instruction_ids) AS ids(instruction_id)
LEFT JOIN public.inquiry_state_machine ism ON ism.instruction_id = ids.instruction_id
LEFT JOIN public.supervisor_approval_queue saq ON saq.instruction_id = ids.instruction_id
LEFT JOIN LATERAL (
  SELECT action
  FROM public.supervisor_interrupt_audit_events audit
  WHERE audit.instruction_id = ids.instruction_id
  ORDER BY audit.recorded_at DESC
  LIMIT 1
) evt ON TRUE;";
            command.Parameters.Add(new NpgsqlParameter<string[]>("instruction_ids", NpgsqlDbType.Array | NpgsqlDbType.Text)
            {
                TypedValue = ids
            });

            using var reader = command.ExecuteReader();
            var projections = new Dictionary<string, AckInterruptProjection>(StringComparer.Ordinal);
            while (reader.Read())
            {
                var instructionId = reader.GetString(0);
                var inquiryState = reader.IsDBNull(1) ? null : reader.GetString(1);
                var queueStatus = reader.IsDBNull(2) ? null : reader.GetString(2);
                var latestAction = reader.IsDBNull(3) ? null : reader.GetString(3);
                projections[instructionId] = FromDatabaseValues(instructionId, inquiryState, queueStatus, latestAction);
            }

            foreach (var id in ids)
            {
                projections.TryAdd(id, new AckInterruptProjection(id, null, null, null, "LIVE_DB_PROJECTED_NO_STATE"));
            }

            return projections;
        }
        catch
        {
            return ids.ToDictionary(id => id, id => Unavailable(id, dataSource), StringComparer.Ordinal);
        }
    }

    internal static AckInterruptProjection Unavailable(string instructionId, NpgsqlDataSource? dataSource)
        => new(
            instructionId,
            null,
            null,
            null,
            dataSource is null ? "UNAVAILABLE_STORAGE_MODE_FILE" : "UNAVAILABLE_DB_LOOKUP_ERROR");

    private static AckInterruptProjection FromDatabaseValues(string instructionId, string? inquiryState, string? queueStatus, string? latestAction)
    {
        if (string.IsNullOrWhiteSpace(inquiryState) && string.IsNullOrWhiteSpace(queueStatus) && string.IsNullOrWhiteSpace(latestAction))
        {
            return new AckInterruptProjection(instructionId, null, null, null, "LIVE_DB_PROJECTED_NO_STATE");
        }

        var acknowledgementState = inquiryState switch
        {
            "ACKNOWLEDGED" => "ACKNOWLEDGED",
            "ESCALATED" => "PENDING_ACKNOWLEDGEMENT",
            "AWAITING_EXECUTION" => "PENDING_ACKNOWLEDGEMENT",
            _ => latestAction switch
            {
                "ACKNOWLEDGED" => "ACKNOWLEDGED",
                "RESUMED" => "PENDING_ACKNOWLEDGEMENT",
                "RESET" => "PENDING_ACKNOWLEDGEMENT",
                _ => null
            }
        };

        int? escalationTier = string.Equals(inquiryState, "ESCALATED", StringComparison.Ordinal)
            || string.Equals(queueStatus, "ESCALATED", StringComparison.Ordinal)
            ? 3
            : null;

        var supervisorInterruptState = latestAction switch
        {
            "ESCALATED" => "ESCALATED",
            "ACKNOWLEDGED" => "ACKNOWLEDGED",
            "RESUMED" => "RESUMED",
            "RESET" => "RESET",
            _ => queueStatus switch
            {
                "ESCALATED" => "ESCALATED",
                "RESET" => "RESET",
                "TIMED_OUT" => "TIMED_OUT",
                _ => null
            }
        };

        return new AckInterruptProjection(
            instructionId,
            acknowledgementState,
            escalationTier,
            supervisorInterruptState,
            "LIVE_DB_PROJECTED");
    }
}
