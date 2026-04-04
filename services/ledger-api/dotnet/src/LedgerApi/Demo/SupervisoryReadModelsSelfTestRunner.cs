using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Symphony.LedgerApi.Demo;

public static class SupervisoryReadModelsSelfTestRunner
{
    public static async Task<int> RunAsync(ILogger logger, CancellationToken cancellationToken)
    {
        var rootDir = global::EvidenceMeta.ResolveRepoRoot(Directory.GetCurrentDirectory());
        var evidenceDir = Path.Combine(rootDir, "evidence", "phase1");
        Directory.CreateDirectory(evidenceDir);
        var evidenceMeta = global::EvidenceMeta.Load(rootDir);
        var evidencePath = Path.Combine(evidenceDir, "tsk_p1_demo_007_supervisory_read_models.json");

        var tenantId = "11111111-1111-1111-1111-111111111111";
        var programId = "program-a";
        var supplierId = "supplier-007";
        var submissionLogPath = Environment.GetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE")
            ?? Path.Combine(Path.GetTempPath(), "symphony_demo_supervisory_read_model_submissions.ndjson");
        var exceptionLogPath = Environment.GetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE")
            ?? Path.Combine(Path.GetTempPath(), "symphony_demo_supervisory_read_model_exceptions.ndjson");
        File.Delete(submissionLogPath);
        File.Delete(exceptionLogPath);
        Environment.SetEnvironmentVariable("EVIDENCE_LINK_SUBMISSIONS_FILE", submissionLogPath);
        Environment.SetEnvironmentVariable("DEMO_EXCEPTION_LOG_FILE", exceptionLogPath);
        Environment.SetEnvironmentVariable("SYMPHONY_KNOWN_TENANTS", tenantId);
        Environment.SetEnvironmentVariable("DEMO_EVIDENCE_LINK_SIGNING_KEY", "demo-link-self-test-key");
        Environment.SetEnvironmentVariable("DEMO_INSTRUCTION_SIGNING_KEY", "demo-instruction-signing-key");

        await global::SupplierRegistryUpsertHandler.HandleAsync(new global::SupplierRegistryUpsertRequest(
            tenantId,
            supplierId,
            "Supplier Seven",
            "MMO:+260970000007",
            -15.39m,
            28.32m,
            true));
        await global::ProgramSupplierAllowlistUpsertHandler.HandleAsync(new global::ProgramSupplierAllowlistUpsertRequest(
            tenantId,
            programId,
            supplierId,
            true));

        // Generate one allowed instruction and one denied instruction to populate exception log.
        _ = await global::SignedInstructionFileHandler.GenerateAsync(new global::SignedInstructionGenerateRequest(
                tenantId,
                programId,
                "SYM-2026-00041",
                supplierId,
                "MMO:+260970000007",
                9900,
                "ZMW",
                "INV-007-A"),
            logger,
            cancellationToken);

        _ = await global::SignedInstructionFileHandler.GenerateAsync(new global::SignedInstructionGenerateRequest(
                tenantId,
                "program-b",
                "instr-007-denied",
                supplierId,
                "MMO:+260970000007",
                9900,
                "ZMW",
                "INV-007-B"),
            logger,
            cancellationToken);

        // Populate evidence submissions.
        var issue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "SYM-2026-00041",
                programId,
                "SUPPLIER",
                "+260971700700",
                null,
                null,
                null,
                300),
            logger,
            cancellationToken);

        var token = string.Empty;
        if (issue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(issue.Body));
            token = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }

        var ctx = new DefaultHttpContext();
        ctx.Request.Headers["x-tenant-id"] = tenantId;
        ctx.Request.Headers["x-evidence-link-token"] = token;
        ctx.Request.Headers["x-submitter-msisdn"] = "+260971700700";
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(
                Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, 
                "s3://bucket/inv-007.pdf", 
                null, 
                null,
                JsonSerializer.SerializeToElement(new
                {
                    plastic_type = "PET",
                    gross_weight_kg = 12.5m,
                    tare_weight_kg = 0.1m,
                    net_weight_kg = 12.4m,
                    collector_id = supplierId
                })),
            ctx,
            logger,
            cancellationToken);

        var fieldOfficerIssue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "SYM-2026-00041",
                programId,
                "FIELD_OFFICER",
                "+260971700701",
                -15.4167m,
                28.2833m,
                500m,
                300),
            logger,
            cancellationToken);
        var fieldOfficerToken = string.Empty;
        if (fieldOfficerIssue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(fieldOfficerIssue.Body));
            fieldOfficerToken = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }
        var officerCtx = new DefaultHttpContext();
        officerCtx.Request.Headers["x-tenant-id"] = tenantId;
        officerCtx.Request.Headers["x-evidence-link-token"] = fieldOfficerToken;
        officerCtx.Request.Headers["x-submitter-msisdn"] = "+260971700701";
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.COLLECTION_PHOTO, "s3://bucket/photo-007.jpg", -15.4167m, 28.2833m),
            officerCtx,
            logger,
            cancellationToken);
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.QUALITY_AUDIT_RECORD, "token://field-officer/fo-007", -15.4167m, 28.2833m),
            officerCtx,
            logger,
            cancellationToken);

        var borrowerIssue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "SYM-2026-00041",
                programId,
                "BORROWER",
                "+260971700702",
                null,
                null,
                null,
                300),
            logger,
            cancellationToken);
        var borrowerToken = string.Empty;
        if (borrowerIssue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(borrowerIssue.Body));
            borrowerToken = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }
        var borrowerCtx = new DefaultHttpContext();
        borrowerCtx.Request.Headers["x-tenant-id"] = tenantId;
        borrowerCtx.Request.Headers["x-evidence-link-token"] = borrowerToken;
        borrowerCtx.Request.Headers["x-submitter-msisdn"] = "+260971700702";
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.TRANSFER_MANIFEST, "sms://borrower/ack-007", null, null),
            borrowerCtx,
            logger,
            cancellationToken);

        var flaggedIssue = await global::EvidenceLinkIssueHandler.HandleAsync(
            new global::EvidenceLinkIssueRequest(
                tenantId,
                "SYM-2026-00047",
                programId,
                "BORROWER",
                "+260971700703",
                null,
                null,
                null,
                300),
            logger,
            cancellationToken);
        var flaggedToken = string.Empty;
        if (flaggedIssue.StatusCode == StatusCodes.Status200OK)
        {
            using var doc = JsonDocument.Parse(JsonSerializer.Serialize(flaggedIssue.Body));
            flaggedToken = doc.RootElement.TryGetProperty("token", out var t) ? t.GetString() ?? string.Empty : string.Empty;
        }
        var flaggedCtx = new DefaultHttpContext();
        flaggedCtx.Request.Headers["x-tenant-id"] = tenantId;
        flaggedCtx.Request.Headers["x-evidence-link-token"] = flaggedToken;
        flaggedCtx.Request.Headers["x-submitter-msisdn"] = "+260971700703";
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, "s3://bucket/inv-047.pdf", null, null),
            flaggedCtx,
            logger,
            cancellationToken);
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.COLLECTION_PHOTO, "s3://bucket/photo-047.jpg", null, null),
            flaggedCtx,
            logger,
            cancellationToken);
        _ = await global::EvidenceLinkSubmitHandler.HandleAsync(
            new global::EvidenceLinkSubmitRequest(Pwrm0001ArtifactTypes.TRANSFER_MANIFEST, "sms://borrower/ack-047", null, null),
            flaggedCtx,
            logger,
            cancellationToken);
        await global::DemoExceptionLog.AppendAsync(new
        {
            tenant_id = tenantId,
            program_id = programId,
            instruction_id = "SYM-2026-00047",
            supplier_id = supplierId,
            error_code = "SIM_SWAP_FLAG",
            recorded_at_utc = DateTimeOffset.UtcNow.ToString("O")
        }, cancellationToken);

        var reveal = global::SupervisoryRevealReadModelHandler.Handle(tenantId, programId, null);
        var instructionId = "SYM-2026-00041";
        var dataSource = (Npgsql.NpgsqlDataSource?)null;
        var detail = await SupervisoryInstructionDetailReadModelHandler.HandleAsync(tenantId, instructionId, dataSource);
        var crossTenantDenied = global::ApiAuthorization.AuthorizeTenantScope("22222222-2222-2222-2222-222222222222");

        bool HasTopLevel(JsonElement root, params string[] fields)
            => fields.All(field => root.TryGetProperty(field, out _));

        bool hasRequired = false;
        bool hasProofRows = false;
        bool hasAllProofTypes = false;
        bool hasFlaggedStatus = false;
        bool hasFailedStatus = false;
        if (reveal.StatusCode == StatusCodes.Status200OK)
        {
            using var revealDoc = JsonDocument.Parse(JsonSerializer.Serialize(reveal.Body));
            hasRequired = HasTopLevel(revealDoc.RootElement, "programme_summary", "timeline", "evidence_completeness", "exception_log");
            hasProofRows = revealDoc.RootElement.TryGetProperty("proof_rows", out var proofRows) && proofRows.ValueKind == JsonValueKind.Array;
            if (hasProofRows)
            {
                var typeSet = new HashSet<string>(StringComparer.Ordinal);
                foreach (var instruction in proofRows.EnumerateArray())
                {
                    if (!instruction.TryGetProperty("proofs", out var proofs) || proofs.ValueKind != JsonValueKind.Array)
                    {
                        continue;
                    }

                    foreach (var proof in proofs.EnumerateArray())
                    {
                        if (proof.TryGetProperty("proof_type_id", out var proofType))
                        {
                            typeSet.Add(proofType.GetString() ?? string.Empty);
                        }
                        if (proof.TryGetProperty("status", out var proofStatus))
                        {
                            var value = proofStatus.GetString() ?? string.Empty;
                            if (string.Equals(value, "FLAGGED", StringComparison.OrdinalIgnoreCase))
                            {
                                hasFlaggedStatus = true;
                            }
                            if (string.Equals(value, "FAILED", StringComparison.OrdinalIgnoreCase))
                            {
                                hasFailedStatus = true;
                            }
                        }
                    }
                }

                hasAllProofTypes = new[]
                {
                    Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD,
                    Pwrm0001ArtifactTypes.COLLECTION_PHOTO,
                    Pwrm0001ArtifactTypes.QUALITY_AUDIT_RECORD,
                    Pwrm0001ArtifactTypes.TRANSFER_MANIFEST
                }.All(typeSet.Contains);
            }
        }

        bool detailHasRequired = false;
        bool detailHasAckPlaceholders = false;
        bool detailHasRawArtifacts = false;
        bool detailHasWeighbridgeFields = false;
        if (detail.StatusCode == StatusCodes.Status200OK)
        {
            using var detailDoc = JsonDocument.Parse(JsonSerializer.Serialize(detail.Body));
            detailHasRequired = HasTopLevel(detailDoc.RootElement, "proof_rows", "raw_artifacts", "supplier_policy_context");
            detailHasAckPlaceholders = HasTopLevel(detailDoc.RootElement, "acknowledgement_state", "escalation_tier", "supervisor_interrupt_state", "ack_interrupt_projection_state");
            detailHasRawArtifacts = detailDoc.RootElement.TryGetProperty("raw_artifacts", out var rawArtifacts) && rawArtifacts.ValueKind == JsonValueKind.Array && rawArtifacts.GetArrayLength() >= 4;
            
            // PWRM-003 Task 3: Verify weighbridge detail fields appear in proof_rows
            if (detailDoc.RootElement.TryGetProperty("proof_rows", out var proofRows) && proofRows.ValueKind == JsonValueKind.Array)
            {
                foreach (var proof in proofRows.EnumerateArray())
                {
                    if (proof.TryGetProperty("artifact_type", out var artifactType) 
                        && string.Equals(artifactType.GetString(), Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
                    {
                        detailHasWeighbridgeFields = 
                            proof.TryGetProperty("plastic_type", out var pt) && pt.ValueKind == JsonValueKind.String &&
                            proof.TryGetProperty("net_weight_kg", out var nw) && nw.ValueKind == JsonValueKind.Number &&
                            proof.TryGetProperty("collector_id", out var cid) && cid.ValueKind == JsonValueKind.String;
                        break;
                    }
                }
            }
        }

        // Test hard override: PGM-ZAMBIA-GRN-001 should return true even with empty submissions
        var emptySubmissions = Array.Empty<JsonElement>();
        var hardOverrideWorks = SupervisoryRevealReadModelHandler.TestIsPwrm0001Programme("PGM-ZAMBIA-GRN-001", emptySubmissions);
        
        // Test generic path: requires BOTH conditions
        var nonOverrideProgramWithoutBoth = SupervisoryRevealReadModelHandler.TestIsPwrm0001Programme("OTHER-PROGRAM", emptySubmissions);

        var tests = new[]
        {
            new { name = "reveal_read_model_components_present", status = (reveal.StatusCode == StatusCodes.Status200OK && hasRequired) ? "PASS" : "FAIL" },
            new { name = "proof_rows_present", status = hasProofRows ? "PASS" : "FAIL" },
            new { name = "proof_model_covers_pt_001_to_pt_004", status = hasAllProofTypes ? "PASS" : "FAIL" },
            new { name = "proof_statuses_include_failed_and_flagged", status = (hasFailedStatus && hasFlaggedStatus) ? "PASS" : "FAIL" },
            new { name = "detail_read_model_present", status = (detail.StatusCode == StatusCodes.Status200OK && detailHasRequired) ? "PASS" : "FAIL" },
            new { name = "detail_raw_artifacts_present", status = detailHasRawArtifacts ? "PASS" : "FAIL" },
            new { name = "detail_ack_placeholders_present", status = detailHasAckPlaceholders ? "PASS" : "FAIL" },
            new { name = "detail_weighbridge_fields_present", status = detailHasWeighbridgeFields ? "PASS" : "FAIL" },
            new { name = "cross_tenant_denied_fail_closed", status = (crossTenantDenied is not null && crossTenantDenied.StatusCode == StatusCodes.Status403Forbidden) ? "PASS" : "FAIL" },
            new { name = "pwrm0001_hard_override_fires_with_empty_submissions", status = hardOverrideWorks ? "PASS" : "FAIL" },
            new { name = "pwrm0001_generic_path_requires_both_conditions", status = !nonOverrideProgramWithoutBoth ? "PASS" : "FAIL" }
        };

        var status = tests.All(x => x.status == "PASS") ? "PASS" : "FAIL";

        await File.WriteAllTextAsync(
            evidencePath,
            JsonSerializer.Serialize(new
            {
                check_id = "TSK-P1-DEMO-007-SUPERVISORY-READ-MODELS",
                task_id = "TSK-P1-DEMO-007",
                timestamp_utc = evidenceMeta.TimestampUtc,
                git_sha = evidenceMeta.GitSha,
                schema_fingerprint = evidenceMeta.SchemaFingerprint,
                status,
                pass = status == "PASS",
                details = new
                {
                    reveal_api = "/v1/supervisory/programmes/{program_id}/reveal",
                    read_only = true,
                    tests
                }
            }, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine,
            cancellationToken);

        Console.WriteLine($"Evidence written: {evidencePath}");
        return status == "PASS" ? 0 : 1;
    }
}
