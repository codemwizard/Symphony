using FinancialCore.Domain;

namespace FinancialCore.Application.Interfaces;

public interface ILedgerRepository
{
    Task AddRangeAsync(IEnumerable<LedgerEntry> entries, CancellationToken cancellationToken = default);
    Task<decimal> GetBalanceAsync(string accountId, string currency, CancellationToken cancellationToken = default);
    Task<bool> HasEntryWithPostingKeyAsync(string instructionId, string postingKey, CancellationToken cancellationToken = default);
}
