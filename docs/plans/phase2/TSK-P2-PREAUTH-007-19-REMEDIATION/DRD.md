# DRD: TSK-P2-PREAUTH-007-19 Provenance Binding Remediation

**Task ID:** TSK-P2-PREAUTH-007-19-REMEDIATION
**Owner:** SECURITY_GUARDIAN
**Date:** 2026-04-26
**Status:** DRAFT
**DRD Type:** Implementation Plan

---

## Executive Summary

This DRD addresses 5 critical security gaps in the TSK-P2-PREAUTH-007-19 implementation. The original implementation passed verification but failed to enforce the security requirements specified in the PLAN.md. This remediation breaks the fixes into 5 small, focused tasks following the TSK-P1-240 pattern to prevent AI drift and ensure each fix is independently verifiable.

---

## Issues Identified

| Issue | Severity | Description |
|-------|----------|-------------|
| **Issue 1** | CRITICAL | Missing superuser check - verifier never validates that db_role is NOT postgres or a superuser |
| **Issue 2** | HIGH | Weak placeholders for empty fields - "-" doesn't distinguish between no evidence and fake hash |
| **Issue 3** | HIGH | Meaningless fallbacks when DATABASE_URL unset - returns "unknown:unknown:unknown" provides no provenance |
| **Issue 4** | HIGH | No evidence digest validation - never validates that digest matches the evidence file on disk |
| **Issue 5** | MEDIUM | Tab delimiter fragility - IFS whitespace merging required workaround, approach is fragile |

---

## Anti-Drift and Anti-Hallucination Measures

Following the lessons learned from WAVE5_TASK_CREATION_LESSONS_LEARNED.md and the TSK-P1-240 pattern:

### 1. Small Task Granularity
- Each remediation task has **3-5 work items** (not 5-6, since these are focused fixes)
- Each task has a **single, focused responsibility**
- This prevents AI drift by limiting scope and reducing cognitive load

### 2. Explicit Stop Conditions
- Each task has **specific stop conditions** that must be checked before proceeding
- Stop conditions are **mechanically verifiable** (e.g., "if superuser check is missing → STOP")
- This prevents "continuing anyway" when requirements aren't met

### 3. Behavioral Verification
- All verifiers use **live behavioral tests**, not static grep checks
- Verifiers must **inspect real system state** (DB, file, output)
- This prevents "grep theatre" and self-referential validation

### 4. Evidence Digest Validation
- All tasks require **evidence digest validation** against actual files
- This prevents fake hashes and placeholder abuse
- This addresses the "cheat patterns blocked" requirement from TSK-P1-240

### 5. Regulated Surface Compliance
- Tasks touching regulated surfaces (pre_ci.sh, verifier scripts) require **approval metadata before edit**
- This follows the Wave 5 lesson: "Approval artifacts MUST be created BEFORE editing any regulated surface file"

### 6. Remediation Trace Compliance
- All tasks update EXEC_LOG.md with **required markers**: failure_signature, origin_task_id, repro_command, verification_commands_run, final_status
- EXEC_LOG.md is **append-only**
- This ensures durable audit trail

---

## Task Breakdown

### Task 1: Add Superuser Check to Executor Identity Validation

**Task ID:** TSK-P2-PREAUTH-007-19-R1
**Title:** Add superuser check to executor identity validation
**Owner:** SECURITY_GUARDIAN
**Status:** planned
**Priority:** CRITICAL

**Objective:**
Add validation to ensure executor identity is not running under postgres superuser or any overprivileged role.

**Files to Change:**
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

**Stop Conditions:**
- If superuser check is added but allows postgres role → STOP
- If superuser check is added but doesn't check rolsuper → STOP
- If superuser check is added but doesn't check rolcreaterole → STOP

**Work Items:**
1. Add check to verify db_role is not "postgres"
2. Add check to verify db_role is not a superuser (query pg_roles.rolsuper)
3. Add check to verify db_role is not a role creator (query pg_roles.rolcreaterole)
4. Update verifier to fail if any superuser condition is met
5. Run verifier and confirm it fails for postgres role

**Acceptance Criteria:**
- Verifier rejects postgres role explicitly
- Verifier rejects any role with rolsuper = true
- Verifier rejects any role with rolcreaterole = true
- Verifier passes for symphony_admin (non-superuser role)

