# Phase-1 AI Agent Orchestration Strategy
**Symphony Financial Infrastructure - .NET 10 Implementation**  
**Date**: February 9, 2026  
**Context**: Transitioning from Phase-0 (database foundation) to Phase-1 (runtime implementation)

---

## Executive Summary

Your current detailed task approach works but creates **friction** and **overhead**. Based on your Phase-0 execution excellence and the Phase-1 roadmap, I recommend a **hybrid tiered approach** that gives AI agents:

1. **Strong guardrails** (invariants, contracts, security policies)
2. **Clear outcomes** (what, not how)
3. **Contextual autonomy** (bounded creativity within constraints)

This balances **control** (Tier-1 financial requirements) with **velocity** (letting AI solve implementation details).

---

## Current Approach Analysis

### What You're Doing Now ✅
```yaml
# Example: TSK-P0-XXX style
task_id: "TSK-P0-010"
deliverables:
  - "Specific migration file with exact columns"
  - "Exact verifier script path"
  - "Precise evidence JSON structure"
implementation_steps:
  - "Step 1: Create this exact file"
  - "Step 2: Add these exact lines"
  - "Step 3: Run this exact command"
```

### Strengths
- ✅ Deterministic outcomes
- ✅ Easy to verify completion
- ✅ Works well for structural tasks (Phase-0)
- ✅ Prevents AI from inventing architecture

### Weaknesses for Phase-1
- ❌ **Over-specified for implementation code** - AI can't leverage its coding strengths
- ❌ **Serial execution** - forces waterfall when some tasks could parallelize
- ❌ **Brittle** - small changes cascade to many task rewrites
- ❌ **Missing feedback loops** - no room for "this approach didn't work, try alternative"
- ❌ **Agent dependency** - requires human to write perfect specs upfront

---

## Recommended Approach: **Tiered Agent Autonomy Framework**

### Principle: Match Constraint Level to Risk Level

```
┌─────────────────────────────────────────────────────┐
│  TIER 1: INVARIANT-CONSTRAINED (Strict)            │
│  → Database schema, security boundaries, compliance │
│  → AI gets: Outcome + Constraints, chooses path    │
├─────────────────────────────────────────────────────┤
│  TIER 2: CONTRACT-GUIDED (Guided)                  │
│  → API contracts, service boundaries, data flow    │
│  → AI gets: Interface spec, picks implementation   │
├─────────────────────────────────────────────────────┤
│  TIER 3: PATTERN-BASED (Autonomous)                │
│  → Business logic, utilities, internal plumbing    │
│  → AI gets: Requirements + examples, creates code  │
└─────────────────────────────────────────────────────┘
```

---

## Tier 1: Invariant-Constrained Tasks (Database, Security, Compliance)

**Use for**: Schema changes, security boundaries, regulatory hooks

### Task Structure
```yaml
# tasks/phase1/TSK-P1-010-instruction-finality/MISSION.md

## Mission
Implement runtime enforcement of INV-111 (Instruction Finality Invariant)

## Invariant Contract (NON-NEGOTIABLE)
- Once instruction.status = 'finalized', NO mutations allowed
- Violation attempts MUST be logged and rejected
- Evidence MUST emit to: evidence/phase1/instruction_finality_runtime.json

## Success Criteria
✅ INT-G25 gate passes in CI
✅ Verifier script returns PASS with evidence
✅ Manual test: attempt to update finalized instruction → rejected

## Constraints
- MUST use existing schema: ledger.instruction_ledger
- MUST NOT add new tables (reuse existing audit pattern)
- Security: State transitions require authenticated tenant context
- Performance: State check adds <10ms to write path

## Context Files
- docs/architecture/adrs/ADR-0002-ledger-immutability-reconciliation.md
- scripts/db/verify_instruction_finality_invariant.sh (stub, needs implementation)
- Phase-0 example: scripts/db/verify_business_foundation_hooks.sh

## Agent Freedom
- Choose: .NET middleware vs. database trigger vs. hybrid
- Choose: Exception type and error codes
- Choose: Logging framework integration approach
- Design: Evidence JSON structure (must include: timestamp, tenant_id, instruction_id, violation_type)

## Forbidden Approaches
- ❌ Soft-delete instead of hard rejection
- ❌ Client-side only validation (must be server-enforced)
- ❌ Logging PII in evidence (tenant_id OK, member names NOT OK)

## Acceptance Test
```csharp
// Provided by human, AI must make this pass
[Fact]
public async Task FinalizedInstruction_RejectsUpdate()
{
    var instruction = await CreateAndFinalizeInstruction();
    
    await Assert.ThrowsAsync<InstructionFinalizedViolation>(
        () => instruction.UpdateAmount(newAmount: 999)
    );
    
    var evidence = await LoadEvidence("instruction_finality_runtime.json");
    Assert.Equal("PASS", evidence.Status);
    Assert.Contains(instruction.Id, evidence.ViolationsBlocked);
}
```
```

