# TSK-P2-RLS-BYPASS-001 PLAN - Inventory app.bypass_rls dependency surfaces

Task: TSK-P2-RLS-BYPASS-001
Owner: SECURITY_GUARDIAN
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-001.INVENTORY_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Produce a complete dependency inventory for every repository surface that references
or operationally depends on `app.bypass_rls`.

Done means `evidence/phase2/rls_bypass_dependency_inventory.json` exists, was emitted
by `scripts/audit/verify_rls_bypass_dependency_inventory.sh`, includes required
Wave-8 evidence fields, scans all required roots, and contains no UNKNOWN findings.

## Regulated Surface Compliance

This task edits regulated surfaces:

- `scripts/audit/verify_rls_bypass_dependency_inventory.sh`
- `evidence/phase2/rls_bypass_dependency_inventory.json`

Before editing either path, create Stage A approval artifacts under
`approvals/YYYY-MM-DD/` and validate them against
`docs/operations/approval_metadata.schema.json`.

Stage B approval artifacts are required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only. It must contain:

- `failure_signature`
- `origin_task_id`
- `repro_command`
- `verification_commands_run`
- `final_status`

These markers must exist when regulated files are modified, not after pre-CI catches
their absence.

## Architectural Context

`app.bypass_rls` weakens inherited tenant-isolation guarantees. However, removing it
blindly can break seed, bootstrap, repair, tests, or CI paths that still depend on
bypass semantics. This task does not remediate. It establishes the dependency map
needed to split remediation into safe, single-domain tasks.

## Pre-conditions

- `docs/operations/PHASE_EXECUTION_ENVELOPE.md` has been read in full.
- `.agent/rejection_context.md` is absent or has no active lockout.
- Stage A approval metadata exists before editing regulated files.
- No existing migration is modified.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `scripts/audit/verify_rls_bypass_dependency_inventory.sh` | Create | Deterministic inventory verifier |
| `evidence/phase2/rls_bypass_dependency_inventory.json` | Emit | Inventory evidence |
| `tasks/TSK-P2-RLS-BYPASS-001/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-001/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- RLS policy migration
- Runtime source modification
- Seed/admin boundary refactor
- Baseline regeneration
- Tenant-isolation runtime proof

## Stop Conditions

- Stop if any finding remains UNKNOWN.
- Stop if any required scan root cannot be scanned.
- Stop if evidence lacks observed paths, hashes, command outputs, or execution trace.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Create inventory verifier [ID rls_bypass_001_w01]

Create `scripts/audit/verify_rls_bypass_dependency_inventory.sh`.

The verifier must scan at minimum:

- `schema/**`
- `src/**`
- `scripts/**`
- `tests/**`
- `.github/workflows/**`
- `docs/**`
- root-level `Program.cs` if present
- fixture directories discovered in the repository

It must search for:

- `app.bypass_rls`
- `set_config('app.bypass_rls'`
- `set_config("app.bypass_rls"`
- SQL or C# variants that manipulate the same setting

Done when all scan roots are listed in evidence.

### Step 2 - Classify findings [ID rls_bypass_001_w02]

Classify each finding as one of:

- `RUNTIME`
- `ADMIN`
- `SEED`
- `TEST`
- `MIGRATION`
- `CI_BOOTSTRAP`
- `DOCS`
- `UNKNOWN`

Assign remediation_required as one of:

- `remove`
- `isolate`
- `refactor`
- `rewrite_test`
- `one_time_migration_only`
- `document_only`
- `investigate`

Done when no live finding remains UNKNOWN.

### Step 3 - Record detailed rows [ID rls_bypass_001_w03]

For every finding, record:

- path
- line number
- matched text class
- execution surface
- runtime_reachable boolean
- remediation_required
- recommended follow-on owner

Done when evidence contains one row per finding.

### Step 4 - Fail closed on incomplete proof [ID rls_bypass_001_w04]

Fail if:

- scan roots are skipped
- any finding is UNKNOWN
- evidence lacks required fields
- static hand-authored evidence is detected

Done when negative fixtures fail.

### Step 5 - Emit evidence [ID rls_bypass_001_w05]

Emit `evidence/phase2/rls_bypass_dependency_inventory.json`.

Done when evidence includes summary counts and full findings.

## Verification

```bash
test -x scripts/audit/verify_rls_bypass_dependency_inventory.sh && bash scripts/audit/verify_rls_bypass_dependency_inventory.sh > evidence/phase2/rls_bypass_dependency_inventory.json || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-001 --evidence evidence/phase2/rls_bypass_dependency_inventory.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_dependency_inventory.json must include:

task_id
git_sha
timestamp_utc
status
checks
observed_paths
observed_hashes
command_outputs
execution_trace
scan_roots
findings
summary_counts
unknown_findings_count
runtime_reachable_count
remediation_classes
Rollback
Remove only this task's verifier and evidence output. Do not modify source, schema,
tests, seed code, baseline files, or historical migrations.

Risk
Risk	Consequence	Mitigation
Inventory is grep-only	Follow-on remediation misses operational dependency	Require classification and remediation class per finding
Runtime path misclassified	Hidden bypass survives	Require runtime_reachable boolean and owner recommendation
Scan root skipped	False clean inventory	Verifier fails on skipped scan roots
Evidence hand-authored	Inadmissible proof	Require observed paths, hashes, command outputs, and execution trace
