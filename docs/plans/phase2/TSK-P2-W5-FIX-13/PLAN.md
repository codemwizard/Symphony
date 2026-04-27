# TSK-P2-W5-FIX-13 PLAN — Wave 5 State Machine Integration Verifier

Task: TSK-P2-W5-FIX-13
Owner: QA_VERIFIER
Depends on: TSK-P2-W5-FIX-12
failure_signature: P2.W5-FIX.INTEGRATION.NO_LIFECYCLE_PROOF
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

This is the **Wave 5 graduation gate**. After all 12 prior fixes, there is no single
script that proves the entire state machine works end-to-end. This task creates a
standalone integration verifier that exercises the full INSERT lifecycle:

1. Authority validation (enforce_transition_authority)
2. Execution binding validation (enforce_execution_binding)
3. State rule validation (enforce_transition_state_rules)
4. Signature enforcement (enforce_transition_signature)
5. Data authority upgrade (upgrade_authority_on_execution_binding)
6. Current state update (update_current_state → state_current)

If this script passes, the Wave 5 state machine is **proven correct** and Wave 6 can begin.

---

## Pre-conditions

- [ ] TSK-P2-W5-FIX-12 status=completed.
- [ ] All 9 schema migrations (0145-0153) applied.
- [ ] All trigger renames applied (bi_XX_/ai_XX_ naming).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_wave5_state_machine_integration.sh` | CREATE | Full lifecycle test |
| `evidence/phase2/tsk_p2_w5_fix_13.json` | CREATE | Evidence — Wave 5 graduation proof |

---

## Implementation Steps

### Step 1: Design Integration Scenario
**What:** `[ID w5_fix_13_work_01]` Define test scenario:
```sql
BEGIN;
-- 1. Create test execution_record with interpretation_version_id
-- 2. Create test policy_decision matching entity_type
-- 3. Seed state_rule for entity_type='integration_test', PENDING→APPROVED
-- 4. INSERT state_transition with all valid data
-- 5. VERIFY: transition_hash starts with PLACEHOLDER_PENDING_SIGNING_CONTRACT:
-- 6. VERIFY: transitioned_at is set (via set_transitioned_at if exists)
-- 7. VERIFY: state_current row exists with current_state='APPROVED'
-- 8. VERIFY: data_authority upgraded (via upgrade_authority_on_execution_binding)
-- 9. NEGATIVE: INSERT with invalid state transition → rejected by state_rules
-- 10. NEGATIVE: INSERT with non-existent policy_decision_id → rejected by FK
ROLLBACK;
```

### Step 2: Write Integration Script
**What:** `[ID w5_fix_13_work_02]` Create `scripts/db/verify_wave5_state_machine_integration.sh`.
**How:** Full lifecycle in a single transaction with explicit assertions on each trigger effect.

### Step 3: Run Integration Test
**What:** `[ID w5_fix_13_work_03]` Execute script and produce evidence.

### Step 4: Update EXEC_LOG
**What:** `[ID w5_fix_13_work_04]` Final remediation trace.

---

## Verification

```bash
bash scripts/db/verify_wave5_state_machine_integration.sh || exit 1
test -f evidence/phase2/tsk_p2_w5_fix_13.json || exit 1
# Verify lifecycle_complete field
cat evidence/phase2/tsk_p2_w5_fix_13.json | grep -q '"lifecycle_complete": true' || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_w5_fix_13.json`

Required fields:
- `task_id`: "TSK-P2-W5-FIX-13"
- `git_sha`: commit sha
- `timestamp_utc`: ISO 8601
- `status`: "PASS"
- `checks`: array of all trigger effect assertions
- `lifecycle_complete`: true — all 6 trigger effects verified
- `trigger_effects_verified`: object with per-trigger results
- `negative_test_results`: object with state_rule rejection + FK rejection

This is the **canonical proof** that Wave 5 is complete and Wave 6 can begin.

---

## Rollback

Not applicable — this is a verification-only task. If it fails, the preceding FIX tasks
must be re-examined.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Integration test misses trigger | Incomplete proof | Check all 6 effects explicitly |
| Test passes on mocked state | False graduation | Use psql against live DB |
| state_current not checked | Silent trigger failure | Assert row exists with correct state |

---

## Anti-Drift Cheating Limits

After Wave 5 graduation:
- **Ed25519 signing**: Still placeholder (Wave 6 design task)
- **Data authority derivation**: Not implemented (Wave 6)
- **Cross-entity signing**: Not addressed (Wave 6)
- **Rule seeding**: Only test rules exist — production rules are a deployment concern

---

## Approval (for regulated surfaces)

- [ ] Approval metadata exists
