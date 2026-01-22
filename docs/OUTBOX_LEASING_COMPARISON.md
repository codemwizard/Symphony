# Outbox Leasing Implementation Comparison

## Overview

This document compares two approaches to implementing outbox leasing and append-only attempts:

1. **Current Implementation**: DELETE-on-claim + DISPATCHING attempts as implicit lease
2. **Proposed Plan**: Explicit leasing with lease fields + outcome-only attempts

---

## Current Implementation

### Architecture

**Leasing Model**: Implicit (DELETE-on-claim + DISPATCHING attempt as lease)

**Flow**:
1. `claimNextBatch()`: DELETE rows from `payment_outbox_pending`, INSERT `DISPATCHING` attempt
2. `insertOutcome()`: INSERT terminal attempt with `attempt_no + 1`
3. Zombie detection: Find stale `DISPATCHING` attempts older than threshold

**Key Code**:
```typescript
// claimNextBatch() - DELETE on claim
DELETE FROM payment_outbox_pending
...
INSERT INTO payment_outbox_attempts (..., state='DISPATCHING', ...)

// insertOutcome() - Append terminal attempt
WITH current_max AS (SELECT MAX(attempt_no) ...)
INSERT INTO payment_outbox_attempts (..., attempt_no = max + 1, ...)
```

### Strengths ✅

1. **Simple**: DELETE removes rows immediately, no lease management
2. **Append-only attempts**: Terminal attempts correctly use `attempt_no + 1`
3. **No lease fields**: Fewer columns to manage
4. **Works**: Handles basic cases correctly

### Weaknesses ❌

1. **Implicit leasing**: DISPATCHING attempt acts as lease (not explicit)
2. **No lease token**: Cannot prevent stale completions
3. **No worker tracking**: Cannot identify which worker claimed what
4. **Race conditions**: Stale worker can complete after crash
5. **Zombie detection**: Relies on inference (stale DISPATCHING attempts)
6. **Two-step process**: Claim inserts DISPATCHING, then insert terminal
7. **No lease expiration**: Relies on time-based heuristics
8. **Lost visibility**: Cannot see "in-flight" work in pending table

### Critical Issue: Race Condition

```typescript
// Current: Stale worker can complete after lease lost
// Worker A crashes after claiming
// Worker B claims same work
// Worker A wakes up and calls insertOutcome() → SUCCEEDS! ❌
// No lease_token check means stale completion possible
```

---

## Proposed Plan

### Architecture

**Leasing Model**: Explicit (lease fields in pending table)

**Flow**:
1. `claim_outbox_batch()`: UPDATE pending with lease fields, return lease_token
2. `complete_outbox_attempt()`: Verify lease_token, INSERT attempt, UPDATE/DELETE pending
3. Lease repair: Find expired leases, clear them, append `ZOMBIE_REQUEUE` attempt

**Key Components**:

#### Schema Changes
```sql
ALTER TABLE payment_outbox_pending
ADD COLUMN claimed_by TEXT,
ADD COLUMN lease_expires_at TIMESTAMPTZ,
ADD COLUMN lease_token UUID;
```

#### Claim Function
```sql
CREATE OR REPLACE FUNCTION claim_outbox_batch(
  p_batch_size INT,
  p_worker_id TEXT,
  p_lease_seconds INT
)
RETURNS TABLE (...)
AS $$
  UPDATE payment_outbox_pending
  SET
    claimed_by = p_worker_id,
    lease_token = gen_random_uuid(),
    lease_expires_at = now() + make_interval(secs => p_lease_seconds)
  WHERE next_attempt_at <= now()
    AND (lease_expires_at IS NULL OR lease_expires_at <= now())
  FOR UPDATE SKIP LOCKED
  RETURNING ...;
$$;
```

