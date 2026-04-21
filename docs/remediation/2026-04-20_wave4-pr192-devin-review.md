# DRD Lite

## Metadata
- Template Type: Lite
- Incident Class: governance/contract-remediation (Wave 4 Authority Binding task packs)
- Severity: L1
- Status: Resolved
- Owner: Supervisor (PR #192 take-over; originating author TSK-P2-PREAUTH-004-00..03 CREATE-TASK batch)
- Date: 2026-04-20
- Task: TSK-P2-PREAUTH-004-01 (primary) + TSK-P2-PREAUTH-004-02 / TSK-P2-PREAUTH-004-03 (EXEC_LOG format standardisation)
- Branch: devin/1776714902-wave4-004-00
- PR: https://github.com/codemwizard/Symphony/pull/192

## Summary

Devin Review on PR #192 surfaced a batch of contract-level defects in the Wave 4
Authority Binding task packs (CREATE-TASK mode — no runtime code yet, but the
PLAN/meta pair is the authoritative contract IMPLEMENT-TASK will follow). The
defects cluster into four classes, all resolved in this remediation batch:

1. **Enforcement-code collision (CRITICAL)** — The append-only trigger spec in
   `docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md` raised
   `ERRCODE = '23514'`. `23514` is PostgreSQL's standard `check_violation` and
   is raised natively by the `decision_hash` / `signature` CHECK regexes on the
   same table. Append-only rejections and CHECK violations therefore became
   indistinguishable by SQLSTATE, which would collapse the contracted negative
   tests N3 (CHECK) and N5 (append-only `UPDATE`) into the same signal.
2. **SECURITY DEFINER omission (CRITICAL, regulated-surface hardening)** — Wave 3
   established the canonical pattern for append-only triggers in
   `schema/migrations/0133_execution_records_triggers.sql` (`GF056`,
   `SECURITY DEFINER SET search_path = pg_catalog, public`,
   `REVOKE ALL ON FUNCTION ... FROM PUBLIC`). The 004-01 PLAN silently deviated
   and stated *"SECURITY DEFINER is not required on the trigger function"* —
   reopening the `search_path`-injection posture gap explicitly closed by
   AGENTS.md hard constraints.
3. **DELETE path not tested (CRITICAL, proof gap)** — Stop conditions required
   blocking both `UPDATE` and `DELETE`, but the contracted negative-test set
   stopped at N1–N5 and exercised `UPDATE` only. A broken `DELETE` path would
   have passed CI and silently invalidated the append-only guarantee.
4. **Payload → column ambiguity (CRITICAL, determinism risk)** — The 004-00
   canonical-payload contract uses the field name `issued_at`; the 004-01
   column name is `signed_at`. The mapping existed nowhere in authoritative
   form, so two implementers could diverge (`issued_at → signed_at` vs
   `issued_at → created_at` vs introducing a new `issued_at` column) and
   silently break `decision_hash` recompute at 004-03 V3 verify time.

Additional items closed in the same batch:

- EXEC_LOG format inconsistency (004-00 carried machine-readable trace fields;
  004-01/02/03 did not) — standardised.
- Evidence drift (`evidence/phase0/*.json` were frozen at a prior intermediate
  git_sha with `1970-01-01` timestamps) — regenerated against the current PR
  HEAD so git_sha, timestamps, and scanned-file counts reflect PR #192 state.
- DAG dependency gap for TSK-P2-PREAUTH-004-02 — already closed in a prior
  commit on this branch (`98dd5ea7`, referenced here for audit completeness).

## First Failing Signal

- Artifact/log path: `docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md:107-108`
  (pre-remediation) — `ERRCODE = '23514'` inside the
  `enforce_policy_decisions_append_only` function definition.
- Error signature (synthesised, CREATE-TASK mode has no runtime failure yet):
  `PHASE2.PREAUTH.POLICY_DECISIONS_SCHEMA.APPEND_ONLY_ERRCODE_COLLISION` +
  `PHASE2.PREAUTH.POLICY_DECISIONS_SCHEMA.SECURITY_DEFINER_ABSENT` +
  `PHASE2.PREAUTH.POLICY_DECISIONS_SCHEMA.DELETE_TEST_MISSING` +
  `PHASE2.PREAUTH.POLICY_DECISIONS_PAYLOAD.COLUMN_MAPPING_UNDECLARED`.

## Impact

- What was blocked: IMPLEMENT-TASK handoff for migration `0134`
  (`policy_decisions`). Any implementer following the PLAN verbatim would have
  (a) emitted a `23514` collision, (b) installed a non-hardened
  `SECURITY INVOKER` trigger function, (c) shipped a five-test harness that
  could not detect a regressed `DELETE` path, and (d) risked breaking
  `decision_hash` recompute at 004-03 V3 time through a silent payload/column
  mapping divergence. All four classes were CRITICAL_FAIL per the updated
  `failure_modes` section of `tasks/TSK-P2-PREAUTH-004-01/meta.yml`.
- Delay: zero downstream impact (caught pre-implementation in PR review).
- Attempts before record: 1 (remediation applied in this batch; no prior
  attempt failed).

## Diagnostic Trail

- Commands:
  - Read PLAN/meta/EXEC_LOG for 004-00..03 and the Wave 3 reference trigger
    `schema/migrations/0133_execution_records_triggers.sql`.
  - `rg 'ERRCODE' schema/migrations/` to enumerate in-use GF-prefixed codes and
    confirm `GF061` as the next free slot after `GF060` (K13 taxonomy alignment).
  - `cat docs/contracts/sqlstate_map.schema.json` → confirmed
    `code_pattern = ^P\d{4}$`; GF-prefixed codes cannot be registered in the
    current sqlstate_map.yml without a separate schema change.
  - `bash scripts/audit/lint_yaml_conventions.sh`,
    `bash scripts/audit/verify_baseline_change_governance.sh`,
    `bash scripts/audit/verify_control_planes_drift.sh`,
    `bash scripts/audit/check_sqlstate_map_drift.sh` → regenerated evidence
    from current PR HEAD.
- Results:
  - GF-prefix sequence currently populated: `GF001` (reg26 separation),
    `GF050`–`GF051` (statutory_levy_registry, exchange_rate_audit_log append-
    only), `GF055`–`GF061` (project/protected_areas geofence +
    execution_records append-only + temporal binding + K13 taxonomy). `GF061`
    is the next free slot and is assigned here to the `policy_decisions`
    append-only enforcement function.
  - `scripts/audit/check_sqlstate_map_drift.sh` passes both before and after
    this remediation because the sqlstate_map registry is not touched (see
    "Known limitation" in Fix Applied §).

## Root Cause

Confirmed.

- Cause 1 (SQLSTATE collision): CREATE-TASK authorship picked the standard
  `23514` code without cross-checking against the CHECK regexes on the same
  table. The hedge in `tasks/TSK-P2-PREAUTH-004-01/meta.yml` line 98
  *"SQLSTATE 23514 (or equivalent repo-standard code)"* was not binding
  because the authoritative SQL block in the PLAN hard-coded `23514`.
- Cause 2 (SECURITY DEFINER omission): Authoring assumed *"a trigger that only
  RAISEs cannot be a privilege-escalation surface"*, which overlooks (a)
  `search_path`-injection vectors that the rest of the repo defends against by
  convention and (b) the auditor expectation that identical trigger classes
  share identical security posture.
- Cause 3 (DELETE test missing): Authoring counted rejection paths rather than
  mutation verbs; `UPDATE` and `DELETE` are one trigger but two verbs, and only
  the `UPDATE` verb was covered.
- Cause 4 (payload/column mapping): The 004-00 contract uses the payload field
  name `issued_at` and the 004-01 schema uses the column name `signed_at`. The
  implicit mapping was obvious to both authors but not pinned anywhere the
  IMPLEMENT-TASK writer would see.

## Fix Applied

Files changed (all documentation / contract surfaces; no `src/` or runtime
code; no applied-migration edits; migration `0134` remains unwritten until
IMPLEMENT-TASK):

- `docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md`
  - Append-only trigger SQL block:
    `ERRCODE = '23514'` → `ERRCODE = 'GF061'`
    with message prefix `GF061: policy_decisions is append-only, UPDATE/DELETE not allowed`;
    function declared `SECURITY DEFINER SET search_path = pg_catalog, public`;
    followed by `REVOKE ALL ON FUNCTION ... FROM PUBLIC`.
  - Removed the stale note claiming *"SECURITY DEFINER is not required"*.
  - Added rationale block explaining (a) `23514` collision with CHECK
    violations on the same table and (b) GF-prefix convention (GF050/051/055/
    056) alignment.
  - Added **Payload → Column Mapping (NON-NEGOTIABLE)** section listing the
    eight canonical-JSON keys ↔ columns, explicitly pinning
    `issued_at (payload) ↔ signed_at (column)` with RFC 3339 UTC
    serialisation.
  - Negative-test table extended with `N6` (DELETE rejection); both N5 and N6
    upgraded to require `SQLSTATE = 'GF061'` as an assertion (not just a
    rejection signal).
  - Stop conditions updated: "six contracted negative tests (N1–N6)".
  - Step 2 done-when grep set expanded to require
    `ERRCODE = 'GF061'`, `SECURITY DEFINER`,
    `search_path = pg_catalog, public`, and
    `REVOKE ALL ON FUNCTION public.enforce_policy_decisions_append_only`.
  - Step 4 verifier contract extended with a `pg_proc` query for
    `prosecdef = true` and `proconfig LIKE '%search_path=pg_catalog, public%'`;
    evidence JSON now carries `function_security_posture`.
  - Failure Modes table extended with three new CRITICAL_FAIL rows for
    SECURITY DEFINER omission, wrong ERRCODE, and REVOKE omission.

- `tasks/TSK-P2-PREAUTH-004-01/meta.yml`
  - `stop_conditions`: added four new entries (SECURITY DEFINER,
    non-GF061 SQLSTATE, REVOKE omission, N5/N6 SQLSTATE assertion).
  - `proof_guarantees`: added pg_proc posture guarantee and GF061 guarantee;
    corrected the "six failure paths" count.
  - `work_item_02` rewritten to bind the implementer to GF061,
    SECURITY DEFINER hardening, and the REVOKE statement; canonical reference
    points to `0133_execution_records_triggers.sql`.
  - `work_item_04` verifier contract extended with pg_proc query and
    `function_security_posture` evidence field.
  - `work_item_05` harness contract extended from N1–N5 to N1–N6 with explicit
    SQLSTATE = 'GF061' assertions on N5 and N6.
  - `acceptance_criteria` verification grep extended with the six new tokens.
  - `negative_tests` extended with a new `TSK-P2-PREAUTH-004-01-N6` entry
    (DELETE rejection).
  - `evidence[0].must_include` extended with `function_security_posture`.
  - `failure_modes` extended with three new CRITICAL_FAIL entries.

- `docs/plans/phase2/TSK-P2-PREAUTH-004-01/EXEC_LOG.md`
  - Prepended machine-readable trace fields (`failure_signature`,
    `origin_task_id`, `repro_command`, `verification_commands_run`,
    `final_status`) to match the 004-00 pattern.
  - Appended an Execution History row documenting this Devin Review
    remediation batch with the six sub-fixes enumerated.

- `docs/plans/phase2/TSK-P2-PREAUTH-004-02/EXEC_LOG.md`,
  `docs/plans/phase2/TSK-P2-PREAUTH-004-03/EXEC_LOG.md`
  - Prepended the same machine-readable trace fields; appended a
    format-standardisation History row. No PLAN / meta content changed for
    004-02 or 004-03 in this pass.

- `docs/tasks/phase2_pre_atomic_dag.yml`
  - (Already pushed as commit `98dd5ea7` in a prior pass) — added
    `TSK-P2-PREAUTH-004-00` to `depends_on` for `TSK-P2-PREAUTH-004-02`.

- `evidence/phase0/yaml_conventions_lint.json`,
  `evidence/phase0/baseline_governance.json`,
  `evidence/phase0/control_planes_drift.json`,
  `evidence/phase0/sqlstate_map_drift.json`
  - Regenerated via the canonical producers
    (`scripts/audit/lint_yaml_conventions.sh`,
    `scripts/audit/verify_baseline_change_governance.sh`,
    `scripts/audit/verify_control_planes_drift.sh`,
    `scripts/audit/check_sqlstate_map_drift.sh`) against current PR HEAD so
    `git_sha`, `timestamp_utc`, and `checked_file_count` reflect PR #192 state
    rather than the prior frozen/zeroed values.

Known limitation (follow-up, not blocking this PR):

- `docs/contracts/sqlstate_map.yml` pins `code_pattern = ^P\d{4}$` (enforced
  by `docs/contracts/sqlstate_map.schema.json` and
  `scripts/audit/check_sqlstate_map_drift.sh`). The in-use GF-prefix
  convention (`GF001`, `GF050`, `GF051`, `GF055`–`GF061`) therefore cannot be
  registered in `sqlstate_map.yml` without a separate schema change. The
  authoritative declaration of `GF061` lives in this PLAN and will be mirrored
  verbatim into `schema/migrations/0134_policy_decisions.sql` at
  IMPLEMENT-TASK time, matching the pattern used by every in-use GF code.
  Harmonising the registry with the in-use GF convention is tracked as a
  follow-up remediation (separate task, separate PR) and is called out in
  both `PLAN.md` and the 004-01 EXEC_LOG batch entry so the gap is visible
  to the next curator pass.

Why the fix should work:

- The GF061 assignment is byte-compared against the five greps added to both
  PLAN Step 2 and meta.yml acceptance_criteria; any implementer drift from
  `GF061` / `SECURITY DEFINER` / `search_path = pg_catalog, public` / `REVOKE
  ALL ON FUNCTION` fails the `verification` chain before evidence is emitted.
- The pg_proc query in the verifier (`work_item_04`) turns the SECURITY
  DEFINER + search_path hardening from a grep-over-SQL check into a
  catalogue-observed posture check, matching the Wave 3 hardening audit
  pattern.
- The Payload → Column Mapping table is the single source of truth the
  004-03 V3 verifier will re-read when recomputing `sha256(canonical_json(...))`;
  any divergence produces a hash mismatch, which V3 already tests.
- N6 (DELETE rejection) closes the `UPDATE`-only gap in the harness and
  enforces `SQLSTATE = 'GF061'` explicitly, so a CHECK-violation masquerading
  as append-only enforcement is caught.

## Verification Outcomes

Commands run in this sandbox (non-DB; CREATE-TASK mode has no runtime DDL to
execute):

- `bash scripts/audit/lint_yaml_conventions.sh` → `PASS`, evidence
  regenerated, `checked_file_count = 4` (was 1 under the prior frozen
  evidence).
- `bash scripts/audit/verify_baseline_change_governance.sh` → `PASS`,
  evidence regenerated.
- `bash scripts/audit/verify_control_planes_drift.sh` → `PASS`, evidence
  regenerated.
- `bash scripts/audit/check_sqlstate_map_drift.sh` → `PASS` (unchanged; the
  registry itself is not touched, consistent with the known-limitation note
  above).

Commands deferred to CI (DATABASE_URL not available in this sandbox):

- `scripts/db/verify_invariants.sh` — runs in the CI environment with a seeded
  database.
- `python3 scripts/audit/verify_plan_semantic_alignment.py --plan
  docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md --meta
  tasks/TSK-P2-PREAUTH-004-01/meta.yml` — CI gate. This is the decisive gate
  for 004-01 PLAN/meta coherence and is re-run by CI on the post-remediation
  HEAD.
- PASS/FAIL: local-regeneration gates PASS; semantic-alignment + DB gates
  tracked via PR-level CI on commit `<pending batch commit SHA>`.

## Escalation Trigger

Escalate to a Full DRD if any of the following is observed post-merge:

- `verify_plan_semantic_alignment.py` reports a non-PASS for 004-01 on the
  post-remediation HEAD.
- IMPLEMENT-TASK authorship of `0134_policy_decisions.sql` deviates from
  `GF061` / SECURITY DEFINER / search_path / REVOKE (i.e. a later review
  catches the same class of defect on the migration file).
- A later wave introduces a second GF-prefixed code without a corresponding
  registry-harmonisation task (this DRD's known limitation re-manifests as a
  systemic drift, requiring a Full DRD on the sqlstate_map.yml schema).

## Canonical References

- `AGENT_ENTRYPOINT.md`
- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/operations/debug-remediation-policy.md`
- `docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md` (Wave 4 Authority Binding
  contract — upstream source of the payload-field ↔ column mapping pinned by
  this remediation).
- `schema/migrations/0133_execution_records_triggers.sql` (Wave 3 append-only
  trigger reference pattern).
