# REM-2026-04-21_entity-binding-structural-enforcement — DRD Casefile STUB

**Status:** STUB (opened, scoped, no derived tasks yet)
**Opened by:** Wave 4 authority-binding closure requirement (reviewer audit on PR #192, 2026-04-21)
**Severity placeholder:** L2 (cross-entity replay is a high-impact authorisation failure mode)
**Canonical reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Policy:** docs/operations/REMEDIATION_TRACE_WORKFLOW.md + `.agent/policies/debug-remediation-policy.md`
**Implementing wave:** **Wave 5** (must land before the state-machine service that consumes `enforce_authority_transition_binding` ships — see §Wave assignment).

---

## DRD markers

- failure_signature: `PHASE2.PREAUTH.AUTHORITY_BINDING.ENTITY_STRUCTURAL_ENFORCEMENT_MISSING`
- origin_task_id: `TSK-P2-PREAUTH-004-03` (declared `proof_limitation` — insert-time entity coherence between `policy_decisions` and `execution_records`)
- origin_gate_id: (no active gate; design-time audit)
- first_observed_utc: `2026-04-21T00:00:00Z`
- reporter: `mwiza` (user reviewer critique on Wave 4 design, session 2026-04-21)
- severity: `L2`
- repro_command: _(not yet defined; to be assigned when the first derived task lands. The negative test shape: insert a `policy_decisions` row whose `entity_type`/`entity_id` diverges from the bound `execution_records` row; expect SQLSTATE rejection at INSERT time, not only at verify time.)_
- final_status: `open_stub`

---

## What is declared and what is deferred

### Declared and enforced today (Wave 4)

`TSK-P2-PREAUTH-004-03` delivers entity binding through **four cryptographic + relational layers** that foreclose the cross-entity replay path at verify time:

1. `policy_decisions.execution_id` is FK-equality-bound to the `execution_records` row under evaluation (not merely FK-existence).
2. `execution_records` existence is checked before the decision is consulted.
3. `decision_hash = sha256(canonical_json(decision_payload))` is recomputed externally (bash + `jq`/python, not a DB helper) against the canonical RFC 8785 JCS serialisation of the payload reconstructed from the row; `entity_type` and `entity_id` are inside that payload, so tampering either column yields a hash mismatch.
4. `UNIQUE (execution_id, decision_type)` prevents a second decision of the same type from being stapled to the same execution.

The `decision_hash` → row-reconstruction contract is pinned verbatim in `docs/plans/phase2/TSK-P2-PREAUTH-004-01/PLAN.md` §"Payload → Column Mapping (NON-NEGOTIABLE)".

### Deferred and owned by this casefile (Wave 5)

`execution_records` does NOT today carry `entity_type` / `entity_id` columns (verified across migrations 0118, 0131, 0132, 0133). Because those columns do not exist on the bound surface, the Wave 4 design cannot implement a structural (schema-level) check at `policy_decisions` INSERT time that reads the entity identity from `execution_records` and rejects a mismatch.

This means Wave 4 relies on **cryptographic enforcement** (hash recompute detects tampering) rather than **structural enforcement** (schema constraint prevents misuse). Reviewer audit 2026-04-21 correctly flagged the distinction: hash-based detection requires every payload-reconstruction code path to use the same canonical-JSON function. A future caller that reconstructs payload differently — partial reconstruction, alternate serialisation, missing entity fields — can produce false positives or false negatives.

This is not a bug in Wave 4; it is a declared, tracked limitation. This casefile exists to close it.

---

## Wave assignment

**Implementing wave: Wave 5.**

Rationale:

- Wave 5 materialises the state-machine service layer that calls `enforce_authority_transition_binding(p_execution_id, p_to_state_rule_id)` — the function delivered by TSK-P2-PREAUTH-004-03.
- For that service call to be structurally (not only cryptographically) safe, `execution_records` must carry `entity_type` and `entity_id` **before** the state machine begins operating against real transitions.
- Deferring to Wave 6 would mean Wave 5 ships with the state machine relying exclusively on cryptographic enforcement — extending the accepted-risk window by an entire wave without architectural justification.
- Therefore: the derived tasks under this casefile are a **Wave 5 prerequisite bundle** (shaped to land as the first tasks in Wave 5, ahead of the state-machine tasks proper).

The Wave 5 task list will accordingly begin with the derived tasks authored under this casefile, not with state-machine tasks. The state-machine tasks in Wave 5 depend on these.

---

## Non-interference declaration

> **Derived tasks under this casefile MUST NOT weaken the Wave 4 authority-binding contract.**

Concretely:

1. `policy_decisions` append-only contract (`enforce_policy_decisions_append_only`, SQLSTATE `GF061`, `SECURITY DEFINER SET search_path = pg_catalog, public`, `REVOKE ALL ON FUNCTION ... FROM PUBLIC`) is untouchable. No `UPDATE`/`DELETE` verbs on `policy_decisions` are introduced under this casefile.
2. The `decision_hash = sha256(canonical_json(decision_payload))` canonicalisation rule (RFC 8785 JCS) and its payload field set are unchanged. Adding `entity_type`/`entity_id` columns to `execution_records` does NOT change what is hashed for `policy_decisions` — those columns continue to live on `policy_decisions` and continue to be in the hashed payload.
3. The semantic invariant `INV-AUTH-TRANSITION-BINDING-01` (and its numeric registry ID assigned in 004-03 IMPLEMENT) is preserved verbatim. This casefile may add a **second, complementary invariant** (e.g. `INV-AUTH-ENTITY-COHERENCE-01`) that states "for every `policy_decisions` row, `execution_records.entity_*` equals `policy_decisions.entity_*`"; it must not redefine or subsume the existing one.
4. `rule_priority` tiebreak semantics on `state_rules` (lower `state_rule_id` UUID wins on equal priority, negative priorities valid as deny rules) are unchanged.
5. Migrations under this casefile are expand-only, forward-only. No column drops, no destructive ALTERs on existing tables. Backfill strategy for the new `entity_type`/`entity_id` columns on `execution_records` is required before the `NOT NULL` constraint can be applied (see §Provisional scope).

Any PR arriving under this casefile that violates items 1–5 is rejected at review.

---

## Two candidate approaches (to be resolved during ADR authoring)

Both close the gap; either is acceptable. The ADR associated with the first derived task chooses one and documents why.

### Option A — Extend `execution_records` with entity columns + insert-time coherence trigger

- Migration (forward-only, expand-only):
  - `ALTER TABLE execution_records ADD COLUMN entity_type TEXT`; `ADD COLUMN entity_id UUID`.
  - Backfill step derives `entity_type`/`entity_id` from the bound `policy_decisions` row (if one exists) or defaults per the lifecycle rule (if no decision exists yet).
  - `ALTER TABLE execution_records ALTER COLUMN entity_type SET NOT NULL`; same for `entity_id`. Applied in a subsequent migration after the backfill is complete.
- New trigger on `policy_decisions` INSERT: `enforce_policy_decisions_entity_coherence` raises a named SQLSTATE (candidate: `GF062`, distinct from `GF061` append-only and distinct from regex CHECK codes) if `policy_decisions.entity_type` ≠ `execution_records.entity_type` or `policy_decisions.entity_id` ≠ `execution_records.entity_id` for the bound `execution_id`.
- Pros: structural enforcement at the same DB layer as the existing append-only trigger; single transaction rejects at INSERT; no service-layer dependency.
- Cons: requires a backfill migration with careful ordering; grows the truth-anchor surface with two columns that are also (redundantly) on `policy_decisions`.

### Option B — Enforce binding at the state-transition service layer

- No schema change to `execution_records`.
- The state-machine service, before calling `enforce_authority_transition_binding(...)`, does a SELECT-compare on the bound `policy_decisions` row's `entity_type`/`entity_id` against the transition's declared entity (which the service holds in application memory from the state graph), and rejects in-service if mismatched.
- Pros: no schema churn, no backfill, closes the gap logically.
- Cons: enforcement is now application-side. A second caller that bypasses the service (direct SQL call to `enforce_authority_transition_binding`, or a future adapter that calls the function directly) is unprotected. Weaker than Option A by one layer.

### Decision criterion

If a regulator or audit control requires that the database itself enforces entity coherence irrespective of caller identity, Option A is mandatory. Otherwise, either is defensible. The ADR authored with the first derived task will document the choice.

---

## Why this is a stub and not N tasks (yet)

Opening a stub now rather than drafting derived tasks is deliberate:

- The ADR that picks Option A vs Option B must be authored before the first derived task, because the task shapes differ materially.
- Wave 5 scope is not yet fully drafted; these tasks must fit the Wave 5 DAG alongside state-machine tasks and cannot be authored in a vacuum.
- `execution_records` backfill strategy (Option A) depends on production row count at Wave 5 kickoff, which is not known today.
- Single-responsibility discipline (`TASK_CREATION_PROCESS.md §Anti-patterns`) prohibits drafting tasks that cannot yet be executed.

This stub exists so that:

- the deferred gap is publicly pinned and grep-able as an open item;
- the reviewer audit finding from 2026-04-21 has a named tracked owner (this casefile) rather than a loose "declared limitation" note in a PLAN;
- Wave 5 cannot open without a concrete task list that begins with closure of this casefile.

---

## Provisional scope (pending activation at Wave 5 kickoff)

In scope **when derived tasks are authored** (not before):

- ADR: `docs/decisions/ADR-XXXX-entity-binding-structural-enforcement-choice.md` — selects Option A or Option B with rationale.
- If Option A:
  - Migration (expand): add `entity_type TEXT`, `entity_id UUID` to `execution_records` (nullable initially).
  - Backfill migration: populate `entity_type`/`entity_id` from bound `policy_decisions` rows where present; document default strategy for pre-decision `execution_records` rows.
  - Migration (constrain): `SET NOT NULL` on both columns after backfill completes.
  - Trigger: `enforce_policy_decisions_entity_coherence` (SECURITY DEFINER hardened, explicit EXECUTE posture, named SQLSTATE).
  - Verifier: positive path + two negative paths (type mismatch, id mismatch) asserting SQLSTATE explicitly; wired into `scripts/audit/run_invariants_fast_checks.sh`.
  - Registration: `INV-AUTH-ENTITY-COHERENCE-01` in `INVARIANTS_MANIFEST.yml` + `INVARIANTS_IMPLEMENTED.md` with numeric ID on registration.
  - Evidence: `evidence/phase2/tsk_p2_wave5_entity_coherence.json`.
- If Option B:
  - Service-layer check in the Wave 5 state-machine task (not a separate DB task).
  - Integration test that bypasses the service layer and calls `enforce_authority_transition_binding` directly with a cross-entity replay payload; expected outcome: test is **informational** (demonstrates the gap Option B leaves open) rather than a hard fail. The casefile documents this as an accepted residual risk.

Activation pre-conditions (all must hold before derived tasks are opened):

1. Wave 4 closed (all three of 004-01, 004-02, 004-03 at `status: implemented` on main).
2. ADR for Option A vs Option B authored and approved.
3. Wave 5 task DAG drafted, with derived tasks under this casefile as the first nodes.
4. (Option A only) Backfill strategy for existing `execution_records` rows explicitly documented.

---

## Out of scope

- Any change to the Wave 4 `decision_hash` payload contract.
- Any change to `policy_decisions` append-only semantics or SQLSTATE.
- Any rework of `state_rules` rule-priority tiebreak semantics.
- Retroactive modification of existing 004-01/004-02/004-03 migrations — all changes here are expand-only in new migrations.

---

## Links

- Sibling Wave 4 contract: `docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md`
- Sibling authority-binding invariant task: `docs/plans/phase2/TSK-P2-PREAUTH-004-03/PLAN.md` (declares the proof_limitation this casefile closes)
- Reviewer audit thread (session 2026-04-21): user critique referencing "cryptographic enforcement is not structural enforcement" distinction; rebuttal + concession captured in session log.
- Sibling lifecycle casefile (parallel stub pattern): `docs/plans/remediation/REM-2026-04-20_execution-lifecycle/`