#### Complete Function
```sql
CREATE OR REPLACE FUNCTION complete_outbox_attempt(
  p_outbox_id UUID,
  p_lease_token UUID,
  p_worker_id TEXT,
  p_state outbox_attempt_state,
  ...
)
AS $$
  -- 1) Verify lease ownership + token
  SELECT ... FROM payment_outbox_pending
  WHERE outbox_id = p_outbox_id
    AND claimed_by = p_worker_id
    AND lease_token = p_lease_token
    AND lease_expires_at > now()
  FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'LEASE_LOST' USING ERRCODE = 'P7002';
  END IF;
  
  -- 2) Insert append-only attempt
  INSERT INTO payment_outbox_attempts (..., attempt_no = MAX + 1, ...);
  
  -- 3) Update pending (delete terminal, clear lease for retryable)
  IF p_state IN ('DISPATCHED','FAILED') THEN
    DELETE FROM payment_outbox_pending WHERE outbox_id = p_outbox_id;
  ELSIF p_state = 'RETRYABLE' THEN
    UPDATE payment_outbox_pending SET lease cleared, next_attempt_at = ...;
  END IF;
$$;
```

### Strengths ✅

1. **Explicit leasing**: Clear lease fields (`claimed_by`, `lease_expires_at`, `lease_token`)
2. **Idempotent completion**: `lease_token` prevents stale completions
3. **Deterministic recovery**: Expired leases are explicit, not inferred
4. **Worker tracking**: Can identify which worker owns what
5. **Race-safe**: Stale workers fail with `P7002 LEASE_LOST`
6. **Cleaner attempts**: Only outcomes (no DISPATCHING state)
7. **Single completion function**: Atomic lease check + attempt insert + pending update
8. **Better observability**: In-flight work visible in pending with lease fields
9. **Mathematically consistent**: No inference, all state is explicit

### Weaknesses ❌

1. **More complex**: Requires lease management logic
2. **More columns**: 3 additional fields in pending table
3. **More functions**: Need `claim_outbox_batch()` and `complete_outbox_attempt()`
4. **Migration required**: Schema changes needed
5. **More code**: More logic to maintain

### Race Safety Example

```sql
-- Proposed: Stale worker blocked
-- Worker A crashes, lease expires
-- Worker B claims with new lease_token
-- Worker A wakes up, calls complete_outbox_attempt(old_token) → FAILS with P7002 ✅
```

---

## Side-by-Side Comparison

| Aspect | Current Implementation | Proposed Plan |
|--------|----------------------|---------------|
| **Leasing Model** | Implicit (DISPATCHING attempt) | Explicit (lease fields) |
| **Crash Recovery** | Inference-based (stale DISPATCHING) | Deterministic (lease expiration) |
| **Race Safety** | Vulnerable (no token check) | Protected (lease_token validation) |
| **Worker Tracking** | None | Full (claimed_by) |
| **Attempt States** | DISPATCHING + outcomes | Outcomes only |
| **Pending Visibility** | Lost after claim (DELETE) | Visible (lease fields) |
| **Completion Safety** | No protection | Token + expiry check |
| **Complexity** | Lower | Higher |
| **Correctness** | Good | Stronger |

---

## Detailed Analysis

### Leasing Mechanism

**Current**:
- DELETE removes row from pending immediately
- DISPATCHING attempt implicitly represents "claimed" state
- No explicit lease expiration
- Zombie detection via time-based inference on DISPATCHING attempts

**Proposed**:
- UPDATE sets lease fields (claimed_by, lease_expires_at, lease_token)
- Row stays in pending with lease metadata
- Explicit lease expiration timestamp
- Zombie detection via `lease_expires_at <= now()`

### Attempt States

**Current**:
- `DISPATCHING`: Represents "in-flight" work (acts as lease)
- `DISPATCHED`, `FAILED`, `RETRYABLE`: Terminal outcomes
- Two attempts per cycle: DISPATCHING (N) + terminal (N+1)

**Proposed**:
- No `DISPATCHING` state in attempts
- Only outcomes: `DISPATCHED`, `FAILED`, `RETRYABLE`, `ZOMBIE_REQUEUE`
- One attempt per cycle: outcome only (N+1)
- Lease state tracked in pending table

