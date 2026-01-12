# .NET Financial Core API Contract Specification

**Document ID:** SYM-API-CORE  
**Version:** 1.2.0-LOCKED  
**Date:** January 11, 2026  
**Status:** LOCKED — Phase-7 Control Artifact  
**Owner:** Financial Core Team

---

## 1. Overview

This document specifies the API contract between the **Node.js Orchestration Layer** and the **.NET Financial Core**. The Financial Core is the authoritative system for:

- Instruction state management
- Ledger operations (postings, balances)
- Financial invariant enforcement
- Terminal state determination

> [!IMPORTANT]
> The .NET Financial Core is the **single source of truth** for financial state. Node.js may query and request transitions, but .NET decides and enforces.

---

## 2. Architecture Boundary

```
┌─────────────────────────────────────────────────────────────────────┐
│                 NODE.JS ORCHESTRATION LAYER                         │
│  - Participant resolution      - Retry evaluation                   │
│  - Policy enforcement          - Repair orchestration               │
│  - Attempt tracking (diagnostic)                                    │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              │ HTTPS / mTLS
                              │ JSON over REST
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 .NET FINANCIAL CORE                                 │
│  - Instruction state machine   - Ledger entries                     │
│  - Balance checks              - Posting idempotency                │
│  - Terminal state enforcement  - Proof-of-funds                     │
└─────────────────────────────────────────────────────────────────────┘
```

> [!NOTE]
> Ledger postings and instruction terminal transitions occur **atomically** within the Financial Core. There is no partial completion state.

---

## 3. Security Requirements

### 3.1 Transport Security

| Requirement | Specification |
|-------------|---------------|
| Protocol | HTTPS (TLS 1.3) |
| Authentication | mTLS (mutual TLS) |
| Certificate | Node.js presents service certificate |
| Validation | .NET validates against trusted CA |

### 3.2 Request Headers (Required)

| Header | Description |
|--------|-------------|
| `X-Request-ID` | Correlation ID (UUID) |
| `X-Ingress-Sequence-ID` | Ingress attestation sequence |
| `X-Participant-ID` | Calling participant identifier |
| `X-Service-Name` | Calling service (e.g., `symphony-orchestrator`) |

### 3.3 Caller Restrictions

> [!CAUTION]
> Only trusted orchestration services authenticated via mTLS may invoke transition endpoints. External clients and participants are **prohibited** from direct access.

### 3.4 Rate Limiting

Rate limits are applied per **calling service identity** and **participant context**, configurable by policy. Default: 1000 requests/second per service-participant pair.

---

## 4. Authoritative Instruction State Transition Rules

The .NET Financial Core enforces the following **authoritative** instruction state machine. All transitions not explicitly permitted below are **rejected**.

### 4.1 Instruction States

| State | Description | Terminal |
|-------|-------------|----------|
| `RECEIVED` | Instruction created, not yet authorized | No |
| `AUTHORIZED` | Passed all pre-execution policy, balance, and eligibility checks. Does not imply external rail acceptance. | No |
| `EXECUTING` | Execution initiated with external rail | No |
| `COMPLETED` | Successfully executed | **Yes** |
| `FAILED` | Permanently failed | **Yes** |

### 4.2 Allowed State Transitions

| From State | To State | Allowed | Notes |
|------------|----------|---------|-------|
| `RECEIVED` | `AUTHORIZED` | ✅ | Authorization completed |
| `AUTHORIZED` | `EXECUTING` | ✅ | Execution initiated |
| `EXECUTING` | `COMPLETED` | ✅ | External confirmation of success |
| `EXECUTING` | `FAILED` | ✅ | Deterministic failure or reconciled failure |
| `RECEIVED` | `*` | ❌ | Except AUTHORIZED |
| `AUTHORIZED` | `*` | ❌ | Except EXECUTING |
| `EXECUTING` | `*` | ❌ | Except COMPLETED or FAILED |
| `COMPLETED` | `*` | ❌ | Terminal state |
| `FAILED` | `*` | ❌ | Terminal state |

### 4.3 Terminal State Enforcement

- `COMPLETED` and `FAILED` are **terminal and irreversible**
- Once an instruction reaches a terminal state:
  - No further transitions are permitted
  - All subsequent transition requests are rejected with `ALREADY_TERMINAL`
- Terminal state enforcement satisfies **INV-FIN-02** (Single Success per Instruction)

### 4.4 Concurrency and Exclusivity Rules

