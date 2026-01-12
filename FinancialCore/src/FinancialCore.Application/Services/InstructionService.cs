using FinancialCore.Application.Interfaces;
using FinancialCore.Domain;

namespace FinancialCore.Application.Services;

public class InstructionService : IInstructionService
{
    private readonly IInstructionRepository _instructionRepository;
    private readonly ILedgerRepository _ledgerRepository;
    private readonly IUnitOfWork _unitOfWork;

    public InstructionService(
        IInstructionRepository instructionRepository,
        ILedgerRepository ledgerRepository,
        IUnitOfWork unitOfWork)
    {
        _instructionRepository = instructionRepository;
        _ledgerRepository = ledgerRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<string>> CreateInstructionAsync(
        string idempotencyKey,
        string participantId,
        string instructionType,
        decimal amount,
        string currency,
        string debitAccountId,
        string creditAccountId,
        CancellationToken cancellationToken = default)
    {
        // Check idempotency
        var existing = await _instructionRepository.GetByIdempotencyKeyAsync(idempotencyKey, cancellationToken);
        if (existing != null)
        {
            return Result.Fail<string>("DUPLICATE_IDEMPOTENCY_KEY");
        }

        var instruction = new Instruction(
            Guid.NewGuid().ToString(),
            idempotencyKey,
            participantId,
            instructionType,
            amount,
            currency,
            debitAccountId,
            creditAccountId
        );

        await _instructionRepository.AddAsync(instruction, cancellationToken);
        await _unitOfWork.CommitAsync(cancellationToken);

        return Result.Ok(instruction.InstructionId);
    }

    public async Task<Result<Instruction>> GetInstructionAsync(string instructionId, CancellationToken cancellationToken = default)
    {
        var instruction = await _instructionRepository.GetByIdAsync(instructionId, cancellationToken);
        if (instruction == null)
        {
            return Result.Fail<Instruction>("INSTRUCTION_NOT_FOUND");
        }
        return Result.Ok(instruction);
    }

    public async Task<Result<Unit>> TransitionInstructionAsync(
        string instructionId,
        InstructionState targetState,
        string? railReference = null,
        string? failureReason = null,
        CancellationToken cancellationToken = default)
    {
        // 1. Load Instruction
        var instruction = await _instructionRepository.GetByIdAsync(instructionId, cancellationToken);
        if (instruction == null)
            return Result.Fail<Unit>("INSTRUCTION_NOT_FOUND");

        // 2. Domain Transition Logic
        var transitionResult = instruction.TransitionTo(targetState, railReference, failureReason);
        if (!transitionResult.IsSuccess)
            return transitionResult;

        // 3. Application Workflow (Atomic Transaction)
        // If transitioning to COMPLETED, we must create ledger entries.
        // If transitioning to FAILED, we just update state (no ledger entries for FAILED in this model, unless reversal? 
        // Spec says "Failures terminate before side-effects", implied no ledger entries).
        
        try
        {
            // We use UnitOfWork to ensure atomicity. 
            // NOTE: DbContext tracks changes to 'instruction' automatically because we loaded it from the same context.
            // But we need to define the transaction boundary explicitly if we are doing multi-step logic.
            
            // Actually, we should probably start a transaction explicitly to be safe and clear, 
            // especially since we might be reading then writing.
            // But standard EF Core SaveChanges is atomic.
            // However, we need to add Ledger Entries *before* saving if we want them in the same transaction.

            if (targetState == InstructionState.Completed)
            {
                // Create Ledger Entries
                var debitEntry = new LedgerEntry(
                    Guid.NewGuid().ToString(),
                    instruction.InstructionId,
                    instruction.DebitAccountId,
                    'D',
                    instruction.Amount,
                    instruction.Currency,
                    "posting-debit-" + instruction.InstructionId, // Simplistic posting key derivation
                    1
                );

                var creditEntry = new LedgerEntry(
                    Guid.NewGuid().ToString(),
                    instruction.InstructionId,
                    instruction.CreditAccountId,
                    'C',
                    instruction.Amount,
                    instruction.Currency,
                    "posting-credit-" + instruction.InstructionId,
                    2
                );

                await _ledgerRepository.AddRangeAsync(new[] { debitEntry, creditEntry }, cancellationToken);
            }

            // Save everything (Instruction update + Ledger entries if any)
            await _unitOfWork.CommitAsync(cancellationToken);
            
            return Result.Ok(new Unit());
        }
        catch (Exception ex)
        {
            // Log exception?
            // If it's a DbUpdateException (e.g. concurrency or unique constraint), return appropriate error
             if (ex.InnerException?.Message.Contains("ux_instruction_single_success") == true)
             {
                 return Result.Fail<Unit>("ALREADY_TERMINAL"); // Or CONCURRENT_MODIFICATION
             }
             if (ex.InnerException?.Message.Contains("ux_posting_idempotency") == true)
             {
                 return Result.Fail<Unit>("DUPLICATE_POSTING");
             }
             
             // Generic for now, but in production we'd map exceptions better
             throw; 
        }
    }
}
