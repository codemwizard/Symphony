# TSK-P2-PREAUTH-007-09 PLAN — Trust Architecture: Delegated Grant Schema

Task: TSK-P2-PREAUTH-007-09
Owner: DB_FOUNDATION
Gap Source: G-08 part 2 (W7_GAP_ANALYSIS.md line 166, lines 226-229)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-09.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Implementation Status: COMPLETED** — Migration 0166 applied, verifier passing.

---

## Objective

Create the DDL schema for `delegated_signing_grants` to satisfy the non-masquerade invariant. This is the control preventing custodial OpenBao from becoming platform impersonation.

**Non-Masquerade Invariant (from G-08, line 229):**
> No platform-controlled credential may produce a signature that verifies as an authority actor without an actor-scoped grant bound to actor identity, payload hash, nonce, and expiry.

**Schema Requirements:**
- `delegated_signing_grants` table with: grant_id, actor_id, platform_credential_id, payload_hash, nonce (unique), expires_at (TIMESTAMPTZ, NOT NULL), consumed_at (TIMESTAMPTZ NULL).
- Nonce uniqueness prevents replay.
- Expiry prevents indefinite delegation.
- `consumed_at` tracks one-time use.

---

## Files Changed

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0166_create_delegated_signing_grants.sql` | CREATED | Delegated grant schema |
| `scripts/audit/verify_tsk_p2_preauth_007_09.sh` | CREATED | Verifier |
| `evidence/phase2/tsk_p2_preauth_007_09.json` | CREATED | Output artifact |

---

## Implementation (Completed)

### Schema
- `delegated_signing_grants` table created.
- UNIQUE constraint on `nonce` for replay prevention.
- NOT NULL on `expires_at` for mandatory expiry.
- CHECK constraint: `expires_at > created_at`.

### Verification
- Positive: table exists, constraints active.
- Negative: duplicate nonce rejected; missing expires_at rejected.
