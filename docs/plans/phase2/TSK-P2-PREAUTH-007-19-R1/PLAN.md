# Implementation Plan for TSK-P2-PREAUTH-007-19-R1

**Task ID:** TSK-P2-PREAUTH-007-19-R1
**Title:** Add superuser check to executor identity validation
**Owner:** SECURITY_GUARDIAN
**Status:** planned

---

## Objective

Add validation to ensure executor identity is not running under postgres superuser or any overprivileged role. This addresses a critical security gap in TSK-P2-PREAUTH-007-19 where the verifier never validated that db_role is NOT postgres or a superuser.

---

## Pre-Conditions

- TSK-P2-PREAUTH-007-19 is completed
- DATABASE_URL is set and accessible
- Symphonym database is running
- Stage A approval artifact exists before editing verifier script

---

## Files to Change

- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

---

## Stop Conditions

- If superuser check is added but allows postgres role → STOP
- If superuser check is added but doesn't check rolsuper → STOP
- If superuser check is added but doesn't check rolcreaterole → STOP

---

## Implementation Steps

### Step 1: Pre-Edit Documentation
- Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
- Create Stage A approval sidecar: `approvals/YYYY-MM-DD/.approval.json`
- Validate with `bash scripts/audit/validate_approval_metadata.sh approvals/YYYY-MM-DD/.approval.json`
- Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

### Step 2: Add postgres role check
- In `verify_tsk_p2_preauth_007_19.sh`, add check to verify db_role is not "postgres"
- Add check in the executor identity validation section
- Fail with specific error if db_role is "postgres"

### Step 3: Add rolsuper check
- Query pg_roles.rolsuper for the db_role
- Fail with specific error if rolsuper = true
- Use DATABASE_URL for the query

### Step 4: Add rolcreaterole check
- Query pg_roles.rolcreaterole for the db_role
- Fail with specific error if rolcreaterole = true
- Use DATABASE_URL for the query

### Step 5: Update verifier logic
- Integrate superuser checks into the existing executor identity validation
- Ensure checks run after parsing executor_id field
- Update error messages to be specific about which check failed

### Step 6: Post-Edit Documentation
- Update EXEC_LOG.md with verification_commands_run and final_status
- Run conformance check with `--mode=stage-a --branch=<branch-name>`

---

## Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r1.json
```

---

## Evidence Contract

- evidence/phase2/tsk_p2_preauth_007_19_r1.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - superuser_validation_check

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
| Superuser check too restrictive | MEDIUM | LOW | Test with symphony_admin role before finalizing |
| pg_roles query fails | LOW | MEDIUM | Ensure DATABASE_URL is set correctly |

---

## Success Criteria

- [ ] Verifier rejects postgres role explicitly
- [ ] Verifier rejects any role with rolsuper = true
- [ ] Verifier rejects any role with rolcreaterole = true
- [ ] Verifier passes for symphony_admin (non-superuser role)
- [ ] EXEC_LOG.md is updated with required markers
- [ ] Stage A approval artifact exists before edit
