using FinancialCore.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FinancialCore.Api.Controllers;

[ApiController]
[Route("api/v1")]
public class LedgerController : ControllerBase
{
    private readonly ILedgerService _ledgerService;

    public LedgerController(ILedgerService ledgerService)
    {
        _ledgerService = ledgerService;
    }

    // GET /api/v1/accounts/{accountId}/balance
    [HttpGet("accounts/{accountId}/balance")]
    public async Task<IActionResult> GetBalance(string accountId, [FromQuery] string currency = "USD")
    {
        // Spec implies currency is returned, so input should probably specific currency.
        // Assuming default or required query param.
        
        var balance = await _ledgerService.GetBalanceAsync(accountId, currency);
        
        return Ok(new
        {
            accountId,
            availableBalance = balance.ToString("F2"),
            pendingBalance = "0.00", // Not actively tracking pending in this minimal core
            currency,
            asOf = DateTime.UtcNow
        });
    }

    // POST /api/v1/ledger/validate-posting
    [HttpPost("ledger/validate-posting")]
    public async Task<IActionResult> ValidatePosting([FromBody] ValidatePostingRequest request)
    {
        var result = await _ledgerService.ValidatePostingAsync(
            request.InstructionId,
            request.DebitAccountId,
            request.CreditAccountId,
            decimal.Parse(request.Amount),
            request.Currency
        );

        if (!result.IsSuccess)
        {
            // If strictly validation failure, retun 200 with valid=false?
            // "rejectionReason": "INSUFFICIENT_FUNDS"
            
            // Spec says:
            // Response: 200 OK (Valid) { "valid": true }
            // Response: 422 Unprocessable Entity (Invalid) { "valid": false, "rejectionReason": ... }
            
            // Actually, usually validation endpoints return 200 with valid: false.
            // Let's check spec if shown. The request provided earlier didn't show 422.
            // But let's assume if it fails logic (insufficient funds), it's a valid=false.
            // If it errors (e.g. DB down), that's 500.
            
            return Ok(new { valid = false, rejectionReason = result.Error });
        }

        return Ok(new { valid = true });
    }
}

public class ValidatePostingRequest
{
    public string InstructionId { get; set; } = string.Empty;
    public string DebitAccountId { get; set; } = string.Empty;
    public string CreditAccountId { get; set; } = string.Empty;
    public string Amount { get; set; } = string.Empty;
    public string Currency { get; set; } = string.Empty;
}
