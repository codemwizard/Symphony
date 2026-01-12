using FinancialCore.Application.Interfaces;
using FinancialCore.Application.Services;
using FinancialCore.Infrastructure.Persistence;
using FinancialCore.Infrastructure.Persistence.Repositories;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography.X509Certificates;

var builder = WebApplication.CreateBuilder(args);

// 1. Validate Environment Variables (Secure Coding Standard)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrEmpty(connectionString))
{
    // Check ENV var directly if config source is missing
    connectionString = Environment.GetEnvironmentVariable("POSTGRES_CONNECTION_STRING");
    if (string.IsNullOrEmpty(connectionString))
    {
        Console.Error.WriteLine("FATAL: Missing required environment variable 'POSTGRES_CONNECTION_STRING' or ConnectionString:DefaultConnection");
        Environment.Exit(1);
    }
}

// 2. Configure Database
builder.Services.AddDbContext<FinancialCoreDbContext>(options =>
    options.UseNpgsql(connectionString));

// 3. Register Application Services (DI)
builder.Services.AddScoped<IInstructionRepository, InstructionRepository>();
builder.Services.AddScoped<ILedgerRepository, LedgerRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<IInstructionService, InstructionService>();
builder.Services.AddScoped<ILedgerService, LedgerService>();

// 4. Configure API
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 5. Configure Pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

// 6. Ensure Database Created (Development Only - or use migrations properly)
// For sandbox, we might want to auto-migrate.
// using (var scope = app.Services.CreateScope())
// {
//     var db = scope.ServiceProvider.GetRequiredService<FinancialCoreDbContext>();
//     // db.Database.EnsureCreated(); // Or Migrate()
// }

app.Run();
