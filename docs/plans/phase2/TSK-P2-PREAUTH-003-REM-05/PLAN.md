# TSK-P2-PREAUTH-003-REM-05 PLAN — Integrity verifier + CI wiring + self-certifying evidence

Task: TSK-P2-PREAUTH-003-REM-05
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-REM-03
failure_signature: PHASE2.PREAUTH.EXECUTION_RECORDS.VERIFIER_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
remediation_casefile: docs/plans/remediation/REM-2026-04-20_execution-truth-anchor/PLAN.md

---

## Objective

Produce `scripts/db/verify_execution_truth_anchor.sh`: a single integrity verifier that inspects seven proof surfaces (5x NOT NULL + 1x UNIQUE + 1x FK + 2x trigger = 9 primitive assertions, grouped) and emits a self-certifying evidence JSON carrying `verification_tool_version`, `verification_input_snapshot`, `verification_run_hash`. A smoke harness drives seven degradation scenarios to prove the verifier is not fail-open.

CI wiring (invoking this verifier from `scripts/dev/pre_ci.sh` and `scripts/audit/run_invariants_fast_checks.sh`) is owned by `TSK-P2-PREAUTH-003-REM-05B` under the SECURITY_GUARDIAN path authority per AGENTS.md. That is deliberately split from this task so every work item falls under a single owner role.

---

## Architectural Context

