# Pre-Existing Issues Report
**Date**: 2026-04-08  
**Context**: Meta.yml Schema Fixes for GF-W1-UI Tasks  
**Reporter**: Kiro AI Assistant

---

## Executive Summary

During the process of fixing 10 meta.yml files (GF-W1-UI-014 through GF-W1-UI-023) to conform to the canonical schema, several pre-existing issues were encountered that are unrelated to the meta.yml task but block full pre_ci passage. This report documents these issues for prioritization and remediation.

---

## Issue 1: PII Leakage in Supervisory Dashboard

**Severity**: HIGH  
**Category**: Security / Compliance  
**Status**: BLOCKING PRE_CI

### Description
The supervisory dashboard contains a PII leakage violation where a phone number is passed as a URL query parameter.

### Location
- **File**: `src/supervisory-dashboard/index.html`
- **Line**: 4625
- **Code**: 
  ```javascript
  const response = await fetch(`/pilot-demo/api/workers/lookup?phone=${encodeURIComponent(phone)}`, {
  ```

### Impact
- Blocks pre_ci passage at the "Regulated payload guardrails (PII leakage lint)" gate
- Violates PII handling policies
- Phone numbers in URL query parameters are logged in web server access logs, creating a compliance risk

### Failure Signature
```
FAILURE_LAYER=audit/governance
FAILURE_GATE_ID=pre_ci.phase0_ordered_checks
FAILURE_SIGNATURE=PRECI.AUDIT.GATES
FAILURE_LABEL=Phase-0 audit and schema gates
```

### Recommended Remediation
1. Move phone number from URL query parameter to POST request body
2. Update the `/pilot-demo/api/workers/lookup` endpoint to accept POST instead of GET
3. Ensure phone number is never logged in access logs
4. Add test to verify PII is not in URL parameters

### Related Files
- `src/supervisory-dashboard/index.html` (line 4625)
- Backend endpoint handler for `/pilot-demo/api/workers/lookup`

### Priority
**CRITICAL** - This blocks all pre_ci runs and represents a security/compliance violation.

---

## Issue 2: DRD Lockout System Behavior

**Severity**: MEDIUM  
**Category**: Developer Experience  
**Status**: RESOLVED (for this instance)

### Description
The DRD (Debug Remediation Discipline) lockout system blocked pre_ci execution after 4 consecutive failures of the task meta schema check. While this is working as designed, the lockout persisted even after the underlying issue was fixed.

### Observed Behavior
1. Task meta schema check failed 4 times consecutively
2. DRD lockout activated with signature `PRECI.GOVERNANCE.TASK_META_SCHEMA`
3. Lockout prevented pre_ci execution even after meta.yml files were fixed
4. Required manual creation of remediation casefile and clearance

### Root Cause
The lockout system is designed to prevent blind reruns without root cause analysis. However, it requires manual intervention even when the fix is straightforward.

### Impact
- Adds friction to development workflow
- Requires understanding of DRD system and remediation casefile format
- Can be confusing for developers unfamiliar with the system

### Recommended Improvements
1. Add clearer documentation in error messages about the remediation casefile format
2. Consider auto-clearing lockout if the underlying check passes (with audit trail)
3. Provide a helper script to generate remediation casefiles with proper YAML frontmatter
4. Add examples of properly formatted remediation casefiles to documentation

### Related Files
- `.toolchain/pre_ci_debug/drd_lockout.env`
- `scripts/audit/verify_drd_casefile.sh`
- `scripts/audit/new_remediation_casefile.sh`
- `docs/plans/phase1/REM-2026-04-08_pre_ci-verify_task_meta_schema/PLAN.md`

### Priority
**MEDIUM** - System is working as designed but could be more developer-friendly.

---

## Issue 3: Remediation Casefile Format Ambiguity

**Severity**: LOW  
**Category**: Documentation / Developer Experience  
**Status**: IDENTIFIED

### Description
The remediation casefile format requires YAML frontmatter with `failure_signature` and `root_cause` fields, but this is not clearly documented. The verifier script falls back to regex parsing if YAML parsing fails, which can mask format issues.

### Observed Behavior
1. Created remediation casefile without YAML frontmatter initially
2. Verifier script parsed it via regex fallback with warning
3. Format requirements not immediately clear from error messages

