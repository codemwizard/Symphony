# TSK-P2-GOV-CONV-001 PLAN - Produce Phase-2 reconciliation manifest

Task: TSK-P2-GOV-CONV-001
Owner: INVARIANTS_CURATOR
failure_signature: PHASE2.GOV_CONV.TSK-P2-GOV-CONV-001.RECONCILIATION_SCAN_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

## Objective

Produce a mechanically derived reconciliation manifest from `tasks/TSK-P2-*/meta.yml`.
Done means `evidence/phase2/gov_conv_001_reconciliation_manifest.json` exists,
contains one row per readable Phase-2 task metadata file, includes summary counts,
and is emitted by a verifier that fails closed on partial scans.

## Regulated Surface Compliance

- Approval metadata is required before editing `scripts/audit/**` or `evidence/**`.
- Stage A approval must exist before file edits.
- Stage B approval is required after PR opening.
- Validate approval sidecars against `docs/operations/approval_metadata.schema.json`.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include:

- `failure_signature`
- `origin_task_id`
- `repro_command`
- `verification_commands_run`
- `final_status`

## Architectural Context

The Phase-2 machine contract and executed Phase-2 task evidence have drift risk.
Later invariant and contract tasks must not infer executed work from roadmap prose.
This task establishes the repository-derived inventory used by later tasks.

## Pre-conditions

- `tasks/` is readable.
- `scripts/audit/` and `evidence/phase2/` are writable after approval metadata exists.
- `docs/operations/TASK_CREATION_PROCESS.md` and `TSK-P1-240` proof-graph rules have been read.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_gov_conv_001.sh` | Create | Task-specific verifier |
| `evidence/phase2/gov_conv_001_reconciliation_manifest.json` | Emit | Evidence manifest |
| `tasks/TSK-P2-GOV-CONV-001/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-GOV-CONV-001/EXEC_LOG.md` | Create/update append-only | Execution trace |

## Out of Scope

- Assigning invariant IDs
- Modifying `INVARIANTS_MANIFEST.yml`
- Modifying `phase2_contract.yml`
- Modifying existing task metadata

## Stop Conditions

- Stop if approval metadata is absent before editing regulated files.
- Stop if row count is below 80.
- Stop if any manifest row lacks required fields.
- Stop if evidence cannot be generated from live inspection.

## Implementation Steps

### Step 1 - Build verifier [ID gov_conv_001_w01]

Create `scripts/audit/verify_gov_conv_001.sh`. It must scan `tasks/TSK-P2-*/meta.yml`, parse each YAML file, and emit JSON derived from repository state.

Done when the verifier identifies Phase-2 task metadata without using `evidence/phase2/**` as the source of truth.

### Step 2 - Emit rows [ID gov_conv_001_w02]

For each task, emit task identity, declared evidence paths, evidence existence booleans, declared verifier paths, verifier existence booleans, declared invariants, status, phase, and owner role.

Done when every readable TSK-P2 task metadata file has one manifest row.

### Step 3 - Emit summary counts [ID gov_conv_001_w03]

Compute counts from the emitted rows.

Done when `summary_counts` contains only non-negative integers and matches the row data.

### Step 4 - Add fail-closed behavior [ID gov_conv_001_w04]

Fail if row count is below 80, rows are malformed, metadata is unreadable, or evidence is static.

Done when negative fixtures fail and the live scan passes.

## Verification

```bash
test -x scripts/audit/verify_gov_conv_001.sh && bash scripts/audit/verify_gov_conv_001.sh > evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-GOV-CONV-001 --evidence evidence/phase2/gov_conv_001_reconciliation_manifest.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
```

## Evidence Contract

`evidence/phase2/gov_conv_001_reconciliation_manifest.json` must include:
`task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `rows`,
`summary_counts`, `total_tasks`, `evidence_complete`, `verifier_complete`,
and `inv_id_absent`.

## Rollback

Remove only this task's verifier and evidence output. Do not change any existing
Phase-2 task metadata or contract document as part of rollback.

## Risk

| Risk | Consequence | Mitigation |
|---|---|---|
| YAML parsing differs across environments | False scan failures | Use Python YAML parser already available in repo tooling or fail with explicit dependency error |
| Evidence directory scanned instead of task metadata | Contract drift persists | Negative test requires metadata-first behavior |
| Missing paths are skipped | False completeness | Preserve paths and mark booleans false |
