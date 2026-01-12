using FinancialCore.Domain;

namespace FinancialCore.Application.Interfaces;

public interface ILedgerService
{
    Task<decimal> GetBalanceAsync(string accountId, string currency, CancellationToken cancellationToken = default);
    
    Task<Result<Unit>> ValidatePostingAsync(
         string instructionId,
         string debitAccountId,
         string creditAccountId,
         decimal amount,
         string currency,
         CancellationToken cancellationToken = default);
}
