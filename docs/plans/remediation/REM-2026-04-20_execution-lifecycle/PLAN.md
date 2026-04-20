# REM-2026-04-20_execution-lifecycle — DRD Casefile STUB

**Status:** STUB (opened, scoped, no derived tasks yet)
**Opened by:** sibling closure requirement of REM-2026-04-20_execution-truth-anchor
**Severity placeholder:** L2 (multi-table + state-machine + retry semantics)
**Canonical reference:** docs/operations/AI_AGENT_OPERATION_MANUAL.md
**Policy:** docs/operations/REMEDIATION_TRACE_WORKFLOW.md + `.agent/policies/debug-remediation-policy.md`

---

## DRD markers

- failure_signature: `PHASE2.PREAUTH.EXECUTION_LIFECYCLE.RETRY_STATE_MODEL_MISSING`
- origin_task_id: `TSK-P2-PREAUTH-003-01, TSK-P2-PREAUTH-003-02` (via sibling audit)
- origin_gate_id: (no active gate; pre-implementation)
- first_observed_utc: `2026-04-20T00:00:00Z`
- reporter: `mwiza` (user brief, Wave 3 audit — user's 5-point HOLD, points 1-3 which belong here rather than in the truth-anchor casefile)
- severity: `L2`
- repro_command: _(not yet defined; to be assigned when the first derived task lands)_
- final_status: `open_stub`

---

## Boundary declaration (non-interference — shared with REM-2026-04-20_execution-truth-anchor)

> **This system MUST NOT touch the `execution_records` append-only contract.**

Concretely:

1. `public.execution_records` is governed by `INV-EXEC-TRUTH-001` from the sibling casefile and is **append-only** via `execution_records_append_only_trigger` (installed by migration 0133). Any derived task under this lifecycle casefile that issues `ALTER TABLE public.execution_records ...`, `UPDATE public.execution_records ...`, `DELETE FROM public.execution_records ...`, or `DROP TRIGGER execution_records_append_only_trigger` is a boundary violation and must be blocked in code review.
2. The **only** surface permitted to carry mutable lifecycle state (`INITIATED`, `RETRYING`, `FAILED`, `PARTIAL`, `COMPLETED`, etc.) is a new table, `public.execution_attempts` (exact shape TBD). This casefile owns that table's creation and all mutation verbs on it.
3. Retries reuse `adapter_invocation_id` as a logical-invocation surrogate. This column lives on `execution_attempts`, **never** on `execution_records`. One completed invocation that produces a proven deterministic output emits exactly one `execution_records` row (the truth); the preceding/concurrent attempt rows remain on `execution_attempts`.
4. A state-transition function (pattern parallel to `enforce_transition_state_rules` already present in migration 0120 per INV-176) governs legal moves in the `execution_attempts` state graph. Illegal transitions raise an exception.
5. The lifecycle verifier emitted by this casefile will cross-check that, for every `execution_records` row, there exists at least one terminal-state `execution_attempts` row linked by `adapter_invocation_id`, and the reverse is not required (there can be attempts that never produce a truth row).

Any PR arriving under this casefile that violates items 1-5 is rejected at review.

---

## Why this is a stub and not five tasks (yet)

The user-approved decision (Option B, session 2026-04-20) separated the three architectural jobs that were initially conflated in the Wave 3 remediation design:

| Layer | Table | Mutability | Casefile |
|---|---|---|---|
| Execution Truth | `public.execution_records` | append-only | REM-2026-04-20_execution-truth-anchor (active; five tasks REM-01..REM-05) |
| Execution Attempts | `public.execution_attempts` (TBD) | state-machine | this stub (no derived tasks yet) |
| Invocation Identity | `adapter_invocation_id` (on attempts) | surrogate | this stub (no derived tasks yet) |

Opening a stub now rather than five concrete tasks is deliberate:

- The truth-anchor casefile must land first so that the non-interference boundary is legally enforceable at the DB-trigger layer before lifecycle DDL can be proposed.
- `adapter_invocation_id` semantics are dependent on the active `adapter_registrations` surface (Phase 2 blueprint Step 11). Without that surface, the retry-key FK would have no parent to point at.
- Single-responsibility discipline (`TASK_CREATION_PROCESS.md §Anti-patterns`) prohibits drafting tasks that can't yet be executed.

This stub exists so that:
- the boundary declaration is publicly pinned and grep-able;
- any future drift or proposed code touching `execution_records` mutation has a named authoritative counter-document;
- the sibling truth-anchor PR can legitimately close without leaving the lifecycle gap unclaimed.

---

## Provisional scope (pending activation)

In scope **when derived tasks are authored** (not before):

- Forward migration creating `public.execution_attempts` with a state column governed by a state-transition trigger pattern mirroring INV-176 (`enforce_transition_state_rules`).
- `adapter_invocation_id UUID NOT NULL` on `execution_attempts`, with uniqueness constraint scoped appropriately (likely `UNIQUE(adapter_invocation_id, attempt_number)`).
- `failure_reason TEXT NULL`, `retry_count INT NOT NULL DEFAULT 0`, `previous_attempt_id UUID NULL` with FK-to-self for retry chains.
- `execution_attempts_completed_link_check()` trigger that, on a state transition to `COMPLETED`, asserts that the matching `execution_records` row exists and carries the same `adapter_invocation_id`. Non-existence does not block state transition (the truth write is separate); mismatch does.
- Lifecycle-layer verifier `scripts/db/verify_execution_lifecycle.sh` + CI wiring.
- Invariant registration `INV-EXEC-LIFECYCLE-001` or similar, keyed to state-transition correctness and retry idempotency.

Out of scope (forever, per boundary declaration):
- Any DDL, trigger, function, or state change targeting `public.execution_records`.
- Any modification of `INV-EXEC-TRUTH-001`.
- Merging execution-truth and execution-lifecycle semantics into a single table.

---

## Activation pre-conditions

This stub converts to an active casefile with derived tasks **only when all of the following hold**:

1. `REM-2026-04-20_execution-truth-anchor` final_status is `closed` (all five tasks `completed`, `INV-EXEC-TRUTH-001` status=`implemented`, `checkpoint/EXEC-TRUTH-REM` cleared).
2. `adapter_registrations` table is active (Phase 2 blueprint Step 11) so that `adapter_invocation_id` has an FK parent, OR the retry-key is explicitly scoped to be tenant-local and FK-less as an expand-phase stage.
3. User approval on the draft task DAG (expected: five to seven tasks in the `execution_attempts` + state machine + retry + lifecycle verifier + invariant registration shape).
4. An approved ADR in `docs/decisions/` documenting the `execution_records ↔ execution_attempts` boundary contract. The boundary contract is the regulator-proofing layer the user flagged as the highest-value follow-on during the Wave 3 audit; it is a pre-condition for this stub to activate, not a deliverable of it.

Until all four conditions hold, this file remains a stub and any PR that adds derived tasks under it is rejected at review.

---

## Non-interference verifier (to be added once this stub activates)

A lightweight grep-based verifier will be wired into `scripts/audit/run_invariants_fast_checks.sh` that fails CI if any PR diff contains one of the following forbidden patterns against `public.execution_records`:

- `UPDATE public.execution_records`
- `DELETE FROM public.execution_records`
- `ALTER TABLE public.execution_records`
- `DROP TRIGGER execution_records_append_only_trigger`

until the verifier gains an explicit approval-metadata override (reserved for future truth-anchor-local migrations). That non-interference check is **not** the responsibility of this stub; it belongs to the first derived task opened under this casefile, listed above as "Activation pre-conditions #4".

---

## Proof guarantees (provisional, to be refined on activation)

- Lifecycle state transitions are DB-trigger-enforced, not application-layer best-effort.
- Retries are idempotent under `adapter_invocation_id`; two successful retries do not produce two `execution_records` truth rows.
- The lifecycle verifier cross-checks the link from `execution_records` to at least one terminal `execution_attempts` row; mismatch fails CI.
- Zero mutation verbs against `public.execution_records` are allowed from this casefile.

## Proof limitations

- This is a stub; no verifier is emitted yet.
- `adapter_registrations` dependency means activation timing is gated on an adjacent Phase 2 track.
- The state graph itself is not yet specified; ADR authoring is part of activation pre-condition #4.