### Why This Works
- **Outcome-focused**: "Reject finalized updates" vs "Add these 47 lines to InstructionService.cs"
- **Bounded autonomy**: AI chooses implementation, not architecture
- **Verifiable**: Test must pass, gate must pass, evidence must exist
- **Traceable**: Forbidden approaches prevent common AI mistakes

---

## Tier 2: Contract-Guided Tasks (Services, APIs, Integrations)

**Use for**: New services, API endpoints, cross-service communication

### Task Structure
```yaml
# tasks/phase1/TSK-P1-020-payment-orchestration-service/MISSION.md

## Mission
Build Payment Orchestration Service that coordinates: 
Ingress → Validation → Ledger → Outbox → PSP Integration

## API Contract (FIXED)
```csharp
// src/Services/PaymentOrchestration/IPaymentOrchestrator.cs
public interface IPaymentOrchestrator
{
    Task<PaymentResult> ProcessPaymentAsync(
        PaymentRequest request, 
        CancellationToken ct
    );
    
    Task<PaymentStatus> GetStatusAsync(
        Guid correlationId, 
        CancellationToken ct
    );
}

public record PaymentResult(
    Guid CorrelationId,
    PaymentStatus Status,
    string? ErrorCode,
    DateTimeOffset ProcessedAt
);
```

## Non-Functional Requirements
- Latency: P95 < 200ms (measured via INT-G25 evidence)
- Idempotency: Duplicate requests return cached result (no double-spend)
- Resilience: Retry PSP calls with exponential backoff (max 3 attempts)
- Observability: OpenTelemetry traces, structured logs

## Integration Points
```yaml
Depends on:
  - Ledger Service (already exists from Phase-0 migration executor)
  - Outbox Pattern (schema exists, needs .NET publisher)
  
Provides to:
  - API Gateway (Phase-1 task TSK-P1-025)
  - Webhook Handler (Phase-1 task TSK-P1-030)
```

## Architectural Constraints
- MUST use MediatR for internal command/query separation
- MUST implement IPaymentOrchestrator (can add internal interfaces)
- Database access ONLY via repositories (no raw SQL in service)
- Configuration via IOptions<PaymentOrchestratorConfig>

## Reference Implementations
- Example service: src/Services/TenantService/ (Phase-0 stub)
- Retry pattern: Use Polly with jitter
- Evidence emission: See scripts/db/verify_business_foundation_hooks.sh

## Agent Freedom
- Choose: Service layer architecture (handlers, validators, mappers)
- Choose: Unit of Work vs DbContext per request
- Design: Internal error taxonomy
- Design: Metrics and logging structure
- Optimize: Parallel validation steps (if safe)

## Success Criteria
✅ All API contract methods implemented
✅ Integration tests pass (provided by human)
✅ P95 latency < 200ms in load test (10 TPS for 1 min)
✅ Code coverage > 80%
✅ No compiler warnings

## Load Test (Provided)
```bash
# scripts/phase1/load_test_payment_orchestrator.sh
# AI doesn't write this, but must make it pass
artillery run --target http://localhost:5000 \
  --config scripts/phase1/artillery/payment_orchestrator.yml
