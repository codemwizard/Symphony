using FinancialCore.Application.Interfaces;
using FinancialCore.Application.Services;
using FinancialCore.Domain;
using FinancialCore.Infrastructure.Persistence;
using FinancialCore.Infrastructure.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace FinancialCore.Tests;

public class AtomicityTests
{
    private FinancialCoreDbContext GetInMemoryDbContext()
    {
        var options = new DbContextOptionsBuilder<FinancialCoreDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        
        return new FinancialCoreDbContext(options);
    }

    [Fact]
    public async Task Transition_Rejected_If_Ledger_Posting_Fails_MandatoryAtomicTest()
    {
        // Arrange
        using var context = GetInMemoryDbContext();
        var instructionRepo = new InstructionRepository(context);
        var unitOfWork = new UnitOfWork(context);
        
        // Mock Ledger Repository to FAIL on addition
        var failingLedgerRepo = new MockFailingLedgerRepository();
        
        var service = new InstructionService(instructionRepo, failingLedgerRepo, unitOfWork);
        
        // Create initial instruction in EXECUTING state
        var instruction = new Instruction(
            "instr-fail-test",
            "idem-key-fail",
            "participant-1",
            "PAYMENT",
            100m,
            "USD",
            "acct-1",
            "acct-2");
        
        // transition to executing manually for setup
        instruction.TransitionTo(InstructionState.Authorized);
        instruction.TransitionTo(InstructionState.Executing);
        
        await instructionRepo.AddAsync(instruction);
        await unitOfWork.CommitAsync();

        // Act
        // Attempt transition to COMPLETED, which triggers ledger posting
        var ex = await Assert.ThrowsAsync<Exception>(() => 
            service.TransitionInstructionAsync("instr-fail-test", InstructionState.Completed));
            
        // Assert
        Assert.Equal("INTENTIONAL_LEDGER_FAILURE", ex.Message);
        
        // Verify Instruction State ROLLED BACK
        // In EF Core InMemory, if exception is thrown during Commit, changes might be in local tracker but not committed.
        // We need to re-fetch from a fresh context or check DB state.
        
        // However, InstructionService updates state on line 77, then adds ledger entries, then Commits.
        // If Fail happens during LedgerRepo.AddRange (which is before commit in my impl? No, AddRange is async but usually just tracks).
        // My MockFailingLedgerRepository will throw immediately on AddRange.
        
        // So UnitOfWork.Commit is never called.
        // The instruction entity in memory is modified.
        // But the DATABASE (simulated) should remain unchanged.
        
        var reloadedInstruction = await instructionRepo.GetByIdAsync("instr-fail-test");
        
        // In a real integration test with TransactionScope, the DB transaction would rollback.
        // Here, since Commit wasn't called, the DB shouldn't be updated.
        // But EF Core In-Memory behaves slightly differently if we reuse context.
        // Reloading from context might show dirty state.
        
        context.ChangeTracker.Clear(); // Detach all to fetch fresh from "DB"
        var freshDownload = await instructionRepo.GetByIdAsync("instr-fail-test");
        
        Assert.Equal(InstructionState.Executing, freshDownload!.State);
        Assert.False(freshDownload.IsTerminal);
    }
}

public class MockFailingLedgerRepository : ILedgerRepository
{
    public Task AddRangeAsync(IEnumerable<LedgerEntry> entries, CancellationToken cancellationToken = default)
    {
        throw new Exception("INTENTIONAL_LEDGER_FAILURE");
    }

    public Task<decimal> GetBalanceAsync(string accountId, string currency, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(1000m);
    }

    public Task<bool> HasEntryWithPostingKeyAsync(string instructionId, string postingKey, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(false);
    }
}
