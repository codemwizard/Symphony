# TSK-P2-PREAUTH-004-00 PLAN — Author Wave 4 authority-binding contract and prove semantic alignment before any schema work

Task: TSK-P2-PREAUTH-004-00
Owner: DB_FOUNDATION
Depends on: TSK-P2-PREAUTH-003-02
Blocks: TSK-P2-PREAUTH-004-01, TSK-P2-PREAUTH-004-02, TSK-P2-PREAUTH-004-03
failure_signature: PHASE2.PREAUTH.AUTHORITY_BINDING.CONTRACT_MISSING
canonical_reference: docs/operations/AI_AGENT_OPERATION_MANUAL.md
wave_reference: Wave 4 — Authority Binding
origin_task_id: TSK-P2-PREAUTH-004-00
repro_command: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-004-00/meta.yml
verification_commands_run: python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-004-00/meta.yml
final_status: PLANNED

---

## Objective

Wave 3 delivered `execution_records` as an append-only cryptographic truth anchor for what actually ran. Wave 4 extends that anchor to **who had the authority to let it run, against which entity, at what point in the state machine**. This PLAN.md is the architectural contract the three downstream Wave 4 tasks (004-01, 004-02, 004-03) must implement. It fixes three defects in the previous Wave 4 draft: (1) the cryptographic binding between a policy decision and its payload was undefined, making `decision_hash` and `signature` fields theatre; (2) `policy_decisions` was not tied to a transition entity, so a decision for one entity could be replayed on an unrelated entity; (3) `state_rules` lacked a conflict-resolution tiebreaker, allowing two valid transitions for the same authority state to deadlock. This task produces no SQL and no verifier scripts. Its sole deliverable is this PLAN.md passing `verify_plan_semantic_alignment.py`, so that 004-01/02/03 can implement against a fixed contract.

---

## Architectural Context

`policy_decisions` is the Wave 4 analogue of `execution_records`: append-only, immutable, cryptographically anchored. Where Wave 3 hashes inputs and outputs of a run, Wave 4 hashes the decision payload that authorised the run. For the anchor to be real — rather than a table of self-declared `status=PASS` rows — three contracts must be fixed in this PLAN before any migration is authored:

1. **Cryptographic contract.** `decision_hash` must be a deterministic function of the decision payload (not a user-provided opaque string). The downstream verifier (owned by 004-03) must recompute the hash from the payload and reject the decision if it does not match. The signature must commit to the hash, not the payload, so that signatures over a canonicalised form can be checked without re-canonicalising on every verify. This is what distinguishes an audit trail from a ledger.

2. **Entity context.** A decision is authoritative only for the entity it was issued against. Without `entity_type` and `entity_id` columns and a binding check, the same signed `decision_hash` could be replayed across unrelated state transitions — a cross-entity replay attack against the authority layer. The downstream verifier must assert that the `entity_type` and `entity_id` columns match the corresponding fields embedded in the canonical payload that produced `decision_hash`.

3. **Rule priority.** `state_rules` encodes which transitions are permissible given an authority state. If two rules match a single transition and both `allowed = true`, the state machine has no deterministic answer. The contract adds `rule_priority INT NOT NULL DEFAULT 0` (higher wins) plus a deterministic tiebreaker (lower `state_rule_id` UUID wins on equal priority) so that rule selection is a total order — no deadlocks, no non-determinism under replay.

The four Wave 4 tasks are deliberately narrow:

| Task | Boundary | Deliverable |
|---|---|---|
| 004-00 (this task) | DOCS_ONLY | This PLAN.md + semantic alignment proof |
| 004-01 | SINGLE_TABLE | `policy_decisions` table via migration |
| 004-02 | SINGLE_TABLE | `state_rules` table via migration |
| 004-03 | SINGLE_INVARIANT | Authority-transition binding invariant + verifier + evidence |

Downstream tasks are out of scope here. This PLAN defines their contract; it does not implement it.

---

## Pre-conditions

