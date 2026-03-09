using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Npgsql;

record RegulatoryIncidentRecord(
    string IncidentId,
    string TenantId,
    string IncidentType,
    string DetectedAt,
    string Description,
    string Severity,
    string Status,
    string? ReportedToBozAt,
    string? BozReference,
    string CreatedAt
);

record RegulatoryIncidentEventRecord(
    string IncidentId,
    string EventType,
    string EventPayload,
    string CreatedAt
);

record RegulatoryIncidentCreateResult(
    bool Success,
    string? IncidentId,
    string? TenantId,
    string? Status,
    string? CreatedAt,
    string? Error)
{
    public static RegulatoryIncidentCreateResult Ok(string incidentId, string tenantId, string status, string createdAt)
        => new(true, incidentId, tenantId, status, createdAt, null);

    public static RegulatoryIncidentCreateResult Fail(string error)
        => new(false, null, null, null, null, error);
}

record RegulatoryIncidentUpdateResult(bool Success, string? Error)
{
    public static RegulatoryIncidentUpdateResult Ok() => new(true, null);
    public static RegulatoryIncidentUpdateResult Fail(string error) => new(false, error);
}

record RegulatoryIncidentReportLookup(
    bool Found,
    RegulatoryIncidentRecord? Incident,
    IReadOnlyList<RegulatoryIncidentEventRecord> Timeline,
    string? Error);

interface IRegulatoryIncidentStore
{
    Task<RegulatoryIncidentCreateResult> CreateIncidentAsync(RegulatoryIncidentCreateRequest request, CancellationToken cancellationToken);
    Task<RegulatoryIncidentUpdateResult> UpdateStatusAsync(string incidentId, string status, CancellationToken cancellationToken);
    Task<RegulatoryIncidentReportLookup> GetIncidentReportDataAsync(string incidentId, CancellationToken cancellationToken);
}

static class RegulatoryIncidentValidation
{
    private static readonly HashSet<string> AllowedSeverity = new(StringComparer.OrdinalIgnoreCase)
    {
        "LOW", "MEDIUM", "HIGH", "CRITICAL"
    };

    private static readonly HashSet<string> AllowedStatus = new(StringComparer.OrdinalIgnoreCase)
    {
        "OPEN", "UNDER_INVESTIGATION", "REPORTED", "CLOSED"
    };

    public static List<string> ValidateCreateRequest(RegulatoryIncidentCreateRequest request)
    {
        var errors = new List<string>();
        if (!Guid.TryParse(request.tenant_id, out _))
        {
            errors.Add("tenant_id must be a valid UUID");
        }
        if (!DateTimeOffset.TryParse(request.detected_at, out _))
        {
            errors.Add("detected_at must be ISO 8601");
        }
        if (string.IsNullOrWhiteSpace(request.incident_type))
        {
            errors.Add("incident_type is required");
        }
        if (string.IsNullOrWhiteSpace(request.description))
        {
            errors.Add("description is required");
        }
        if (!AllowedSeverity.Contains(request.severity ?? string.Empty))
        {
            errors.Add("severity must be one of LOW|MEDIUM|HIGH|CRITICAL");
        }
        return errors;
    }

    public static bool IsAllowedStatus(string status) => AllowedStatus.Contains(status);
}
