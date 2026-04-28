# REM-2026-04-21_entity-binding-structural-enforcement — EXEC_LOG (STUB)

Append-only. Do not retroactively rewrite entries.

---

## 2026-04-21T00:00:00Z — Stub opened

- **Actor:** supervisor / devin-a8f1396e6bde4a80bf70bae475972a98
- **Reporter:** mwiza (reviewer audit on Wave 4 design, session 2026-04-21, rebuttal-and-concession cycle)
- **failure_signature:** `PHASE2.PREAUTH.AUTHORITY_BINDING.ENTITY_STRUCTURAL_ENFORCEMENT_MISSING`
- **Severity:** L2 (provisional)
- **Origin task:** `TSK-P2-PREAUTH-004-03` declared the insert-time entity-coherence gap as a named `proof_limitation`. Reviewer audit reframed the gap as a live risk requiring a tracked follow-up rather than a standalone note. This casefile is the tracked follow-up.
- **Implementing wave:** **Wave 5** (pinned in PLAN.md §Wave assignment).
- **Non-interference boundary:** explicitly declared in PLAN.md §Non-interference declaration. This casefile MUST NOT weaken the Wave 4 authority-binding contract, the `policy_decisions` append-only trigger, the `decision_hash = sha256(canonical_json(...))` payload contract, or the `state_rules` rule-priority tiebreak.
- **Derived tasks:** NONE. Stub only.
- **Activation pre-conditions:**
  1. Wave 4 closed (004-01, 004-02, 004-03 all at `status: implemented` on main).
  2. ADR for Option A (extend `execution_records` + insert-time coherence trigger) vs Option B (service-layer enforcement) authored and approved.
  3. Wave 5 task DAG drafted, with derived tasks under this casefile as the first nodes (state-machine tasks in Wave 5 depend on these).
  4. (Option A only) Backfill strategy for existing `execution_records` rows explicitly documented.
- **final_status:** `open_stub`

---

## (Future entries)

- Wave 4 closure confirmation (all three IMPLEMENT PRs merged) — triggers pre-condition 1.
- ADR authoring — Option A vs Option B decision, with rationale. Link to `docs/decisions/ADR-XXXX-*.md` once authored.
- Wave 5 task DAG draft linked — triggers pre-condition 3.
- First derived task id assigned (suggested pattern: `TSK-P2-STATEMACHINE-005-00-entity-coherence-prereq`), with its own failure_signature.
- `INV-AUTH-ENTITY-COHERENCE-01` (or equivalent) registration in `INVARIANTS_MANIFEST.yml` once chosen.
- Non-interference verifier wiring into `scripts/audit/run_invariants_fast_checks.sh`.
- `final_status: active` once derived tasks are authored and approved.

Do not advance `final_status` beyond `open_stub` until all four activation pre-conditions are satisfied.