- At most **one active transition** may be processed per instruction at any time
- Concurrent transition requests result in `CONCURRENT_MODIFICATION`
- The Financial Core guarantees **single-writer semantics** per instruction

### 4.5 Authority Clause

- State transition requests are **advisory**
- The Financial Core MAY reject any request that:
  - Violates the transition rules
  - Violates a financial invariant
  - Conflicts with concurrent processing
- **The Financial Core is the sole authority for instruction state.**

---

## 5. Instruction State Endpoints

### 5.1 GET /api/v1/instructions/{instructionId}/state

Query current instruction state.

> [!NOTE]
> Query endpoints are strictly **read-only** and SHALL NOT mutate state or produce ledger side-effects.

#### Request

```http
GET /api/v1/instructions/{instructionId}/state HTTP/1.1
Host: financial-core.symphony.internal
X-Request-ID: {uuid}
X-Ingress-Sequence-ID: {sequence}
X-Participant-ID: {participantId}
```

#### Response: 200 OK

```json
{
  "instructionId": "instr-001",
  "state": "EXECUTING",
  "isTerminal": false,
  "createdAt": "2026-01-11T07:00:00Z",
  "updatedAt": "2026-01-11T07:05:00Z",
  "participantId": "part-001",
  "idempotencyKey": "idem-key-12345678"
}
```

#### Response: 404 Not Found

```json
{
  "error": "INSTRUCTION_NOT_FOUND",
  "message": "Instruction not found",
  "instructionId": "instr-001"
}
```

---

### 5.2 POST /api/v1/instructions/{instructionId}/transition

Request state transition (advisory command).

> [!WARNING]
> Transition requests are **advisory**. The .NET Financial Core may reject them if invariant conditions are not met. Transition requests may be rejected even if syntactically valid.

#### Request

```http
POST /api/v1/instructions/{instructionId}/transition HTTP/1.1
Host: financial-core.symphony.internal
Content-Type: application/json
X-Request-ID: {uuid}
X-Ingress-Sequence-ID: {sequence}
X-Participant-ID: {participantId}

{
  "targetState": "COMPLETED",
  "reason": "Rail confirmed successful execution",
  "railReference": "RAIL-REF-12345",
  "reconciliationEventId": "repair-001"
}
```

#### Response: 200 OK (Accepted)

```json
{
  "accepted": true,
  "instructionId": "instr-001",
  "previousState": "EXECUTING",
  "newState": "COMPLETED",
  "transitionedAt": "2026-01-11T07:10:00Z"
}
```

#### Response: 409 Conflict (Rejected)

```json
{
  "accepted": false,
  "instructionId": "instr-001",
  "currentState": "COMPLETED",
  "rejectionReason": "ALREADY_TERMINAL",
  "message": "Instruction is already in terminal state"
}
```

#### Rejection Reasons

| Code | Description |
|------|-------------|
| `ALREADY_TERMINAL` | Instruction already COMPLETED or FAILED |
| `INVALID_TRANSITION` | State transition not allowed per §4.2 |
| `INVARIANT_VIOLATION` | Would violate financial invariant |
| `CONCURRENT_MODIFICATION` | Another transition in progress |

---

### 5.3 POST /api/v1/instructions

Create new instruction.

#### Request

```http
POST /api/v1/instructions HTTP/1.1
Host: financial-core.symphony.internal
Content-Type: application/json
X-Request-ID: {uuid}
X-Ingress-Sequence-ID: {sequence}
X-Participant-ID: {participantId}

{
  "idempotencyKey": "idem-key-12345678",
  "participantId": "part-001",
  "instructionType": "PAYMENT",
  "amount": "1000.00",
  "currency": "ZMW",
  "debitAccountId": "acct-001",
  "creditAccountId": "acct-002",
  "messageType": "pacs.008",
  "metadata": {
    "endToEndId": "E2E-001",
    "remittanceInfo": "Invoice 12345"
  }
}
```

#### Response: 201 Created

```json
{
  "instructionId": "instr-001",
  "state": "RECEIVED",
  "idempotencyKey": "idem-key-12345678",
  "createdAt": "2026-01-11T07:00:00Z"
}
```

#### Response: 409 Conflict (Duplicate)

```json
{
  "error": "DUPLICATE_IDEMPOTENCY_KEY",
  "existingInstructionId": "instr-001",
  "existingState": "EXECUTING",
  "message": "Instruction with this idempotency key already exists"
}
```

---

## 6. Ledger API

