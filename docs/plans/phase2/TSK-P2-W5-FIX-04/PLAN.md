# TSK-P2-W5-FIX-04 PLAN — Harden all Wave 5 trigger functions with SECURITY DEFINER

Task: TSK-P2-W5-FIX-04
Owner: DB_FOUNDATION
Depends on: TSK-P2-W5-FIX-03
failure_signature: P2.W5-FIX.SECURITY-DEFINER.MISSING_HARDENING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

AGENTS.md mandates: "SECURITY DEFINER functions must harden: SET search_path = pg_catalog,
public." Migrations 0139-0144 created trigger functions as plain SECURITY INVOKER (default).
After this task, all trigger functions will have `SECURITY DEFINER SET search_path =
pg_catalog, public`, proven via `pg_proc.prosecdef = true` and `pg_proc.proconfig`.

Note: Migration 0137 already created `enforce_state_transition_authority()` and
`upgrade_authority_on_execution_binding()` with SECURITY DEFINER. The target functions
for this task are those created in 0139-0144 WITHOUT SECURITY DEFINER:
1. `enforce_transition_state_rules()` (0139)
2. `enforce_transition_authority()` (0140, fixed in FIX-01)
3. `enforce_transition_signature()` (0141)
4. `enforce_execution_binding()` (0142)
5. `deny_state_transitions_mutation()` (0143)
6. `update_current_state()` (0144)

---

## Architectural Context

SECURITY DEFINER hardening must follow FIX-01/FIX-02/FIX-03 because the function bodies
must be in their corrected state before being rewritten with security posture. Rewriting
a broken function with SECURITY DEFINER just hardens the bug.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-03 status=completed.
- [ ] MIGRATION_HEAD = 0147.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0148_harden_trigger_functions_security_definer.sql` | CREATE | CREATE OR REPLACE all 6 functions with SECURITY DEFINER |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Update to 0148 |
| `scripts/db/verify_tsk_p2_w5_fix_04.sh` | CREATE | Verify prosecdef + proconfig |
| `evidence/phase2/tsk_p2_w5_fix_04.json` | CREATE | Evidence |
| Governance files (THREAT_MODEL, COMPLIANCE_MAP, baseline, ADR-0010, evidence) | MODIFY | Steps 9-13 |
| `tasks/TSK-P2-W5-FIX-04/meta.yml` | MODIFY | Status update |

---

## Stop Conditions

- **SECURITY DEFINER added without SET search_path** → STOP (privilege escalation)
- **Function body logic changed** → STOP (security posture only)
- **Baseline not regenerated** → STOP

---

## Implementation Steps

### Step 1: Audit Current Security Posture
**What:** `[ID w5_fix_04_work_01]` Query pg_proc for all 6 functions.
**How:**
```sql
SELECT proname, prosecdef, proconfig
FROM pg_proc WHERE proname IN (
    'enforce_transition_state_rules', 'enforce_transition_authority',
    'enforce_transition_signature', 'enforce_execution_binding',
    'deny_state_transitions_mutation', 'update_current_state'
);
```
**Done when:** EXEC_LOG shows all 6 have prosecdef=false.

### Step 2: Write Migration
**What:** `[ID w5_fix_04_work_02]` CREATE OR REPLACE each function with current body + SECURITY DEFINER SET search_path = pg_catalog, public.
**How:** For each function, extract current body from pg_proc, then CREATE OR REPLACE with identical body plus security posture. Do NOT change any logic.

### Step 3: Update MIGRATION_HEAD
**What:** `[ID w5_fix_04_work_03]` Update to 0148.

### Step 4: Write Verification Script
**What:** `[ID w5_fix_04_work_04]` Check prosecdef=true and proconfig for all 6.

### Step 5-10: Run verification, governance, baseline, evidence staging, EXEC_LOG.
**What:** `[ID w5_fix_04_work_05..10]` Standard governance sequence.

---

## Verification

```bash
psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_proc WHERE proname IN ('enforce_transition_state_rules','enforce_transition_authority','enforce_transition_signature','enforce_execution_binding','deny_state_transitions_mutation','update_current_state') AND prosecdef = true" | grep -q '6' || exit 1
bash scripts/db/verify_tsk_p2_w5_fix_04.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_04.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_04.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, functions_hardened, prosecdef_verified, proconfig_verified

---

## Rollback

1. CREATE OR REPLACE all functions without SECURITY DEFINER
2. Update MIGRATION_HEAD, regenerate baseline

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| SECURITY DEFINER without SET search_path | Privilege escalation | Verifier checks proconfig |
| Function body changed | Logic regression | Diff current vs new body |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