**Verification Commands:**
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r1.json
```

**Evidence Contract:**
- evidence/phase2/tsk_p2_preauth_007_19_r1.json must include check for superuser validation

---

### Task 2: Replace Weak Placeholders with Meaningful Empty Indicators

**Task ID:** TSK-P2-PREAUTH-007-19-R2
**Title:** Replace weak placeholders with meaningful empty indicators
**Owner:** SECURITY_GUARDAN
**Status:** planned
**Priority:** HIGH

**Objective:**
Replace "-" placeholder with a structured empty indicator that distinguishes between "no evidence file" and "legitimate empty hash".

**Files to Change:**
- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

**Stop Conditions:**
- If placeholder is still "-" → STOP
- If placeholder can be confused with a real hash → STOP
- If verifier doesn't validate placeholder format → STOP

**Work Items:**
1. Replace "-" placeholder with "NONE" in emit_preci_step_with_provenance
2. Update verifier to validate that evidence_digest is either SHA256 or "NONE"
3. Add check to ensure "NONE" is only used when evidence_file is empty/missing
4. Update verifier to reject "-" as invalid evidence_digest
5. Run verifier and confirm it accepts "NONE" but rejects "-"

**Acceptance Criteria:**
- Placeholder is "NONE" (uppercase, meaningful)
- Verifier accepts "NONE" as valid empty indicator
- Verifier rejects "-" as invalid
- Verifier validates that "NONE" only appears when evidence_file is empty

**Verification Commands:**
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r2.json
```

**Evidence Contract:**
- evidence/phase2/tsk_p2_preauth_007_19_r2.json must include check for placeholder validation

---

### Task 3: Fail Meaningless Fallbacks When DATABASE_URL Unset

**Task ID:** TSK-P2-PREAUTH-007-19-R3
**Title:** Fail meaningless fallbacks when DATABASE_URL unset
**Owner:** SECURITY_GUARDIAN
**Status:** planned
**Priority:** HIGH

**Objective:**
Replace "unknown:unknown:unknown" fallbacks with explicit failure when DATABASE_URL is not set, ensuring provenance is never meaningless.

**Files to Change:**
- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

**Stop Conditions:**
- If functions still return "unknown" when DATABASE_URL unset → STOP
- If verifier accepts "unknown" values → STOP
- If DATABASE_URL check is not explicit → STOP

**Work Items:**
1. Add explicit check in capture_env_fingerprint to fail if DATABASE_URL is unset
2. Add explicit check in capture_executor_identity to fail if DATABASE_URL is unset
3. Update error messages to be specific: "DATABASE_URL must be set for provenance capture"
4. Update verifier to reject "unknown" values in any provenance field
5. Run verifier without DATABASE_URL and confirm it fails explicitly

**Acceptance Criteria:**
- Functions fail with clear error when DATABASE_URL is unset
- Error message explicitly states DATABASE_URL requirement
- Verifier rejects "unknown" in any provenance field
- Verifier passes when DATABASE_URL is set correctly

**Verification Commands:**
```bash
# Test 1: Without DATABASE_URL (should fail)
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r3_fail.json || true

# Test 2: With DATABASE_URL (should pass)
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r3_pass.json
```

**Evidence Contract:**
- evidence/phase2/tsk_p2_preauth_007_19_r3_fail.json must show explicit DATABASE_URL failure
- evidence/phase2/tsk_p2_preauth_007_19_r3_pass.json must show pass with DATABASE_URL set

---

### Task 4: Add Evidence Digest Validation Against File on Disk

**Task ID:** TSK-P2-PREAUTH-007-19-R4
**Title:** Add evidence digest validation against file on disk
**Owner:** SECURITY_GUARDIAN
**Status:** planned
**Priority:** HIGH

**Objective:**
Add validation to ensure evidence_digest in trace log matches the SHA-256 of the actual evidence file on disk.

**Files to Change:**
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

**Stop Conditions:**
- If verifier only checks format but not file match → STOP
- If verifier accepts mismatched digest → STOP
- If verifier doesn't check file existence → STOP

**Work Items:**
1. Add check to verify evidence file exists when evidence_digest is not "NONE"
2. Add check to compute SHA-256 of evidence file on disk
3. Add check to compare trace log evidence_digest with computed file digest
4. Update verifier to fail if digests don't match
5. Run verifier with a real evidence file and confirm digest validation works

**Acceptance Criteria:**
- Verifier checks evidence file existence when digest is not "NONE"
- Verifier computes SHA-256 of evidence file on disk
- Verifier compares trace digest with file digest
- Verifier fails if digests don't match
- Verifier passes when digests match

