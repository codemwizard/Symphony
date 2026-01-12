using FinancialCore.Domain;

namespace FinancialCore.Application.Interfaces;

public interface IInstructionRepository
{
    Task<Instruction?> GetByIdAsync(string instructionId, CancellationToken cancellationToken = default);
    Task<Instruction?> GetByIdempotencyKeyAsync(string idempotencyKey, CancellationToken cancellationToken = default);
    Task AddAsync(Instruction instruction, CancellationToken cancellationToken = default);
    Task UpdateAsync(Instruction instruction, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(string instructionId, CancellationToken cancellationToken = default);
}