### Expected Format
```yaml
---
failure_signature: PRECI.GOVERNANCE.TASK_META_SCHEMA
root_cause: Description of the root cause
---

# Rest of the markdown document
```

### Impact
- Developers may create incorrectly formatted casefiles
- Regex fallback masks the issue but generates warnings
- Inconsistent casefile formats across the repository

### Recommended Improvements
1. Update `scripts/audit/new_remediation_casefile.sh` to generate proper YAML frontmatter
2. Add validation that rejects casefiles without proper YAML frontmatter
3. Document the required format in error messages and documentation
4. Add examples to `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`

### Related Files
- `scripts/audit/verify_drd_casefile.sh` (lines 60-90)
- `scripts/audit/new_remediation_casefile.sh`
- `docs/operations/REMEDIATION_TRACE_WORKFLOW.md`

### Priority
**LOW** - Workaround exists (regex fallback) but proper format should be enforced.

---

## Summary of Blocking Issues

| Issue | Severity | Blocks Pre_CI | Requires Immediate Action |
|-------|----------|---------------|---------------------------|
| PII Leakage in Supervisory Dashboard | HIGH | ✅ YES | ✅ YES |
| DRD Lockout System Behavior | MEDIUM | ❌ NO | ❌ NO |
| Remediation Casefile Format Ambiguity | LOW | ❌ NO | ❌ NO |

---

## Recommended Action Plan

### Immediate (Blocks Progress)
1. **Fix PII Leakage Issue**
   - Create spec for moving phone lookup to POST request body
   - Implement backend endpoint changes
   - Update frontend to use POST instead of GET
   - Verify PII leakage lint passes

### Short Term (Improves Developer Experience)
2. **Improve DRD Lockout Documentation**
   - Add clear examples to error messages
   - Document remediation casefile format requirements
   - Consider auto-clear on successful check

3. **Enforce Proper Casefile Format**
   - Update scaffolder to generate YAML frontmatter
   - Remove regex fallback or make it emit errors
   - Add validation tests

### Long Term (System Improvements)
4. **Review PII Handling Patterns**
   - Audit all API endpoints for PII in URLs
   - Establish pattern library for PII-safe API design
   - Add automated checks for common PII leakage patterns

---

## Context: What Was Accomplished

Despite these pre-existing issues, the original task was completed successfully:

✅ **Completed**: Fixed 10 meta.yml files (GF-W1-UI-014 through GF-W1-UI-023)
- All files now conform to canonical schema from `Gove/tasks/_template/meta.yml`
- TSK-CLEAN-001 verifier passes for all 23 meta.yml files
- Task meta schema check passes in pre_ci
- DRD lockout cleared with proper remediation casefile

❌ **Blocked**: Full pre_ci passage due to PII leakage issue (unrelated to meta.yml work)

---

## Files Created/Modified During This Session

### Created
- `tasks/GF-W1-UI-014/meta.yml`
- `tasks/GF-W1-UI-015/meta.yml`
- `tasks/GF-W1-UI-016/meta.yml`
- `tasks/GF-W1-UI-017/meta.yml`
- `tasks/GF-W1-UI-018/meta.yml`
- `tasks/GF-W1-UI-019/meta.yml`
- `tasks/GF-W1-UI-020/meta.yml`
- `tasks/GF-W1-UI-021/meta.yml`
- `tasks/GF-W1-UI-022/meta.yml`
- `tasks/GF-W1-UI-023/meta.yml`
- `docs/plans/phase1/REM-2026-04-08_pre_ci-verify_task_meta_schema/PLAN.md`

### Status
All created files are valid and pass their respective verifiers. The blocking issue is in pre-existing code.

---

## Next Steps

1. **Immediate**: Address PII leakage issue in `src/supervisory-dashboard/index.html:4625`
2. **Review**: Audit other API calls in supervisory dashboard for similar PII leakage patterns
3. **Document**: Update developer guidelines for PII-safe API design
4. **Improve**: Enhance DRD lockout system documentation and developer experience

---

**Report Generated**: 2026-04-08T12:45:00Z  
**Session Context**: Meta.yml schema fixes for GF-W1-UI-014 through GF-W1-UI-023  
**Pre_CI Status**: BLOCKED by PII leakage (unrelated to completed work)
