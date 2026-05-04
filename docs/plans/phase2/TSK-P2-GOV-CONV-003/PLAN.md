# TSK-P2-GOV-CONV-003 PLAN - Register REG and SEC Phase-2 invariant IDs

Task: TSK-P2-GOV-CONV-003
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-GOV-CONV-001
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-003.REG_SEC_INV_REGISTRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Register only REG- and SEC-scoped Phase-2 invariant IDs in
`docs/invariants/INVARIANTS_MANIFEST.yml`, grounded in the reconciliation manifest
from TSK-P2-GOV-CONV-001.

Done means all new IDs are REG/SEC-scoped, unique, manifest-traceable, and verified
by `scripts/audit/verify_gov_conv_003.sh`.

## Regulated Surface Compliance

- Approval metadata is required before editing `docs/invariants/**`, `scripts/audit/**`, or `evidence/**`.
- Stage A approval must exist before edits.
- Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

The Phase-2 contract must reference invariant IDs grounded in implemented or
roadmap-governed work. REG and SEC rows are kept in a dedicated task so security
and registration claims are auditable without mixing unrelated PREAUTH or Wave
clusters.

## Pre-conditions

- TSK-P2-GOV-CONV-001 is completed.
- `evidence/phase2/gov_conv_001_reconciliation_manifest.json` exists and validates.
- Approval metadata exists before regulated files are edited.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/invariants/INVARIANTS_MANIFEST.yml` | Modify | Register REG/SEC invariant IDs |
| `scripts/audit/verify_gov_conv_003.sh` | Create | Verify REG/SEC registration |
| `evidence/phase2/gov_conv_003_reg_sec_inv_registration.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-003/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-003/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- PREAUTH invariant registration
- W5/W6/W8 invariant registration
- Phase-2 machine contract rewrite
- CI gate wiring

## Stop Conditions

- Stop if the reconciliation manifest is absent or invalid.
- Stop if proposed IDs duplicate existing invariant IDs.
- Stop if any proposed entry lacks REG/SEC manifest traceability.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Identify REG/SEC rows [ID gov_conv_003_w01]

Review the reconciliation manifest and isolate only REG and SEC rows missing
registered invariant IDs.

Done when EXEC_LOG records the reviewed rows and excludes all other clusters.

### Step 2 - Register REG/SEC invariants [ID gov_conv_003_w02]

Update `INVARIANTS_MANIFEST.yml` with only REG/SEC-scoped entries. Each entry must
carry precise description, status, verifier reference, and evidence reference.

Done when no non-REG/SEC entry is changed by this task.

### Step 3 - Create verifier [ID gov_conv_003_w03]

Create `verify_gov_conv_003.sh` to check ID uniqueness, REG/SEC-only scope,
manifest traceability, and required fields.

Done when duplicate and out-of-scope fixtures fail.

### Step 4 - Emit evidence [ID gov_conv_003_w04]

Run the verifier and emit `gov_conv_003_reg_sec_inv_registration.json`.

Done when evidence includes registered IDs, source manifest rows, duplicate count,
and out-of-scope entries.

## Verification

```bash
test -x scripts/audit/verify_gov_conv_003.sh && bash scripts/audit/verify_gov_conv_003.sh > evidence/phase2/gov_conv_003_reg_sec_inv_registration.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-003 --evidence evidence/phase2/gov_conv_003_reg_sec_inv_registration.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

`evidence/phase2/gov_conv_003_reg_sec_inv_registration.json` must include:
`task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `registered_ids`,
`source_manifest_rows`, `duplicate_id_count`, and `out_of_scope_entries`.

## Rollback

Remove only the REG/SEC invariant entries added by this task and remove this
task's verifier/evidence. Do not modify PREAUTH or Wave invariant entries.

## Risk

| Risk | Consequence | Mitigation |
|---|---|---|
| Broad security claims | Overclaimed contract rows | Require precise invariant descriptions and verifier/evidence refs |
| Duplicate ID allocation | Ambiguous registry | Verifier rejects duplicates |
| Scope mixing | Review drift | Verifier rejects non-REG/SEC entries |
