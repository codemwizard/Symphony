namespace FinancialCore.Domain;

public class LedgerEntry
{
    public string LedgerEntryId { get; private set; }
    public string InstructionId { get; private set; }
    public string AccountId { get; private set; }
    
    // 'D' or 'C'
    public char Direction { get; private set; }
    
    public decimal Amount { get; private set; }
    public string Currency { get; private set; }
    
    public string PostingKey { get; private set; }
    public int PostingSequence { get; private set; }
    
    public DateTime CreatedAt { get; private set; }

    // Navigation property
    // public Instruction Instruction { get; private set; }

    protected LedgerEntry() { }

    public LedgerEntry(
        string ledgerEntryId,
        string instructionId,
        string accountId,
        char direction,
        decimal amount,
        string currency,
        string postingKey,
        int postingSequence)
    {
        if (direction != 'D' && direction != 'C')
            throw new ArgumentException("Direction must be 'D' or 'C'");
        if (amount <= 0)
            throw new ArgumentException("Amount must be positive");

        LedgerEntryId = ledgerEntryId;
        InstructionId = instructionId;
        AccountId = accountId;
        Direction = direction;
        Amount = amount;
        Currency = currency;
        PostingKey = postingKey;
        PostingSequence = postingSequence;
        CreatedAt = DateTime.UtcNow;
    }
}
