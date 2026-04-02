# GF-W1-FNC-005 PLAN — Implement issue_asset_batch and retire_asset_batch

<!--
  PLAN.md RULES
  ─────────────
  1. This file must exist BEFORE status = 'in-progress' in meta.yml.
  2. Every section marked REQUIRED must be filled before any code is written.
  3. The EXEC_LOG.md is the append-only record of what actually happened.
     Do not retroactively edit this PLAN.md to match the log.
  4. failure_signature must match the format used in verify_remediation_trace.sh.
  5. PROOF GRAPH INTEGRITY: Every work item, acceptance criterion, and verification command MUST be explicitly mapped using tracking IDs (e.g., `[ID <task_id>_work_item_01]`).
-->

Task: GF-W1-FNC-005
Owner: DB Foundation Agent
Depends on: GF-W1-FNC-007B
failure_signature: PHASE1.DB.FNC005.IMPLEMENTATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

Implement `issue_asset_batch` and `retire_asset_batch` functions that provide the final state mutations moving batches into "ISSUED" or "RETIRED" states, completing the green finance pilot lifecycle. These functions will use SECURITY DEFINER with hardened search_path, enforce confidence gate constraints from FNC-007A, validate state transitions, and maintain append-only audit trails. Done when verifier script confirms function existence, SECURITY DEFINER posture, proper state validation, confidence enforcement integration, and retirement-before-issuance prevention.

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

This task provides the core lifecycle closure functions that physically mint and retire asset batches. It must run after FNC-007B (CI confidence gate) because issuance depends on confidence enforcement being active, but before PLT-001 (pilot registration) which uses these functions to create actual batches. This prevents the anti-pattern of allowing batch state changes without proper confidence validation and ensures the confidence gate from FNC-007A is respected at the application layer.

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] GF-W1-FNC-007B is status=completed and evidence validates.
- [ ] DATABASE_URL is set to a fresh test DB for migration testing.
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).
- [ ] Agent conformance passes: `scripts/audit/verify_agent_conformance.sh`

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0114_gf_fn_asset_lifecycle.sql` | CREATE | Implement issue/retire functions with SECURITY DEFINER |
| `scripts/db/verify_gf_fnc_005.sh` | CREATE | Verify function implementation and state validation |
| `tasks/GF-W1-FNC-005/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/GF-W1-FNC-005/PLAN.md` | MODIFY | This plan document |
| `docs/plans/phase1/GF-W1-FNC-005/EXEC_LOG.md` | MODIFY | Append-only execution log |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If functions lack SECURITY DEFINER or hardened search_path** -> STOP
- **If retirement-before-issuance is not prevented** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: Create migration with asset lifecycle functions
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID gf_w1_fnc_005_work_item_01]` Implement `0114_gf_fn_asset_lifecycle.sql` with issue/retire functions
**How:** Create migration with SECURITY DEFINER functions that validate confidence scores, enforce state transitions, prevent retirement before issuance, maintain append-only audit trails, and use hardened search_path
**Done when:** Migration file exists and applies cleanly without errors

```sql
-- Example structure for 0114_gf_fn_asset_lifecycle.sql
-- Issue asset batch function
CREATE OR REPLACE FUNCTION public.issue_asset_batch(
    p_asset_batch_id UUID,
    p_tenant_id UUID,
    p_issuance_payload JSONB DEFAULT '{}'
) RETURNS UUID
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    v_lifecycle_event_id UUID;
    v_current_status TEXT;
BEGIN
    -- Validate batch exists and is in ISSUABLE state
    SELECT status INTO v_current_status
    FROM public.asset_batches
    WHERE asset_batch_id = p_asset_batch_id
      AND tenant_id = p_tenant_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'BATCH001: Asset batch not found';
    END IF;
    
    IF v_current_status != 'APPROVED' THEN
        RAISE EXCEPTION 'BATCH002: Batch not in APPROVED state. Current: %', v_current_status;
    END IF;
    
    -- Create lifecycle event (this will trigger confidence enforcement)
    INSERT INTO public.asset_lifecycle_events (
        asset_batch_id, tenant_id, lifecycle_event_type, event_payload_json
    ) VALUES (
        p_asset_batch_id, p_tenant_id, 'ISSUED', p_issuance_payload
    ) RETURNING asset_lifecycle_event_id INTO v_lifecycle_event_id;
    
    -- Update batch status
    UPDATE public.asset_batches
    SET status = 'ISSUED', issued_at = now()
    WHERE asset_batch_id = p_asset_batch_id;
    
    RETURN v_lifecycle_event_id;
END;
$$;

-- Retire asset batch function
CREATE OR REPLACE FUNCTION public.retire_asset_batch(
    p_asset_batch_id UUID,
    p_tenant_id UUID,
    p_retirement_payload JSONB DEFAULT '{}'
) RETURNS UUID
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    v_lifecycle_event_id UUID;
    v_current_status TEXT;
BEGIN
    -- Validate batch exists and is in RETIRABLE state
    SELECT status INTO v_current_status
    FROM public.asset_batches
    WHERE asset_batch_id = p_asset_batch_id
      AND tenant_id = p_tenant_id
    FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'BATCH001: Asset batch not found';
    END IF;
    
    IF v_current_status != 'ISSUED' THEN
        RAISE EXCEPTION 'BATCH003: Batch not in ISSUED state. Current: %', v_current_status;
    END IF;
    
    -- Create retirement event
    INSERT INTO public.asset_lifecycle_events (
        asset_batch_id, tenant_id, lifecycle_event_type, event_payload_json
    ) VALUES (
        p_asset_batch_id, p_tenant_id, 'RETIRED', p_retirement_payload
    ) RETURNING asset_lifecycle_event_id INTO v_lifecycle_event_id;
    
    -- Update batch status
    UPDATE public.asset_batches
    SET status = 'RETIRED', retired_at = now()
    WHERE asset_batch_id = p_asset_batch_id;
    
    RETURN v_lifecycle_event_id;
END;
$$;
```

