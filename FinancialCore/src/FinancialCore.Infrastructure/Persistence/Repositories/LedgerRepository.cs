using FinancialCore.Application.Interfaces;
using FinancialCore.Domain;
using Microsoft.EntityFrameworkCore;

namespace FinancialCore.Infrastructure.Persistence.Repositories;

public class LedgerRepository : ILedgerRepository
{
    private readonly FinancialCoreDbContext _dbContext;

    public LedgerRepository(FinancialCoreDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddRangeAsync(IEnumerable<LedgerEntry> entries, CancellationToken cancellationToken = default)
    {
        await _dbContext.LedgerEntries.AddRangeAsync(entries, cancellationToken);
    }

    public async Task<decimal> GetBalanceAsync(string accountId, string currency, CancellationToken cancellationToken = default)
    {
        // Using the view 'account_balances' via raw SQL since it's a view and we only need read access
        // Alternatively, map a Keyless Entity type to the view.
        // For simplicity and to ensure we use the view logic, let's map a keyless entity or query it.
        // But EF Core might not update the view in memory if we just added items in same transaction.
        // Wait, 'account_balances' view is derived from 'ledger_entries'.
        // If we are checking balance within a transaction where we JUST added entries, the view might return old data unless flush?
        // Actually, in same transaction, standard SQL behavior applies.
        
        // However, for pure read (proof of funds) we typically read committed state.
        // For validation during posting, we might need current snapshot.
        
        // Let's implement this by summing ledger entries directly to avoid View mapping complexity if we want, 
        // OR map the view. The implementation plan required the VIEW.
        // Let's rely on mapping. But since we haven't created a Domain Entity for Balance View, I'll use raw SQL query or just manual sum if performance isn't critical yet.
        // The spec says "Balance checks are performed as read-only queries over this view".
        
        // Let's query the view.
        // But first, I need ot Map it or use FromSqlRaw.
        // Since I didn't add the Keyless Entity in Domain, I'll use FromSqlRaw to a DTO or scalar.
        
        // Actually, simpler:
        // SELECT balance FROM account_balances WHERE account_id = {0} AND currency = {1}
        
        try 
        {
            // Note: Views are not automatically created by EF migrations if we wrote raw SQL script.
            // We assume the schema exists.
            
            var result = await _dbContext.Database
                .SqlQuery<decimal>($"SELECT balance FROM account_balances WHERE account_id = {accountId} AND currency = {currency}")
                .SingleOrDefaultAsync(cancellationToken);
                
            return result;
        }
        catch (InvalidOperationException) 
        {
            // No row found means balance 0
            return 0;
        }
    }

    public async Task<bool> HasEntryWithPostingKeyAsync(string instructionId, string postingKey, CancellationToken cancellationToken = default)
    {
        return await _dbContext.LedgerEntries
            .AnyAsync(e => e.InstructionId == instructionId && e.PostingKey == postingKey, cancellationToken);
    }
}
