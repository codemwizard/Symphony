# Implementation Plan: Outbox Lease Model Closeout

## Objective
Finalize the lease-in-pending outbox model by removing DISPATCHING-era residue, tightening guardrails against regressions, and producing a deterministic audit evidence bundle under `reports/`.

## Scope
- Schema cleanup in `schema/v1/011_payment_outbox.sql` to remove the obsolete DISPATCHING index and document the enum deprecation.
- Guardrails that block delete-on-claim patterns and DISPATCHING inserts while allowing legitimate terminal deletes inside DB functions.
- Evidence generator that outputs grants, schema invariants, and proof/test artifacts into `reports/outbox-evidence/`.

## Non-goals
- Changes to the lease model itself, worker logic, or DB functions (covered by existing lease plans).
- Replacing or reworking existing tests beyond ensuring required tests are listed in the evidence bundle.

---

## 1) Schema cleanup: remove DISPATCHING residue

### File
- `schema/v1/011_payment_outbox.sql`

### Task 1.1 — Drop obsolete DISPATCHING-age index
- Remove creation of `ix_attempts_dispatching_age`.
- Add a `DROP INDEX IF EXISTS public.ix_attempts_dispatching_age;` stanza for idempotency.

### Task 1.2 — Document DISPATCHING deprecation
- Add a short comment near the `outbox_attempt_state` enum declaration:
  - DISPATCHING exists for historical reads only.
  - Inserts are forbidden by policy/guardrails (optionally a DB-level check in a later PR).
  - DISPATCHING is not used operationally; inflight is lease state on pending.

### Definition of Done
- Schema no longer creates the DISPATCHING-age index.
- Enum is documented as deprecated for inserts.

---

## 2) Guardrails: permanently block old patterns

### Files
- `scripts/guardrails/db-role-guardrails.sh` (and any outbox-specific guardrail script if present)

### Task 2.1 — Block delete-on-claim CTE pattern
- Fail on the exact old claim CTE shape:
  - `WITH due AS (...)`
  - contains `FOR UPDATE SKIP LOCKED`
  - followed by `DELETE FROM payment_outbox_pending` + `USING due`
- Keep patterns narrow to avoid false positives in completion deletes or DDL.

### Task 2.2 — Block DISPATCHING inserts
- Fail only when `INSERT INTO payment_outbox_attempts` appears in proximity to `DISPATCHING`.
- Allow historical reads and enum references outside insert statements.

### Task 2.3 — Allow legitimate terminal deletes in DB functions
- Ensure the guardrails allow deletes inside DB functions that complete terminal attempts.
- Allow DDL and schema SQL under `schema/`.

### Definition of Done
- Guardrails reliably catch delete-on-claim and DISPATCHING inserts.
- Legitimate completion deletes are not blocked.

---

## 3) Evidence bundle generator: auditor-visible output

### New files
- `scripts/reports/generate-outbox-evidence.sh` (preferred) or `.ts`
- `reports/.gitkeep` (optional)

### Task 3.1 — Create deterministic report directory
- Output to `reports/outbox-evidence/` with stable file names.
- Ensure the generator is deterministic and grep-friendly.
- Overwrite or recreate the directory on each run.

### Task 3.2 — Include grants and invariants
- Include grants for outbox tables and functions.
- Include full function definitions for:
  - `enqueue_payment_outbox`
  - `claim_outbox_batch`
  - `complete_outbox_attempt`
  - `repair_expired_leases`
  - append-only trigger function (`deny_outbox_attempts_mutation`)
- Include DDL snippets for:
  - pending lease columns + lease consistency CHECK
  - append-only trigger binding for attempts
  - terminal uniqueness partial index
- Optionally include `schema/views/outbox_status_view.sql` output.

### Task 3.3 — Include proof/test evidence
- Emit a manifest with proof test commands and expected SQLSTATEs.
- Avoid heavy or non-deterministic logs; keep outputs compact.

### Definition of Done
- `scripts/reports/generate-outbox-evidence.*` creates `reports/outbox-evidence/*` deterministically.
- Evidence includes grants, function bodies, invariants, and proof/test manifest.

---

## 4) Test plan (PR gating)

### Unit
- `tests/unit/outboxAppendOnlyTrigger.spec.ts`
- `tests/unit/leaseRepairProof.spec.ts`
- `tests/unit/OutboxRelayer.spec.ts`

### Integration (DB-gated)
- `tests/integration/outboxLeaseLossProof.spec.ts`
- `tests/integration/outboxCompleteConcurrencyProof.spec.ts`
- `tests/integration/outboxConcurrency.test.ts`

### CI
- Ensure guardrails are enforced with `ENFORCE_NO_DB_QUERY=1`.

### Definition of Done
- Tests pass and guardrails block regressions.
- Evidence generator runs and produces `reports/outbox-evidence/*`.
- Optional regression proof: `SELECT COUNT(*) FROM payment_outbox_attempts WHERE state='DISPATCHING';` is 0 after relayer activity.

---

## Open Questions / Decisions Needed
- Confirm the preferred script language for evidence generation (`.sh` vs `.ts`).
- Confirm whether `reports/.gitkeep` is desired or if the generator should create the directory on demand.
