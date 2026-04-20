# REM-2026-04-20_execution-truth-anchor — EXEC_LOG

Append-only. Do not retroactively rewrite entries.

---

## 2026-04-20T00:00:00Z — Casefile opened

- **Actor:** supervisor / devin-a8f1396e6bde4a80bf70bae475972a98
- **Reporter:** mwiza (user brief, Wave 3 audit)
- **failure_signature:** `PHASE2.PREAUTH.EXECUTION_RECORDS.TRUTH_ANCHOR_SEMANTIC_GAP`
- **Origin task(s):** `TSK-P2-PREAUTH-003-01`, `TSK-P2-PREAUTH-003-02`
- **Origin gate:** `checkpoint/EXEC-TRUTH`
- **Severity:** L2 (multi-gate schema + triggers + constraints + invariant + verifier)
- **Scope locked:** strict Wave 3 subset (`input_hash`, `output_hash`, `runtime_version`, `tenant_id`) + FK NOT NULL + UNIQUE + append-only trigger + temporal-binding trigger + INV-EXEC-TRUTH-001 + verifier. Retry / lifecycle / failure-state deferred to sibling casefile `REM-2026-04-20_execution-lifecycle`.
- **Audit commands executed:**
  - `grep -n 'interpretation_version_id' schema/migrations/0118_create_execution_records.sql`
  - `grep -rn 'execution_records_append_only' schema/migrations/`
  - `grep -n 'INV-EXEC-' docs/invariants/INVARIANTS_MANIFEST.yml`
  - `cat schema/migrations/MIGRATION_HEAD` (returned `0130`)
- **Audit findings:** all 5 gaps enumerated in PLAN.md §Gap enumeration confirmed OPEN.
- **User clarifications received:**
  - Wave 3 is `-00/-01/-02` (no `-03`).
  - INV-175 belongs to data_authority scope; execution-truth anchor requires a new invariant (`INV-EXEC-TRUTH-001`).
  - FK target stays `interpretation_packs(interpretation_pack_id)` (user Q2 = option a).
- **Derived tasks authored:** `TSK-P2-PREAUTH-003-REM-01..05`.

## 2026-04-20T00:00:00Z — Sibling casefile stub opened

- `docs/plans/remediation/REM-2026-04-20_execution-lifecycle/PLAN.md` authored as a stub with non-interference boundary declaration. No derived tasks yet. Sibling owner: `DB_FOUNDATION` (future lifecycle DDL) + `SECURITY_GUARDIAN` (future state-transition verifier).

## 2026-04-20T10:45:00Z — Task-pack split for path-authority alignment

- **Actor:** supervisor / devin-79f3cbd8d81c4f18a54fc18134d68088
- **Trigger:** Devin Review PR #187 flagged two path-authority violations on the initial five derived tasks (`BUG_pr-review-job-c4fc938f95fc4692ac528a10081cda97_0001` and `_0002`):
  - REM-05 originally owned by `SECURITY_GUARDIAN` while touching `scripts/db/**` (DB_FOUNDATION's exclusive surface under AGENTS.md).
  - REM-04 originally scoped over both `docs/invariants/**` (INVARIANTS_CURATOR) and `docs/security/**` (SECURITY_GUARDIAN), crossing role boundaries.
- **Resolution:** split each into two single-owner tasks rather than weaken path authority:
  - **REM-05 (DB_FOUNDATION)** retains verifier authorship in `scripts/db/verify_execution_truth_anchor.sh` + evidence emission.
  - **REM-05B (SECURITY_GUARDIAN)** — NEW — owns CI wiring in `scripts/dev/pre_ci.sh` and `scripts/audit/run_invariants_fast_checks.sh`.
  - **REM-04 (INVARIANTS_CURATOR)** narrowed to `docs/invariants/INVARIANTS_MANIFEST.yml` + `docs/invariants/INVARIANTS_IMPLEMENTED.md`.
  - **REM-04B** — NEW — owns the threat-model + compliance-map surfaces. (See 2026-04-20T10:50:00Z entry below: owner_role was corrected from SECURITY_GUARDIAN to ARCHITECT, and file paths from `docs/security/**` to `docs/architecture/**`.)
- **Revised DAG:** REM-01 → REM-02 → REM-03 → REM-05 → REM-05B → REM-04 → REM-04B → `checkpoint/EXEC-TRUTH-REM`. Registered in `docs/tasks/phase2_pre_atomic_dag.yml` stage `1-execution-truth-remediation` and `docs/tasks/PHASE2_TASKS.md` Wave 3-R.
- **Total derived tasks after split:** seven (REM-01, REM-02, REM-03, REM-04, REM-04B, REM-05, REM-05B). Supersedes the "REM-01..05" count recorded in the 2026-04-20T00:00:00Z opening entry.

---

## (Future entries)

- REM-01 acceptance + evidence path
- REM-02 acceptance + evidence path (and backfill branch decision)
- REM-03 acceptance + evidence path
- REM-05 acceptance + evidence path (verifier PASS under `DATABASE_URL`)
- REM-05B acceptance + evidence path (pre_ci.sh + run_invariants_fast_checks.sh invoke the verifier and fail closed)
- REM-04 acceptance + evidence path (INV-EXEC-TRUTH-001 status flipped to `implemented` in `docs/invariants/**`)
- REM-04B acceptance + evidence path (threat-model + compliance-map rows registered in `docs/architecture/**`)
- `final_status: closed` once all seven tasks report `status: completed` and `checkpoint/EXEC-TRUTH-REM` clears.

Do not close this casefile until all seven derived tasks' evidence files validate under `scripts/audit/validate_evidence.py` **and** `scripts/dev/pre_ci.sh` returns 0.
