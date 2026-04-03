# PWRM-002 Design

## FIX F11: structured_payload required — no two-class WEIGHBRIDGE_RECORD
The submit handler enforces this immediately after GPS validation:
```csharp
if (string.Equals(request.artifact_type.Trim(), Pwrm0001ArtifactTypes.WEIGHBRIDGE_RECORD, StringComparison.Ordinal))
{
    if (request.structured_payload is null ||
        request.structured_payload.Value.ValueKind == JsonValueKind.Null)
    {
        return new HandlerResult(StatusCodes.Status400BadRequest, new
        {
            error_code = "INVALID_REQUEST",
            errors = new[] { "structured_payload is required for WEIGHBRIDGE_RECORD" }
        });
    }
    // then validate
}
```
Result: every WEIGHBRIDGE_RECORD in the log is guaranteed to have non-null,
validated structured_payload. Read models in PWRM-003 and PWRM-004 rely on this
unconditionally.

## FIX F14: Backend net computation — client value is discarded as stored value
```csharp
// In Pwrm0001WeighbridgePayloadValidator:
var gross = grossEl.GetDecimal();   // decimal
var tare  = tareEl.GetDecimal();    // decimal
var submitted_net = netEl.GetDecimal();
var backend_net = gross - tare;     // decimal subtraction

if (Math.Abs(submitted_net - backend_net) > 0.01m)
    violations.Add($"net_weight_kg {submitted_net} does not match gross {gross} minus tare {tare} within 0.01 tolerance");

// The validator returns backend_net alongside violations:
return (violations.ToArray(), backend_net);
```
The submit handler stores `net_weight_kg = backend_net` in the log record.
The client-submitted `net_weight_kg` is never written to persistent storage.

## FIX F12: SemaphoreSlim serialises appends
```csharp
static class EvidenceLinkSubmissionLog
{
    private static readonly SemaphoreSlim _appendLock = new(1, 1);

    public static async Task AppendAsync(object payload, CancellationToken ct)
    {
        await _appendLock.WaitAsync(ct);
        try
        {
            var sequenceNumber = ReadAll().Count;
            // inject sequence_number into payload before writing
            Directory.CreateDirectory(Path.GetDirectoryName(PathValue)!);
            await TamperEvidentChain.AppendJsonAsync(PathValue, "evidence_event_submission",
                payload with { sequence_number = sequenceNumber }, ct);
        }
        finally { _appendLock.Release(); }
    }
}
```
Note: since `payload` is an anonymous object, sequence_number injection needs to
be done by constructing the full object before passing to `AppendJsonAsync`.
The lock ensures that `ReadAll().Count` is stable between read and write.

## Validator return type
`Pwrm0001WeighbridgePayloadValidator.Validate` returns `(string[] violations, decimal backendNet)`.
The submit handler uses `backendNet` as the stored value.

## Validation order in submit handler
1. Token validation
2. Tenant + MSISDN check
3. artifact_type / artifact_ref presence
4. **GPS validation** (outermost gate — always runs)
5. **WEIGHBRIDGE_RECORD required-payload check** (returns 400 if null)
6. **Weighbridge validator** (returns violations + backendNet)
7. sequence_number = ReadAll().Count (inside lock via AppendAsync)
8. Append to log (stores backendNet, not submitted net)

## New files
- `Commands/Pwrm0001ArtifactTypes.cs` — extended with validator (or companion)
- `Demo/WeighbridgeCaptureSelfTestRunner.cs`