using System.Text.Json;

static class Pwrm0001ArtifactTypes
{
    public const string WEIGHBRIDGE_RECORD   = "WEIGHBRIDGE_RECORD";
    public const string COLLECTION_PHOTO     = "COLLECTION_PHOTO";
    public const string QUALITY_AUDIT_RECORD = "QUALITY_AUDIT_RECORD";
    public const string TRANSFER_MANIFEST    = "TRANSFER_MANIFEST";

    public static readonly IReadOnlyDictionary<string, string> ProofTypeDisplayLabels =
        new Dictionary<string, string>(StringComparer.Ordinal)
        {
            [WEIGHBRIDGE_RECORD]   = "Weighbridge Collection Record",
            [COLLECTION_PHOTO]     = "Field Collection Photo",
            [QUALITY_AUDIT_RECORD] = "Quality Audit Record",
            [TRANSFER_MANIFEST]    = "Offtake Transfer Manifest",
        };

    public static bool IsPwrm0001ArtifactType(string? value) =>
        value is not null && ProofTypeDisplayLabels.ContainsKey(value);
}

static class Pwrm0001WeighbridgePayloadValidator
{
    private static readonly HashSet<string> ValidPlasticTypes =
        new(StringComparer.Ordinal) { "PET", "HDPE", "LDPE", "PP", "PS", "OTHER" };

    // Returns violations array + the backend-computed net weight
    public static (string[] violations, decimal backendNet) Validate(JsonElement payload)
    {
        var violations = new List<string>();
        decimal gross = 0m, tare = 0m, submittedNet = 0m;
        decimal backendNet = 0m;

        // plastic_type
        if (!payload.TryGetProperty("plastic_type", out var ptEl) || ptEl.ValueKind != JsonValueKind.String)
            violations.Add("plastic_type is required and must be a string");
        else if (!ValidPlasticTypes.Contains(ptEl.GetString()!))
            violations.Add($"plastic_type '{ptEl.GetString()}' is not valid; must be PET HDPE LDPE PP PS OTHER");

        // gross_weight_kg — must be JSON number (decimal)
        if (!payload.TryGetProperty("gross_weight_kg", out var gEl) || gEl.ValueKind != JsonValueKind.Number)
            violations.Add("gross_weight_kg must be a JSON number");
        else { gross = gEl.GetDecimal(); if (gross <= 0m) violations.Add("gross_weight_kg must be > 0"); }

        // tare_weight_kg — must be JSON number (decimal)
        if (!payload.TryGetProperty("tare_weight_kg", out var tEl) || tEl.ValueKind != JsonValueKind.Number)
            violations.Add("tare_weight_kg must be a JSON number");
        else { tare = tEl.GetDecimal(); if (tare < 0m) violations.Add("tare_weight_kg must be >= 0"); }

        // net_weight_kg — present and is a number; used for sanity check only
        if (!payload.TryGetProperty("net_weight_kg", out var nEl) || nEl.ValueKind != JsonValueKind.Number)
            violations.Add("net_weight_kg must be a JSON number");
        else submittedNet = nEl.GetDecimal();

        // backend recomputes net; tolerance check
        backendNet = gross - tare;
        if (violations.Count == 0 && Math.Abs(submittedNet - backendNet) > 0.01m)
            violations.Add($"net_weight_kg {submittedNet} does not match gross {gross} minus tare {tare} within 0.01 tolerance");

        // collector_id
        if (!payload.TryGetProperty("collector_id", out var cidEl)
            || cidEl.ValueKind != JsonValueKind.String
            || string.IsNullOrWhiteSpace(cidEl.GetString()))
            violations.Add("collector_id is required and must be a non-empty string");

        return (violations.ToArray(), backendNet);
    }
}