### 6.1 GET /api/v1/accounts/{accountId}/balance

Query current balance (for proof-of-funds).

> [!NOTE]
> Query endpoints are strictly **read-only** and SHALL NOT mutate state or produce ledger side-effects. Balance checks are performed as read-only queries over the ledger-derived view and do not introduce additional state.

#### Response: 200 OK

```json
{
  "accountId": "acct-001",
  "availableBalance": "50000.00",
  "pendingBalance": "1000.00",
  "currency": "ZMW",
  "asOf": "2026-01-11T07:00:00Z"
}
```

---

### 6.2 POST /api/v1/ledger/validate-posting

Pre-validate a posting (proof-of-funds check).

> [!NOTE]
> This is a **pre-flight validation only** endpoint. It does NOT create a posting and does NOT write ledger entries.

#### Request

```json
{
  "instructionId": "instr-001",
  "debitAccountId": "acct-001",
  "creditAccountId": "acct-002",
  "amount": "1000.00",
  "currency": "ZMW"
}
```

#### Response: 200 OK (Valid)

```json
{
  "valid": true,
  "instructionId": "instr-001",
  "availableBalance": "50000.00",
  "postExecutionBalance": "49000.00"
}
```

#### Response: 422 Unprocessable (Invalid)

```json
{
  "valid": false,
  "instructionId": "instr-001",
  "reason": "INSUFFICIENT_FUNDS",
  "availableBalance": "500.00",
  "requiredAmount": "1000.00"
}
```

---

## 7. Invariant Enforcement

| Invariant | Enforcement |
|-----------|-------------|
| **INV-FIN-01** | Ledger always zero-sum |
| **INV-FIN-02** | Only one SUCCESS per instruction |
| **INV-FIN-05** | Posting idempotency (duplicate key rejected) |
| **INV-FLOW-02** | Failures terminate before side-effects |

### 7.1 Invariant Violation Response

```json
{
  "error": "INVARIANT_VIOLATION",
  "invariant": "INV-FIN-02",
  "message": "Only one SUCCESS per instruction allowed",
  "instructionId": "instr-001",
  "currentState": "COMPLETED"
}
```

---

## 8. Error Response Schema

```json
{
  "error": "ERROR_CODE",
  "message": "Human-readable message",
  "correlationId": "X-Request-ID value",
  "timestamp": "2026-01-11T07:00:00Z",
  "details": {}
}
```

### 8.1 Standard Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INSTRUCTION_NOT_FOUND` | 404 | Instruction does not exist |
| `ACCOUNT_NOT_FOUND` | 404 | Account does not exist |
| `DUPLICATE_IDEMPOTENCY_KEY` | 409 | Idempotency key already used |
| `ALREADY_TERMINAL` | 409 | Already in terminal state |
| `CONCURRENT_MODIFICATION` | 409 | Another transition in progress |
| `INVALID_TRANSITION` | 422 | State transition not allowed |
| `INSUFFICIENT_FUNDS` | 422 | Balance check failed |
| `INVARIANT_VIOLATION` | 422 | Would violate invariant |
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Authentication failed |
| `FORBIDDEN` | 403 | Not authorized |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Unexpected internal error |

---

## 9. Webhook Callbacks (Optional)

> [!NOTE]
> Webhooks are **informational only** and do not replace authoritative state queries.

### 9.1 POST {callback_url}

```json
{
  "event": "INSTRUCTION_STATE_CHANGED",
  "instructionId": "instr-001",
  "previousState": "EXECUTING",
  "newState": "COMPLETED",
  "timestamp": "2026-01-11T07:10:00Z",
  "signature": "HMAC-SHA256 signature"
}
```

---

## 10. Versioning

All endpoints are versioned (`/api/v1/`). Breaking changes require a new major API version.

---

## 11. Implementation Checklist

| Endpoint | Method | Priority |
|----------|--------|----------|
| `/instructions/{id}/state` | GET | P0 |
| `/instructions/{id}/transition` | POST | P0 |
| `/instructions` | POST | P0 |
| `/accounts/{id}/balance` | GET | P1 |
| `/ledger/validate-posting` | POST | P1 |

---

## Document Control

**Version:** 1.2.0-LOCKED  
**Status:** LOCKED — Phase-7 Control Artifact  
**Lock Date:** January 11, 2026  
**Last Updated:** January 11, 2026

> [!CAUTION]
> This document is **LOCKED** as a Phase-7 control artifact. Any changes require formal change control review.
