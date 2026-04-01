# GF-W1-FNC-006 PLAN — Implement issue_verifier_read_token

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

Task: GF-W1-FNC-006
Owner: DB Foundation Agent
Depends on: GF-W1-FNC-004
failure_signature: PHASE1.DB.FNC006.IMPLEMENTATION
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective
<!-- REQUIRED. 3-5 sentences. -->
<!-- Answer: what does done look like, how will a reviewer know it is correct,
     what risk is eliminated when this task closes. Do not repeat the title. -->

Implement `issue_verifier_read_token` function that generates cryptographically secure, time-bound read tokens allowing auditors to access ledger state and evidence files without permanent or broad table permissions. The function will use SECURITY DEFINER with hardened search_path, enforce token expiration via cryptographic signatures, and respect RLS boundaries. Done when the verifier script confirms function existence, SECURITY DEFINER posture, proper search_path hardening, token expiration logic, and RLS compliance.

---

## Architectural Context
<!-- REQUIRED for SECURITY and INTEGRITY risk_class tasks. Optional for DOCS_ONLY. -->
<!-- Why does this task exist in this position in the DAG? What breaks if it
     runs out of order? What architectural sin does it prevent being ported forward? -->

This task provides the auditor access layer required before confidence enforcement (GF-W1-FNC-007A) can verify that third parties have controlled read access to evidence. It must run after FNC-004 (authority decisions) because verifier tokens need to reference decision records, but before FNC-007A (confidence enforcement) which depends on verifiable audit trails. This prevents the anti-pattern of granting blanket table access to auditors and ensures all access is cryptographically bounded and time-limited.

---

## Pre-conditions
<!-- REQUIRED. What must be true before the first line of code is written. -->
<!-- These are the depends_on tasks plus any environmental requirements. -->

- [ ] GF-W1-FNC-004 is status=completed and evidence validates.
- [ ] DATABASE_URL is set to a fresh test DB for migration testing.
- [ ] This PLAN.md has been reviewed and approved (for regulated surfaces).
- [ ] Agent conformance passes: `scripts/audit/verify_agent_conformance.sh`

---

## Files to Change
<!-- REQUIRED. Exact list. Must match meta.yml::touches exactly.
     Any file modified that is NOT on this list => FAIL_REVIEW. -->

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0112_gf_fn_verifier_read_token.sql` | CREATE | Implement verifier token function with SECURITY DEFINER |
| `scripts/db/verify_gf_fnc_006.sh` | CREATE | Verify function implementation and RLS compliance |
| `tasks/GF-W1-FNC-006/meta.yml` | MODIFY | Update status to completed |
| `docs/plans/phase1/GF-W1-FNC-006/PLAN.md` | MODIFY | This plan document |
| `docs/plans/phase1/GF-W1-FNC-006/EXEC_LOG.md` | MODIFY | Append-only execution log |

---

## Stop Conditions
<!-- REQUIRED. Define explicitly when this task should hard-stop and fail. 
     These must match the TSK-P1-240 anti-drift standards. -->

- **If any node in the proof graph is orphaned** -> STOP
- **If any verifier lacks a symbolic failure obligation (`|| exit 1`)** -> STOP
- **If evidence is static or self-declared instead of derived** -> STOP
- **If verification does not inspect real system state (self-referential)** -> STOP
- **If ≥3 weak signals (subjective wording like 'ensure' or 'appropriate') are detected without hard failing** -> STOP
- **If function lacks SECURITY DEFINER or hardened search_path** -> STOP
- **If token expiration logic is not mathematically enforced** -> STOP

---

## Implementation Steps
<!-- REQUIRED. Ordered. Each step is atomic and verifiable.
     A step is done when its output can be checked, not when the agent thinks it's done. 
     CRITICAL: EVERY step must include an explicit tracking ID (e.g., `[ID <task_slug>_work_item_NN]`) that maps directly to the acceptance_criteria and verification blocks in meta.yml. -->

### Step 1: Create migration with verifier token function
<!-- Include the explicit ID tags inside implementation and verification specs -->
**What:** `[ID gf_w1_fnc_006_work_item_01]` Implement `0112_gf_fn_verifier_read_token.sql` with `issue_verifier_read_token` function
**How:** Create migration with SECURITY DEFINER function that generates time-bound JWT-like tokens with cryptographic signatures, stores tokens in `verifier_tokens` table, enforces expiration via CHECK constraint, and uses hardened search_path
**Done when:** Migration file exists and applies cleanly without errors

```sql
-- Example structure for 0112_gf_fn_verifier_read_token.sql
CREATE TABLE public.verifier_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id),
    scope_payload_json JSONB NOT NULL DEFAULT '{}'
);

-- RLS and policies
ALTER TABLE public.verifier_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_tokens FORCE ROW LEVEL SECURITY;

