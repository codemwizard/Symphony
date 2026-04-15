# PII Leakage Remediation Task Created

**Date**: 2026-04-08  
**Task ID**: REM-2026-04-08-PII-LEAK  
**Priority**: CRITICAL  
**Status**: PLANNED - Ready for Implementation

---

## Summary

A remediation task has been created to fix the PII leakage issue identified in the pre-existing issues report. The task follows Symphony's canonical task creation process and includes:

✅ Remediation casefile with proper YAML frontmatter  
✅ Detailed implementation plan (PLAN.md)  
✅ Task metadata file (meta.yml) conforming to canonical schema  
✅ Execution log (EXEC_LOG.md)

---

## Task Details

**Issue**: Phone number passed as URL query parameter in worker lookup endpoint  
**Location**: `src/supervisory-dashboard/index.html:4625`  
**Impact**: Blocks pre_ci, creates compliance risk, violates PII handling policy

**Solution**: Move phone number from URL query parameter to POST request body

---

## Files Created

1. **Remediation Casefile**
   - Path: `docs/plans/phase1/REM-2026-04-08_pii_leakage_worker_lookup/`
   - Contains: PLAN.md with YAML frontmatter and detailed implementation steps

2. **Task Metadata**
   - Path: `tasks/REM-2026-04-08-PII-LEAK/meta.yml`
   - Conforms to: Canonical schema from `Gove/tasks/_template/meta.yml`
   - Owner: SECURITY_GUARDIAN
   - Priority: CRITICAL
   - Risk Class: SECURITY

3. **Execution Log**
   - Path: `docs/plans/phase1/REM-2026-04-08_pii_leakage_worker_lookup/EXEC_LOG.md`
   - Tracks: Implementation progress and decisions

---

## Implementation Plan Overview

### Step 1: Update Frontend (W1)
- Change worker lookup from GET to POST
- Add `Content-Type: application/json` header
- Move phone from URL to JSON request body: `{"phone": "+260971100001"}`

### Step 2: Update Backend (W2)
- Change endpoint from MapGet to MapPost
- Read phone from JSON request body instead of query parameter
- Maintain same response format and error handling

### Step 3: Verify PII Lint (W3)
- Run `bash scripts/audit/lint_pii_leakage_payloads.sh`
- Confirm status: "PASS"
- Verify no phone in URL findings

### Step 4: Test Functionality (W4)
- Test valid worker lookup
- Test invalid worker (404)
- Test wrong supplier_type
- Test inactive worker

### Step 5: Run Pre-CI (W5)
- Execute full pre_ci
- Confirm all gates pass
- Verify no new failures

---

## Verification Commands

```bash
# Confirm frontend uses POST
grep -q 'method.*POST' src/supervisory-dashboard/index.html || exit 1

# Confirm JSON content type
grep -q 'Content-Type.*application/json' src/supervisory-dashboard/index.html || exit 1

# Confirm no phone in URL
! grep -q '/workers/lookup?phone=' src/supervisory-dashboard/index.html

# Confirm backend uses POST
grep -q 'MapPost.*workers/lookup' services/ledger-api/dotnet/src/LedgerApi/Program.cs || exit 1

# Confirm PII lint passes
bash scripts/audit/lint_pii_leakage_payloads.sh || exit 1

# Confirm evidence exists with PASS status
test -f evidence/phase0/pii_leakage_payloads.json || exit 1
cat evidence/phase0/pii_leakage_payloads.json | grep '"status": "PASS"' || exit 1
```

---

## Files to Modify

| File | Action | Lines |
|------|--------|-------|
| `src/supervisory-dashboard/index.html` | MODIFY | ~4625 (worker lookup function) |
| `services/ledger-api/dotnet/src/LedgerApi/Program.cs` | MODIFY | Worker lookup endpoint handler |

---

## Testing Checklist

- [ ] Valid worker lookup (worker-chunga-001) returns worker data
- [ ] Invalid worker (not registered) returns 404 error
- [ ] Worker with supplier_type != "WORKER" shows error
- [ ] Inactive worker shows error
- [ ] Token issuance flow works end-to-end
- [ ] PII leakage lint passes
- [ ] Full pre_ci passes

---

## Security Benefits

1. **No Access Log Leakage**: Phone numbers no longer logged in web server access logs
2. **No Caching**: POST requests not cached by default (unlike GET)
3. **No Referrer Leakage**: Phone numbers won't appear in referrer headers
4. **Compliance**: Meets data privacy requirements for PII handling

---

## Next Steps

To implement this task:

1. **Review the implementation plan**:
   ```bash
   cat docs/plans/phase1/REM-2026-04-08_pii_leakage_worker_lookup/PLAN.md
   ```

2. **Review the task metadata**:
   ```bash
   cat tasks/REM-2026-04-08-PII-LEAK/meta.yml
   ```

3. **Begin implementation** following the 5-step plan in PLAN.md

4. **Run verification commands** after each step

5. **Update EXEC_LOG.md** with implementation progress

---

## References

- **Original Issue Report**: `inbox/PRE_EXISTING_ISSUES_REPORT.md`
- **Implementation Plan**: `docs/plans/phase1/REM-2026-04-08_pii_leakage_worker_lookup/PLAN.md`
- **Task Metadata**: `tasks/REM-2026-04-08-PII-LEAK/meta.yml`
- **Execution Log**: `docs/plans/phase1/REM-2026-04-08_pii_leakage_worker_lookup/EXEC_LOG.md`
- **PII Lint Script**: `scripts/audit/lint_pii_leakage_payloads.sh`

---

**Created**: 2026-04-08T13:00:00Z  
**Type**: Security Remediation / DRD Task  
**Blocking**: Yes - blocks all pre_ci runs  
**Ready**: Yes - all documentation complete, ready for implementation
