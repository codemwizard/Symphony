# TSK-P2-RLS-BYPASS-006 PLAN - Regenerate baseline with provenance

Task: TSK-P2-RLS-BYPASS-006
Owner: DB_FOUNDATION
Depends on: TSK-P2-RLS-BYPASS-004, TSK-P2-RLS-BYPASS-005
failure_signature: PHASE2.RLS_BYPASS.TSK-P2-RLS-BYPASS-006.BASELINE_REFRESH_FAIL
canonical_reference: docs/operations/PHASE_EXECUTION_ENVELOPE.md

## Objective

Regenerate canonical baseline artifacts after the RLS bypass policy migration, with
provenance and an explicit baseline-refresh explanation.

Done means current baseline artifacts no longer contain `app.bypass_rls` policy
definitions and evidence records dump provenance and normalized schema hash.

## Regulated Surface Compliance

Create Stage A approval metadata before editing:

- `schema/baseline.sql`
- `schema/baselines/current/**`
- `scripts/db/verify_rls_bypass_baseline_refresh.sh`
- `evidence/phase2/rls_bypass_baseline_refresh.json`

Stage B approval is required after PR opening.

## Remediation Trace Compliance

`EXEC_LOG.md` is append-only and must include `failure_signature`, `origin_task_id`,
`repro_command`, `verification_commands_run`, and `final_status`.

## Architectural Context

Baseline updates must be intentional, migration-linked, and provenance-bearing.
This task follows the addendum baseline governance rule after the policy migration.

## Pre-conditions

- TSK-P2-RLS-BYPASS-004 and 005 are complete.
- Migration 0204 is applied.
- DATABASE_URL is set.
- Stage A approval metadata exists before regulated edits.

## Files to Change

| File | Action | Reason |
|---|---|---|
| `schema/baseline.sql` | Regenerate | Canonical baseline update |
| `schema/baselines/current/0001_baseline.sql` | Regenerate | Current baseline artifact |
| `schema/baselines/current/baseline.normalized.sql` | Regenerate | Normalized baseline artifact |
| `scripts/db/verify_rls_bypass_baseline_refresh.sh` | Create | Verify baseline refresh |
| `evidence/phase2/rls_bypass_baseline_refresh.json` | Emit | Baseline provenance evidence |
| `tasks/TSK-P2-RLS-BYPASS-006/meta.yml` | Create | Task contract |
| `docs/plans/phase2/TSK-P2-RLS-BYPASS-006/EXEC_LOG.md` | Create/update append-only | Remediation trace |

## Out of Scope

- Creating migrations
- Editing application code
- Runtime RLS behavior proof
- CI workflow edits
- Phase-2 closeout claim

## Stop Conditions

- Stop if migration or terminal-policy evidence is missing.
- Stop if baseline provenance cannot be recorded.
- Stop if baseline still contains app.bypass_rls policy definitions.
- Stop if approval metadata is absent before regulated edits.

## Implementation Steps

### Step 1 - Confirm prerequisites [ID rls_bypass_006_w01]

Record passing migration and terminal-policy evidence references in EXEC_LOG.

Done when prerequisite proof is linked.

### Step 2 - Regenerate baseline [ID rls_bypass_006_w02]

Regenerate baseline artifacts using repo-approved tooling and DATABASE_URL.

Done when files are regenerated, not manually edited.

### Step 3 - Record explanation [ID rls_bypass_006_w03]

Append a baseline refresh explanation to EXEC_LOG.

Done when rationale cites the RLS bypass migration.

### Step 4 - Create verifier [ID rls_bypass_006_w04]

Create `verify_rls_bypass_baseline_refresh.sh`.

Done when it rejects missing provenance and app.bypass_rls in current baseline.

### Step 5 - Emit evidence [ID rls_bypass_006_w05]

Emit `rls_bypass_baseline_refresh.json`.

Done when evidence includes provenance and validates.

## Verification

```bash
test -x scripts/db/verify_rls_bypass_baseline_refresh.sh && bash scripts/db/verify_rls_bypass_baseline_refresh.sh > evidence/phase2/rls_bypass_baseline_refresh.json || exit 1
bash scripts/db/check_baseline_drift.sh || exit 1
python3 scripts/audit/validate_evidence.py --task TSK-P2-RLS-BYPASS-006 --evidence evidence/phase2/rls_bypass_baseline_refresh.json || exit 1
RUN_PHASE2_GATES=1 bash scripts/dev/pre_ci.sh || exit 1
Evidence Contract
evidence/phase2/rls_bypass_baseline_refresh.json must include:
task_id, git_sha, timestamp_utc, status, checks, observed_paths,
observed_hashes, command_outputs, execution_trace, pg_dump_version,
pg_server_version, dump_source, normalized_schema_sha256, migration_head,
baseline_paths, and app_bypass_rls_in_current_baseline.

Rollback
Regenerate baseline from the prior migration state only through a new governed
rollback/remediation task. Do not hand-edit baseline files.

Risk
Risk	Consequence	Mitigation
Manual baseline edit	Unreproducible schema state	Provenance verifier
Current baseline still contains bypass	Closeout remains false	Verifier rejects string in current policy definitions
Runtime proof conflated	Overclaim	Runtime proof is separate task
