# TSK-P2-PREAUTH-007-06 PLAN — Invariant Registry Schema & Append-Only Topology

Task: TSK-P2-PREAUTH-007-06
Owner: DB_FOUNDATION
Gap Source: G-01 part 1 (W7_GAP_ANALYSIS.md line 159)
failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-06.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Implementation Status: COMPLETED** — Migration 0163 applied, verifier passing.

---

## Regulated Surface Compliance (CRITICAL)

- Reference: `REGULATED_SURFACE_PATHS.yml`
- **MANDATORY PRE-CONDITION**: MUST NOT edit any migration or regulated file without prior approval metadata.

---

## Remediation Trace Compliance (CRITICAL)

- Reference: `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`
- `EXEC_LOG.md` is append-only.
- Mandatory markers: `failure_signature`, `origin_task_id`, `repro_command`, `verification_commands_run`, `final_status`.

---

## Objective

Create the physical `invariant_registry` table with typed fields (`verifier_type`, `severity`, `execution_layer`, `is_blocking`, `checksum`) and an append-only trigger that blocks UPDATE and DELETE operations.

**From G-01 (line 159):**
- The `invariant_registry` table is the foundation of the entire enforcement system.
- Must be append-only: no UPDATE, no DELETE. Corrections via versioned supersession only (new row + `supersedes_invariant_id`).
- Immutability rule matches the pattern used by `policy_decisions`.
- Privilege posture: `symphony_command` cannot modify at runtime.

---

## Files Changed

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0163_create_invariant_registry.sql` | CREATED | Migration creating the table |
| `scripts/audit/verify_tsk_p2_preauth_007_06.sh` | CREATED | Verifier with append-only negative test |
| `evidence/phase2/tsk_p2_preauth_007_06.json` | CREATED | Output artifact |

---

## Implementation (Completed)

### Schema
- `invariant_registry` table created with: `id`, `invariant_id`, `verifier_type`, `severity`, `execution_layer`, `is_blocking`, `checksum`, `created_at`.
- Append-only trigger blocks UPDATE and DELETE operations.

### Verification
- Positive: table exists, columns correct.
- Negative: UPDATE and DELETE on `invariant_registry` are rejected by trigger.

### Rebaseline
- Baseline regenerated after migration 0163.
