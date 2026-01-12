using FinancialCore.Application.Interfaces;
using FinancialCore.Domain;
using Microsoft.AspNetCore.Mvc;

namespace FinancialCore.Api.Controllers;

[ApiController]
[Route("api/v1/instructions")]
public class InstructionsController : ControllerBase
{
    private readonly IInstructionService _instructionService;

    public InstructionsController(IInstructionService instructionService)
    {
        _instructionService = instructionService;
    }

    // GET /api/v1/instructions/{instructionId}/state
    [HttpGet("{instructionId}/state")]
    public async Task<IActionResult> GetState(string instructionId)
    {
        var result = await _instructionService.GetInstructionAsync(instructionId);
        if (!result.IsSuccess)
        {
            return NotFound(new { error = "INSTRUCTION_NOT_FOUND", message = "Instruction not found", instructionId });
        }

        var instr = result.Value!;
        return Ok(new
        {
            instructionId = instr.InstructionId,
            state = instr.State.ToString().ToUpper(),
            isTerminal = instr.IsTerminal,
            createdAt = instr.CreatedAt,
            updatedAt = instr.UpdatedAt,
            participantId = instr.ParticipantId,
            idempotencyKey = instr.IdempotencyKey
        });
    }

    // POST /api/v1/instructions/{instructionId}/transition
    [HttpPost("{instructionId}/transition")]
    public async Task<IActionResult> Transition(string instructionId, [FromBody] TransitionRequest request)
    {
        // Parse target state enum
        if (!Enum.TryParse<InstructionState>(request.TargetState, true, out var targetDto))
        {
             return BadRequest(new { error = "INVALID_STATE", message = "Invalid target state" });
        }

        var result = await _instructionService.TransitionInstructionAsync(
            instructionId, 
            targetDto, 
            request.RailReference, 
            request.Reason); // Map reason to FailureReason for FAILED? Spec says "reason" in body.

        if (!result.IsSuccess)
        {
            if (result.Error == "INSTRUCTION_NOT_FOUND")
                return NotFound(new { error = "INSTRUCTION_NOT_FOUND" });
            if (result.Error == "ALREADY_TERMINAL")
                return Conflict(new { error = "ALREADY_TERMINAL", message = "Instruction is already in a terminal state" });
            if (result.Error == "INVALID_TRANSITION")
                return Conflict(new { error = "INVALID_TRANSITION", message = "State transition not allowed" });
            
            return StatusCode(500, new { error = "INTERNAL_ERROR", message = result.Error });
        }

        return Ok(new { accepted = true, instructionId, newState = targetDto.ToString().ToUpper() });
    }
    
    // POST /api/v1/instructions (Create)
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateInstructionRequest request)
    {
        var result = await _instructionService.CreateInstructionAsync(
            request.IdempotencyKey,
            request.ParticipantId,
            request.InstructionType,
            decimal.Parse(request.Amount), // Assuming string input for precision, but simple Parse for now
            request.Currency,
            request.DebitAccountId,
            request.CreditAccountId
        );

        if (!result.IsSuccess)
        {
            if (result.Error == "DUPLICATE_IDEMPOTENCY_KEY")
                return Conflict(new { error = "DUPLICATE_IDEMPOTENCY_KEY", message = "Instruction with this idempotency key already exists" });

            return StatusCode(500, new { error = "INTERNAL_ERROR", message = result.Error });
        }

        return CreatedAtAction(nameof(GetState), new { instructionId = result.Value }, new { instructionId = result.Value });
    }
}

public class TransitionRequest
{
    public string TargetState { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public string? RailReference { get; set; }
    public string? ReconciliationEventId { get; set; }
}

public class CreateInstructionRequest
{
    public string IdempotencyKey { get; set; } = string.Empty;
    public string ParticipantId { get; set; } = string.Empty;
    public string InstructionType { get; set; } = string.Empty;
    public string Amount { get; set; } = string.Empty; // String to avoid float precision issues in JSON
    public string Currency { get; set; } = string.Empty;
    public string DebitAccountId { get; set; } = string.Empty;
    public string CreditAccountId { get; set; } = string.Empty;
}
