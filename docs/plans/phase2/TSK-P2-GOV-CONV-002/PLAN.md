# TSK-P2-GOV-CONV-002 PLAN - Register PREAUTH Phase-2 invariant IDs

Task: TSK-P2-GOV-CONV-002
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-GOV-CONV-001
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-002.PREAUTH_INV_REGISTRATION_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Register only PREAUTH-scoped Phase-2 invariant IDs in
`docs/invariants/INVARIANTS_MANIFEST.yml`, grounded in the reconciliation manifest
from TSK-P2-GOV-CONV-001.

Done means all new IDs are PREAUTH-scoped, unique, manifest-traceable, and verified
by `scripts/audit/verify_gov_conv_002.sh`.

## Regulated Surface Compliance

- Approval metadata is required before editing `docs/invariants/**`, `scripts/audit/**`, or `evidence/**`.
- Stage A approval must exist before edits.
- Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include:

- `failure_signature`
- `origin_task_id`
- `repro_command`
- `verification_commands_run`
- `final_status`

## Architectural Context

The Phase-2 contract must reference real invariant IDs, not task IDs or roadmap
claims. PREAUTH registration is split from other clusters so each registry update
has a narrow review surface and a clear source manifest.

## Pre-conditions

- TSK-P2-GOV-CONV-001 is completed.
- `evidence/phase2/gov_conv_001_reconciliation_manifest.json` exists and validates.
- Approval metadata exists before regulated files are edited.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `docs/invariants/INVARIANTS_MANIFEST.yml` | Modify | Register PREAUTH invariant IDs |
| `scripts/audit/verify_gov_conv_002.sh` | Create | Verify PREAUTH registration |
| `evidence/phase2/gov_conv_002_preauth_inv_registration.json` | Emit | Evidence |
| `tasks/TSK-P2-GOV-CONV-002/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-002/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- REG or SEC invariant registration
- W5, W6, or W8 invariant registration
- Phase-2 contract rewrite
- Contract verifier creation

## Stop Conditions

- Stop if the reconciliation manifest is absent or invalid.
- Stop if proposed IDs duplicate existing invariant IDs.
- Stop if any proposed entry lacks PREAUTH manifest traceability.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Identify PREAUTH rows [ID gov_conv_002_w01]

Review `gov_conv_001_reconciliation_manifest.json` and isolate only PREAUTH-005,
PREAUTH-006, and PREAUTH-007 rows missing registered invariant IDs.

Done when EXEC_LOG records the reviewed PREAUTH rows.

### Step 2 - Register PREAUTH invariants [ID gov_conv_002_w02]

Update `INVARIANTS_MANIFEST.yml` with only PREAUTH-scoped entries. Each entry must
have a precise invariant description, status, verifier reference, and evidence
reference.

Done when no non-PREAUTH entry is changed by this task.

### Step 3 - Create verifier [ID gov_conv_002_w03]

Create `verify_gov_conv_002.sh` to check uniqueness, PREAUTH-only scope, manifest
traceability, and required fields.

Done when duplicate and out-of-scope fixtures fail.

### Step 4 - Emit evidence [ID gov_conv_002_w04]

Run the verifier and emit `gov_conv_002_preauth_inv_registration.json`.

Done when evidence includes registered IDs, source manifest rows, duplicate count,
and out-of-scope entries.

## Verification

```bash
test -x scripts/audit/verify_gov_conv_002.sh && bash scripts/audit/verify_gov_conv_002.sh > evidence/phase2/gov_conv_002_preauth_inv_registration.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-002 --evidence evidence/phase2/gov_conv_002_preauth_inv_registration.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

`evidence/phase2/gov_conv_002_preauth_inv_registration.json` must include:
`task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `registered_ids`,
`source_manifest_rows`, `duplicate_id_count`, and `out_of_scope_entries`.

## Rollback

Remove only the PREAUTH invariant entries added by this task and remove this task's
verifier/evidence. Do not modify non-PREAUTH invariant entries.

## Risk

| Risk | Consequence | Mitigation |
|---|---|---|
| Invariants too broad | Future contract rows overclaim | Require manifest source rows and precise verifier references |
| Duplicate ID allocation | Registry ambiguity | Verifier rejects duplicates |
| Cluster mixing | Review scope becomes unclear | Verifier rejects non-PREAUTH entries |
