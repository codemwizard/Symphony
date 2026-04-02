# GF-W1-FNC-007A PLAN — Implement confidence enforcement schema constraint

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

Task: GF-W1-FNC-007A
Owner: DB Foundation Agent
Depends on: GF-W1-FNC-006
failure_signature: PHASE1.DB.FNC007A.IMPLEMENTATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

Implement database-level trigger or check constraints that physically prevent any batch lifecycle transition into "ISSUED" unless required cryptographic authority confidence scores are mathematically present in the database. The enforcement will be implemented as a trigger on `asset_lifecycle_events` that validates confidence thresholds before allowing state transitions, using SECURITY DEFINER with hardened search_path. Done when verifier script confirms trigger existence, constraint enforcement, proper error handling, and mathematical confidence validation.

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

This task provides the mechanical gate that ensures invalid batches cannot be minted, which is required before asset batch issuance (FNC-005) can be safely implemented. It must run after FNC-006 (verifier tokens) because confidence validation needs to reference auditor tokens, but before FNC-007B (CI wiring) which depends on this constraint existing. This prevents the anti-pattern of allowing batch issuance without proper confidence validation and ensures the database itself enforces business rules rather than relying on application-layer checks.

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] GF-W1-FNC-006 is status=completed and evidence validates.
- [ ] DATABASE_URL is set to a fresh test DB for migration testing.
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).
- [ ] Agent conformance passes: `scripts/audit/verify_agent_conformance.sh`

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0113_gf_fn_confidence_enforcement.sql` | CREATE | Implement confidence enforcement trigger and constraints |
| `scripts/db/verify_gf_fnc_007a.sh` | CREATE | Verify trigger implementation and constraint enforcement |
| `tasks/GF-W1-FNC-007A/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/GF-W1-FNC-007A/PLAN.md` | MODIFY | This plan document |
| `docs/plans/phase1/GF-W1-FNC-007A/EXEC_LOG.md` | MODIFY | Append-only execution log |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If trigger lacks SECURITY DEFINER or hardened search_path** -> STOP
- **If confidence validation is not mathematically enforced** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: Create migration with confidence enforcement trigger
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID gf_w1_fnc_007a_work_item_01]` Implement `0113_gf_fn_confidence_enforcement.sql` with confidence validation trigger
**How:** Create migration with SECURITY DEFINER trigger function that validates confidence scores before allowing ISSUED state transitions, enforces mathematical thresholds, and uses hardened search_path
**Done when:** Migration file exists and applies cleanly without errors

```sql
-- Example structure for 0113_gf_fn_confidence_enforcement.sql
-- Confidence enforcement trigger function
CREATE OR REPLACE FUNCTION public.enforce_confidence_before_issuance()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    v_confidence_sum NUMERIC;
    v_required_threshold NUMERIC := 0.95; -- 95% confidence required
    v_batch_id UUID;
BEGIN
    -- Only enforce on transitions to ISSUED
    IF NEW.lifecycle_event_type = 'ISSUED' AND OLD.lifecycle_event_type != 'ISSUED' THEN
        v_batch_id := NEW.asset_batch_id;
        
        -- Sum confidence scores from authority decisions
        SELECT COALESCE(SUM(decision_confidence_score), 0)
        INTO v_confidence_sum
        FROM public.authority_decisions
        WHERE subject_type = 'asset_batch'
          AND subject_id = v_batch_id
          AND decision_outcome = 'APPROVED'
          AND decision_payload_json->>'confidence_score' IS NOT NULL;
        
        -- Enforce mathematical threshold
        IF v_confidence_sum < v_required_threshold THEN
            RAISE EXCEPTION 'CONF001: Insufficient confidence for issuance. Required: %, Actual: %',
                v_required_threshold, v_confidence_sum;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger on asset_lifecycle_events
CREATE TRIGGER asset_lifecycle_confidence_enforcement
    BEFORE UPDATE ON public.asset_lifecycle_events
    FOR EACH ROW
    EXECUTE FUNCTION public.enforce_confidence_before_issuance();
```

### Step 2: Implement comprehensive verification script
**What:** `[ID gf_w1_fnc_007a_work_item_02]` Create `verify_gf_fnc_007a.sh` with structural and behavioral checks
**How:** Write bash script that verifies migration existence, trigger creation, SECURITY DEFINER posture, search_path hardening, confidence validation logic, mathematical threshold enforcement, and negative test cases
**Done when:** Verification script exists and is executable

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID gf_w1_fnc_007a_work_item_03]` Implement verification integration with negative tests
**How:** Define execution failure tests (N1...N3) that simulate insufficient confidence, missing authority decisions, and bypass attempts. Ensure verifier script explicitly rejects these conditions with CONF001 error
**Done when:** The integration wrapper script exits non-zero against unfixed code, and exits 0 against the target implementation

### Step 4: Emit evidence and validate
**What:** `[ID gf_w1_fnc_007a_work_item_04]` Run verifier and validate evidence schema
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/db/verify_gf_fnc_007a.sh && bash scripts/db/verify_gf_fnc_007a.sh > evidence/phase1/gf_w1_fnc_007a.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON schema is written to disk

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID gf_w1_fnc_007a_work_item_01] [ID gf_w1_fnc_007a_work_item_02] [ID gf_w1_fnc_007a_work_item_04]
test -x scripts/db/verify_gf_fnc_007a.sh && bash scripts/db/verify_gf_fnc_007a.sh > evidence/phase1/gf_w1_fnc_007a.json || exit 1

# [ID gf_w1_fnc_007a_work_item_04]
test -f evidence/phase1/gf_w1_fnc_007a.json && cat evidence/phase1/gf_w1_fnc_007a.json | grep "observed_hashes" || exit 1

# [ID gf_w1_fnc_007a_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/phase1/gf_w1_fnc_007a.json`

Required fields:
- `task_id`: "GF-W1-FNC-007A"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `migration_applied`: "0113_gf_fn_confidence_enforcement.sql"
- `triggers_created`: ["asset_lifecycle_confidence_enforcement"]
- `security_defender_count`: 1
- `confidence_threshold_enforced`: 0.95
- `negative_tests_passed`: ["N1", "N2", "N3"]

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. Disable the trigger: `DROP TRIGGER IF EXISTS asset_lifecycle_confidence_enforcement ON public.asset_lifecycle_events;`
2. Drop the function: `DROP FUNCTION IF EXISTS public.enforce_confidence_before_issuance CASCADE;`
3. Create rollback migration with reverse operations
4. Update status back to 'planned' in meta.yml
5. File exception in docs/security/EXCEPTION_REGISTER.yml with rationale and expiry.

---

## Risk
<!-- REQUIRED. Name what can go wrong in this specific task.
     These must match or extend the failure_modes in meta.yml. -->

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Evidence file missing | FAIL | Verify script writes JSON evidence directly |
| Verification script panics or exits > 0 | FAIL | Comprehensive error handling in verifier |
| Creating schema bypasses | CRITICAL_FAIL | Enforce SECURITY DEFINER and search_path hardening |
| Confidence validation not enforced | CRITICAL_FAIL | Mathematical trigger with explicit exception CONF001 |
| Trigger missing or disabled | CRITICAL_FAIL | Verification checks for trigger existence and enablement |
| Anti-pattern: application-layer validation only | FAIL_REVIEW | Database-level trigger enforces rules regardless of application |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/phase1/approvals/GF-W1-FNC-007A.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
