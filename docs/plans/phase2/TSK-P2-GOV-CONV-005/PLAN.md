# TSK-P2-GOV-CONV-005 PLAN - Rewrite Phase-2 machine contract

Task: TSK-P2-GOV-CONV-005
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-GOV-CONV-002, TSK-P2-GOV-CONV-003, TSK-P2-GOV-CONV-004
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-005.CONTRACT_REWRITE_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Rewrite `docs/PHASE2/phase2_contract.yml` to use invariant-centric contract rows.

Done means the contract has no task_id-keyed delivery rows, every row references a
registered invariant, status values match Phase-2 lifecycle vocabulary, and
`verify_gov_conv_005.sh` emits PASS evidence.

## Regulated Surface Compliance

- Approval metadata is required before editing `docs/PHASE2/**`, `scripts/audit/**`, or `evidence/**`.
- Stage A approval must exist before edits.
- Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Phase-2 and above must follow the invariant-centric contract pattern. Task IDs are
execution units, not contract guarantees. This task performs the machine contract
normalization only after invariant registration tasks complete.

## Pre-conditions

- TSK-P2-GOV-CONV-002, 003, and 004 are complete.
- Needed invariant IDs exist in `INVARIANTS_MANIFEST.yml`.
- Approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/PHASE2/phase2_contract.yml` | Modify | Convert to invariant-centric rows |
| `scripts/audit/verify_gov_conv_005.sh` | Create | Verify this rewrite |
| `evidence/phase2/gov_conv_005_phase2_contract_rewrite.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-005/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-005/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Canonical `verify_phase2_contract.sh`
- CI wiring
- Human Phase-2 contract document
- Phase-2 policy document
- Ratification approval artifacts

## Stop Conditions

- Stop if prerequisite invariant-registration tasks are incomplete.
- Stop if a required invariant is missing.
- Stop if any row lacks required invariant-centric fields.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Rewrite rows [ID gov_conv_005_w01]

Modify `phase2_contract.yml` so delivery rows use `invariant_id`, `status`,
`required`, `gate_id`, `verifier`, and `evidence_path`.

Done when no row depends on task ID as its contract identity.

### Step 2 - Remove task_id-keyed rows [ID gov_conv_005_w02]

Remove task-id contract rows from the machine contract while leaving task packs
unchanged.

Done when a task_id-keyed fixture fails verification.

### Step 3 - Validate invariant references [ID gov_conv_005_w03]

Ensure every row references a registered invariant ID.

Done when missing-invariant fixtures fail verification.

### Step 4 - Create verifier [ID gov_conv_005_w04]

Create `verify_gov_conv_005.sh` to validate row schema, status vocabulary,
registered invariant references, and absence of task_id rows.

Done when all negative fixtures fail.

### Step 5 - Emit evidence [ID gov_conv_005_w05]

Run verifier and emit `gov_conv_005_phase2_contract_rewrite.json`.

Done when evidence includes row counts and all violation arrays are empty.

## Verification

```bash
test -x scripts/audit/verify_gov_conv_005.sh && bash scripts/audit/verify_gov_conv_005.sh > evidence/phase2/gov_conv_005_phase2_contract_rewrite.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-005 --evidence evidence/phase2/gov_conv_005_phase2_contract_rewrite.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

`evidence/phase2/gov_conv_005_phase2_contract_rewrite.json` must include:
`task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `total_rows`,
`invalid_rows`, `missing_invariants`, and `task_id_rows_found`.

## Rollback

Restore the previous `docs/PHASE2/phase2_contract.yml` content and remove this
task's verifier/evidence. Do not modify invariant registration tasks during rollback.

## Risk

| Risk | Consequence | Mitigation |
|---|---|---|
| Task IDs remain in contract rows | Contract remains execution-centric | Verifier rejects task_id rows |
| Missing invariant references | Contract rows cannot be enforced | Verifier checks manifest IDs |
| Contract verifier conflated with rewrite | Cross-agent scope drift | Canonical verifier is separate task |