**Verification Commands:**
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r4.json
```

**Evidence Contract:**
- evidence/phase2/tsk_p2_preauth_007_19_r4.json must include check for evidence digest validation

---

### Task 5: Replace Tab Delimiter with Non-Whitespace Delimiter

**Task ID:** TSK-P2-PREAUTH-007-19-R5
**Title:** Replace tab delimiter with non-whitespace delimiter
**Owner:** SECURITY_GUARDIAN
**Status:** planned
**Priority:** MEDIUM

**Objective:**
Replace tab delimiter with a non-whitespace delimiter (e.g., "|") to eliminate IFS whitespace merging fragility.

**Files to Change:**
- `scripts/dev/pre_ci.sh`
- `scripts/audit/verify_tsk_p2_preauth_007_19.sh`

**Stop Conditions:**
- If tab delimiter is still used → STOP
- If new delimiter is whitespace → STOP
- If verifier doesn't parse new delimiter correctly → STOP

**Work Items:**
1. Replace "\t" with "|" in emit_preci_step_with_provenance
2. Replace IFS=$'\t' with IFS="|" in verifier
3. Replace awk -F'\t' with awk -F'|' in verifier
4. Remove placeholder workaround (no longer needed with non-whitespace delimiter)
5. Run verifier and confirm parsing works with new delimiter

**Acceptance Criteria:**
- Trace log uses "|" delimiter instead of "\t"
- Verifier parses "|" delimiter correctly
- Empty fields are handled correctly without placeholder workaround
- All 8 fields are parsed correctly

**Verification Commands:**
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_r5.json
```

**Evidence Contract:**
- evidence/phase2/tsk_p2_preauth_007_19_r5.json must include check for delimiter parsing

---

## Execution Sequence

Tasks must be executed in this order:
1. TSK-P2-PREAUTH-007-19-R1 (Superuser check) - CRITICAL security gap
2. TSK-P2-PREAUTH-007-19-R2 (Placeholders) - HIGH, affects all subsequent tasks
3. TSK-P2-PREAUTH-007-19-R3 (DATABASE_URL fallbacks) - HIGH, foundational
4. TSK-P2-PREAUTH-007-19-R4 (Evidence digest validation) - HIGH, builds on R2
5. TSK-P2-PREAUTH-007-19-R5 (Delimiter) - MEDIUM, cleanup

---

## Regulated Surface Compliance

**Reference:** docs/operations/REGULATED_SURFACE_PATHS.yml

**Regulated Paths:**
- scripts/dev/pre_ci.sh
- scripts/audit/verify_tsk_p2_preauth_007_19.sh

**Approval Workflow:** stage_a_stage_b

**Stage A Required Before Edit:** YES

**Must Read:**
- docs/operations/REGULATED_SURFACE_PATHS.yml
- docs/operations/approval_metadata.schema.json

---

## Remediation Trace Compliance

**Reference:** docs/operations/REMEDIATION_TRACE_WORKFLOW.md

**Required Markers:**
- failure_signature: PHASE2.STRICT.TSK-P2-PREAUTH-007-19-REMEDIATION.PROOF_FAIL
- origin_task_id: TSK-P2-PREAUTH-007-19-REMEDIATION
- repro_command: bash scripts/audit/verify_tsk_p2_preauth_007_19.sh
- verification_commands_run: (per task)
- final_status: (per task)

**Marker Location:** EXEC_LOG.md (this DRD + task-specific EXEC_LOG.md)

**Append-Only:** YES

**Markers Required At Edit:** YES

**Must Read:**
- docs/operations/REMEDIATION_TRACE_WORKFLOW.md

---

## Final Verification

After all 5 tasks are complete, run the full TSK-P2-PREAUTH-007-19 verifier:

```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@localhost:55432/symphony"
bash scripts/audit/verify_tsk_p2_preauth_007_19.sh > evidence/phase2/tsk_p2_preauth_007_19_final.json
```

**Final Acceptance Criteria:**
- All 5 remediation tasks pass individually
- Full TSK-P2-PREAUTH-007-19 verifier passes
- Evidence digest validation works for real evidence files
- Superuser check rejects postgres role
- DATABASE_URL requirement is enforced
- Delimiter parsing is robust

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Task dependencies cause cascade failures | LOW | MEDIUM | Each task has independent verification |
| Delimiter change breaks existing trace logs | LOW | LOW | This is a new feature, no existing logs to break |
| Superuser check too restrictive | MEDIUM | LOW | Test with symphony_admin role before finalizing |
| Evidence digest validation performance | LOW | LOW | Only runs during verification, not in hot path |

---

## Rollback Plan

If any task fails verification:
1. Revert the specific file changes for that task
2. Update EXEC_LOG.md with failure details
3. Create remediation casefile if needed
4. Do not proceed to next task until current task passes

---

## Success Criteria

- [ ] All 5 remediation tasks pass individual verification
- [ ] Full TSK-P2-PREAUTH-007-19 verifier passes
- [ ] No "unknown" values in provenance fields
- [ ] Superuser check is enforced
- [ ] Evidence digest validation is implemented
- [ ] Delimiter is non-whitespace and robust
- [ ] EXEC_LOG.md is updated for all tasks
- [ ] Approval metadata is created before regulated surface edits
