# GF-W1-UI-010 Implementation Plan

## Failure Signature
`PHASE1.GF-W1.UI-010.TSK_P1_219_UPDATE_4_TABS`

## Objective

Update TSK-P1-219 verifier to expect 4 tabs instead of 3 and add specific checks for worker-tokens tab and screen.

## Pre-conditions

1. GF-W1-UI-002 (worker token tab structure) is complete
2. src/supervisory-dashboard/index.html has 4 tabs
3. TSK-P1-219 verifier currently checks for 3 tabs

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_tsk_p1_219.sh` | MODIFY | Update tab count check, add worker-tokens checks, update evidence schema |
| `.toolchain/script_integrity/verifier_hashes.sha256` | MODIFY | Update hash for modified verifier |
| `evidence/phase1/gf_w1_ui_010.json` | CREATE | Evidence file |

## Stop Conditions

1. Tab count still checks for 3 instead of 4
2. Specific worker-tokens tab check not added
3. Specific screen-worker-tokens check not added
4. Evidence schema not updated
5. Verifier hash not updated

## Implementation Steps

### Step 1: Update Tab Count Check
**Tracking ID:** W1  
**What:** Update tab count check from 3 to 4  
**How:** Change line `if [ "$TAB_COUNT" -lt 3 ]` to `if [ "$TAB_COUNT" -lt 4 ]`  
**Done-when:** Verifier requires minimum 4 tabs

### Step 2: Add Worker Tokens Tab Check
**Tracking ID:** W2  
**What:** Add check for worker-tokens tab existence  
**How:** Add grep check for `switchTab('worker-tokens'` in dashboard file  
**Done-when:** Verifier confirms worker-tokens tab exists

### Step 3: Add Worker Tokens Screen Check
**Tracking ID:** W3  
**What:** Add check for screen-worker-tokens screen existence  
**How:** Add grep check for `id="screen-worker-tokens"` in dashboard file  
**Done-when:** Verifier confirms screen-worker-tokens exists

### Step 4: Update Evidence Schema
**Tracking ID:** W4  
**What:** Update evidence JSON schema  
**How:** Add worker_tokens_tab and worker_tokens_screen boolean fields to evidence payload  
**Done-when:** Evidence includes new check results

### Step 5: Update Verifier Hash
**Tracking ID:** W5  
**What:** Update verifier hash in verifier_hashes.sha256  
**How:** Run `sha256sum scripts/audit/verify_tsk_p1_219.sh` and update hash file  
**Done-when:** Hash file contains new hash for verifier

## Verification

| ID | Command | Purpose |
|----|---------|---------|
| V1 | `grep -q 'TAB_COUNT.*-lt 4' scripts/audit/verify_tsk_p1_219.sh \|\| exit 1` | Confirm tab count check updated |
| V2 | `grep -q \"switchTab('worker-tokens'\" scripts/audit/verify_tsk_p1_219.sh \|\| exit 1` | Confirm worker-tokens check added |
| V3 | `bash scripts/audit/verify_tsk_p1_219.sh \|\| exit 1` | Confirm verifier passes |

## Evidence Contract

```json
{
  "task_id": "GF-W1-UI-010",
  "timestamp": "ISO8601",
  "tab_count_check_updated": true,
  "worker_tokens_tab_check_added": true,
  "worker_tokens_screen_check_added": true,
  "evidence_schema_updated": true,
  "verifier_hash_updated": true
}
```

## Rollback

1. Revert changes to `scripts/audit/verify_tsk_p1_219.sh` (restore tab count check to 3)
2. Revert changes to `.toolchain/script_integrity/verifier_hashes.sha256`
3. Delete `evidence/phase1/gf_w1_ui_010.json`

## Risk Assessment

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Tab count not updated | GOVERNANCE.VERIFIER_FAILS_INCORRECTLY | Update -lt 3 to -lt 4 |
| Specific checks missing | GOVERNANCE.INCOMPLETE_VERIFICATION | Add grep checks for tab and screen |
| Evidence schema stale | GOVERNANCE.STALE_EVIDENCE_FORMAT | Add new boolean fields |
| Hash not updated | SECURITY.INTEGRITY_CHECK_FAILS | Run sha256sum and update hash file |
