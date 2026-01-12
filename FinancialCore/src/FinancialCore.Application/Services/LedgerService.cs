using FinancialCore.Application.Interfaces;
using FinancialCore.Domain;

namespace FinancialCore.Application.Services;

public class LedgerService : ILedgerService
{
    private readonly ILedgerRepository _ledgerRepository;
    private readonly IInstructionRepository _instructionRepository;

    public LedgerService(ILedgerRepository ledgerRepository, IInstructionRepository instructionRepository)
    {
        _ledgerRepository = ledgerRepository;
        _instructionRepository = instructionRepository;
    }

    public async Task<decimal> GetBalanceAsync(string accountId, string currency, CancellationToken cancellationToken = default)
    {
        return await _ledgerRepository.GetBalanceAsync(accountId, currency, cancellationToken);
    }

    public async Task<Result<Unit>> ValidatePostingAsync(
        string instructionId,
        string debitAccountId,
        string creditAccountId,
        decimal amount,
        string currency,
        CancellationToken cancellationToken = default)
    {
        // 1. Check if instruction exists (optional, but good for context)
        // actually validate-posting endpoint might be called before instruction creation? 
        // Spec says: "Pre-validate a posting (proof-of-funds check)."
        // The Request object has instructionId.
        
        // 2. Check Debtor Balance
        var debtorBalance = await _ledgerRepository.GetBalanceAsync(debitAccountId, currency, cancellationToken);
        
        // Simple logic: Balance must be sufficient.
        // Assuming 'balance' is a net sum. If account is Liability/Equity, credit is positive. If Asset, debit is positive?
        // Schema view: C is +, D is -. 
        // So for a standard bank account (Liability from bank perspective), a positive balance means funds available.
        // Debiting reduces the balance.
        
        if (debtorBalance < amount)
        {
            return Result.Fail<Unit>("INSUFFICIENT_FUNDS");
        }
        
        return Result.Ok(new Unit());
    }
}
