# Saga Pattern for Complex Workflows
## Explanation and Integration with Symphony

**Date:** 2026-01-XX  
**Purpose:** Explain the Saga pattern and how it fits into Symphony's payment orchestration architecture

---

## Table of Contents

1. [What is the Saga Pattern?](#1-what-is-the-saga-pattern)
2. [Why Do We Need Sagas?](#2-why-do-we-need-sagas)
3. [Saga Pattern Types](#3-saga-pattern-types)
4. [Reference Implementation Analysis](#4-reference-implementation-analysis)
5. [Symphony's Current Approach](#5-symphonys-current-approach)
6. [How Saga Fits into Symphony](#6-how-saga-fits-into-symphony)
7. [Implementation Recommendations](#7-implementation-recommendations)
8. [Code Examples](#8-code-examples)

---

## 1. What is the Saga Pattern?

The **Saga Pattern** is a design pattern for managing distributed transactions that span multiple services or steps. Unlike traditional ACID transactions (which use two-phase commit and require all steps to succeed or fail together), a Saga breaks a complex workflow into a series of smaller, independent transactions with **compensation logic** for each step.

### Key Concepts

1. **Saga Steps**: A workflow is broken into discrete steps (e.g., fraud check → authorization → settlement → notification)
2. **Compensation**: Each step has a corresponding compensation action that can undo its effects
3. **Orchestration**: Steps are executed sequentially, and if any step fails, all previous steps are compensated (rolled back) in reverse order
4. **Event-Driven**: Saga state is tracked through events, making it auditable and recoverable

### Simple Example

Imagine a payment workflow with 4 steps:

```
Step 1: Fraud Check      → Success
Step 2: Bank Authorization → Success  
Step 3: Settlement        → FAILS ❌
Step 4: Notification      → (never reached)

Compensation (reverse order):
Step 2: Reverse Authorization ✅
Step 1: Mark fraud check as invalid ✅
```

**Key Difference from Traditional Transactions:**
- Traditional: All-or-nothing atomic transaction (either all steps succeed or all fail together)
- Saga: Each step commits independently, but failures trigger compensation (undo operations) for previous steps

---

## 2. Why Do We Need Sagas?

### Problem: Distributed Transactions Are Hard

In microservices or distributed systems, you often need to coordinate multiple services:

```
Payment Service → Fraud Service → Bank Service → Settlement Service → Notification Service
```

**Challenges:**
1. **Cannot use traditional transactions** across services (each service has its own database)
2. **Partial failures** are common (network issues, service outages)
3. **Need to maintain consistency** even when services fail
4. **Need auditability** for regulatory compliance

### Example: What Happens Without Sagas

**Scenario:** A payment goes through 3 steps:
1. ✅ Fraud check passes
2. ✅ Bank authorizes $1000
3. ❌ Settlement service fails (database timeout)

**Without Saga Pattern:**
- Fraud check completed (money locked)
- Bank authorization completed (money held)
- Settlement failed (payment stuck)
- **Problem**: Money is held but payment isn't completed
- **Solution**: Manual intervention required (expensive, error-prone)

**With Saga Pattern:**
- Fraud check completed
- Bank authorization completed
- Settlement failed → **Automatic compensation**
  - Reverse bank authorization (release hold)
  - Mark fraud check as invalid
- Payment marked as FAILED
- **Result**: Clean state, no manual intervention needed

---

## 3. Saga Pattern Types

### 3.1 Orchestration-Based Saga (Recommended for Symphony)

A **central orchestrator** (e.g., a payment orchestrator service) coordinates all steps:

```
┌─────────────────────┐
│ Payment Orchestrator│
│   (Saga Coordinator)│
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
Step 1      Step 2      Step 3      Step 4
(Fraud)  (Auth)      (Settle)    (Notify)
```

**Pros:**
- Centralized control and visibility
- Easier to implement and debug
- Better for complex workflows
- Good for event sourcing

**Cons:**
- Orchestrator becomes a single point of logic (but not a bottleneck if stateless)

### 3.2 Choreography-Based Saga

Each service knows what to do next and communicates via events:

```
Step 1 ──event──> Step 2 ──event──> Step 3 ──event──> Step 4
  │                 │                 │
  └──compensate──>  └──compensate──>  └──compensate──>
```

**Pros:**
- Decoupled services
- No single orchestrator

**Cons:**
- Harder to understand workflow
- Difficult to debug
- Complex compensation logic

**Recommendation for Symphony:** Use **Orchestration-Based Saga** because:
- Symphony already has centralized orchestration (FinancialCore)
- Better fit for regulatory compliance (centralized audit trail)
- Easier to implement compensation logic
- Aligns with Symphony's event sourcing goals

---

## 4. Reference Implementation Analysis

The reference implementation uses an **Event-Sourced Saga** pattern:

### Key Components:

1. **Event-Sourced Saga**: State is stored as events in EventStoreDB
2. **Atomic State Transitions**: All events committed atomically
3. **Compensation Data**: Each step stores data needed for compensation
4. **Compensation Execution**: On failure, compensations run in reverse order

### Example Flow from Reference:

```typescript
// Reference Implementation Saga Steps:
const steps = [
  stepFraudCheck,        // Step 0: Check fraud
  stepBankAuthorization, // Step 1: Authorize with bank
  stepSettlement,        // Step 2: Settle funds
  stepNotification       // Step 3: Send notification
];

// Execution:
for (let i = 0; i < steps.length; i++) {
  try {
    const result = await steps[i](paymentId, request, transaction);
    // Append success event atomically
    await transaction.append(`payment-${paymentId}`, successEvent);
  } catch (error) {
    // Append failure event
    await transaction.append(`payment-${paymentId}`, failureEvent);
    // Execute compensation for completed steps (in reverse order)
    await compensate(sagaState, transaction);
    throw error;
  }
}
```

**Key Features:**
- ✅ Each step stores compensation data
- ✅ Events are committed atomically (all-or-nothing)
- ✅ Compensation runs automatically on failure
- ✅ Full event trail for auditability

---

## 5. Symphony's Current Approach

### Current Architecture:

Symphony uses a **simpler workflow pattern** with state machines and repair workflows:

```
Instruction State Machine:
RECEIVED → PROCESSING → COMPLETED/FAILED

Transaction Attempts:
INITIATED → SUCCESS/FAILED/TIMEOUT

Repair Workflow:
TIMEOUT → Query Rail → Reconcile → Transition
```

### What Symphony Has:

1. ✅ **State Machine**: Instructions have clear states and transitions
2. ✅ **Transaction Attempts**: Retry logic with multiple attempts
3. ✅ **Repair Workflow**: Reconciliation for ambiguous states (TIMEOUT)
4. ✅ **Transactional Outbox**: For reliable external rail dispatch
5. ✅ **Compensation Logic**: Partial (repair workflow can transition to FAILED)

### What Symphony Lacks for Full Saga Pattern:

1. ❌ **Multi-Step Orchestration**: No explicit saga orchestrator
2. ❌ **Compensation Data Storage**: No storage for compensation information
3. ❌ **Automatic Compensation**: Compensation is manual (repair workflow)
4. ❌ **Event-Sourced Saga State**: Saga state not stored as events
5. ❌ **Step-Level Granularity**: Steps not explicitly modeled

### Current Workflow Example:

**Symphony's current flow:**
```
1. Instruction RECEIVED
2. Instruction → PROCESSING
3. Outbox Dispatch → External Rail
4. Rail Response → COMPLETED or FAILED
5. If TIMEOUT → Repair Workflow → Query Rail → Reconcile
```

**Limitations:**
- Single-step external call (rail dispatch)
- No multi-step orchestration within Symphony
- Compensation is reactive (repair workflow), not proactive
- Complex workflows (fraud → auth → settle) would need manual coordination

---

## 6. How Saga Fits into Symphony

### 6.1 Where Saga Pattern Is Needed

Symphony's architecture could benefit from Saga pattern for:

1. **Multi-Step Internal Workflows**:
   - Fraud check → Authorization → Settlement → Notification
   - AML check → Compliance validation → Routing decision
   - Multi-rail coordination (primary rail → fallback rail)

2. **Complex Payment Flows**:
   - Split payments (multiple recipients)
   - Conditional workflows (if amount > X, require approval)
   - Multi-currency conversions

3. **Failure Recovery**:
   - Automatic compensation when steps fail
   - Better than current repair workflow (which is reactive)

### 6.2 Integration Points

#### A. Instruction Lifecycle Enhancement

**Current:**
```
RECEIVED → PROCESSING → COMPLETED/FAILED
```

**With Saga:**
```
RECEIVED → SAGA_INITIATED → SAGA_STEP_1 → SAGA_STEP_2 → ... → COMPLETED
                                              ↓ (if failure)
                                         SAGA_COMPENSATING → FAILED
```

#### B. Event Sourcing Integration

Saga state should be stored as events (aligns with Symphony's event sourcing goals):

```
Event: PaymentSagaInitiated
Event: PaymentSagaStepCompleted (step: fraud_check)
Event: PaymentSagaStepCompleted (step: authorization)
Event: PaymentSagaStepFailed (step: settlement)
Event: PaymentSagaCompensationStarted
Event: PaymentSagaCompensationCompleted (step: authorization)
Event: PaymentSagaCompensationCompleted (step: fraud_check)
Event: PaymentSagaCompensated (final_state: FAILED)
```

#### C. Transactional Outbox Integration

Saga steps that need external calls should use the outbox pattern:

```
Saga Step: Bank Authorization
  → Write to outbox (atomic with saga state)
  → Relayer dispatches to bank
  → Saga waits for response
  → Saga advances to next step
```

---

## 7. Implementation Recommendations

### 7.1 Phase 1: Basic Saga Orchestrator (Foundation)

**Goal:** Add saga orchestration for internal multi-step workflows

**Components to Add:**

1. **Saga Orchestrator Service**
   ```typescript
   class PaymentSagaOrchestrator {
     async executeSaga(workflow: SagaWorkflow): Promise<SagaResult>
     async compensate(sagaId: string, failedStep: number): Promise<void>
   }
   ```

2. **Saga State Storage**
   ```sql
   CREATE TABLE payment_sagas (
     id UUID PRIMARY KEY,
     instruction_id UUID NOT NULL,
     current_step INT NOT NULL,
     status saga_status NOT NULL,
     compensation_data JSONB,
     created_at TIMESTAMPTZ,
     updated_at TIMESTAMPTZ
   );
   ```

3. **Saga Steps Configuration**
   ```typescript
   interface SagaStep {
     name: string;
     execute: (context: SagaContext) => Promise<StepResult>;
     compensate: (context: SagaContext, compensationData: any) => Promise<void>;
   }
   ```

**Estimated Effort:** 3-4 weeks

### 7.2 Phase 2: Event-Sourced Saga (Alignment with Event Sourcing)

**Goal:** Store saga state as events (aligns with Symphony's event sourcing goals)

**Components to Add:**

1. **Event Store Integration** (EventStoreDB or PostgreSQL event log)
2. **Saga Event Types**
   - `PaymentSagaInitiated`
   - `PaymentSagaStepCompleted`
   - `PaymentSagaStepFailed`
   - `PaymentSagaCompensationStarted`
   - `PaymentSagaCompensated`

**Benefits:**
- Complete audit trail
- State reconstruction from events
- Time-travel debugging
- Regulatory compliance

**Estimated Effort:** 2-3 weeks (after Phase 1)

### 7.3 Phase 3: Complex Workflow Support

**Goal:** Support complex workflows (fraud → auth → settle → notify)

**Components to Add:**

1. **Workflow Definitions** (configuration-driven)
2. **Conditional Steps** (if-then logic)
3. **Parallel Steps** (when steps can run concurrently)
4. **External Step Integration** (integrating with outbox pattern)

**Estimated Effort:** 3-4 weeks (after Phase 2)

---

## 8. Code Examples

### 8.1 Symphony Saga Orchestrator (Proposed)

```typescript
// libs/saga/PaymentSagaOrchestrator.ts

import { Pool } from 'pg';
import { logger } from '../logging/logger.js';

export interface SagaStep {
  name: string;
  execute: (context: SagaContext) => Promise<StepResult>;
  compensate: (context: SagaContext, compensationData: any) => Promise<void>;
}

export interface SagaContext {
  sagaId: string;
  instructionId: string;
  paymentRequest: PaymentRequest;
  compensationData: Map<string, any>;
}

export interface StepResult {
  success: boolean;
  compensationData?: any;
  error?: string;
}

export class PaymentSagaOrchestrator {
  constructor(
    private readonly pool: Pool,
    private readonly steps: SagaStep[]
  ) {}

  async executeSaga(
    instructionId: string,
    paymentRequest: PaymentRequest
  ): Promise<SagaResult> {
    const sagaId = crypto.randomUUID();
    const context: SagaContext = {
      sagaId,
      instructionId,
      paymentRequest,
      compensationData: new Map()
    };

    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Initialize saga state
      await this.initializeSaga(sagaId, instructionId, client);

      // Execute steps sequentially
      for (let i = 0; i < this.steps.length; i++) {
        const step = this.steps[i];
        
        try {
          logger.info({ sagaId, step: step.name, stepIndex: i }, 'Executing saga step');

          // Execute step
          const result = await step.execute(context);

          if (!result.success) {
            throw new Error(result.error || `Step ${step.name} failed`);
          }

          // Store compensation data
          if (result.compensationData) {
            context.compensationData.set(step.name, result.compensationData);
          }

          // Record step completion
          await this.recordStepCompletion(sagaId, i, step.name, client);

        } catch (error) {
          logger.error({ sagaId, step: step.name, error }, 'Saga step failed');

          // Record step failure
          await this.recordStepFailure(sagaId, i, step.name, error, client);

          // Execute compensation
          await this.compensate(context, i, client);

          await client.query('ROLLBACK');
          return { success: false, sagaId, failedStep: i };
        }
      }

      // All steps succeeded
      await this.markSagaComplete(sagaId, client);
      await client.query('COMMIT');

      return { success: true, sagaId };

    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  private async compensate(
    context: SagaContext,
    failedStepIndex: number,
    client: PoolClient
  ): Promise<void> {
    logger.info({ sagaId: context.sagaId, failedStep: failedStepIndex }, 'Starting compensation');

    await this.recordCompensationStarted(context.sagaId, client);

    // Compensate in reverse order
    for (let i = failedStepIndex - 1; i >= 0; i--) {
      const step = this.steps[i];
      const compensationData = context.compensationData.get(step.name);

      if (compensationData) {
        try {
          await step.compensate(context, compensationData);
          await this.recordCompensationCompleted(context.sagaId, i, step.name, client);
        } catch (error) {
          logger.error({ sagaId: context.sagaId, step: step.name, error }, 'Compensation failed');
          // Log but continue (best effort compensation)
        }
      }
    }

    await this.recordCompensationCompleted(context.sagaId, client);
  }

  // Database methods (simplified)
  private async initializeSaga(sagaId: string, instructionId: string, client: PoolClient): Promise<void> {
    await client.query(
      `INSERT INTO payment_sagas (id, instruction_id, status, current_step, created_at)
       VALUES ($1, $2, 'IN_PROGRESS', 0, NOW())`,
      [sagaId, instructionId]
    );
  }

  private async recordStepCompletion(sagaId: string, stepIndex: number, stepName: string, client: PoolClient): Promise<void> {
    await client.query(
      `UPDATE payment_sagas 
       SET current_step = $1, updated_at = NOW()
       WHERE id = $2`,
      [stepIndex + 1, sagaId]
    );
  }

  private async recordStepFailure(sagaId: string, stepIndex: number, stepName: string, error: any, client: PoolClient): Promise<void> {
    await client.query(
      `UPDATE payment_sagas 
       SET status = 'COMPENSATING', updated_at = NOW()
       WHERE id = $1`,
      [sagaId]
    );
  }

  private async markSagaComplete(sagaId: string, client: PoolClient): Promise<void> {
    await client.query(
      `UPDATE payment_sagas 
       SET status = 'COMPLETED', updated_at = NOW()
       WHERE id = $1`,
      [sagaId]
    );
  }

  private async recordCompensationStarted(sagaId: string, client: PoolClient): Promise<void> {
    // Record compensation started event
  }

  private async recordCompensationCompleted(sagaId: string, stepIndex: number, stepName: string, client: PoolClient): Promise<void> {
    // Record compensation completed event
  }

  private async recordCompensationCompleted(sagaId: string, client: PoolClient): Promise<void> {
    await client.query(
      `UPDATE payment_sagas 
       SET status = 'COMPENSATED', updated_at = NOW()
       WHERE id = $1`,
      [sagaId]
    );
  }
}
```

### 8.2 Example Saga Steps

```typescript
// libs/saga/steps/FraudCheckStep.ts

export const fraudCheckStep: SagaStep = {
  name: 'fraud_check',
  
  async execute(context: SagaContext): Promise<StepResult> {
    // Call fraud service
    const fraudResult = await fraudService.check(context.paymentRequest);
    
    if (!fraudResult.passed) {
      return {
        success: false,
        error: `Fraud check failed: ${fraudResult.reason}`
      };
    }

    // Store compensation data (fraud check ID for reversal)
    return {
      success: true,
      compensationData: {
        checkId: fraudResult.checkId,
        timestamp: new Date()
      }
    };
  },

  async compensate(context: SagaContext, compensationData: any): Promise<void> {
    // Mark fraud check as invalid (if needed)
    if (compensationData.checkId) {
      await fraudService.invalidateCheck(compensationData.checkId);
    }
  }
};

// libs/saga/steps/BankAuthorizationStep.ts

export const bankAuthorizationStep: SagaStep = {
  name: 'bank_authorization',
  
  async execute(context: SagaContext): Promise<StepResult> {
    // Use outbox pattern for external call
    const authorizationRequest = {
      participantId: context.paymentRequest.participantId,
      idempotencyKey: `${context.sagaId}-auth`,
      eventType: 'BANK_AUTHORIZATION',
      payload: {
        amount: context.paymentRequest.amount,
        currency: context.paymentRequest.currency
      }
    };

    // Write to outbox (atomic with saga state)
    const outboxResult = await outboxDispatchService.dispatch(
      authorizationRequest,
      client // Same transaction
    );

    // Wait for relayer to process (or use event-driven approach)
    const authorizationResult = await waitForAuthorizationResult(outboxResult.outboxId);

    if (!authorizationResult.authorized) {
      return {
        success: false,
        error: `Authorization failed: ${authorizationResult.reason}`
      };
    }

    return {
      success: true,
      compensationData: {
        authorizationId: authorizationResult.authorizationId,
        holdId: authorizationResult.holdId
      }
    };
  },

  async compensate(context: SagaContext, compensationData: any): Promise<void> {
    // Reverse authorization (release hold)
    if (compensationData.authorizationId) {
      await bankService.reverseAuthorization(compensationData.authorizationId);
    }
  }
};
```

### 8.3 Integration with Current Architecture

```typescript
// services/control-plane/src/sagaOrchestrator.ts

import { PaymentSagaOrchestrator } from '../../../libs/saga/PaymentSagaOrchestrator.js';
import { fraudCheckStep, bankAuthorizationStep } from '../../../libs/saga/steps/index.js';

// Define payment workflow
const paymentWorkflowSteps = [
  fraudCheckStep,
  bankAuthorizationStep,
  settlementStep,    // (to be implemented)
  notificationStep   // (to be implemented)
];

// Initialize orchestrator
const sagaOrchestrator = new PaymentSagaOrchestrator(
  db.pool,
  paymentWorkflowSteps
);

// Use in instruction processing
async function processPayment(instructionId: string, paymentRequest: PaymentRequest) {
  try {
    const result = await sagaOrchestrator.executeSaga(instructionId, paymentRequest);
    
    if (result.success) {
      // Transition instruction to COMPLETED
      await instructionService.transitionInstruction(instructionId, 'COMPLETED');
    } else {
      // Transition instruction to FAILED
      await instructionService.transitionInstruction(instructionId, 'FAILED');
    }
  } catch (error) {
    logger.error({ instructionId, error }, 'Saga execution failed');
    throw error;
  }
}
```

---

## 9. Benefits for Symphony

### 9.1 Immediate Benefits

1. **Automatic Compensation**: No manual intervention for partial failures
2. **Better Failure Handling**: Proactive compensation vs reactive repair
3. **Workflow Clarity**: Explicit step definitions make workflows understandable
4. **Testability**: Each step can be tested independently

### 9.2 Long-term Benefits

1. **Complex Workflow Support**: Can handle fraud → auth → settle → notify workflows
2. **Regulatory Compliance**: Complete audit trail of saga execution
3. **Scalability**: Can add new steps without changing core logic
4. **Event Sourcing Alignment**: Saga state can be stored as events (future enhancement)

---

## 10. Migration Strategy

### Phase 1: Add Saga for New Features (No Breaking Changes)

- Keep existing instruction processing as-is
- Add saga orchestrator for new complex workflows
- Gradually migrate existing workflows to saga pattern

### Phase 2: Enhance Existing Workflows

- Convert repair workflow to use saga compensation
- Add saga steps for multi-rail coordination
- Integrate with event sourcing (when implemented)

### Phase 3: Full Saga Integration

- All complex workflows use saga pattern
- Event-sourced saga state
- Complete audit trail

---

## 11. Conclusion

The Saga pattern is a powerful tool for managing complex, multi-step workflows in distributed systems. For Symphony:

1. **Current State**: Symphony has good foundations (state machines, repair workflows) but lacks explicit saga orchestration
2. **Need**: Saga pattern would help with complex workflows (fraud → auth → settle → notify)
3. **Fit**: Saga pattern aligns well with Symphony's architecture goals (event sourcing, auditability)
4. **Recommendation**: Implement orchestration-based saga pattern in phases, starting with basic orchestrator and gradually enhancing

The Saga pattern complements Symphony's existing patterns (transactional outbox, state machines) and provides a structured way to handle complex workflows with automatic compensation.

---

**Document End**