```
```

### Why This Works
- **Interface contract locks behavior**: AI can't invent breaking changes
- **Quality gates prevent slop**: Coverage, latency, warnings
- **Examples guide patterns**: AI copies proven approaches
- **Freedom on internals**: AI optimizes within bounds

---

## Tier 3: Pattern-Based Tasks (Utilities, Helpers, Plumbing)

**Use for**: Logging helpers, extension methods, DTO mappings, value objects

### Task Structure
```markdown
# tasks/phase1/TSK-P1-040-common-utilities/MISSION.md

## Mission
Create shared utilities for payment processing domain

## Requirements
1. **CorrelationId Value Object**
   - Validate format (UUID v4 or ISO 20022 reference)
   - Equality comparison
   - ToString() for logging (redact if needed)

2. **Currency Amount Value Object**
   - Immutable decimal with currency code
   - Prevent precision loss
   - Arithmetic operators with same-currency enforcement

3. **Result<T> Pattern**
   - Success/Failure discriminated union
   - Error details without exceptions in happy path
   - Railway-oriented programming helpers (Map, Bind)

4. **Retry Extension Methods**
   - Generic WithRetry<T> for database operations
   - Exponential backoff with jitter
   - Logging on retry attempts

## Quality Standards
- All public methods XML-documented
- 100% unit test coverage (these are small)
- No external dependencies beyond System.*

## Examples
```csharp
// Desired usage (AI designs implementation)
var amount = new CurrencyAmount(100.50m, "ZMW");
var doubled = amount * 2; // ✅
var mixed = amount + new CurrencyAmount(50, "USD"); // ❌ throws

var result = await GetPaymentAsync(id)
    .WithRetry(maxAttempts: 3, backoff: TimeSpan.FromSeconds(1));

if (result.IsSuccess)
    return result.Value;
else
    _logger.LogWarning("Failed: {Error}", result.Error);
```

## Success Criteria
✅ Compiles with no warnings
✅ All examples work as shown
✅ Unit tests green
✅ Peer review: "Would use in production"
```

### Why This Works
- **Outcome + example = clear intent**
- **No micro-management**: AI designs the implementation
- **Quality enforced**: Tests, warnings, usability
- **Fast iteration**: Low risk, high autonomy

---

## Meta-Framework: How to Decide Which Tier

```
┌────────────────────────────────────────────────────────┐
│ Decision Tree: Which Tier Should This Task Use?       │
└────────────────────────────────────────────────────────┘

Does it touch:
  - Database schema?
  - Security boundaries?
  - Regulatory requirements?
  - Money/financial calculations?
    → YES → TIER 1 (Invariant-Constrained)

Does it define:
  - Service contracts?
  - API interfaces?
  - Cross-service protocols?
  - Performance SLAs?
    → YES → TIER 2 (Contract-Guided)

Is it:
  - Internal utility?
  - Reusable helper?
  - DTO mapping?
  - Low-risk plumbing?
    → YES → TIER 3 (Pattern-Based)
```

---

## Phase-1 Task Mapping (Based on Your Roadmap)

### Tier 1 Tasks (Strict Control)

```yaml
TSK-P1-010: # INV-111 Instruction Finality
  tier: 1
  why: "Touches ledger immutability (regulatory requirement)"
  
TSK-P1-011: # INV-112 PII Decoupling + Purge
  tier: 1
  why: "ZDPA compliance, security boundary"
  
TSK-P1-012: # INV-113 Rail Sequence Truth Anchor
  tier: 1
  why: "Data integrity, financial reconciliation"
  
TSK-P1-013: # INV-115 Anchor-Sync Lifecycle
  tier: 1
  why: "Payment finality, regulatory audit trail"

# Performance Invariants
INV-P1-PERF-01: # Hot-Path Index Coverage
  tier: 1
  why: "Database schema change"
  
INV-P1-PERF-02: # Lock-Free Write Path
  tier: 1
  why: "Database concurrency model"
```

### Tier 2 Tasks (Guided)

