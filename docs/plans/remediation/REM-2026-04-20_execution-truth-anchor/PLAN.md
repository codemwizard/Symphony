# REM-2026-04-20_execution-truth-anchor — DRD Full Casefile

Severity: **L2 — Multi-gate** (schema hardening + trigger enforcement + constraint tightening + invariant registration + verifier integration)
Canonical reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
Policy: docs/operations/REMEDIATION_TRACE_WORKFLOW.md + `.agent/policies/debug-remediation-policy.md`

---

## DRD markers

- failure_signature: `PHASE2.PREAUTH.EXECUTION_RECORDS.TRUTH_ANCHOR_SEMANTIC_GAP`
- origin_task_id: `TSK-P2-PREAUTH-003-01, TSK-P2-PREAUTH-003-02`
- origin_gate_id: `checkpoint/EXEC-TRUTH`
- first_observed_utc: `2026-04-20T00:00:00Z`
- reporter: `mwiza` (user brief, Wave 3 audit)
- severity: `L2`
- repro_command: `DATABASE_URL=<url> bash scripts/db/verify_execution_truth_anchor.sh`
- verification_commands_run (audit phase):
  - `grep -n 'interpretation_version_id' schema/migrations/0118_create_execution_records.sql`
  - `grep -n 'execution_records_append_only' schema/migrations/*.sql || true`
  - `grep -n 'INV-EXEC-' docs/invariants/INVARIANTS_MANIFEST.yml || true`
  - `cat schema/migrations/MIGRATION_HEAD`
- final_status: `open` (pending closure by TSK-P2-PREAUTH-003-REM-01..REM-05, REM-05B, REM-04, REM-04B)

---

## Summary

Migration 0118 created `public.execution_records` as a nominal "execution truth anchor" but left it semantically broken on five dimensions below. Because 0118 is applied (`MIGRATION_HEAD=0130`) and **forward-only migrations are non-negotiable** (AGENTS.md "hard constraints"), all five gaps are closed via new migrations `0131`, `0132`, `0133` plus invariant registration and verifier wiring. No edit to 0118 is permitted.

This casefile decomposes into **seven derived tasks** (REM-01, REM-02, REM-03, REM-05, REM-05B, REM-04, REM-04B) and one sibling casefile stub (`REM-2026-04-20_execution-lifecycle`). REM-05/REM-05B and REM-04/REM-04B are path-authority splits per AGENTS.md: the non-suffixed half owns one role's surface, the `B` half owns the other. The sibling casefile handles execution lifecycle / retry / failure-state semantics which **must not** touch the append-only contract established here.

---

## Scope

In scope:
- `public.execution_records` schema hardening via forward migrations 0131, 0132, 0133.
- Registration of new invariant `INV-EXEC-TRUTH-001` with enforcement + verification.
- New verifier `scripts/db/verify_execution_truth_anchor.sh` + CI wiring.
- Temporal-binding trigger that re-resolves `interpretation_version_id` via `resolve_interpretation_pack(project_id, execution_timestamp)`.
- Verifier-integrity evidence fields (`verification_tool_version`, `verification_input_snapshot`, `verification_run_hash`).

Out of scope (explicit proof limitations):
- `execution_state` / `retry_count` / `failure_reason` / `adapter_invocation_id` columns — belong to the lifecycle casefile, **not** here. Mutable state on this table is forbidden once REM-03 lands.
- `factor_set_version`, `methodology_version`, `conversion_version`, `rounding_precision`, `adapter_id` FK, `instruction_id`, `calculation_context` on `evidence_nodes` — dependent on Factor/Unit Registry and active `adapter_registrations`, deferred to separate Phase 2 tracks.
- `interpretation_version_id` as a distinct surrogate on `interpretation_packs` parent table — user Q2 answer was option (a): FK target remains real PK `interpretation_pack_id`. Documented as naming quirk in invariant notes.
- Editing migration 0118 in any form.

---

## Boundary declaration (shared with REM-2026-04-20_execution-lifecycle)

1. `public.execution_records` is **append-only** from REM-03 forward. Mutable state on this table is a contract violation.
2. `execution_attempts` (to be introduced by the lifecycle casefile) is the **only** surface permitted to hold mutable lifecycle state.
3. Retries reuse `adapter_invocation_id` (lifecycle surface). They **never** mutate `execution_records`.
4. One completed adapter invocation resulting in a proven deterministic output emits exactly one `execution_records` row. Partial / failed / retrying invocations do not emit `execution_records` rows.
5. Any PR that violates (1)-(4) must be blocked by the verifier produced in REM-05.

---

## Gap enumeration (hypothesis → resolution)

| # | Hypothesis (confirmed gap) | Evidence in repo | Resolving task |
|---|---|---|---|
| H1 | `execution_records.interpretation_version_id` is nullable and carries no enforced FK-not-null contract | `schema/migrations/0118_create_execution_records.sql` line 11 | REM-02 |
| H2 | Determinism columns (`input_hash`, `output_hash`, `runtime_version`, `tenant_id`) are absent, so row replay is impossible | Same migration; no ALTER in 0119-0130 touches execution_records | REM-01 (expand) + REM-02 (contract) |
| H3 | No `BEFORE UPDATE OR DELETE` trigger; rows are mutable | `grep execution_records schema/migrations/*.sql` returns no trigger | REM-03 |
| H4 | No `UNIQUE(tenant_id, input_hash, interpretation_version_id, runtime_version)` determinism anchor; same input can yield multiple truths within a tenant | Same migration; no ADD CONSTRAINT UNIQUE in 0119-0130 | REM-02 |
| H5 | No `INV-EXEC-*` invariant registered; no integrity verifier; INV-175 covers a different scope (data_authority enum) | `docs/invariants/INVARIANTS_MANIFEST.yml` lines 1651-1668 | REM-04 + REM-05 |
| H6 | No temporal-binding enforcement; callers may pass a retroactively-resolved `interpretation_version_id` | Function `resolve_interpretation_pack(project_id, as_of)` exists (0116) but is not enforced at INSERT time on execution_records | REM-03 (second trigger) |

