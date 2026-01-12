using FinancialCore.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FinancialCore.Infrastructure.Persistence.Configurations;

public class InstructionConfiguration : IEntityTypeConfiguration<Instruction>
{
    public void Configure(EntityTypeBuilder<Instruction> builder)
    {
        builder.ToTable("instructions");

        builder.HasKey(i => i.InstructionId);

        builder.Property(i => i.InstructionId)
            .HasColumnName("instruction_id");

        builder.Property(i => i.IdempotencyKey)
            .HasColumnName("idempotency_key")
            .IsRequired();

        builder.HasIndex(i => i.IdempotencyKey)
            .IsUnique();

        builder.Property(i => i.ParticipantId)
            .HasColumnName("participant_id")
            .IsRequired();

        builder.Property(i => i.InstructionType)
            .HasColumnName("instruction_type")
            .IsRequired();

        builder.Property(i => i.Amount)
            .HasColumnName("amount")
            .HasColumnType("numeric(18,2)")
            .IsRequired();

        builder.Property(i => i.Currency)
            .HasColumnName("currency")
            .HasMaxLength(3)
            .IsFixedLength()
            .IsRequired();

        builder.Property(i => i.DebitAccountId)
            .HasColumnName("debit_account_id")
            .IsRequired();

        builder.Property(i => i.CreditAccountId)
            .HasColumnName("credit_account_id")
            .IsRequired();

        builder.Property(i => i.State)
            .HasColumnName("state")
            .IsRequired();

        builder.Property(i => i.IsTerminal)
            .HasColumnName("is_terminal")
            .HasDefaultValue(false)
            .IsRequired();

        builder.Property(i => i.RailReference)
            .HasColumnName("rail_reference");

        builder.Property(i => i.FailureReason)
            .HasColumnName("failure_reason");

        builder.Property(i => i.CreatedAt)
            .HasColumnName("created_at")
            .HasDefaultValueSql("NOW()")
            .IsRequired();

        builder.Property(i => i.UpdatedAt)
            .HasColumnName("updated_at")
            .HasDefaultValueSql("NOW()")
            .IsRequired();

        builder.Property(i => i.Version)
            .HasColumnName("version")
            .IsConcurrencyToken()
            .HasDefaultValue(0)
            .IsRequired();
            
        // Map enum type
        // Note: This relies on Npgsql mapping in DbContext
    }
}
