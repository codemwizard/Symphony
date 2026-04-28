# TSK-P2-W8-DB-007a PLAN - Scope authorization enforcement

Task: TSK-P2-W8-DB-007a
Owner: DB_FOUNDATION
failure_signature: P2.W8.TSK_P2_W8_DB_007a.PROOF_FAIL
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md

---

## Objective

Enforce scope authorization as a distinct authoritative boundary failure.

## Control Position

- Authoritative Wave 8 boundary: `asset_batches`
- Primary enforcement domain: `scope authorization`
- Contract authority outranks implementation authority.
- SQL is the authoritative runtime executor only where this task implements runtime behavior.
- No advisory fallback is permitted for Wave 8 completion work.

## Scope Discipline

- This task is invalid if it expands into more than one primary enforcement domain.
- If implementation reveals a second enforcement domain, stop and create a follow-on pack.
- No completion credit is permitted unless the artifacts or behavior declared here are fully delivered.

## Intent

Wave 8 must distinguish cryptographic validity from authorization scope and timestamp integrity. This task adds the scope authorization failure domain without bundling it into generic crypto invalidity.

## Dependencies

TSK-P2-W8-DB-006

## Deliverables

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0178_wave8_scope_and_timestamp_enforcement.sql` | MODIFY | Deliver or update the task-controlled artifact |
| `scripts/db/verify_tsk_p2_w8_db_007a.sql` | CREATE | Deliver or update the task-controlled artifact |
| `scripts/db/verify_tsk_p2_w8_db_007a.sh` | CREATE | Deliver or update the task-controlled artifact |
| `evidence/phase2/tsk_p2_w8_db_007a.json` | CREATE | Deliver or update the task-controlled artifact |

## Stop Conditions

- Stop if the work expands beyond `scope authorization`.
- Stop if approval metadata is missing for a regulated-surface edit.
- Stop if the verifier path cannot be tied directly to the work-item IDs below.
- Stop if evidence cannot satisfy `TSK-P1-240` proof-carrying fields.

## Work Items

### Step 1
**What:** [ID w8_db_007a_work_01] Enforce project scope authorization and narrower entity-type scope authorization where the signing contract requires it.
**Done when:** [ID w8_db_007a_work_01] PostgreSQL rejects writes signed by keys outside the authorized project or entity scope.

### Step 2
**What:** [ID w8_db_007a_work_02] Build a verifier that distinguishes wrong-scope failures.
**Done when:** [ID w8_db_007a_work_02] The verifier distinguishes wrong-scope failures at `asset_batches`.

## Runtime Boundary Guardrail

- This is a Wave 8 runtime-affecting task.
- The verifier is insufficient unless it physically causes PostgreSQL to accept or reject a write at the authoritative `asset_batches` boundary.
- Structural introspection, object existence checks, or helper-only tests do not satisfy this task.

## Verification

```bash
bash scripts/db/verify_tsk_p2_w8_db_007a.sh > evidence/phase2/tsk_p2_w8_db_007a.json
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-W8-DB-007a/PLAN.md --meta tasks/TSK-P2-W8-DB-007a/meta.yml
```

## Evidence Contract

Evidence file: `evidence/phase2/tsk_p2_w8_db_007a.json`

Required proof fields:
- `task_id`
- `git_sha`
- `timestamp_utc`
- `status`
- `checks`
- `observed_paths`
- `observed_hashes`
- `command_outputs`
- `execution_trace`

## Approval and Trace

- Stage A approval metadata is required before regulated-surface edits.
- `EXEC_LOG.md` is append-only and must carry remediation trace markers.

## Database Connection

The PostgreSQL container IP is dynamic. To find the current IP:
```bash
docker inspect symphony-postgres | grep IPAddress
```

Then set DATABASE_URL:
```bash
export DATABASE_URL="postgresql://symphony_admin:symphony_pass@<dynamic-ip>:55432/symphony"
```

For local development with Docker Compose, the hostname may be `symphony-postgres` or `localhost:55432` depending on network configuration.

## Baseline Drift Handling

If `schema/baseline.sql` changes during this task:
1. The change must be accompanied by at least one migration change in the same PR
2. An explanation artifact must be created (ADR or plan log entry) describing why baseline changed
3. Run `scripts/db/check_baseline_drift.sh` to generate evidence at `./evidence/phase0/baseline_drift.json`
4. Baseline drift checks are fail-closed in CI

Reference: docs/PLANS-addendum_1.md sections 1-3