---

## Task DAG

```
TSK-P2-PREAUTH-003-02 (Wave 3 terminal)
        └── REM-01 (migration 0131: expand — nullable determinism columns)
                └── REM-02 (migration 0132: contract — NOT NULL + UNIQUE + FK NOT NULL)
                        └── REM-03 (migration 0133: append-only trigger + temporal-binding trigger)
                                └── REM-05 (verifier + smoke harness — DB_FOUNDATION)
                                        └── REM-05B (CI wiring into pre_ci.sh + run_invariants_fast_checks.sh — SECURITY_GUARDIAN)
                                                └── REM-04 (register INV-EXEC-TRUTH-001 in docs/invariants/** — INVARIANTS_CURATOR, fail-closed on REM-05 evidence)
                                                        └── REM-04B (register INV-EXEC-TRUTH-001 in docs/architecture/** — ARCHITECT)
                                                                └── checkpoint/EXEC-TRUTH-REM
```

Fail-closed sequencing: REM-04 only flips `INV-EXEC-TRUTH-001` status to `implemented` after REM-05 produces fresh verifier evidence carrying all integrity fields, and only after REM-05B wires the verifier into the CI gates. REM-04B registers the security-review surfaces once REM-04 has published the manifest block. If any upstream evidence is missing or stale, the downstream task blocks.

Path-authority rationale: Devin Review flagged that bundling verifier authorship (scripts/db/**) with CI wiring (scripts/dev/pre_ci.sh + scripts/audit/**) in a single task violated AGENTS.md because those surfaces belong to different owner roles. Similarly, bundling the docs/invariants/** registry with the docs/architecture/** threat-model + compliance-map surfaces crossed the INVARIANTS_CURATOR ↔ ARCHITECT boundary. Splitting REM-05 → REM-05 + REM-05B and REM-04 → REM-04 + REM-04B keeps every work item under one owner role. (REM-04B was initially authored against `docs/security/**` under SECURITY_GUARDIAN; Devin Review `BUG_pr-review-job-108a9b4113194ec09d57c8e6c3986cd1_0001` corrected the paths to `docs/architecture/**` where THREAT_MODEL.md and COMPLIANCE_MAP.md actually live, and the owner to ARCHITECT — see the REM-04B EXEC_LOG path-correction entry.)

Two-strike non-convergence trigger (per debug-remediation-policy §Severity Model): if REM-02 pre-condition (`SELECT COUNT(*) FROM execution_records WHERE any_new_column IS NULL` == 0 after backfill) fails on a second consecutive run, DRD lockout fires and `REM-02b` (backfill deep-dive) is opened automatically.

---

## Verification commands (casefile-level)

```bash
# Audit repro (no side effects)
grep -n 'interpretation_version_id' schema/migrations/0118_create_execution_records.sql | head -5 || exit 1
grep -n 'execution_records_append_only' schema/migrations/ 2>/dev/null | head -1 ; true
grep -n 'INV-EXEC-TRUTH-001' docs/invariants/INVARIANTS_MANIFEST.yml 2>/dev/null | head -1 ; true
test -f schema/migrations/MIGRATION_HEAD && cat schema/migrations/MIGRATION_HEAD || exit 1

# Closure verifier (runs after REM-05 lands)
test -x scripts/db/verify_execution_truth_anchor.sh && bash scripts/db/verify_execution_truth_anchor.sh > evidence/phase2/execution_truth_anchor.json || exit 1
```

---

## Rollback

Every forward migration in this casefile is reversible only by additional forward migrations (no `DROP TRIGGER`/`DROP COLUMN` at runtime). If the closure set must be reverted:
1. Author migration 0134 that drops the trigger and the NOT NULL / UNIQUE constraints (in that order).
2. Author migration 0135 that drops the determinism columns (last, only after downstream consumers confirmed gone).
3. Flip `INV-EXEC-TRUTH-001` status back to `in_progress` and file exception in `docs/security/EXCEPTION_REGISTER.yml`.
4. Re-open this casefile with `final_status: reopened` and bump the repro_command to include the rollback migrations.

---

## Proof guarantees

- Every resolving task emits a signed evidence JSON at `evidence/phase2/<task_slug>.json` carrying `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`.
- Every resolving task has at least one negative test written **before** acceptance criteria.
- The sole append-only contract on `execution_records` is enforced at the DB trigger layer, not at the application layer.
- Temporal binding is enforced at INSERT time via `resolve_interpretation_pack(project_id, execution_timestamp)` mismatch raising an exception.
- Verifier script itself is content-hashed into each run's evidence so a compromised verifier cannot silently emit PASS.

## Proof limitations

- Backfill policy for pre-existing `execution_records` rows is resolved inside REM-02 at execution time (expected: 0 rows; if non-zero, fork to REM-02b).
- FK target remains `interpretation_packs(interpretation_pack_id)` — child column name `interpretation_version_id` is preserved for historical continuity and documented as a naming quirk in INV-EXEC-TRUTH-001 notes.
- Lifecycle / retry / failure-state semantics are intentionally NOT addressed here. The sibling casefile `REM-2026-04-20_execution-lifecycle` owns those.

---

## Approval (regulated surface)

Casefile authored on branch `devin/<ts>-wave3-truth-anchor-rem`. Approval metadata sidecars are produced per derived task under `evidence/phase2/approvals/TSK-P2-PREAUTH-003-REM-<NN>.json` before any status leaves `planned`.
