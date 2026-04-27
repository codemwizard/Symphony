# TSK-P2-PREAUTH-007-07 PLAN — Registry Supersession & Execution Constraints

Task: TSK-P2-PREAUTH-007-07
Owner: DB_FOUNDATION
Gap Source: G-01 part 2 (W7_GAP_ANALYSIS.md line 159)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-07.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Implementation Status: COMPLETED** — Migration 0164 applied, verifier passing.

---

## Objective

Add constraints to `invariant_registry` for linear supersession (no forks) and execution semantics (checksum, freshness).

**From G-01 (line 159):**
- Supersession chain rule: supersession must form a single linear chain per invariant family — forked supersession is invalid and rejected by UNIQUE constraint on `supersedes_invariant_id`.
- Active row resolution: latest non-superseded row per `invariant_id` family.
- Superseding rows must restate `is_blocking` (no inheritance).
- Execution semantics: how verifier execution is resolved from registry rows, freshness enforcement, behavior when verifier code checksum disagrees with registry checksum (must block, not warn).

---

## Files Changed

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0164_registry_supersession_constraints.sql` | CREATED | Constraints for linear supersession |
| `scripts/audit/verify_tsk_p2_preauth_007_07.sh` | CREATED | Verifier |
| `evidence/phase2/tsk_p2_preauth_007_07.json` | CREATED | Output artifact |

---

## Implementation (Completed)

### Constraints Added
- UNIQUE constraint on `supersedes_invariant_id` preventing forked supersession chains.
- Execution constraints for checksum validation and freshness enforcement.

### Verification
- Positive: constraints exist, valid supersession chain accepted.
- Negative: attempting to fork a supersession chain fails with constraint violation.