CREATE POLICY verifier_tokens_tenant_isolation ON public.verifier_tokens
    FOR ALL TO PUBLIC
    USING (tenant_id = current_setting('app.current_tenant_id', true)::UUID);

-- SECURITY DEFINER function
CREATE OR REPLACE FUNCTION public.issue_verifier_read_token(
    p_tenant_id UUID,
    p_scope_payload JSONB DEFAULT '{}',
    p_expires_hours INTEGER DEFAULT 24
) RETURNS TEXT
SECURITY DEFINER
SET search_path = pg_catalog, public
LANGUAGE plpgsql
AS $$
DECLARE
    v_token TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Implementation logic here
    RETURN v_token;
END;
$$;
```

### Step 2: Implement comprehensive verification script
**What:** `[ID gf_w1_fnc_006_work_item_02]` Create `verify_gf_fnc_006.sh` with structural and behavioral checks
**How:** Write bash script that verifies migration existence, function creation, SECURITY DEFINER posture, search_path hardening, table creation, RLS policies, token expiration logic, and negative test cases
**Done when:** Verification script exists and is executable

### Step 3: Write the Negative Test Constraints
<!-- This step is mandatory for all tasks.
     The negative test must fail against the unfixed code and pass against the fixed code.
     Do not write it after the fix. Write it before, prove it catches the problem. -->
**What:** `[ID gf_w1_fnc_006_work_item_03]` Implement verification integration with negative tests
**How:** Define execution failure tests (N1...N3) that simulate token expiration, invalid tenant access, and missing RLS. Ensure verifier script explicitly rejects these conditions
**Done when:** The integration wrapper script exits non-zero against unfixed code, and exits 0 against the target implementation

### Step 4: Emit evidence and validate
**What:** `[ID gf_w1_fnc_006_work_item_04]` Run verifier and validate evidence schema
**How:**
```bash
# Output from the bash execution script MUST route directly into the JSON evidence trace
test -x scripts/db/verify_gf_fnc_006.sh && bash scripts/db/verify_gf_fnc_006.sh > evidence/phase1/gf_w1_fnc_006.json || exit 1
```
**Done when:** Verification executes through failure paths and the explicit JSON schema is written to disk

---

## Verification
<!-- REQUIRED. Copy exactly from meta.yml::verification. Must be runnable verbatim.
     CRITICAL: Each command MUST include an explicit tracking tag linking back to the implementation step, and MUST feature a hard failure fallback (`|| exit 1`). -->

```bash
# [ID gf_w1_fnc_006_work_item_01] [ID gf_w1_fnc_006_work_item_02] [ID gf_w1_fnc_006_work_item_04]
test -x scripts/db/verify_gf_fnc_006.sh && bash scripts/db/verify_gf_fnc_006.sh > evidence/phase1/gf_w1_fnc_006.json || exit 1

# [ID gf_w1_fnc_006_work_item_04]
test -f evidence/phase1/gf_w1_fnc_006.json && cat evidence/phase1/gf_w1_fnc_006.json | grep "observed_hashes" || exit 1

# [ID gf_w1_fnc_006_work_item_04]
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

---

## Evidence Contract
<!-- REQUIRED. Describe what the evidence JSON must contain.
     This is the machine-checkable proof that the task is done. The evidence script MUST write directly into this JSON structure natively. -->

File: `evidence/phase1/gf_w1_fnc_006.json`

Required fields:
- `task_id`: "GF-W1-FNC-006"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects (including positive and negative assertions)
- `migration_applied`: "0112_gf_fn_verifier_read_token.sql"
- `functions_created`: ["issue_verifier_read_token"]
- `security_defender_count`: 1
- `rls_policies_count`: 1
- `negative_tests_passed`: ["N1", "N2", "N3"]

---

## Rollback
<!-- REQUIRED for DB_SCHEMA and APP_LAYER blast_radius tasks.
     Reference docs/security/ROLLBACK_RULES.md for the general policy.
     State what is specific to this task. -->

If this task must be reverted:
1. Disable the function: `DROP FUNCTION IF EXISTS public.issue_verifier_read_token CASCADE;`
2. Drop the verifier_tokens table: `DROP TABLE IF EXISTS public.verifier_tokens CASCADE;`
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
| Token expiration not enforced | CRITICAL_FAIL | Mathematical CHECK constraints and function validation |
| RLS policies missing | CRITICAL_FAIL | Verification checks for RLS enablement and policies |
| Anti-pattern: weak access controls | FAIL_REVIEW | Verify tokens are time-bound and scope-limited |

---

## Approval (for regulated surfaces)
<!-- Required when touches includes: schema/migrations/**, scripts/audit/**,
     scripts/db/**, docs/invariants/**, .github/workflows/**, evidence/** -->

- [ ] Approval metadata artifact exists at: `evidence/phase1/approvals/GF-W1-FNC-006.json`
- [ ] Approved by: <approver_id>
- [ ] Approval timestamp: <ISO 8601>
