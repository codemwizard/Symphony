# TSK-P1-222 PLAN — Repair the TSK-RLS-ARCH-001 task contract so that Wave 1 implementation stays truthful and fail-closed

Task: TSK-P1-222
Owner: SUPERVISOR
Depends on: []
failure_signature: PHASE1.GOVERNANCE.TSK-P1-222.CONTRACT_DRIFT
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Narrow the parent RLS task contract (`TSK-RLS-ARCH-001`) so that its stated scope, verifier path, evidence path, and closure assumptions match the newly staged Wave 1 execution model. A reviewer will know it is correct when the parent task explicitly delegates DB implementation to the child tasks and no longer implies that the full remediation blob is implemented in one pass. A deterministic Phase 1 verifier `scripts/audit/verify_tsk_p1_222.sh` will prove that the parent task contains no undeclared drift.

---

## Architectural Context

The `TSK-RLS-ARCH-001` parent task historically bundled all RLS architecture transformations (schema, linting, tests) into one massive execution blob. This carries high drift risk and violates the principle of "small, highly instructive tasks." TSK-P1-222 exists at the head of Wave 1 to legally split that omnibus scope into the staged execution sequence. This prevents the "Leaving `TSK-RLS-ARCH-001` broad enough that Wave 1 work can hide undeclared scope" anti-pattern from `meta.yml`.

---

## Pre-conditions

- [x] This task has no dependencies (`depends_on: []`).
- [x] `docs/reference/rls-remediation-first-five-tasks.md` and `docs/reference/rls-remediation-remainder-plan.md` are available in the repository.
- [ ] This PLAN.md has been reviewed and approved.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `tasks/TSK-RLS-ARCH-001/meta.yml` | MODIFY | Lock scope to purely delegating governance; narrow `touches` and `verification` |
| `docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md` | MODIFY | Add explicit handoff links to Wave 1 and remainder plans |
| `docs/plans/phase1/TSK-RLS-ARCH-001/EXEC_LOG.md` | MODIFY | Document that scope is delegated via standard headers |
| `scripts/audit/verify_tsk_p1_222.sh` | CREATE | Strict pattern-matching verifier to enforce exact, minimal parent pack state |
| `evidence/phase1/tsk_p1_222_rls_contract_repair.json` | CREATE | Output artifact proving validation passed |
| `tasks/TSK-P1-222/meta.yml` | MODIFY | Update status to completed upon success |
| `docs/plans/phase1/TSK-P1-222/EXEC_LOG.md` | MODIFY | Append completion and evidence data |

---

## Stop Conditions

- **If the parent task still implies implementation scope** -> STOP
- **If explicit delegation links to the Wave 1 / remainder plans are missing** -> STOP
- **If the verifier relies on loose string matches instead of comprehensive DB-scope pattern blocking** -> STOP
- **If the declared `touches` list contains any files outside the allowed governance set** -> STOP
- **If the task meta does not explicitly declare itself "non-implementing"** -> STOP

---

## Implementation Steps

### Step 1: Narrow `TSK-RLS-ARCH-001/meta.yml`
**What:** Edit the parent task metadata to strictly eliminate DB-scope bounds and explicitly declare delegation.
**How:** 
- Reduce `touches` to EXACTLY: the parent plan, log, evidence, and `meta.yml` file. Remove everything else.
- Remove all DB-centric verification steps. Ensure `verification` only calls governance-level or semantic-level checks.
- Add an explicit statement to `acceptance_criteria`: "This task is strictly non-implementing and delegates all RLS execution to Wave 1 and the remainder plan."
- Scrub any wording that implies schema enforcement or DB changes unless explicitly marked as delegated.
**Done when:** `TSK-RLS-ARCH-001/meta.yml` possesses a `touches` array containing only the 4 allowed parent files and verification steps lacking any runtime, DB, or CI operations.

### Step 2: Link companion plans in 001 PLAN.md and EXEC_LOG.md
**What:** Update the headers of the parent plan and execution log.
**How:** Inject exact markdown links explicitly pointing reviewers to `docs/reference/rls-remediation-first-five-tasks.md` and `docs/reference/rls-remediation-remainder-plan.md`.
**Done when:** Links are present in the headers of both files.

### Step 3: Write the negative test BEFORE marking acceptance criteria done
**What:** Implement `TSK-P1-222-N1` (verifier script catches drift via patterns and semantic rules).
**How:** 
Write `scripts/audit/verify_tsk_p1_222.sh` to enforce the following:
1. **Negative Pattern Blocking:** Parse `tasks/TSK-RLS-ARCH-001/meta.yml` and explicitly reject the presence of the strings `scripts/db/`, `schema/`, `migration`, `psql`, or `ALTER TABLE` in `touches` or `verification`.
2. **Positive Delegation Assertion:** Verify that explicit links to `rls-remediation-first-five-tasks.md` and `rls-remediation-remainder-plan.md` are present.
3. **Implicit Leakage Check:** Reject the phrases "schema enforcement", "RLS policy application", and "DB changes" across the task pack unless prefaced with "delegated".
4. **Minimal Touches Check:** Assert `touches` array size and content exactly match only the designated governance files.
5. **Executable Verification Block:** Reject any executable DB-centric command from the verification block.
**Done when:** `verify_tsk_p1_222.sh` exits non-zero against the un-modified omnibus contract and successfully passes against the repaired, narrowed contract.

### Step 4: Emit evidence
**What:** Run verifier and validate evidence schema to generate the Phase 1 trace.
**How:**
```bash
bash scripts/audit/verify_tsk_p1_222.sh
python3 scripts/audit/validate_evidence.py \
  --task TSK-P1-222 \
  --evidence evidence/phase1/tsk_p1_222_rls_contract_repair.json
```
**Done when:** Commands exit 0 and evidence format complies.

---

## Verification

```bash
# 1. Task-specific verifier
bash scripts/audit/verify_tsk_p1_222.sh

# 2. Evidence schema validation
python3 scripts/audit/validate_evidence.py \
  --task TSK-P1-222 \
  --evidence evidence/phase1/tsk_p1_222_rls_contract_repair.json

# 3. Full local parity check (must pass before committing)
RUN_PHASE1_GATES=1 bash scripts/dev/pre_ci.sh
```

---

## Evidence Contract

File: `evidence/phase1/tsk_p1_222_rls_contract_repair.json`

Required fields:
- `task_id`: "TSK-P1-222"
- `git_sha`: <commit sha at time of evidence emission>
- `timestamp_utc`: <ISO 8601>
- `status`: "PASS"
- `checks`: array of check objects
- `parent_task_id`: "TSK-RLS-ARCH-001"
- `repaired_paths`: [ "tasks/TSK-RLS-ARCH-001/meta.yml", "docs/plans/phase1/TSK-RLS-ARCH-001/PLAN.md", "docs/plans/phase1/TSK-RLS-ARCH-001/EXEC_LOG.md" ]
- `contract_alignment`: "verified_delegation_and_no_db_footprint"  # Downgraded from 'staged_execution_model_enforced' to match actual machine-verified limits.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Parent RLS task implies DB changes vaguely via semantic wording | FAIL | `verify_tsk_p1_222.sh` explicitly rejects semantic loopholes like 'schema enforcement' |
| Verifier allows DB executables under different names | FAIL | Verifier denies the path segments `scripts/db/`, `schema/`, and terms like `psql` |
| Verifier permits extra, hidden touches | FAIL | Verifier enforces strict set equality on `touches` array |
| Evidence claims guarantees the script cannot verify | FAIL_REVIEW | Evidence schema uses explicit, bounded truth claims (`verified_delegation_and_no_db_footprint`) |