```yaml
Payment Orchestration Service:
  tier: 2
  why: "Core service contract, performance SLA"
  
Ledger Service Implementation:
  tier: 2
  why: "API contract, cross-service integration"
  
Outbox Publisher Service:
  tier: 2
  why: "Reliability pattern, retry guarantees"
  
Authentication Middleware:
  tier: 2
  why: "Security boundary, but standard pattern"
  
Authorization RBAC Engine:
  tier: 2
  why: "Security policy enforcement"

# Availability Invariants  
INV-P1-AVAIL-01: # K8s Redundancy
  tier: 2
  why: "Infrastructure contract, manifest validation"

INV-P1-REL-003: # Circuit Breaker
  tier: 2
  why: "Service resilience pattern"
```

### Tier 3 Tasks (Autonomous)

```yaml
Common Utilities (Value Objects):
  tier: 3
  why: "Internal helpers, no external contract"
  
DTO Mappers:
  tier: 3
  why: "Mechanical transformation"
  
Extension Methods:
  tier: 3
  why: "Syntactic sugar"
  
Logging Helpers:
  tier: 3
  why: "Infrastructure plumbing"
  
Test Fixtures/Builders:
  tier: 3
  why: "Test support code"
```

---

## Workflow: From Roadmap to Running Code

### Phase 1A: Setup (Week 1)

**Human does**:
1. Create `.NET solution structure`:
   ```
   src/
   ├── Services/
   │   ├── PaymentOrchestration/
   │   ├── Ledger/
   │   └── Compliance/
   ├── Shared/
   │   ├── Symphony.Shared.Domain/
   │   └── Symphony.Shared.Infrastructure/
   └── tests/
   ```

2. Install core NuGet packages (from my audit recommendations)

3. Set up CI pipeline stub:
   ```yaml
   # .github/workflows/phase1_ci.yml
   - Build all projects
   - Run unit tests
   - Run integration tests
   - Check code coverage
   - Upload evidence artifacts
   ```

4. Create **agent context file**:
   ```markdown
   # .agent/phase1_context.md
   
   ## Active Phase
   Phase-1: Runtime Implementation
   
   ## Critical Files
   - Phase-0 schema: scripts/db/migrations/*.sql
   - Invariants: docs/invariants/INVARIANTS_MANIFEST.yml
   - Security policy: .agent/rules/03-security-contract.md
   
   ## Current Sprint
   Focus: Ledger Service + Payment Orchestration
   
   ## Non-Negotiables
   - All database access via repositories
   - No raw SQL in services
   - All money calculations use CurrencyAmount value object
   - All async methods have CancellationToken
   ```

**AI does**: Nothing yet (waits for tasks)

---

### Phase 1B: Task Execution (Weeks 2-16)

#### For Tier 1 Tasks (Invariant-Constrained)

**Human provides**:
```markdown
# tasks/phase1/TSK-P1-010/MISSION.md
[As shown in Tier 1 example above]
```

**AI agent workflow**:
1. **Read constraints**: Parse invariant, forbidden approaches, acceptance test
2. **Propose approach**: 
   ```
   I will implement via:
   - Database CHECK constraint + trigger
   - .NET exception InstructionFinalizedViolation
   - Evidence emitter in exception handler
   
   Rationale: [...]
   Alternatives considered: [...]
   ```
3. **Wait for approval**: Human reviews, approves/redirects
4. **Implement**: Write code, tests, verifier script
5. **Self-verify**: Run acceptance test, CI checks
6. **Submit evidence**: Commit + create evidence JSON
7. **Request review**: Tag human for final approval

**Human does**: 
- Approve approach (or redirect)
- Final review (can be quick if tests pass)
- Merge

**Cycle time**: 1-2 days per Tier 1 task

---

#### For Tier 2 Tasks (Contract-Guided)

**Human provides**:
```markdown
# tasks/phase1/TSK-P1-020/MISSION.md
[As shown in Tier 2 example above]
```

