namespace FinancialCore.Domain;

// AUTHORIZED indicates that the instruction has passed all pre-execution
// policy, balance, and eligibility checks. It does not imply external rail acceptance.
public enum InstructionState
{
    Received,
    Authorized,
    Executing,
    Completed, // Terminal
    Failed     // Terminal
}
