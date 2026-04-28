# Implementation Plan for TSK-P2-PREAUTH-007-19-R3

**Task ID:** TSK-P2-PREAUTH-007-19-R3
**Title:** Fail meaningless fallbacks when DATABASE_URL unset
**Owner:** SECURITY_GUARDIAN
**Status:** planned

---

## Objective

Replace "unknown:unknown:unknown" fallbacks with explicit failure when DATABASE_URL is not set, ensuring provenance is never meaningless.

---

## Pre-Conditions

- TSK-P2-PREAUTH-007-19-R2 is completed
- Stage A approval artifact exists before editing files

---

## Files to Change

- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

---

## Stop Conditions

- If functions still return "unknown" when DATABASE_URL unset → STOP
- If verifier accepts "unknown" values → STOP
- If DATABASE_URL check is not explicit → STOP

---

## Implementation Steps

### Step 1: Pre-Edit Documentation
- Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
- Create Stage A approval sidecar: `approvals/YYYY-MM-DD/.approval.json`
- Validate with `bash scripts/audit/validate_approval_metadata.sh approvals/YYYY-MM-DD/.approval.json`
- Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

### Step 2: Add DATABASE_URL check to capture_env_fingerprint
- In `scripts/dev/pre_ci.sh`, add check at start of capture_env_fingerprint
- Fail with error: "DATABASE_URL must be set for provenance capture"
- Return exit code 1 on failure

### Step 3: Add DATABASE_URL check to capture_executor_identity
- In `scripts/dev/pre_ci.sh`, add check at start of capture_executor_identity
- Fail with error: "DATABASE_URL must be set for provenance capture"
- Return exit code 1 on failure

### Step 4: Update verifier to reject "unknown"
- In `verify_tsk_p2_preauth_007_19.sh`, add check for "unknown" in provenance fields
- Reject "unknown" in environment fingerprint
- Reject "unknown" in executor identity
- Fail with specific error if "unknown" is found

### Step 5: Test without DATABASE_URL
- Run verifier without DATABASE_URL set
- Confirm it fails with explicit error
- Verify error message mentions DATABASE_URL requirement

### Step 6: Test with DATABASE_URL
- Run verifier with DATABASE_URL set
- Confirm it passes
- Verify no "unknown" values in output

### Step 7: Post-Edit Documentation
- Update EXEC_LOG.md with verification_commands_run and final_status
- Run conformance check with `--mode=stage-a --branch=<branch-name>`

---

## Verification

```bash
# Test 1: Without DATABASE_URL (should fail)
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r3_fail.json || true

# Test 2: With DATABASE_URL (should pass)
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r3_pass.json
```

---

## Evidence Contract

- evidence/phase2/tsk_p2_preauth_007_19_r3_fail.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - database_url_failure_check
- evidence/phase2/tsk_p2_preauth_007_19_r3_pass.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - database_url_success_check

---

## Rollback Plan

If verification fails:
1. Revert changes to `pre_ci.sh` and `verify_tsk_p2_preauth_007_19.sh`
2. Update EXEC_LOG.md with failure details
3. Create remediation casefile if needed

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| DATABASE_URL check too strict | LOW | MEDIUM | Test with valid DATABASE_URL before finalizing |
| Error message unclear | LOW | LOW | Use specific error message mentioning DATABASE_URL |

---

## Success Criteria

- [ ] Functions fail with clear error when DATABASE_URL is unset
- [ ] Error message explicitly states DATABASE_URL requirement
- [ ] Verifier rejects "unknown" in any provenance field
- [ ] Verifier passes when DATABASE_URL is set correctly
- [ ] EXEC_LOG.md is updated with required markers
- [ ] Stage A approval artifact exists before edit
