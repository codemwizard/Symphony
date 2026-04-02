# GF-W1-FNC-007B PLAN — Wire issuance gate verifying script into CI

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

Task: GF-W1-FNC-007B
Owner: Security Guardian Agent
Depends on: GF-W1-FNC-007A
failure_signature: PHASE1.CI.FNC007B.WIRING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

Wire the confidence enforcement schema constraint (from 007A) into the CI pipeline gate so that even if a future migration accidentally removes the DB-level trigger, the CI pipeline will fail before allowing non-compliant code to merge. This involves modifying `scripts/dev/pre_ci.sh` to call a verification script that structurally enforces the presence of the 007A check constraint. Done when the verifier script confirms CI wiring exists, confidence gate verification is active, and the pipeline blocks unprotected workflows.

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

This task provides the CI-level enforcement that ensures the database constraint from 007A physically exists, creating defense-in-depth. It must run after FNC-007A (confidence enforcement DB constraint) because it needs to verify that constraint exists, but before FNC-005 (asset batch issuance) which depends on confidence enforcement being active. This prevents the anti-pattern of relying solely on database constraints without CI verification, ensuring that even accidental constraint removal is caught before merge.

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] GF-W1-FNC-007A is status=completed and evidence validates.
- [ ] DATABASE_URL is set to a fresh test DB for migration testing.
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).
- [ ] Agent conformance passes: `scripts/audit/verify_agent_conformance.sh`

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `scripts/audit/verify_gf_fnc_007b.sh` | CREATE | Verify CI wiring and confidence gate enforcement |
| `scripts/dev/pre_ci.sh` | MODIFY | Add confidence gate verification to CI pipeline |
| `tasks/GF-W1-FNC-007B/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/GF-W1-FNC-007B/PLAN.md` | MODIFY | This plan document |
| `docs/plans/phase1/GF-W1-FNC-007B/EXEC_LOG.md` | MODIFY | Append-only execution log |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If CI wiring is not structurally enforced in pre_ci.sh** -> STOP
- **If confidence gate verification is bypassable** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: Create CI gate verification script
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID gf_w1_fnc_007b_work_item_01]` Implement `verify_gf_fnc_007b.sh` with CI wiring verification
**How:** Write bash script that verifies the confidence enforcement trigger exists, checks CI integration in pre_ci.sh, validates that confidence gate cannot be bypassed, and includes negative test cases for missing wiring
**Done when:** Verification script exists and is executable

```bash
# Example structure for verify_gf_fnc_007b.sh
#!/bin/bash
set -euo pipefail

# Verify confidence enforcement trigger exists
trigger_exists=$(psql -t -c "SELECT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'asset_lifecycle_confidence_enforcement')::text;" | tr -d '[:space:]')
if [[ "$trigger_exists" != "true" ]]; then
    echo "ERROR: Confidence enforcement trigger missing"
    exit 1
fi

# Verify CI wiring in pre_ci.sh
if ! grep -q "verify_gf_fnc_007b.sh" scripts/dev/pre_ci.sh; then
    echo "ERROR: CI confidence gate not wired"
    exit 1
fi

# Verify confidence function exists
function_exists=$(psql -t -c "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'enforce_confidence_before_issuance')::text;" | tr -d '[:space:]')
if [[ "$function_exists" != "true" ]]; then
    echo "ERROR: Confidence enforcement function missing"
    exit 1
fi

echo "PASS: CI confidence gate verification complete"
```

### Step 2: Wire confidence gate into pre_ci.sh
**What:** `[ID gf_w1_fnc_007b_work_item_02]` Modify `scripts/dev/pre_ci.sh` to include confidence gate verification
**How:** Add verification script call to the GREEN_FINANCE_VERIFIERS section or appropriate gate checkpoint, ensuring it runs after migrations but before final success
**Done when:** pre_ci.sh includes the confidence gate verification and fails appropriately

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID gf_w1_fnc_007b_work_item_03]` Implement verification integration with negative tests
**How:** Define execution failure tests (N1...N3) that simulate missing CI wiring, bypassed confidence gate, and disabled trigger. Ensure verifier script explicitly rejects these conditions
**Done when:** The integration wrapper script exits non-zero against unfixed code, and exits 0 against the target implementation

### Step 4: Emit evidence and validate
**What:** `[ID gf_w1_fnc_007b_work_item_04]` Run verifier and validate evidence schema
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/audit/verify_gf_fnc_007b.sh && bash scripts/audit/verify_gf_fnc_007b.sh > evidence/phase1/gf_w1_fnc_007b.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON schema is written to disk

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID gf_w1_fnc_007b_work_item_01] [ID gf_w1_fnc_007b_work_item_02] [ID gf_w1_fnc_007b_work_item_04]
test -x scripts/audit/verify_gf_fnc_007b.sh && bash scripts/audit/verify_gf_fnc_007b.sh > evidence/phase1/gf_w1_fnc_007b.json || exit 1

# [ID gf_w1_fnc_007b_work_item_04]
test -f evidence/phase1/gf_w1_fnc_007b.json && cat evidence/phase1/gf_w1_fnc_007b.json | grep "observed_hashes" || exit 1

# [ID gf_w1_fnc_007b_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/phase1/gf_w1_fnc_007b.json`

Required fields:
- `task_id`: "GF-W1-FNC-007B"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `ci_wiring_verified`: true
- `confidence_gate_active`: true
- `trigger_exists`: true
- `negative_tests_passed`: ["N1", "N2", "N3"]

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. Remove confidence gate verification from pre_ci.sh
2. Remove the verification script: `rm scripts/audit/verify_gf_fnc_007b.sh`
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
| Wiring CI bypasses | CRITICAL_FAIL | Verification checks for actual CI integration |
| Confidence gate not active | CRITICAL_FAIL | Verification confirms trigger and function existence |
| CI pipeline modified to skip gate | CRITICAL_FAIL | Structural verification of pre_ci.sh content |
| Anti-pattern: manual verification only | FAIL_REVIEW | Automated CI enforcement ensures no human bypass |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/phase1/approvals/GF-W1-FNC-007B.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