### Crash Recovery

**Current**:
```sql
-- Find stale DISPATCHING attempts
SELECT * FROM payment_outbox_attempts
WHERE state = 'DISPATCHING'
  AND claimed_at < NOW() - INTERVAL '120 seconds'
```
- Inference-based: assumes DISPATCHING older than threshold is stale
- Requires heuristics and time-based thresholds
- May miss edge cases

**Proposed**:
```sql
-- Find expired leases
SELECT * FROM payment_outbox_pending
WHERE lease_expires_at <= now()
  AND claimed_by IS NOT NULL
```
- Deterministic: lease expiration is explicit
- No inference needed
- Clear, auditable recovery process

### Race Condition Handling

**Current**:
- No protection against stale completions
- Worker A crashes, Worker B claims, Worker A can still complete
- Relies on idempotency at rail level only

**Proposed**:
- `lease_token` validation prevents stale completions
- Worker A crashes, lease expires, Worker B claims with new token
- Worker A's completion attempt fails with `P7002 LEASE_LOST`
- Strong guarantee: only lease holder can complete

### Observability

**Current**:
- In-flight work not visible in pending (deleted on claim)
- Must query attempts table for DISPATCHING state
- No worker identification

**Proposed**:
- In-flight work visible in pending with lease fields
- Can query: `SELECT * FROM payment_outbox_pending WHERE claimed_by IS NOT NULL`
- Full worker tracking: who claimed what, when it expires

---

## Migration Considerations

### Current → Proposed Migration Path

1. **Schema Migration**:
   ```sql
   ALTER TABLE payment_outbox_pending
   ADD COLUMN claimed_by TEXT,
   ADD COLUMN lease_expires_at TIMESTAMPTZ,
   ADD COLUMN lease_token UUID;
   ```

2. **Function Creation**:
   - Create `claim_outbox_batch()` function
   - Create `complete_outbox_attempt()` function
   - Create `repair_expired_leases()` function

3. **Code Changes**:
   - Replace `claimNextBatch()` with `claim_outbox_batch()` call
   - Replace `insertOutcome()` + `requeue()` with `complete_outbox_attempt()` call
   - Update zombie repair to use lease expiration

4. **Data Migration**:
   - Existing DISPATCHING attempts: Can be left as-is (historical record)
   - Or: Convert to ZOMBIE_REQUEUE attempts and clear leases

5. **Testing**:
   - Phase 4: Lease expiration and repair
   - Phase 5: Stale worker race condition
   - Concurrency: Multiple workers claiming same work

---

## Recommendation

**Adopt the Proposed Plan** for the following reasons:

1. **Correctness**: Lease tokens prevent stale completions (critical for production)
2. **Observability**: In-flight work visible in pending table
3. **Deterministic Recovery**: Explicit lease expiration, no inference
4. **Production-Ready**: Handles edge cases properly
5. **Auditability**: Clear lease ownership and expiration tracking

The current implementation works for happy paths but has race condition risks. The proposed plan is more robust and mathematically sound.

---

## Implementation Checklist

If adopting the proposed plan:

- [ ] Create SQL migration for lease fields
- [ ] Implement `claim_outbox_batch()` function
- [ ] Implement `complete_outbox_attempt()` function
- [ ] Implement `repair_expired_leases()` function
- [ ] Rewrite `OutboxRelayer.ts` to use new functions
- [ ] Update zombie repair worker for lease expiration
- [ ] Update Phase 4 tests (lease expiration)
- [ ] Update Phase 5 tests (stale worker race)
- [ ] Add observability queries for lease monitoring
- [ ] Document lease token validation in code

---

## References

- Current implementation: `libs/outbox/OutboxRelayer.ts`
- Schema: `schema/v1/011_payment_outbox.sql`
- Proposed plan: See implementation plan document
