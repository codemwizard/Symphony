# Implementation Plan for TSK-P2-PREAUTH-007-19-R4

**Task ID:** TSK-P2-PREAUTH-007-19-R4
**Title:** Add evidence digest validation against file on disk
**Owner:** SECURITY_GUARDIAN
**Status:** planned

---

## Objective

Add validation to ensure evidence_digest in trace log matches the SHA-256 of the actual evidence file on disk. The original implementation only checked format but never validated that the digest matched the file.

---

## Pre-Conditions

- TSK-P2-PREAUTH-007-19-R3 is completed
- DATABASE_URL is set and accessible
- Stage A approval artifact exists before editing verifier script

---

## Files to Change

- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

---

## Stop Conditions

- If verifier only checks format but not file match → STOP
- If verifier accepts mismatched digest → STOP
- If verifier doesn't check file existence → STOP

---

## Implementation Steps

### Step 1: Pre-Edit Documentation
- Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
- Create Stage A approval sidecar: `approvals/YYYY-MM-DD/.approval.json`
- Validate with `bash scripts/audit/validate_approval_metadata.sh approvals/YYYY-MM-DD/.approval.json`
- Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

### Step 2: Add evidence file existence check
- In `verify_tsk_p2_preauth_007_19.sh`, add check after parsing evidence_digest
- If evidence_digest is not "NONE", verify evidence file exists
- Fail with specific error if file doesn't exist

### Step 3: Add SHA-256 computation
- Compute SHA-256 of evidence file on disk using sha256sum
- Store computed digest in variable
- Handle case where file is empty

### Step 4: Add digest comparison
- Compare trace log evidence_digest with computed file digest
- Fail with specific error if digests don't match
- Include both digests in error message for debugging

### Step 5: Integrate into existing validation
- Add this check to the existing evidence digest format validation
- Ensure it runs after format check
- Update error handling to be specific about which check failed

### Step 6: Test with real evidence file
- Create a test evidence file
- Run verifier and confirm digest validation works
- Verify mismatch detection by tampering with file

### Step 7: Post-Edit Documentation
- Update EXEC_LOG.md with verification_commands_run and final_status
- Run conformance check with `--mode=stage-a --branch=<branch-name>`

---

## Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r4.json
```

---

## Evidence Contract

- evidence/phase2/tsk_p2_preauth_007_19_r4.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - evidence_digest_validation_check

---

## Rollback Plan

If verification fails:
1. Revert changes to `verify_tsk_p2_preauth_007_19.sh`
2. Update EXEC_LOG.md with failure details
3. Create remediation casefile if needed

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Evidence file modified after emission | LOW | LOW | Only validates at verification time |
| SHA-256 computation fails | LOW | LOW | Handle computation errors gracefully |

---

## Success Criteria

- [ ] Verifier checks evidence file existence when digest is not "NONE"
- [ ] Verifier computes SHA-256 of evidence file on disk
- [ ] Verifier compares trace digest with file digest
- [ ] Verifier fails if digests don't match
- [ ] Verifier passes when digests match
- [ ] EXEC_LOG.md is updated with required markers
- [ ] Stage A approval artifact exists before edit
