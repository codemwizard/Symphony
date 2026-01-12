namespace FinancialCore.Domain;

public class Instruction
{
    public string InstructionId { get; private set; }
    public string IdempotencyKey { get; private set; }
    public string InstructionType { get; private set; }
    public string ParticipantId { get; private set; }
    
    public decimal Amount { get; private set; }
    public string Currency { get; private set; }
    
    public string DebitAccountId { get; private set; }
    public string CreditAccountId { get; private set; }

    public InstructionState State { get; private set; }
    public bool IsTerminal { get; private set; }
    
    public string? RailReference { get; private set; }
    public string? FailureReason { get; private set; }
    
    public DateTime CreatedAt { get; private set; }
    public DateTime UpdatedAt { get; private set; }
    public int Version { get; private set; }

    // EF Core constructor
    protected Instruction() { }

    public Instruction(
        string instructionId, 
        string idempotencyKey, 
        string participantId, 
        string instructionType,
        decimal amount,
        string currency,
        string debitAccountId,
        string creditAccountId)
    {
        if (amount <= 0) throw new ArgumentException("Amount must be positive");

        InstructionId = instructionId;
        IdempotencyKey = idempotencyKey;
        ParticipantId = participantId;
        InstructionType = instructionType;
        Amount = amount;
        Currency = currency;
        DebitAccountId = debitAccountId;
        CreditAccountId = creditAccountId;
        
        State = InstructionState.Received;
        IsTerminal = false;
        CreatedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
        Version = 0;
    }

    public Result<Unit> TransitionTo(InstructionState target, string? railRef = null, string? failReason = null)
    {
        // MANDATORY: Terminal state guard
        if (IsTerminal)
            return Result.Fail<Unit>("ALREADY_TERMINAL");
        
        // Enforce transition rules
        if (!IsValidTransition(State, target))
            return Result.Fail<Unit>("INVALID_TRANSITION");
        
        State = target;
        UpdatedAt = DateTime.UtcNow;
        Version++;

        if (State == InstructionState.Completed || State == InstructionState.Failed)
        {
            IsTerminal = true;
        }

        if (railRef != null) RailReference = railRef;
        if (failReason != null) FailureReason = failReason;

        return Result.Ok(new Unit());
    }
    
    private static bool IsValidTransition(InstructionState from, InstructionState to)
    {
        return (from, to) switch
        {
            (InstructionState.Received, InstructionState.Authorized) => true,
            (InstructionState.Authorized, InstructionState.Executing) => true,
            (InstructionState.Executing, InstructionState.Completed) => true,
            (InstructionState.Executing, InstructionState.Failed) => true,
            _ => false
        };
    }
}
