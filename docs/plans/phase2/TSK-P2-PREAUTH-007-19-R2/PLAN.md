# Implementation Plan for TSK-P2-PREAUTH-007-19-R2

**Task ID:** TSK-P2-PREAUTH-007-19-R2
**Title:** Replace weak placeholders with meaningful empty indicators
**Owner:** SECURITY_GUARDIAN
**Status:** planned

---

## Objective

Replace "-" placeholder with a structured empty indicator that distinguishes between "no evidence file" and "legitimate empty hash". The original implementation used "-" which could be confused with a real hash.

---

## Pre-Conditions

- TSK-P2-PREAUTH-007-19-R1 is completed
- DATABASE_URL is set and accessible
- Stage A approval artifact exists before editing files

---

## Files to Change

- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

---

## Stop Conditions

- If placeholder is still "-" → STOP
- If placeholder can be confused with a real hash → STOP
- If verifier doesn't validate placeholder format → STOP

---

## Implementation Steps

### Step 1: Pre-Edit Documentation
- Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
- Create Stage A approval sidecar: `approvals/YYYY-MM-DD/.approval.json`
- Validate with `bash scripts/audit/validate_approval_metadata.sh approvals/YYYY-MM-DD/.approval.json`
- Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

### Step 2: Replace placeholder in emit_preci_step_with_provenance
- In `scripts/dev/pre_ci.sh`, change `evidence_digest="-"` to `evidence_digest="NONE"`
- Update comment to explain "NONE" means no evidence file available
- Ensure placeholder is uppercase for clarity

### Step 3: Update verifier to accept "NONE"
- In `verify_tsk_p2_preauth_007_19.sh`, update evidence digest format check
- Accept either SHA256 format or "NONE" as valid
- Reject "-" explicitly as invalid

### Step 4: Add validation for "NONE" usage
- Add check to ensure "NONE" only appears when evidence_file is empty/missing
- If evidence_file exists but digest is "NONE", fail with specific error
- This prevents using "NONE" as a fake hash

### Step 5: Update verifier to reject "-"
- Add explicit check to reject "-" as evidence_digest
- Fail with specific error if "-" is found
- This ensures the old placeholder is not accepted

### Step 6: Post-Edit Documentation
- Update EXEC_LOG.md with verification_commands_run and final_status
- Run conformance check with `--mode=stage-a --branch=<branch-name>`

---

## Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r2.json
```

---

## Evidence Contract

- evidence/phase2/tsk_p2_preauth_007_19_r2.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - placeholder_validation_check

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
| "NONE" conflicts with future hash format | LOW | LOW | "NONE" is not a valid SHA256 |
| Existing trace logs use "-" | LOW | LOW | This is a new feature, no existing logs |

---

## Success Criteria

- [ ] Placeholder is "NONE" (uppercase, meaningful)
- [ ] Verifier accepts "NONE" as valid empty indicator
- [ ] Verifier rejects "-" as invalid
- [ ] Verifier validates that "NONE" only appears when evidence_file is empty
- [ ] EXEC_LOG.md is updated with required markers
- [ ] Stage A approval artifact exists before edit