- [ ] `TSK-P2-PREAUTH-003-02` is `status=completed` in its meta.yml (Wave 3 terminal task is closed).
- [ ] `docs/operations/TASK_CREATION_PROCESS.md` Step 1 stub exists at `tasks/TSK-P2-PREAUTH-004-00/meta.yml` with `status: planned`.
- [ ] `scripts/audit/verify_plan_semantic_alignment.py` is present and executable.
- [ ] No migration authored for policy_decisions or state_rules yet (004-01 and 004-02 are both `planned`).

---

## Files to Change

| File | Action | Reason |
|------|--------|--------|
| `docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md` | CREATE/REWRITE | This document — the Wave 4 contract |
| `tasks/TSK-P2-PREAUTH-004-00/meta.yml` | MODIFY | Populate full meta (Step 4 of creation process) to match this PLAN |
| `docs/plans/phase2/TSK-P2-PREAUTH-004-00/EXEC_LOG.md` | MODIFY | Log the contract authorship action |
| `docs/tasks/PHASE2_TASKS.md` | MODIFY | Register TSK-P2-PREAUTH-004-03 row under the Wave 4 section |

Any file modified that is not on this list => FAIL_REVIEW.

---

## Stop Conditions

- **If any SQL migration is written in this task** → STOP (belongs to 004-01/02/03).
- **If any verifier script is written in this task** → STOP (belongs to 004-03).
- **If `decision_hash` is documented without specifying the hashing algorithm and canonicalisation rule** → STOP (that is the exact defect this PLAN must close).
- **If `policy_decisions` schema omits `entity_type` or `entity_id`** → STOP (cross-entity replay remains open).
- **If `state_rules` schema omits `rule_priority` or a deterministic tiebreaker** → STOP (rule-selection non-determinism remains open).
- **If `verify_plan_semantic_alignment.py` reports proof-graph orphans or weak-signal score ≥ 3** → STOP.
- **If 004-01/02/03 meta.yml files are modified in this task** → STOP (each is its own CREATE-TASK handoff).

---

## Cryptographic Contract

The following rules are binding on 004-01 (schema) and 004-03 (verifier). They exist here, not in those tasks, because they cross table boundaries.

### Hash algorithm

```
decision_hash = sha256(canonical_json(decision_payload))
```

- `canonical_json` means deterministic JSON serialisation per RFC 8785 (JCS): UTF-8 output, lexicographic object-key ordering, no insignificant whitespace, numbers in shortest round-trip form, `\uXXXX` escapes only where required by JSON.
- `decision_payload` is a JSON object that MUST include at minimum: `decision_type`, `authority_scope`, `declared_by`, `entity_type`, `entity_id`, `execution_id`, `issued_at`. The full field list is declared in 004-01's PLAN.md; this PLAN pins the minimum set so that binding is verifiable.
- `decision_hash` is stored as a 64-character lowercase hex string in the `decision_hash` column.

### Signature scheme

```
signature = ed25519_sign(decision_hash, declared_by_private_key)
```

- Signature algorithm: Ed25519 (RFC 8032). No other schemes permitted.
- Signatures commit to `decision_hash` as raw 32 bytes, not to the canonical JSON payload. Verifiers check the signature against `hex_decode(decision_hash)`, then separately recompute `decision_hash` from the payload.
- `signature` is stored as a 128-character lowercase hex string (64 raw bytes hex-encoded) in the `signature` column.
- Public-key resolution for `declared_by` is out of scope for Wave 4; the verifier in 004-03 reads the public key from a trusted key table declared in a later wave. Until that wave lands, 004-03's verifier records the key-resolution gap as a named `proof_limitation`, not a silent bypass.

### Verifier recompute rule (binding on 004-03)

The invariant verifier MUST:
1. Read the stored `decision_hash` and `signature` columns.
2. Reconstruct `decision_payload` from the `policy_decisions` row and recompute `canonical_json`.
3. Recompute `sha256(canonical_json(decision_payload))` and assert byte-equality with the stored `decision_hash`. Mismatch → reject.
4. Verify the Ed25519 signature over `hex_decode(decision_hash)`. Mismatch → reject.
5. Assert that the `entity_type` and `entity_id` columns on the row match the corresponding fields inside `decision_payload`. Mismatch → reject (cross-entity replay block).

No step is optional. A verifier that skips steps 3–5 is failing open and must not claim `status=implemented`.