Every prior REM task (REM-01, REM-02, REM-03) ships its own per-gate verifier. Those are the *surface* verifiers used during migration development. This task produces the *anchor* verifier that INV-EXEC-TRUTH-001.enforcement points at — the one CI runs on every push. It deliberately delegates to live DB state rather than re-implementing the checks of its siblings, because divergent logic between surface and anchor verifiers is itself an anti-pattern. Self-certification via three verifier-integrity fields is the only structural defence against a compromised verifier emitting fake PASS evidence: downstream REM-04 cross-checks `verification_tool_version` against a SHA-256 pin in `INVARIANTS_MANIFEST.yml`.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-REM-03` is `status=completed` and its evidence validates.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0133`.
- [ ] `DATABASE_URL` is set.
- [ ] `pg_catalog` queries succeed under the verifier's psql invocation.

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `scripts/db/verify_execution_truth_anchor.sh` | CREATE | The anchor verifier |
| `scripts/db/tests/test_execution_truth_anchor_smoke.sh` | CREATE | Degradation harness |
| `evidence/phase2/tsk_p2_preauth_003_rem_05.json` | CREATE | Evidence emitted by verifier |
| `tasks/TSK-P2-PREAUTH-003-REM-05/meta.yml` | MODIFY | Status progression |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-05/PLAN.md` | CREATE | This document |
| `docs/plans/phase2/TSK-P2-PREAUTH-003-REM-05/EXEC_LOG.md` | CREATE | Append-only record |

---

## Stop Conditions

- Verifier exits 0 on any degraded state -> STOP.
- Evidence omits any of the three verifier-integrity fields -> STOP.
- Verifier not executable -> STOP.
- Verifier re-implements sub-checks from REM-01/02/03 instead of delegating to live DB state -> STOP.
- Any edit lands in `scripts/dev/pre_ci.sh` or `scripts/audit/**` -> STOP (path-authority violation; that scope belongs to REM-05B).

---

## Implementation Steps

### Step 1: Author the integrity verifier

**What:** `[ID tsk_p2_preauth_003_rem_05_work_item_01]` Create `scripts/db/verify_execution_truth_anchor.sh`:

1. `#!/usr/bin/env bash` + `set -Eeuo pipefail`.
2. Require `DATABASE_URL`; `|| exit 1`.
3. Define a small JSON accumulator (a bash array of check objects and a final `jq -n --argjson ...` composer).
4. NOT NULL probe: `psql -qAt -c "SELECT attname FROM pg_attribute WHERE attrelid='public.execution_records'::regclass AND attname IN ('input_hash','output_hash','runtime_version','tenant_id','interpretation_version_id') AND attnotnull=true;"` returns five rows -> `not_null_enforced=true`.
5. UNIQUE probe: `SELECT conname FROM pg_constraint WHERE conrelid='public.execution_records'::regclass AND contype='u' AND conname='execution_records_determinism_unique'` returns one row -> `unique_enforced=true`. Confirm its `conkey` decodes to the three determinism columns.
6. FK probe: `SELECT confrelid::regclass::text FROM pg_constraint WHERE conrelid='public.execution_records'::regclass AND contype='f' AND conkey::int[] @> ARRAY[<attnum of interpretation_version_id>];` equals `interpretation_packs` -> `fk_verified=true`.
7. Append-only trigger probe: `SELECT tgtype FROM pg_trigger WHERE tgrelid='public.execution_records'::regclass AND tgname='execution_records_append_only_trigger';` and decode tgtype bitmask to confirm BEFORE + ROW + (UPDATE|DELETE) -> `append_only_enforced=true`.
8. Temporal-binding trigger probe: same table, `tgname='execution_records_temporal_binding_trigger'`, BEFORE + ROW + INSERT -> `temporal_binding_enforced=true`.
9. SECURITY DEFINER hardening: `SELECT proname FROM pg_proc WHERE proname IN ('execution_records_append_only','enforce_execution_interpretation_temporal_binding') AND prosecdef=true AND 'search_path=pg_catalog, public' = ANY(proconfig);` returns two rows.
10. Verifier-integrity fields: `verification_tool_version` = `sha256sum "$0" | cut -d' ' -f1`. `verification_input_snapshot` = SHA-256 of the canonicalised JSON dump of the probe rows above, sorted deterministically. `verification_run_hash` = SHA-256 of `(verification_tool_version || verification_input_snapshot || json_dump(checks))`.
11. Compose `evidence/phase2/tsk_p2_preauth_003_rem_05.json` via `jq -n` and write to stdout; the verification harness redirects that to the declared path. `|| exit 1` on any assertion failure.

**Done when:** `test -x scripts/db/verify_execution_truth_anchor.sh` exits 0 and, against a 0133-applied database, the verifier exits 0 and the emitted JSON contains literal strings `verification_tool_version`, `verification_input_snapshot`, `verification_run_hash`.

### Step 2: Author the degradation smoke harness

**What:** `[ID tsk_p2_preauth_003_rem_05_work_item_02]` Create `scripts/db/tests/test_execution_truth_anchor_smoke.sh`. The harness runs seven scenarios against a disposable test database, each executed inside a transaction that is rolled back afterwards:

| # | Degradation | Expected bool |
|---|---|---|
| 1 | `ALTER COLUMN interpretation_version_id DROP NOT NULL` | `not_null_enforced=false` |
| 2 | `ALTER TABLE ... DROP CONSTRAINT execution_records_determinism_unique` | `unique_enforced=false` |
| 3 | `ALTER TABLE ... DROP CONSTRAINT <fk name>` | `fk_verified=false` |
| 4 | `DROP TRIGGER execution_records_append_only_trigger` | `append_only_enforced=false` |
| 5 | `DROP TRIGGER execution_records_temporal_binding_trigger` | `temporal_binding_enforced=false` |
| 6 | `CREATE OR REPLACE FUNCTION ... SECURITY INVOKER ...` (weaken definer) | `search_path_hardened` flag (if present) drops |
| 7 | `ALTER FUNCTION ... RESET search_path` | one of the SD hardening asserts fails |

For each scenario, the harness invokes the verifier and asserts exit code != 0. The harness itself exits 0 only when all seven scenarios produce non-zero verifier exits.

**Done when:** The harness exits 0 on a properly-migrated database.

### Step 3: Emit evidence

Run the verifier and confirm evidence lands at `evidence/phase2/tsk_p2_preauth_003_rem_05.json` with status=PASS and all three integrity fields populated.

---

## Verification

```bash
# [ID tsk_p2_preauth_003_rem_05_work_item_01] Run the integrity verifier and emit evidence.
test -x scripts/db/verify_execution_truth_anchor.sh && PRE_CI_CONTEXT=1 bash scripts/db/verify_execution_truth_anchor.sh || exit 1

# [ID tsk_p2_preauth_003_rem_05_work_item_02] Confirm the smoke harness exists for degradation negative tests.
test -x scripts/db/tests/test_execution_truth_anchor_smoke.sh || exit 1

# [ID tsk_p2_preauth_003_rem_05_work_item_01] Confirm evidence contains all three verifier-integrity fields.
test -f evidence/phase2/tsk_p2_preauth_003_rem_05.json && grep -q 'verification_tool_version' evidence/phase2/tsk_p2_preauth_003_rem_05.json && grep -q 'verification_input_snapshot' evidence/phase2/tsk_p2_preauth_003_rem_05.json && grep -q 'verification_run_hash' evidence/phase2/tsk_p2_preauth_003_rem_05.json || exit 1
```

---

## Evidence Contract

File: `evidence/phase2/tsk_p2_preauth_003_rem_05.json`

Required fields:
- `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`
- `observed_paths`: migration 0131 + 0132 + 0133 + MIGRATION_HEAD + verifier itself
- `observed_hashes`: SHA-256 per path
- `command_outputs`: raw psql stdout per probe
- `execution_trace`: timestamps per step
- `not_null_enforced`: true
- `fk_verified`: true
- `unique_enforced`: true
- `append_only_enforced`: true
- `temporal_binding_enforced`: true
- `columns_verified`: [ "input_hash", "output_hash", "runtime_version", "tenant_id", "interpretation_version_id" ]
- `verification_tool_version`: SHA-256 of the verifier script content
- `verification_input_snapshot`: SHA-256 of the canonicalised probe-input dump
- `verification_run_hash`: SHA-256 of (tool_version || input_snapshot || json_dump(checks))

---

## Rollback

1. Remove the verifier and the smoke harness.
2. CI-wiring rollback (scripts/dev/pre_ci.sh + scripts/audit/run_invariants_fast_checks.sh) is owned by REM-05B.
3. Flip INV-EXEC-TRUTH-001 to `in_progress` (REM-04 revert).
4. File exception in `docs/security/EXCEPTION_REGISTER.yml`.

---

## Risk

| Risk | Consequence | Mitigation |
|------|-------------|------------|
| Verifier fails open on degraded state | CRITICAL_FAIL | Smoke harness exercises seven degradations; `|| exit 1` on every probe |
| Evidence tampered post-emission | FAIL | `verification_run_hash` makes tampering detectable; REM-04 cross-checks against manifest pin |
| CI wires verifier with `|| true` | CRITICAL_FAIL | Stop condition + this PLAN's verification grep |
| Double invocation due to non-idempotent edit | FAIL_REVIEW | Sentinel guard comment makes edit idempotent |

---

## Approval (regulated surface)

- [ ] `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-05.json` present
- [ ] Approved by: `<approver_id>`
- [ ] Approval timestamp: `<ISO 8601>`