**AI agent workflow**:
1. **Read contract**: Interface locked, non-functionals clear
2. **Design internals**: Command handlers, validators, mappers
3. **Implement**: Full service with tests
4. **Run quality gates**: Coverage, latency, integration tests
5. **Auto-submit if green**: No approval needed if all gates pass

**Human does**:
- Spot-check (optional, if curious)
- Only intervene if gates fail

**Cycle time**: 3-5 days per Tier 2 task (but parallel)

---

#### For Tier 3 Tasks (Pattern-Based)

**Human provides**:
```markdown
# tasks/phase1/TSK-P1-040/MISSION.md
[As shown in Tier 3 example above]
```

**AI agent workflow**:
1. **Infer from examples**: Understand desired API
2. **Implement + test**: Full autonomy
3. **Auto-merge if perfect**: 100% coverage, no warnings, examples work

**Human does**: Nothing (unless build breaks)

**Cycle time**: 1 day per Tier 3 task

---

## Advanced: Multi-Agent Orchestration

For Phase-1, consider **specialized agents** instead of one god-agent:

### Agent Roster

```yaml
Architect Agent:
  role: "Design system boundaries, review ADRs"
  operates_on: [Tier 1, Tier 2]
  autonomy: "Propose, not implement"
  
Database Agent:
  role: "Schema changes, migrations, verifiers"
  operates_on: [Tier 1 only]
  autonomy: "Implement with approval"
  constraints: "Never DROP columns, never break N-1 compat"
  
Service Builder Agent:
  role: "Implement services per contract"
  operates_on: [Tier 2, Tier 3]
  autonomy: "Auto-merge if tests pass"
  
Security Guardian Agent:
  role: "Review all PRs for security violations"
  operates_on: [All tiers]
  autonomy: "Block merge, not implement"
  
QA Verifier Agent:
  role: "Run acceptance tests, collect evidence"
  operates_on: [All tiers]
  autonomy: "Report only"
```

### Workflow Example (TSK-P1-010)

```
1. Human creates MISSION.md → tags @database-agent

2. Database Agent:
   - Reads MISSION.md
   - Proposes approach → tags @architect-agent
   
3. Architect Agent:
   - Reviews approach against ADRs
   - Approves → Database Agent proceeds
   
4. Database Agent:
   - Implements migration, verifier, evidence
   - Creates PR → auto-tags @security-guardian + @qa-verifier
   
5. Security Guardian:
   - Scans for: SQL injection, secrets in code, PII leaks
   - ✅ PASS → approves
   
6. QA Verifier:
   - Runs acceptance test
   - Collects evidence
   - ✅ PASS → approves
   
7. PR auto-merges (all checks green)

8. Human gets notification: "TSK-P1-010 complete, evidence available"
```

**Benefit**: Specialization + checks/balances. No single agent can violate security or skip tests.

---

## Practical Setup for Your Project

### Option A: Single AI (Codex/Claude/GPT-4)

**Best if**: You're using one AI tool (like OpenAI Codex or Claude Code)

**Setup**:
1. Create **tier templates** (as shown above)
2. For each Phase-1 task, human writes MISSION.md in appropriate tier
3. AI reads MISSION.md, implements, creates PR
4. CI runs gates (tests, coverage, linting)
5. Human reviews only if gates fail or task is Tier 1

**Tools needed**:
- Your existing GitHub Actions CI (already have)
- Codex CLI with file context (already using)
- Evidence collection scripts (already have from Phase-0)

---

### Option B: Multi-Agent (Advanced)

**Best if**: You want maximum automation and have time to set up orchestration

**Setup**:
1. Use **GitHub Issues as task queue**:
   ```
   Issue template: TIER1_MISSION.md
   Labels: tier-1, phase-1, needs-approval
   Assignee: @database-agent-bot
   ```

2. Each agent is a **GitHub Action workflow** triggered by labels:
   ```yaml
   # .github/workflows/database_agent.yml
   on:
     issues:
       types: [labeled]
   jobs:
     implement_tier1:
       if: contains(github.event.issue.labels.*.name, 'tier-1')
       runs-on: ubuntu-latest
       steps:
         - Parse MISSION from issue body
         - Run Codex/Claude to implement
         - Create PR with implementation
         - Add evidence artifact
         - Tag security-guardian + qa-verifier
   ```