---

## policy_decisions Schema (contract for 004-01)

Column-level contract:

| Column | Type | Nullability | Constraint | Notes |
|---|---|---|---|---|
| `policy_decision_id` | UUID | NOT NULL | PRIMARY KEY | Row identity. |
| `execution_id` | UUID | NOT NULL | `REFERENCES execution_records(execution_id)` | Binds the decision to the run it authorised. |
| `decision_type` | TEXT | NOT NULL | (value set defined in 004-01) | What class of decision this is. |
| `authority_scope` | TEXT | NOT NULL | — | Domain the authority covers. |
| `declared_by` | UUID | NOT NULL | — | Principal who signed. |
| `entity_type` | TEXT | NOT NULL | — | Entity class the decision applies to. Prevents cross-entity replay. |
| `entity_id` | UUID | NOT NULL | — | Entity instance the decision applies to. |
| `decision_hash` | TEXT | NOT NULL | `CHECK (decision_hash ~ '^[0-9a-f]{64}$')` | sha256 hex of canonical_json payload. |
| `signature` | TEXT | NOT NULL | `CHECK (signature ~ '^[0-9a-f]{128}$')` | Ed25519 hex signature over decision_hash bytes. |
| `signed_at` | TIMESTAMPTZ | NOT NULL | — | Wallclock at signing. |
| `created_at` | TIMESTAMPTZ | NOT NULL | `DEFAULT now()` | DB insert time; separate from `signed_at` for replay-window analysis. |

Unique / index contract:
- `UNIQUE (execution_id, decision_type)` — at most one decision of each type per execution.
- `INDEX (entity_type, entity_id)` — fast lookup for entity-scoped verification.
- `INDEX (declared_by)` — supports authority-revocation sweeps.

