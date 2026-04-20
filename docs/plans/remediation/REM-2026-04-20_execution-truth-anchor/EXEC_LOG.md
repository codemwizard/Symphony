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

---

## (Future entries)

- REM-01 acceptance + evidence path
- REM-02 acceptance + evidence path (and backfill branch decision)
- REM-03 acceptance + evidence path
- REM-05 acceptance + evidence path (verifier PASS under `DATABASE_URL`)
- REM-04 acceptance + evidence path (INV-EXEC-TRUTH-001 status flipped to `implemented`)
- `final_status: closed` once all five tasks report `status: completed` and `checkpoint/EXEC-TRUTH-REM` clears.

Do not close this casefile until all five derived tasks' evidence files validate under `scripts/audit/validate_evidence.py` **and** `scripts/dev/pre_ci.sh` returns 0.
