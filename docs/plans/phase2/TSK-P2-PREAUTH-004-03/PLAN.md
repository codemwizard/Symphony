# TSK-P2-PREAUTH-004-03 PLAN — Register and enforce INV-AUTH-TRANSITION-BINDING-01

Task: TSK-P2-PREAUTH-004-03
Owner: INVARIANTS_CURATOR
Depends on: TSK-P2-PREAUTH-004-00, TSK-P2-PREAUTH-004-01, TSK-P2-PREAUTH-004-02
Blocks: (Wave 5 state-machine wiring, tracked as a follow-up)
failure_signature: PHASE2.PREAUTH.AUTHORITY_TRANSITION_BINDING.INVARIANT_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
wave_reference: Wave 4 — Authority Binding
origin_task_id: TSK-P2-PREAUTH-004-03
repro_command: bash scripts/db/verify_authority_transition_binding.sh
verification_commands_run: bash scripts/db/verify_authority_transition_binding.sh
final_status: PLANNED

---

## Objective

Seal the Wave 4 cryptographic truth anchor by installing invariant `INV-AUTH-TRANSITION-BINDING-01` exactly as the Wave 4 contract (`docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md`, section *Authority-Transition Binding Invariant*) pins it. The invariant states: **any authority-bearing state transition applied via `execution_records` MUST reference, in the transition payload, exactly one `policy_decisions.policy_decision_id` whose `entity_type`, `entity_id`, and `execution_id` match the transition's entity and execution. Transitions lacking this reference, or referencing a decision bound to a different entity or execution, are rejected.**

