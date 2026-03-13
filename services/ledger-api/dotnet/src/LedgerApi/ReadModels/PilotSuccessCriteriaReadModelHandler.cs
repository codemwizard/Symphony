using System.Text.Json;

static class PilotSuccessCriteriaReadModelHandler
{
    public static HandlerResult Handle(string repoRoot)
    {
        var phase1 = Path.Combine(repoRoot, "evidence", "phase1");
        var demo008Path = Path.Combine(phase1, "tsk_p1_demo_008_supervisory_ui.json");
        var demo009Path = Path.Combine(phase1, "tsk_p1_demo_009_reporting_pack_export.json");
        var demo010Path = Path.Combine(phase1, "tsk_p1_demo_010_reveal_rehearsal.json");
        var demo011Path = Path.Combine(phase1, "tsk_p1_demo_011_pilot_success_criteria_gate.json");

        var demo008 = ReadEvidenceStatus(demo008Path);
        var demo009 = ReadEvidenceStatus(demo009Path);
        var demo010 = ReadEvidenceStatus(demo010Path);
        var demo011 = ReadEvidenceDocument(demo011Path);

        var gateEnforced = ReadDetailBool(demo011, "criteria_gate_enforced");
        var prodProfileProtected = ReadDetailBool(demo011, "production_profile_demo_flags_rejected");
        var gateStatus = ReadStatus(demo011);
        var sourceOfTruth = ReadDetailString(demo011, "source_of_truth") ?? "unavailable";

        var criteria = new object[]
        {
            new { criterion_id = "DEMO-008", category = "Operational", label = "Supervisory dashboard accessible", status = demo008.Status, source = demo008Path },
            new { criterion_id = "DEMO-009", category = "Operational", label = "Reporting pack export deterministic", status = demo009.Status, source = demo009Path },
            new { criterion_id = "DEMO-010", category = "Technical", label = "Reveal rehearsal executed", status = demo010.Status, source = demo010Path },
            new { criterion_id = "DEMO-011-GATE", category = "Regulatory", label = "Pilot criteria gate enforced", status = gateEnforced ? "PASS" : "FAIL", source = demo011Path },
            new { criterion_id = "DEMO-011-PROD", category = "Regulatory", label = "Production profile hides demo routes", status = prodProfileProtected ? "PASS" : "FAIL", source = demo011Path }
        };

        var passCount = criteria.Count(item => string.Equals(item.GetType().GetProperty("status")?.GetValue(item)?.ToString(), "PASS", StringComparison.OrdinalIgnoreCase));
        var failCount = criteria.Length - passCount;

        return new HandlerResult(StatusCodes.Status200OK, new
        {
            status = gateStatus == "PASS" && failCount == 0 ? "PASS" : "FAIL",
            source_of_truth = sourceOfTruth,
            gate_status = gateStatus,
            pass_count = passCount,
            fail_count = failCount,
            pending_count = 0,
            criteria
        });
    }

    private static (string Status, JsonDocument? Document) ReadEvidenceStatus(string path)
    {
        var document = ReadEvidenceDocument(path);
        return (ReadStatus(document), document);
    }

    private static JsonDocument? ReadEvidenceDocument(string path)
    {
        if (!File.Exists(path))
        {
            return null;
        }

        return JsonDocument.Parse(File.ReadAllText(path));
    }

    private static string ReadStatus(JsonDocument? document)
    {
        if (document is null)
        {
            return "FAIL";
        }

        if (document.RootElement.TryGetProperty("status", out var status) && status.ValueKind == JsonValueKind.String)
        {
            return status.GetString()?.ToUpperInvariant() ?? "FAIL";
        }

        if (document.RootElement.TryGetProperty("pass", out var pass) && pass.ValueKind == JsonValueKind.True)
        {
            return "PASS";
        }

        return "FAIL";
    }

    private static bool ReadDetailBool(JsonDocument? document, string key)
    {
        if (document is null
            || !document.RootElement.TryGetProperty("details", out var details)
            || !details.TryGetProperty(key, out var value))
        {
            return false;
        }

        return value.ValueKind == JsonValueKind.True;
    }

    private static string? ReadDetailString(JsonDocument? document, string key)
    {
        if (document is null
            || !document.RootElement.TryGetProperty("details", out var details)
            || !details.TryGetProperty(key, out var value)
            || value.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        return value.GetString();
    }
}