Append-only contract:
- `policy_decisions` MUST be append-only after insert. UPDATE and DELETE of existing rows MUST be blocked by an `enforce_policy_decisions_append_only` trigger (specified in 004-01's PLAN, not this one). This trigger is the Wave 4 analogue of `enforce_execution_records_append_only` from Wave 3.

Negative tests 004-01 MUST exercise:
- Insert without `execution_id` → fails NOT NULL.
- Insert without `signature` → fails NOT NULL.
- Insert with `decision_hash` of wrong length → fails CHECK.
- Insert with `execution_id` that does not exist in `execution_records` → fails FK.
- UPDATE of an existing row → blocked by append-only trigger.

---

## state_rules Schema (contract for 004-02)

Column-level contract:

| Column | Type | Nullability | Constraint | Notes |
|---|---|---|---|---|
| `state_rule_id` | UUID | NOT NULL | PRIMARY KEY | Row identity. Tiebreaker on equal-priority matches (lower UUID wins). |
| `from_state` | TEXT | NOT NULL | — | Source state. |
| `to_state` | TEXT | NOT NULL | — | Destination state. |
| `required_decision_type` | TEXT | NOT NULL | — | Which `policy_decisions.decision_type` must be present for this transition. |
| `allowed` | BOOLEAN | NOT NULL | — | `true` = transition permitted when required decision is present. |
| `rule_priority` | INT | NOT NULL | `DEFAULT 0` | Higher priority wins when multiple rules match. Prevents deadlocks. |
| `created_at` | TIMESTAMPTZ | NOT NULL | `DEFAULT now()` | DB insert time. |

Unique / index contract:
- `UNIQUE (from_state, to_state, required_decision_type)` — a single rule per (transition, decision type) tuple.
- `INDEX (from_state, rule_priority DESC)` — supports priority-ordered rule lookup by source state.

Rule selection contract (binding on Wave 5 state machine, documented here for invariant traceability):
- Given a transition `(from_state → to_state)` with a set of candidate `policy_decisions`, the state machine selects rules matching the `required_decision_type` of each available decision.
- Among matching rules, the one with the highest `rule_priority` wins.
- If two rules have equal `rule_priority`, the rule with the lexicographically smaller `state_rule_id` wins.
- This tiebreak is deterministic under replay: given the same rule set and decisions, selection is a pure function. No deadlock condition exists.

Negative tests 004-02 MUST exercise:
- Insert without `required_decision_type` → fails NOT NULL.
- Duplicate `(from_state, to_state, required_decision_type)` → fails UNIQUE.
- Insert with `rule_priority = -1` → MUST be permitted (negative priorities are valid for explicit deny rules; this is not a CHECK violation and the test confirms absence of an over-tight CHECK).

---

## Authority-Transition Binding Invariant (contract for 004-03)

Invariant ID (proposed, to be registered in 004-03): `INV-AUTH-TRANSITION-BINDING-01`.

Statement:
- Any authority-bearing state transition applied via `execution_records` MUST reference, in the transition payload, exactly one `policy_decisions.policy_decision_id` whose `entity_type`, `entity_id`, and `execution_id` match the transition's entity and execution. Transitions lacking this reference, or referencing a decision bound to a different entity or execution, are rejected.

Enforcement location (binding on 004-03):
- A DB function `enforce_authority_transition_binding(execution_id uuid, policy_decision_id uuid)` that resolves both rows, asserts the binding, and raises on mismatch.
- Attached via trigger to whichever layer applies authority-bearing transitions (the exact attachment point is declared in 004-03's PLAN, informed by Wave 5's state-machine layer).

Verification location (binding on 004-03):
- `scripts/db/verify_authority_transition_binding.sh` that inspects the live DB, exercises positive and negative cases, and emits `evidence/phase2/tsk_p2_preauth_004_03.json` with `observed_paths`, `observed_hashes`, `command_outputs`, and `execution_trace`.

Proof guarantees (binding on 004-03):
- Rows in `execution_records` flagged as authority-bearing without a matching `policy_decisions` row cause the verifier to exit non-zero.
- A decision matching a different `entity_id` than the execution's entity causes the verifier to exit non-zero.

Proof limitations (must be declared in 004-03's PLAN):
- Public-key resolution for signature verification is deferred; during Wave 4 the verifier validates structural binding (FK + entity match + hash recompute) but not signature authenticity. This limitation is explicit, not silent.

---

## Implementation Steps

### Step 1: Author PLAN.md with cryptographic contract

**What:** `[ID tsk_p2_preauth_004_00_work_item_01]` Author this PLAN.md such that it contains an explicit `Cryptographic Contract` section fixing `decision_hash = sha256(canonical_json(decision_payload))`, the Ed25519 signature scheme over `hex_decode(decision_hash)`, and the verifier recompute rule.

**How:** Write the section above verbatim. The exact strings `sha256(canonical_json` and `ed25519` must appear so the verifier's `grep` check can confirm the fields are not drift.

**Done-when:** `grep -q 'sha256(canonical_json'` on the PLAN exits 0 and `grep -q 'ed25519'` on the PLAN exits 0.

### Step 2: Document policy_decisions schema with entity binding

**What:** `[ID tsk_p2_preauth_004_00_work_item_02]` Author the `policy_decisions Schema` section with all 11 columns, including `entity_type TEXT NOT NULL` and `entity_id UUID NOT NULL`, plus the append-only contract and the five mandatory negative tests.

**How:** Table rows must include the exact tokens `entity_type`, `entity_id`, `decision_hash`, `signature`, `execution_id`, so the verifier can confirm by literal grep.

**Done-when:** `grep -q 'entity_type'`, `grep -q 'entity_id'`, `grep -q 'decision_hash'`, `grep -q 'signature'`, and `grep -q 'policy_decisions'` all exit 0 against the PLAN.

### Step 3: Document state_rules schema with rule_priority

**What:** `[ID tsk_p2_preauth_004_00_work_item_03]` Author the `state_rules Schema` section including `rule_priority INT NOT NULL DEFAULT 0` and the deterministic tiebreaker rule (lower `state_rule_id` UUID wins on equal priority).

**How:** The exact tokens `state_rules` and `rule_priority` must appear in the PLAN so the verifier can confirm by literal grep.

**Done-when:** `grep -q 'state_rules'` and `grep -q 'rule_priority'` both exit 0 against the PLAN.

### Step 4: Document authority-transition binding invariant

**What:** `[ID tsk_p2_preauth_004_00_work_item_04]` Author the `Authority-Transition Binding Invariant` section declaring the invariant ID, statement, enforcement location, verification location, proof guarantees, and proof limitations that 004-03 must adopt.

**How:** The invariant ID token `INV-AUTH-TRANSITION-BINDING-01` must appear so the manifest-to-PLAN cross-reference check performed later by 004-03 can succeed.

**Done-when:** `grep -q 'INV-AUTH-TRANSITION-BINDING-01'` exits 0 against the PLAN.

### Step 5: Prove semantic alignment

**What:** `[ID tsk_p2_preauth_004_00_work_item_05]` Run `verify_plan_semantic_alignment.py` against this PLAN and the matching meta.yml. The scanner enforces `work → acceptance → verification` mapping via `[ID …]` tags, forbids no-op verifiers, and flags weak signals.

**How:** `python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-004-00/meta.yml`

**Done-when:** The scanner exits 0 and prints `Proof graph integrity PASSED`.

---

## Verification

```bash
# [ID tsk_p2_preauth_004_00_work_item_01] cryptographic contract present
test -f docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'sha256(canonical_json' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'ed25519' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_004_00_work_item_02] policy_decisions schema with entity binding
grep -q 'policy_decisions' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'entity_type' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'entity_id' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'decision_hash' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'signature' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_004_00_work_item_03] state_rules schema with rule_priority
grep -q 'state_rules' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md && grep -q 'rule_priority' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_004_00_work_item_04] authority-transition binding invariant declared
grep -q 'INV-AUTH-TRANSITION-BINDING-01' docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md || exit 1

# [ID tsk_p2_preauth_004_00_work_item_05] semantic alignment proof
python3 scripts/audit/verify_plan_semantic_alignment.py --plan docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md --meta tasks/TSK-P2-PREAUTH-004-00/meta.yml || exit 1
```

---

## Evidence Contract

`-00` PLAN-creation tasks do not emit a JSON evidence artefact; the evidence is the PLAN.md itself plus a `Proof graph integrity PASSED` line from `verify_plan_semantic_alignment.py`. `verify_plan_semantic_alignment.py` explicitly skips the evidence-binding check for `-00` meta paths. That skip is load-bearing for this task and is not a bypass.

---

## Rollback

If this PLAN is rejected in review:

```bash
rm docs/plans/phase2/TSK-P2-PREAUTH-004-00/PLAN.md
```

Then re-author per review notes and re-run `verify_plan_semantic_alignment.py` before the next review round. No schema, no evidence, no registry state is touched, so rollback is trivial.

---

## Risk

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Downstream 004-01 authors `decision_hash` as an opaque user-supplied string, ignoring the canonical_json rule | Low | HIGH (audit trail becomes self-declared) | This PLAN pins the algorithm verbatim; 004-01's PLAN MUST reference `sha256(canonical_json` and 004-03's verifier MUST recompute. Both verifiers grep for the literal contract text. |
| Downstream 004-01 drops `entity_type`/`entity_id` under schedule pressure | Low | HIGH (cross-entity replay reopens) | Stop conditions in 004-01's meta.yml will cite this PLAN; review gate checks for both tokens. |
| 004-02 treats `rule_priority` as optional | Low | MEDIUM (deadlocks resurface) | This PLAN's `state_rules Schema` marks `rule_priority INT NOT NULL DEFAULT 0`. The tiebreak rule is documented and testable. |
| Wave 5 state-machine layer ignores the rule-selection contract | Medium | MEDIUM (non-determinism under replay) | This PLAN documents the selection rule so that when Wave 5 opens, its PLAN can cite INV-AUTH-TRANSITION-BINDING-01 and inherit the tiebreak discipline. |
| `verify_plan_semantic_alignment.py` flags weak-signal drift as this PLAN is edited | Low | LOW (CI gate) | Completion phrases across implementation steps are phrased as exit-code assertions (literal `exit 0`, `grep -q`, `|| exit 1`) rather than vague language. Weak-signal score target is 0. |

---

## Approval

DOCS_ONLY task. No regulated surface changes (no schema, no scripts, no workflows, no invariant registry). No approval metadata sidecar required beyond `verify_plan_semantic_alignment.py` passing and standard PR review.
