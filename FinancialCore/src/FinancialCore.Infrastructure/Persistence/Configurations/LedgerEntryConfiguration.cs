using FinancialCore.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialCore.Infrastructure.Persistence.Configurations;

public class LedgerEntryConfiguration : IEntityTypeConfiguration<LedgerEntry>
{
    public void Configure(EntityTypeBuilder<LedgerEntry> builder)
    {
        builder.ToTable("ledger_entries");

        builder.HasKey(e => e.LedgerEntryId);

        builder.Property(e => e.LedgerEntryId)
            .HasColumnName("ledger_entry_id");

        builder.Property(e => e.InstructionId)
            .HasColumnName("instruction_id")
            .IsRequired();

        builder.Property(e => e.AccountId)
            .HasColumnName("account_id")
            .IsRequired();

        builder.Property(e => e.Direction)
            .HasColumnName("direction")
            .IsRequired();

        builder.Property(e => e.Amount)
            .HasColumnName("amount")
            .HasColumnType("numeric(18,2)")
            .IsRequired();

        builder.Property(e => e.Currency)
            .HasColumnName("currency")
            .HasMaxLength(3)
            .IsFixedLength()
            .IsRequired();

        builder.Property(e => e.PostingKey)
            .HasColumnName("posting_key")
            .IsRequired();

        builder.Property(e => e.PostingSequence)
            .HasColumnName("posting_sequence")
            .IsRequired();

        builder.Property(e => e.CreatedAt)
            .HasColumnName("created_at")
            .HasDefaultValueSql("NOW()")
            .IsRequired();

        // Unique constraint on (InstructionId, PostingKey)
        builder.HasIndex(e => new { e.InstructionId, e.PostingKey })
            .IsUnique()
            .HasDatabaseName("ux_posting_idempotency");
            
        // Unique constraint on (InstructionId, PostingSequence)
        builder.HasIndex(e => new { e.InstructionId, e.PostingSequence })
            .IsUnique()
            .HasDatabaseName("ux_instruction_posting_sequence");
    }
}
