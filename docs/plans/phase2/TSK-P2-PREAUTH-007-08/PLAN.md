# TSK-P2-PREAUTH-007-08 PLAN — Trust Architecture: PK Registry & Identity Binding

Task: TSK-P2-PREAUTH-007-08
Owner: DB_FOUNDATION
Gap Source: G-08 part 1 (W7_GAP_ANALYSIS.md line 166, lines 210-229)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-08.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Implementation Status: COMPLETED** — Migration 0165 applied, verifier passing.

---

## Objective

Create the `public_keys_registry` PostgreSQL table with temporal validity constraints. This forces the Trust Architecture deliverable to be DDL (SQL), not a Markdown document.

**From G-08 (line 166, lines 210-229):**
- Architect ruling: Actor-rooted signing (Option B). Authority belongs to the actor. Infrastructure may custody keys but may not originate authority.
- Wave 7 must author: public key registry schema, signature envelope schema, signer identity binding, historical validity contract.
- `public_keys_registry` schema with: key_id, actor_id, public_key, algorithm, valid_from (TIMESTAMPTZ), valid_to (TIMESTAMPTZ NULL), revoked_at (TIMESTAMPTZ NULL), revocation_reason.
- Temporal validity: `valid_from < valid_to`, non-overlapping validity windows per actor.

**Risk Assessment (HIGH RISK):**
Without forcing this to DDL, an agent will write a Markdown file saying "We use Ed25519 and actor-rooted keys" and skip the actual schema.

---

## Files Changed

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0165_create_public_keys_registry.sql` | CREATED | PK registry table |
| `scripts/audit/verify_tsk_p2_preauth_007_08.sh` | CREATED | Verifier |
| `evidence/phase2/tsk_p2_preauth_007_08.json` | CREATED | Output artifact |

---

## Implementation (Completed)

### Schema
- `public_keys_registry` table created with temporal validity constraints.
- CHECK constraint: `valid_from < valid_to`.
- Indexes for actor_id and temporal queries.

### Verification
- Positive: table exists, columns correct, temporal constraints active.
- Negative: INSERT with `valid_from > valid_to` rejected by constraint.