### Step 2: Implement comprehensive verification script
**What:** `[ID gf_w1_fnc_005_work_item_02]` Create `verify_gf_fnc_005.sh` with structural and behavioral checks
**How:** Write bash script that verifies migration existence, function creation, SECURITY DEFINER posture, search_path hardening, state validation logic, retirement-before-issuance prevention, confidence enforcement integration, and negative test cases
**Done when:** Verification script exists and is executable

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID gf_w1_fnc_005_work_item_03]` Implement verification integration with negative tests
**How:** Define execution failure tests (N1...N3) that simulate retirement before issuance, invalid state transitions, and confidence gate bypass. Ensure verifier script explicitly rejects these conditions with appropriate error codes
**Done when:** The integration wrapper script exits non-zero against unfixed code, and exits 0 against the target implementation

### Step 4: Emit evidence and validate
**What:** `[ID gf_w1_fnc_005_work_item_04]` Run verifier and validate evidence schema
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/db/verify_gf_fnc_005.sh && bash scripts/db/verify_gf_fnc_005.sh > evidence/phase1/gf_w1_fnc_005.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON schema is written to disk

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID gf_w1_fnc_005_work_item_01] [ID gf_w1_fnc_005_work_item_02] [ID gf_w1_fnc_005_work_item_04]
test -x scripts/db/verify_gf_fnc_005.sh && bash scripts/db/verify_gf_fnc_005.sh > evidence/phase1/gf_w1_fnc_005.json || exit 1

# [ID gf_w1_fnc_005_work_item_04]
test -f evidence/phase1/gf_w1_fnc_005.json && cat evidence/phase1/gf_w1_fnc_005.json | grep "observed_hashes" || exit 1

# [ID gf_w1_fnc_005_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/phase1/gf_w1_fnc_005.json`

Required fields:
- `task_id`: "GF-W1-FNC-005"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `migration_applied`: "0114_gf_fn_asset_lifecycle.sql"
- `functions_created`: ["issue_asset_batch", "retire_asset_batch"]
- `security_defender_count`: 2
- `state_validation_enforced`: true
- `retirement_before_issuance_prevented`: true
- `negative_tests_passed`: ["N1", "N2", "N3"]

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. Disable the functions: `DROP FUNCTION IF EXISTS public.issue_asset_batch CASCADE; DROP FUNCTION IF EXISTS public.retire_asset_batch CASCADE;`
2. Create rollback migration with reverse operations
3. Update status back to 'planned' in meta.yml
4. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk
<!-- REQUIRED. Name what can go wrong in this specific task.
     These must match or extend the failure_modes in meta.yml. -->

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Evidence file missing | FAIL | Verify script writes JSON evidence directly |
| Verification script panics or exits > 0 | FAIL | Comprehensive error handling in verifier |
| Creating schema bypasses | CRITICAL_FAIL | Enforce SECURITY DEFINER and search_path hardening |
| Retirement before issuance allowed | CRITICAL_FAIL | State validation in functions prevents invalid transitions |
| Confidence gate not respected | CRITICAL_FAIL | Functions rely on database trigger from FNC-007A |
| Anti-pattern: direct status updates | FAIL_REVIEW | All state changes go through controlled functions |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/phase1/approvals/GF-W1-FNC-005.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
