using FinancialCore.Domain;
using Xunit;

namespace FinancialCore.Tests;

public class DomainInvariantTests
{
    [Fact]
    public void Cannot_Transition_From_Terminal_State()
    {
        // Arrange
        var instruction = new Instruction(
            "instr-1", "idem-1", "part-1", "PAYMENT", 100m, "USD", "acct-1", "acct-2");
        
        instruction.TransitionTo(InstructionState.Authorized);
        instruction.TransitionTo(InstructionState.Executing);
        instruction.TransitionTo(InstructionState.Completed); // Now terminal
        
        Assert.True(instruction.IsTerminal);
        
        // Act
        var result = instruction.TransitionTo(InstructionState.Failed);
        
        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal("ALREADY_TERMINAL", result.Error);
    }

    [Fact]
    public void Cannot_Skip_States()
    {
        var instruction = new Instruction(
            "instr-1", "idem-1", "part-1", "PAYMENT", 100m, "USD", "acct-1", "acct-2");
            
        // Act: Received -> Completed (Skipping Auth/Exec)
        var result = instruction.TransitionTo(InstructionState.Completed);
        
        // Assert
        Assert.False(result.IsSuccess);
        Assert.Equal("INVALID_TRANSITION", result.Error);
    }
}
