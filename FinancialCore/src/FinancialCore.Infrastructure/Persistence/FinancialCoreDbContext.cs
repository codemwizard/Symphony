using FinancialCore.Domain;
using FinancialCore.Infrastructure.Persistence.Configurations;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace FinancialCore.Infrastructure.Persistence;

public class FinancialCoreDbContext : DbContext
{
    public DbSet<Instruction> Instructions { get; set; } = null!;
    public DbSet<LedgerEntry> LedgerEntries { get; set; } = null!;

    static FinancialCoreDbContext()
    {
        // Register enum type globally for Npgsql source caching
        // This is required to map the PostgreSQL enum 'instruction_state' to the C# enum 'InstructionState'
        NpgsqlConnection.GlobalTypeMapper.MapEnum<InstructionState>("instruction_state");
    }

    public FinancialCoreDbContext(DbContextOptions<FinancialCoreDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Register the enum type with the model builder
        modelBuilder.HasPostgresEnum<InstructionState>("instruction_state");

        // Apply entity configurations
        modelBuilder.ApplyConfiguration(new InstructionConfiguration());
        modelBuilder.ApplyConfiguration(new LedgerEntryConfiguration());
    }
}