3. **Approval gates**:
   ```yaml
   # .github/workflows/security_guardian.yml
   on:
     pull_request:
       types: [opened]
   jobs:
     security_scan:
       - Run Semgrep, CodeQL
       - Check for PII leaks
       - Validate against .agent/rules/03-security-contract.md
       - If PASS → approve PR
       - If FAIL → request changes + comment
   ```

**Tools needed**:
- GitHub Actions (free tier sufficient)
- Codex API access
- Semgrep (already have)
- Custom evidence collector (already have)

---

## Evidence Collection (Unchanged Philosophy)

**Keep your Phase-0 approach**:

```bash
# After task completion, agent runs:
scripts/phase1/collect_evidence.sh TSK-P1-010

# Output:
evidence/phase1/instruction_finality_runtime.json
```

**Evidence format** (your existing pattern):
```json
{
  "task_id": "TSK-P1-010",
  "gate_id": "INT-G25",
  "invariant_id": "INV-111",
  "status": "PASS",
  "timestamp": "2026-02-09T14:30:00Z",
  "verifier": "scripts/db/verify_instruction_finality_invariant.sh",
  "details": {
    "violations_tested": 5,
    "violations_blocked": 5,
    "evidence_emitted": true,
    "performance_impact_ms": 3.2
  }
}
```

---

## Migration from Current Approach

### Week 1: Pilot (Low-Risk Tier 3 Task)

**Choose**: TSK-P1-040 (Common Utilities)

**Steps**:
1. Human writes MISSION.md (Tier 3 template)
2. AI implements autonomously
3. Human reviews: Did it work? Was spec clear enough?
4. Refine template based on learnings

### Week 2-3: Tier 2 (Medium Complexity)

**Choose**: Payment Orchestration Service

**Steps**:
1. Human writes MISSION.md (Tier 2 template)
2. AI proposes approach → human approves
3. AI implements → CI validates
4. Human spot-checks
5. Refine contract-guided approach

### Week 4+: Tier 1 (High Stakes)

**Choose**: INV-111 Instruction Finality

**Steps**:
1. Human writes MISSION.md (Tier 1 template)
2. AI proposes → Architect reviews → Security reviews
3. AI implements → Full gate suite runs
4. Human final approval before merge
5. Lock in Tier 1 workflow

### Week 8: Full Automation

- Tier 3: Auto-merge
- Tier 2: Auto-merge if tests pass
- Tier 1: Human approval only

---

## Anti-Patterns to Avoid

### ❌ DON'T: Over-specify Everything

```yaml
# BAD: Micromanaging AI
steps:
  - "Create file PaymentService.cs"
  - "Add using System.Threading.Tasks;"
  - "Create class PaymentService : IPaymentService"
  - "Add constructor with ILogger parameter"
  - [... 50 more steps]
```

**Why bad**: AI can write boilerplate faster than you can spec it

**Instead**: Give outcome + constraints, let AI generate

---

### ❌ DON'T: Under-specify Critical Things

```yaml
# BAD: Too vague for Tier 1
task: "Make payments secure"
```

**Why bad**: AI will invent its own security model (dangerous)

**Instead**: Use Tier 1 template with explicit constraints

---

### ❌ DON'T: Mix Tiers in One Task

```yaml
# BAD: Database + Service + Utility in one task
task: "Implement payment processing"
deliverables:
  - "New payment_attempts table"      # Tier 1
  - "Payment orchestration service"    # Tier 2
  - "Amount validation helper"         # Tier 3
```

**Why bad**: Unclear what level of autonomy to give

**Instead**: Split into 3 tasks, each with appropriate tier

---

### ❌ DON'T: Ignore CI Failures

```yaml
# BAD: "Just merge it, we'll fix later"
```

**Why bad**: Technical debt compounds fast in AI-written code

**Instead**: Make gates blocking, never override

---

