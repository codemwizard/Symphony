# Implementation Plan for TSK-P2-PREAUTH-007-19-R5

**Task ID:** TSK-P2-PREAUTH-007-19-R5
**Title:** Replace tab delimiter with non-whitespace delimiter
**Owner:** SECURITY_GUARDIAN
**Status:** planned

---

## Objective

Replace tab delimiter with a non-whitespace delimiter (e.g., "|") to eliminate IFS whitespace merging fragility. The original implementation used tabs which caused Bash to merge consecutive tabs when fields were empty.

---

## Pre-Conditions

- TSK-P2-PREAUTH-007-19-R4 is completed
- Stage A approval artifact exists before editing files

---

## Files to Change

- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

---

## Stop Conditions

- If tab delimiter is still used → STOP
- If new delimiter is whitespace → STOP
- If verifier doesn't parse new delimiter correctly → STOP

---

## Implementation Steps

### Step 1: Pre-Edit Documentation
- Create Stage A approval artifact: `approvals/YYYY-MM-DD/BRANCH-<branch-name>.md`
- Create Stage A approval sidecar: `approvals/YYYY-MM-DD/.approval.json`
- Validate with `bash scripts/audit/validate_approval_metadata.sh approvals/YYYY-MM-DD/.approval.json`
- Update EXEC_LOG.md with initial entry including failure_signature, origin_task_id, repro_command

### Step 2: Replace delimiter in emit_preci_step_with_provenance
- In `scripts/dev/pre_ci.sh`, change `printf "PRECI_STEP\t..."` to `printf "PRECI_STEP|..."`
- Update comment to reflect new delimiter
- Ensure all 8 fields are still included

### Step 3: Replace IFS in verifier
- In `verify_tsk_p2_preauth_007_19.sh`, change `IFS=$'\t'` to `IFS="|"`
- Update all read statements that use IFS

### Step 4: Replace awk delimiter in verifier
- In `verify_tsk_p2_preauth_007_19.sh`, change `awk -F'\t'` to `awk -F'|'`
- Update all awk commands that parse trace log

### Step 5: Remove placeholder workaround
- Since "|" is non-whitespace, empty fields don't need placeholders
- Remove the "NONE" placeholder logic for empty evidence_digest
- Empty fields will be preserved correctly with "|" delimiter

### Step 6: Test delimiter parsing
- Run verifier and confirm it parses "|" correctly
- Test with empty fields to ensure no merging
- Verify all 8 fields are parsed correctly

### Step 7: Post-Edit Documentation
- Update EXEC_LOG.md with verification_commands_run and final_status
- Run conformance check with `--mode=stage-a --branch=<branch-name>`

---

## Verification

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r5.json
```

---

## Evidence Contract

- evidence/phase2/tsk_p2_preauth_007_19_r5.json must include:
  - task_id
  - git_sha
  - timestamp_utc
  - status
  - checks
  - delimiter_parsing_check

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
| "|" appears in field content | LOW | LOW | Unlikely for provenance fields |
| External tools parse old format | LOW | LOW | This is a new feature, no external parsers |

---

## Success Criteria

- [ ] Trace log uses "|" delimiter instead of "\t"
- [ ] Verifier parses "|" delimiter correctly
- [ ] Empty fields are handled correctly without placeholder workaround
- [ ] All 8 fields are parsed correctly
- [ ] EXEC_LOG.md is updated with required markers
- [ ] Stage A approval artifact exists before edit