This task authors the enforcement function, installs it in migration `0136`, registers the invariant in the manifest and implemented registries, authors the verifier that exercises four scenarios (one positive, three negative), and emits evidence. It does not wire the function into a Wave 5 trigger point (that is Wave 5's responsibility) and does not verify signature authenticity (public-key resolution is a later wave; this limitation is declared explicitly).

---

## Architectural Context

Wave 4 produces three cooperating artefacts:

| Task | Role in the anchor |
|---|---|
| 004-01 | `policy_decisions` row type: append-only, FK-bound, hash- and signature-committed. Inert without a binding. |
| 004-02 | `state_rules` row type: rule configuration with `rule_priority` total order. Inert without a consumer. |
| 004-03 (this task) | The binding: a DB function + verifier that ties a `policy_decisions` row to an `execution_records` transition, asserting the cross-entity-replay guard. |

Without 004-03, a row in `policy_decisions` is just a self-declared hash. With 004-03, the hash is bound to a specific execution on a specific entity, and any consumer (Wave 5 state machine, audit scripts, forensic tooling) can call `enforce_authority_transition_binding` and get a cryptographically sound answer.

### How the three Wave 4 audit fixes close

1. **Cryptographic binding.** This task's verifier recomputes `sha256(canonical_json(decision_payload))` and asserts byte-equality with the stored `decision_hash`. Mismatch is a verifier failure (V4). This makes `decision_hash` load-bearing at verify time, not just at insert time.

2. **Entity context.** The enforcement function SELECTs the row, then asserts `entity_type` and `entity_id` match the corresponding fields inside the canonical payload. The verifier also asserts the row's `entity_id` matches the `entity_id` of the bound `execution_records` row. Cross-entity replay is blocked in two places (DB function + verifier) because the two surfaces protect against different threats: the DB function is invoked at transition time, the verifier is invoked at audit time.

3. **Rule priority.** Not in this task. Lives on `state_rules` (004-02).

### Signature authenticity gap (declared)

Signature authenticity verification (`ed25519_verify(signature, decision_hash, public_key)`) requires a public-key resolution layer that does not exist in Wave 4. This task declares the gap as a named `proof_limitation` and leaves `signature` column validation at format-only. A future wave that lands the key table will extend this verifier with the missing step.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-004-00`, `TSK-P2-PREAUTH-004-01`, `TSK-P2-PREAUTH-004-02` are all merged.
- [ ] `schema/migrations/MIGRATION_HEAD` reads `0135` at the start of this task.
- [ ] `public.policy_decisions` and `public.state_rules` exist.
- [ ] `public.execution_records` has `entity_type` and `entity_id` populated on every row that represents an authority-bearing transition (or the verifier tolerates rows that lack these fields as "not authority-bearing" and skips them with a recorded count).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `schema/migrations/0136_enforce_authority_transition_binding.sql` | CREATE | Install the enforcement function with SECURITY DEFINER hardening. |
| `schema/migrations/MIGRATION_HEAD` | MODIFY | Advance head from `0135` to `0136`. |
| `docs/invariants/INVARIANTS_MANIFEST.yml` | MODIFY | Register `INV-AUTH-TRANSITION-BINDING-01` with enforcement, verification, and evidence paths. |
| `docs/invariants/INVARIANTS_IMPLEMENTED.md` | MODIFY | Append a row for `INV-AUTH-TRANSITION-BINDING-01`; status starts as `planned` and flips to `implemented` only after fresh evidence. |
| `scripts/db/verify_authority_transition_binding.sh` | CREATE | Exercises V1, V2, V3, V4; emits evidence. |
| `evidence/phase2/tsk_p2_preauth_004_03.json` | CREATE | Emitted by the verifier. |
| `tasks/TSK-P2-PREAUTH-004-03/meta.yml` | CREATE | This task's meta per Task Creation Process §2 Step 4. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-03/PLAN.md` | CREATE | This document. |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-03/EXEC_LOG.md` | CREATE | Log the task authorship. |

Any file modified that is not on this list => FAIL_REVIEW.

---

## Stop Conditions

- **If migration 0136 authors the enforcement function without `SECURITY DEFINER` or without `SET search_path = pg_catalog, public`** → STOP (AGENTS.md hard constraint).
- **If the verifier does not recompute `sha256(canonical_json(decision_payload))`** → STOP (failing open on hash integrity; defect Wave 4 was supposed to close).
- **If the verifier does not assert `(entity_type, entity_id)` columns match payload** → STOP (cross-entity replay passes).
- **If the invariant is marked `status=implemented` without fresh `evidence/phase2/tsk_p2_preauth_004_03.json` (`run_id` or `git_sha` not matching HEAD)** → STOP.
- **If any `ALTER TABLE` targets an applied migration (0001-0135)** → STOP.
- **If any of V1, V2, V3, V4 is omitted** → STOP.

---

## Enforcement Function (authoritative for migration 0136)

```
CREATE OR REPLACE FUNCTION public.enforce_authority_transition_binding(
  p_execution_id         uuid,
  p_policy_decision_id   uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_pd_execution_id  uuid;
  v_pd_entity_type   text;
  v_pd_entity_id     uuid;
  v_er_entity_type   text;
  v_er_entity_id     uuid;
  v_payload_entity_type text;
  v_payload_entity_id   uuid;
BEGIN
  SELECT execution_id, entity_type, entity_id
    INTO v_pd_execution_id, v_pd_entity_type, v_pd_entity_id
    FROM public.policy_decisions
    WHERE policy_decision_id = p_policy_decision_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = format('authority_transition_binding: no policy_decision row for policy_decision_id=%s', p_policy_decision_id);
  END IF;

  SELECT entity_type, entity_id
    INTO v_er_entity_type, v_er_entity_id
    FROM public.execution_records
    WHERE execution_id = p_execution_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = format('authority_transition_binding: no execution_records row for execution_id=%s', p_execution_id);
  END IF;

  IF v_pd_execution_id IS DISTINCT FROM p_execution_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'authority_transition_binding: execution_id mismatch';
  END IF;

  -- Canonical payload entity fields live inside the payload JSON attached to the
  -- policy_decisions row (set_on insert by the adapter). The function resolves
  -- them via a repo-standard accessor and asserts column-vs-payload match.
  SELECT p.entity_type, p.entity_id
    INTO v_payload_entity_type, v_payload_entity_id
    FROM public.policy_decisions_payload_view p
    WHERE p.policy_decision_id = p_policy_decision_id;

  IF v_payload_entity_type IS DISTINCT FROM v_pd_entity_type
     OR v_payload_entity_id   IS DISTINCT FROM v_pd_entity_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'authority_transition_binding: entity_type or entity_id mismatch with payload';
  END IF;
END;
$$;
```

`policy_decisions_payload_view` is a repo-standard helper view that projects `entity_type` and `entity_id` from the canonical payload JSON; its definition lands in the same migration 0136 file or is referenced from a Wave-3 helper view if one already exists. If the view is missing at implement time, the implementer adds its definition to 0136 with the same SECURITY DEFINER hardening posture as the function. The view is read-only.

---

## Verifier Contract (authoritative for `scripts/db/verify_authority_transition_binding.sh`)

The verifier runs four scenarios. Every scenario must produce a deterministic outcome.

| Scenario | Setup | Action | Expected | Proof recorded in evidence |
|---|---|---|---|---|
| V1 (positive) | Insert one `execution_records` row with `entity_type=E`, `entity_id=X`. Insert one `policy_decisions` row bound to that execution with `entity_type=E`, `entity_id=X`, and `decision_hash = sha256(canonical_json(payload))`. | Call `enforce_authority_transition_binding(execution_id, policy_decision_id)`. | No exception. | `scenarios_passed` includes `V1`. |
| V2 (cross-entity reject) | Insert an `execution_records` row with `entity_id=X`. Insert a `policy_decisions` row bound to that execution but with `entity_id=Y`. | Call the function. | `RAISE EXCEPTION ... ERRCODE = '22023'`. | `scenarios_passed` includes `V2`; the raised SQLSTATE is recorded in `command_outputs`. |
| V3 (missing decision reject) | Do not insert a `policy_decisions` row. | Call the function with a random uuid as `p_policy_decision_id`. | `RAISE EXCEPTION ... ERRCODE = 'P0002'`. | `scenarios_passed` includes `V3`. |
| V4 (hash mismatch reject) | Insert a `policy_decisions` row whose stored `decision_hash` is `sha256("tamper")` while the true `sha256(canonical_json(payload))` differs. | Verifier recomputes `sha256(canonical_json(payload))` from the row and compares against stored `decision_hash`. | Recompute mismatches stored; verifier records V4 passed. | `scenarios_passed` includes `V4`; both hashes are recorded (`observed_hashes`). |

Verifier emits `evidence/phase2/tsk_p2_preauth_004_03.json` with `status=PASS` if and only if all four scenarios produce their expected outcomes. Any deviation flips `status=FAIL` and the verifier exits non-zero.

Verifier must use savepoints so V1–V4 can run against the same database without polluting state. Verifier must `set -euo pipefail` at the top and use `|| exit 1` on every `psql` invocation whose failure is not itself the scenario's expected outcome.

---

## Registry Contract

### `docs/invariants/INVARIANTS_MANIFEST.yml`

Append a new entry:

```yaml
- id: INV-AUTH-TRANSITION-BINDING-01
  wave: 4
  statement: >-
    Any authority-bearing state transition applied via execution_records
    MUST reference, in the transition payload, exactly one
    policy_decisions.policy_decision_id whose entity_type, entity_id,
    and execution_id match the transition's entity and execution.
    Transitions lacking this reference, or referencing a decision bound
    to a different entity or execution, are rejected.
  owner: INVARIANTS_CURATOR
  enforcement:
    function: public.enforce_authority_transition_binding(uuid, uuid)
    migration: schema/migrations/0136_enforce_authority_transition_binding.sql
  verification:
    script: scripts/db/verify_authority_transition_binding.sh
  evidence:
    path: evidence/phase2/tsk_p2_preauth_004_03.json
  proof_limitations:
    - "Signature authenticity is not verified (public-key resolution deferred to a later wave)"
  status: planned
```

### `docs/invariants/INVARIANTS_IMPLEMENTED.md`

Append a row: `| INV-AUTH-TRANSITION-BINDING-01 | Wave 4 | planned | evidence/phase2/tsk_p2_preauth_004_03.json |`. Flip status to `implemented` only when evidence exists and its `git_sha` matches HEAD.

---

## Implementation Steps

### Step 1: Author migration 0136 with the enforcement function

- [ID tsk_p2_preauth_004_03_work_item_01] Create `schema/migrations/0136_enforce_authority_transition_binding.sql` with the function above. SECURITY DEFINER. `SET search_path = pg_catalog, public`. No `BEGIN;` / `COMMIT;` (B5). No other DDL.
- **Done when:** `grep -q 'CREATE OR REPLACE FUNCTION public.enforce_authority_transition_binding' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q 'SECURITY DEFINER' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q 'SET search_path = pg_catalog, public' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q "'22023'" schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q "'P0002'" schema/migrations/0136_enforce_authority_transition_binding.sql` exits 0.

### Step 2: Advance MIGRATION_HEAD

- [ID tsk_p2_preauth_004_03_work_item_02] Write the exact token `0136` to `schema/migrations/MIGRATION_HEAD`.
- **Done when:** `grep -Fxq '0136' schema/migrations/MIGRATION_HEAD` exits 0.

### Step 3: Register the invariant

- [ID tsk_p2_preauth_004_03_work_item_03] Append the manifest entry to `docs/invariants/INVARIANTS_MANIFEST.yml` and the row to `docs/invariants/INVARIANTS_IMPLEMENTED.md`. Status is `planned` until evidence is fresh. The implemented-registry flip to `implemented` is a separate commit that runs after the verifier has emitted evidence at the same HEAD SHA.
- **Done when:** `grep -q 'INV-AUTH-TRANSITION-BINDING-01' docs/invariants/INVARIANTS_MANIFEST.yml && grep -q 'INV-AUTH-TRANSITION-BINDING-01' docs/invariants/INVARIANTS_IMPLEMENTED.md` exits 0.

### Step 4: Author the verifier

- [ID tsk_p2_preauth_004_03_work_item_04] Create `scripts/db/verify_authority_transition_binding.sh` that runs V1, V2, V3, V4 as described in the Verifier Contract section. Verifier writes `evidence/phase2/tsk_p2_preauth_004_03.json` with the required fields.
- **Done when:** `bash scripts/db/verify_authority_transition_binding.sh` exits 0 and `jq -e '.status=="PASS" and (.scenarios_passed | index("V1")) and (.scenarios_passed | index("V2")) and (.scenarios_passed | index("V3")) and (.scenarios_passed | index("V4"))' evidence/phase2/tsk_p2_preauth_004_03.json` exits 0.

---

## Verification

- [ID tsk_p2_preauth_004_03_work_item_04] `test -x scripts/db/verify_authority_transition_binding.sh && bash scripts/db/verify_authority_transition_binding.sh > evidence/phase2/tsk_p2_preauth_004_03.json || exit 1`
- [ID tsk_p2_preauth_004_03_work_item_01] `test -f schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q 'CREATE OR REPLACE FUNCTION public.enforce_authority_transition_binding' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q 'SECURITY DEFINER' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q 'SET search_path = pg_catalog, public' schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q "'22023'" schema/migrations/0136_enforce_authority_transition_binding.sql && grep -q "'P0002'" schema/migrations/0136_enforce_authority_transition_binding.sql || exit 1`
- [ID tsk_p2_preauth_004_03_work_item_02] `test -f schema/migrations/MIGRATION_HEAD && grep -Fxq '0136' schema/migrations/MIGRATION_HEAD || exit 1`
- [ID tsk_p2_preauth_004_03_work_item_03] `test -f docs/invariants/INVARIANTS_MANIFEST.yml && grep -q 'INV-AUTH-TRANSITION-BINDING-01' docs/invariants/INVARIANTS_MANIFEST.yml && test -f docs/invariants/INVARIANTS_IMPLEMENTED.md && grep -q 'INV-AUTH-TRANSITION-BINDING-01' docs/invariants/INVARIANTS_IMPLEMENTED.md || exit 1`
- [ID tsk_p2_preauth_004_03_work_item_04] `test -f evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'scenarios_passed' evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'V1' evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'V2' evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'V3' evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'V4' evidence/phase2/tsk_p2_preauth_004_03.json && grep -q 'proof_limitations' evidence/phase2/tsk_p2_preauth_004_03.json || exit 1`

---

## Evidence Contract

| Path | Writer | Must include |
|---|---|---|
| `evidence/phase2/tsk_p2_preauth_004_03.json` | `scripts/db/verify_authority_transition_binding.sh` | `task_id`, `git_sha`, `timestamp_utc`, `status`, `checks`, `observed_paths`, `observed_hashes`, `command_outputs`, `execution_trace`, `scenarios_run`, `scenarios_passed`, `proof_limitations` |

Evidence is emitted only by the verifier. `proof_limitations` MUST include the signature-authenticity gap verbatim.

---

## Failure Modes

| Mode | Severity |
|---|---|
| Function missing SECURITY DEFINER / `SET search_path` | CRITICAL_FAIL |
| Function does not assert entity_type/entity_id match payload | CRITICAL_FAIL |
| Verifier skips decision_hash recompute | CRITICAL_FAIL |
| Invariant marked implemented without fresh evidence | FAIL |
| ALTER targets applied migration | CRITICAL_FAIL |
| Verifier claims signature authenticity without public-key layer | CRITICAL_FAIL |
| Any of V1/V2/V3/V4 omitted | FAIL_REVIEW |

---

## Rollback

Forward-only. Rollback is a new migration that drops the function (and view, if introduced here). Do not edit 0136 after merge.

---

## Risk

| Risk | Mitigation |
|---|---|
| Function fails open on missing payload view | Function's final assertion uses `IS DISTINCT FROM` with explicit `NOT FOUND` on the row lookup; missing payload means the row lookup fails, not a silent pass |
| Verifier tolerates V4 by treating mismatch as success | V4 is contracted in PLAN, meta, and evidence; harness exits non-zero if V4 is not recorded |
| Signature verification claimed without key layer | `proof_limitations` is mandatory; verifier writes it literally; stop_conditions flags as CRITICAL_FAIL if the claim appears |
| Migration ordering gate breaks | MIGRATION_HEAD advance is its own work item with explicit verification |

---

## Approval

Approved by: INVARIANTS_CURATOR
Approval metadata: not required for CREATE-TASK authorship; IMPLEMENT-TASK run will require approval metadata on `schema/migrations/**` and `docs/invariants/**` per AGENTS.md.
