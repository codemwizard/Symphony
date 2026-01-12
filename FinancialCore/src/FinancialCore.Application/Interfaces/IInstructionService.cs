using FinancialCore.Domain;

namespace FinancialCore.Application.Interfaces;

public interface IInstructionService
{
    Task<Result<string>> CreateInstructionAsync(
        string idempotencyKey,
        string participantId,
        string instructionType,
        decimal amount,
        string currency,
        string debitAccountId,
        string creditAccountId,
        CancellationToken cancellationToken = default);

    Task<Result<Instruction>> GetInstructionAsync(string instructionId, CancellationToken cancellationToken = default);

    Task<Result<Unit>> TransitionInstructionAsync(
        string instructionId,
        InstructionState targetState,
        string? railReference = null,
        string? failureReason = null,
        CancellationToken cancellationToken = default);
}
