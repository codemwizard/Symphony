using FinancialCore.Application.Interfaces;
using FinancialCore.Domain;
using Microsoft.EntityFrameworkCore;

namespace FinancialCore.Infrastructure.Persistence.Repositories;

public class InstructionRepository : IInstructionRepository
{
    private readonly FinancialCoreDbContext _dbContext;

    public InstructionRepository(FinancialCoreDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<Instruction?> GetByIdAsync(string instructionId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Instructions
            .FirstOrDefaultAsync(i => i.InstructionId == instructionId, cancellationToken);
    }

    public async Task<Instruction?> GetByIdempotencyKeyAsync(string idempotencyKey, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Instructions
            .FirstOrDefaultAsync(i => i.IdempotencyKey == idempotencyKey, cancellationToken);
    }

    public async Task AddAsync(Instruction instruction, CancellationToken cancellationToken = default)
    {
        await _dbContext.Instructions.AddAsync(instruction, cancellationToken);
    }

    public Task UpdateAsync(Instruction instruction, CancellationToken cancellationToken = default)
    {
        _dbContext.Instructions.Update(instruction);
        return Task.CompletedTask;
    }
    
    public async Task<bool> ExistsAsync(string instructionId, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Instructions
            .AnyAsync(i => i.InstructionId == instructionId, cancellationToken);
    }
}
