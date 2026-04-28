# TSK-P2-W5-FIX-10 PLAN — Fix verifier trigger name reference

Task: TSK-P2-W5-FIX-10
Owner: QA_VERIFIER
Depends on: TSK-P2-W5-FIX-09
failure_signature: P2.W5-FIX.VERIFIER-NAME.FALSE_POSITIVE
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

`scripts/db/verify_tsk_p2_preauth_005_08.sh` references trigger name
`tr_update_current_state` which does not exist. The actual trigger is
`trg_06_update_current` (pre-FIX-05) or `ai_01_update_current_state` (post-FIX-05).
The verifier silently passes because it does not fail-closed on missing results.
After this task, the verifier queries `pg_trigger` for the correct name and exits 1
if the trigger is absent.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-09 status=completed. All schema fixes applied.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_tsk_p2_preauth_005_08.sh` | MODIFY | Fix trigger name + add fail-closed guard |
| `evidence/phase2/tsk_p2_w5_fix_10.json` | CREATE | Evidence |

---

## Implementation Steps

### Step 1: Identify Wrong Reference
**What:** `[ID w5_fix_10_work_01]` grep for 'tr_update_current_state' in verifier. Record line numbers.

### Step 2: Fix Trigger Name
**What:** `[ID w5_fix_10_work_02]` Replace with `ai_01_update_current_state` (post-FIX-05 name).

### Step 3: Add Fail-Closed Guard
**What:** `[ID w5_fix_10_work_03]`
```bash
TRIGGER_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT count(*) FROM pg_trigger WHERE tgname = 'ai_01_update_current_state' AND tgrelid = 'state_transitions'::regclass")
if [ "$TRIGGER_EXISTS" -ne 1 ]; then echo "FAIL: trigger not found"; exit 1; fi
```

### Step 4-5: Run verification, update EXEC_LOG.

---

## Verification

```bash
bash scripts/db/verify_tsk_p2_preauth_005_08.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_10.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_10.json`
Required fields: task_id, git_sha, timestamp_utc, status, checks, trigger_name_corrected

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Wrong name still used | False PASS gate | grep verifier for old name |
| Verifier passes on missing | Governance theater | Fail-closed guard exits 1 |

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