## Metrics to Track

### Velocity
- Tasks completed per week
- Tier 1: Target 2-3/week
- Tier 2: Target 5-7/week (parallel)
- Tier 3: Target 10+/week (fully automated)

### Quality
- Gate pass rate: Target >90% first-try
- Human intervention rate: Target <20% (Tier 2/3)
- Evidence collection success: Target 100%

### Efficiency
- Human time per task:
  - Tier 1: 2-4 hours (review + approve)
  - Tier 2: 30 min (spot check)
  - Tier 3: 0 min (auto)

---

## Recommended Next Steps

### Immediate (This Week)

1. **Create tier templates**:
   ```bash
   mkdir -p .agent/templates/
   # Copy Tier 1/2/3 examples from this doc
   ```

2. **Classify Phase-1 tasks** by tier:
   ```bash
   # In docs/PHASE1/ROADMAP.md, add tier tags
   ```

3. **Pilot one Tier 3 task**:
   - Choose: Common utilities
   - Write MISSION.md
   - Let AI implement
   - Review outcome

### Short-term (Weeks 2-4)

4. **Build multi-agent orchestration** (if desired):
   - Set up GitHub Action agents
   - Wire evidence collection
   - Test on Tier 2 task

5. **Refine templates** based on pilots

6. **Document patterns** that emerge

### Medium-term (Months 2-3)

7. **Full automation for Tier 2/3**
8. **Streamline Tier 1 approvals** (templates + checklists)
9. **Measure velocity** and optimize bottlenecks

---

## Final Recommendation

For **Symphony's Phase-1**, I recommend:

### **Start Simple** (Month 1)
- Use **Tier 2 Contract-Guided** approach for most tasks
- Reserve Tier 1 for database/security critical
- Use Tier 3 opportunistically (when obvious)

### **Automate Gradually** (Month 2-3)
- Add multi-agent orchestration once patterns stabilize
- Auto-merge Tier 3, then Tier 2
- Keep Tier 1 human-reviewed (financial compliance)

### **Maintain Evidence Discipline**
- Every task → evidence artifact
- Gates remain blocking
- Never skip security scans

This balances **velocity** (AI writes 70% of code) with **safety** (humans control architecture and security).

---

## Appendix: MISSION.md Template Library

Save these to `.agent/templates/`:

### tier1_mission_template.md
```markdown
# Mission: [Task Name]

## Invariant Contract
[INV-XXX specification]

## Success Criteria
- [ ] Gate [GATE-ID] passes
- [ ] Acceptance test passes
- [ ] Evidence emitted

## Constraints
[Non-negotiable requirements]

## Agent Freedom
[What AI can choose]

## Forbidden Approaches
- ❌ [Anti-pattern 1]
- ❌ [Anti-pattern 2]

## Acceptance Test
```csharp
[Test code AI must make pass]
```

## Context
- Related ADRs: [links]
- Example implementations: [links]
```

### tier2_mission_template.md
```markdown
# Mission: [Service Name]

## API Contract
```csharp
[Interface definition - LOCKED]
```

## Non-Functional Requirements
- Performance: [SLA]
- Reliability: [SLA]
- Observability: [requirements]

## Integration Points
- Depends on: [services]
- Provides to: [services]

## Architectural Constraints
[Must-use patterns]

## Agent Freedom
[What AI can design]

## Success Criteria
- [ ] Contract implemented
- [ ] Tests pass
- [ ] Performance SLA met
- [ ] Coverage > X%
```

### tier3_mission_template.md
```markdown
# Mission: [Utility Name]

## Requirements
1. [Feature 1]
2. [Feature 2]

## Quality Standards
- Coverage: 100%
- Warnings: 0
- Documentation: All public APIs

## Examples
```csharp
[Desired usage patterns]
```

## Success Criteria
- [ ] Examples work
- [ ] Tests green
- [ ] Peer review: "Would use this"
```

---

**End of Strategy Document**

This approach lets you maintain Tier-1 rigor while gaining AI-powered velocity. Start conservative, automate incrementally, measure everything.
