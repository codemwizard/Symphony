








I can’t actually “look at the repomix” right now because the file contents I’d need to read have expired in this session. If you re-upload the latest `repomix-output.xml` (or split schema files), I can do the exact, table-by-table gap analysis you’re asking for.

That said, I *can* give you a solid, actionable framework for applying SQLSTATEs across the whole DB for this phase, plus a checklist of the invariants that are most commonly missing or under-specified in an orchestration engine like yours.

---

## SQLSTATEs: what they mean in your system

### 1) Authorization / role-boundary (DB privilege layer)

These are “you are not allowed to do that” errors. They should be asserted in role-boundary tests.

* **`42501` — insufficient_privilege**
  What you want when:

  * `symphony_readonly` tries `INSERT/UPDATE/DELETE/TRUNCATE`
  * `symphony_ingest` tries to write to tables it shouldn’t
  * any runtime role tries to touch privileged tables (`participant_outbox_sequences`, etc.)

* **`0LP01` — invalid_grant_operation** (rare in runtime flows)
  Usually shows up when executing GRANT/REVOKE incorrectly, not typical app behavior. Don’t include it in runtime assertions unless you’ve observed it in your env.

### 2) “Invariant violation” (business rules enforced by DB)

These should be deterministic and *yours*, not incidental. The best pattern is:

* **`P0001` — raise_exception (custom invariant)**
  Used when a trigger/function rejects an operation because it violates a business invariant.

  * Example you already have: append-only attempts trigger raises `P0001`.

This is the main code you should standardize on for “Phase invariants” enforced by triggers/functions.

### 3) Data integrity (Postgres built-ins you should lean on)

These are great because they’re proof-grade: not subjective, not dependent on app code.

* **`23505` — unique_violation**
  Idempotency uniqueness, “exactly once” anchors, no duplicates.
* **`23503` — foreign_key_violation**
  Reference integrity: attempts must reference existing instruction, etc.
* **`23514` — check_violation**
  Enumerations, non-negative counters, JSON shape checks, state constraints.
* **`23502` — not_null_violation**
  Required fields.
* **`22P02` — invalid_text_representation**
  Bad UUID, invalid numeric cast, etc. (useful for input validation hardening)

### 4) Transaction / concurrency safety (important for orchestration)

These matter for stress tests and correctness under contention.

* **`40001` — serialization_failure**
  Under SERIALIZABLE or certain locking patterns; app should retry safely.
* **`40P01` — deadlock_detected**
  If you add advisory locks + multiple resources; app should surface + retry or alert.

---

## Which invariants are usually missing or under-defined (Orchestration Engine)

Without seeing your redesigned repomix, these are the most likely gaps **beyond outbox** (based on what you’ve shown in schema excerpts):

### A) Immutability is stated but not *proved*

You revoke UPDATE/DELETE on some tables, but you often want a second layer of proof:

* **Audit-like tables** (ledger, audit_log, status_history, attempts logs):

  * If any privileged role or DB owner can still mutate, you should add **append-only triggers** that raise **`P0001`** (like you did for `payment_outbox_attempts`).
  * Why: REVOKE protects against normal roles, but triggers protect against “privileged accidents”.

**Likely missing:** append-only trigger for `audit_log`, `status_history`, `ledger_entries`, `transaction_attempts`, `execution_attempts` (depending on which ones are meant to be immutable).

### B) State machine transitions not enforced in DB

You have state enums/checks in places, but often the *transition rules* are not enforced:

* instruction state transitions (e.g., RECEIVED → AUTHORIZED → EXECUTING → COMPLETED/FAILED)
* outbox attempt state transitions (DISPATCHING → DISPATCHED/RETRYABLE/FAILED; ZOMBIE_REQUEUE append-only)
* “terminal means terminal” (no leaving terminal states)

**How to enforce:** trigger on UPDATE that validates `OLD.state` → `NEW.state` and raises **`P0001`** if invalid.

### C) “Single terminal success” proofs missing

You already have a partial unique index for instruction “single completed success” (good). Similar proofs commonly needed:

* exactly one `DISPATCHED` attempt per outbox item (if that’s the invariant)
* exactly one terminal dispatch path per `(instruction_id, idempotency_key)`

**How to enforce:** partial unique indexes or trigger checks. Prefer indexes when possible (they yield `23505`).

### D) Kill-switch enforcement exists as a function, but not applied

You define `block_execution_if_killed()` but:

* Is it attached as a trigger to the tables where it matters?
* Is it applied to both ingest writes and executor transitions?

**How to enforce:** BEFORE INSERT/UPDATE triggers on the relevant entrypoints; raise **`P0001`** with a clear message.

### E) Policy version window invariants are usually incomplete

You have ACTIVE/GRACE/RETIRED and “only one ACTIVE”. Typical missing proofs:

* at most one GRACE at a time (if desired)
* GRACE must be older than ACTIVE (monotonic)
* tokens signed with RETIRED must fail (app-layer, but DB can enforce accepted versions table constraints)

**DB enforcement:** constraints/indexes (→ `23505` / `23514`) and/or triggers (→ `P0001`).

---

## How to implement SQLSTATEs “for this phase” across the DB

### 1) Standardize two classes of tests

**Role-boundary tests**

* Expect **`42501`** only.
* Do not mix in trigger expectations.

**Invariant/trigger-proof tests**

* Use privileged principal (`queryNoRole` / DB owner) to ensure the trigger runs.
* Expect **`P0001`** only (deterministic).

### 2) Add a reusable invariant helper in SQL

Create a tiny function used by triggers for consistent error shape:

```sql
CREATE OR REPLACE FUNCTION raise_invariant(p_message TEXT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION '%', p_message USING ERRCODE = 'P0001';
END;
$$;
```

Then in triggers:

```sql
PERFORM raise_invariant('ledger_entries is append-only');
```

### 3) Prefer built-in constraints where possible

* Idempotency uniqueness → **UNIQUE** (→ `23505`)
* enums / bounds → **CHECK** (→ `23514`)
* references → **FOREIGN KEY** (→ `23503`)

Use triggers (`P0001`) only when the rule can’t be expressed as a constraint/index.

### 4) “Immutability tiering” recommendation (audit-grade)

* **Tier 1 (role boundary):** REVOKE UPDATE/DELETE/TRUNCATE from runtime roles → asserts `42501`
* **Tier 2 (invariant):** append-only trigger → asserts `P0001`
* **Tier 3 (evidence):** tests that prove both independently

You’ve done this pattern for outbox attempts; replicate it where you claim immutability.

---

## What I need from repomix to answer precisely

Re-upload your redesigned `repomix-output.xml` (or just:

* all `schema/**/*.sql`
* `libs/db/**`
* `tests/**`)

Then I’ll return:

1. A table-by-table list of **which invariants exist**, **which are missing**, and **which are weak**
2. Exactly where to add **`P0001` triggers** vs where to rely on **235xx constraints**
3. A matching test plan (role-boundary vs trigger-proof) with the SQLSTATE allowlists per invariant type

If you paste or upload the updated repomix, I’ll do the full diff-style assessment.








### What SQLSTATEs you already have (from repomix)

**Custom / app-level invariant codes**

* **`P0001`** — “raise_exception” used by *immutability / append-only triggers* (e.g., `deny_revocation_mutation()`, `deny_attestation_mutation()`, outbox attempts immutability). This is your **canonical “append-only violation”** code.
* **`P7002`** — used in outbox functions for **lease/claim correctness** (e.g., “not in expected state”, “no row claimed/returned”).
* **`P7003`** — used for **retry ceiling exceeded** (retry limit / safety cap).

**Built-in Postgres codes you should rely on**

* **`42501`** — insufficient_privilege (role-boundary proof: “role cannot do that”).
* **`23505`** — unique_violation (idempotency / uniqueness invariants).
* **`23514`** — check_violation (CHECK constraints: state enums, monotonic counters, bounds).
* **`23503`** — foreign_key_violation (if/when you introduce FK integrity).
* **`22P02`** — invalid_text_representation (bad UUID/text casts, etc).
* **`40001`** — serialization_failure (if you use SERIALIZABLE / contention patterns).
* **`40P01`** — deadlock_detected (contention/lock ordering issues).

---

## Which invariants are missing or not adequately defined (across the whole DB)

### 1) **Privilege model is incomplete for new tables**

Your privileges migration (`schema/migrations/0004_privileges.sql`) is outbox-focused and **does not define explicit GRANT/REVOKE posture** for at least:

* `public.ingress_attestations`
* `public.revoked_client_certs`
* `public.revoked_tokens`

**What’s missing**

* Clear “who can INSERT / SELECT” for these tables
* Explicit “who is forbidden” (especially ingest vs executor vs readonly/auditor)

**Why it matters**
Without explicit grants/revokes, you can’t produce audit-grade *role-boundary proofs* for these tables the way you did for outbox.

---

### 2) **Revocation tables lack correctness constraints**

You *do* have append-only enforcement (`P0001` via triggers). But correctness invariants are thin.

**Missing / weak invariants**

* `expires_at` should be `NULL` **or** `expires_at >= revoked_at`
* optional: `reason_code` format / allowlist (if you want evidence-grade consistency)
* operational index: `expires_at` (for cleanup/queries) and/or `revoked_at`

**SQLSTATE expectation**

* Constraint failures should surface as **`23514`** (check_violation).

---

### 3) **Ingress attestation state transitions are not DB-proven**

You enforce append-only on `ingress_attestations` via `P0001`, but if your redesigned system expects fields like “execution started/completed/terminal”, then DB-level invariants for **monotonic state evolution** are either absent or purely application-enforced.

**Typical missing invariants (if your table includes these columns)**

* `execution_completed` cannot be TRUE unless `execution_started` is TRUE
* terminal status cannot change once set (immutability of terminal fields)
* prevent “flip-flop” updates

**How to encode**

* Either:

  * (a) make it *strictly append-only* and write new rows for state changes (best for evidence), or
  * (b) keep updates but add a trigger that enforces monotonic transitions with a custom SQLSTATE (see implementation section).

---

### 4) **Policy version governance lacks explicit transition enforcement**

`policy_versions` likely has uniqueness/constraints, but **does not appear to have DB-enforced state-transition rules** (ACTIVE → GRACE → RETIRED, “only one ACTIVE”, etc.) beyond indexes.

**Missing invariant**

* Prevent invalid transitions (e.g., RETIRED → ACTIVE) via trigger/function.
* Ensure “exactly one ACTIVE” is already covered by unique index; what’s missing is *transition semantics*.

**SQLSTATE expectation**

* Violations should be a **custom policy code** (don’t overload `P0001`).

---

## How to implement SQLSTATEs for this phase (recommended pattern)

### A) Adopt a simple SQLSTATE taxonomy

Keep it consistent and easy to assert in tests:

1. **Role boundary** (GRANT/REVOKE proof)

* Use Postgres built-in: **`42501`**

2. **Append-only / immutability**

* Use **`P0001`** everywhere you deny UPDATE/DELETE via trigger
  (you already do this — keep it)

3. **Business-rule invariants in functions/triggers**

* Use **`P7xxx`** per subsystem:

  * `P71xx` = outbox invariants (you already have `P7002`, `P7003` — you can keep them, but consider reserving ranges)
  * `P72xx` = ingress attestation invariants
  * `P73xx` = policy governance invariants
  * `P74xx` = revocation correctness invariants (optional; checks could just use `23514`)

### B) Implement missing constraints + triggers

**Revocation correctness**

```sql
ALTER TABLE public.revoked_client_certs
  ADD CONSTRAINT ck_revoked_client_certs_expiry
  CHECK (expires_at IS NULL OR expires_at >= revoked_at);

ALTER TABLE public.revoked_tokens
  ADD CONSTRAINT ck_revoked_tokens_expiry
  CHECK (expires_at IS NULL OR expires_at >= revoked_at);
```

→ asserts as `23514`

**Ingress monotonic transitions (if you allow UPDATEs)**

* Add a `BEFORE UPDATE` trigger that rejects regressions with (example) `P7201`.
* If you want *evidence-grade*, prefer append-only modeling instead: insert new “event” rows rather than updating.

**Policy transition enforcement**

* Add a trigger or function that checks OLD/NEW and raises `P7301` for invalid transitions.

### C) Expand privileges + add role-boundary tests (like outbox)

In `schema/migrations/0004_privileges.sql`, explicitly:

* REVOKE ALL on `ingress_attestations`, `revoked_client_certs`, `revoked_tokens` from PUBLIC
* GRANT minimal SELECT/INSERT to the right roles
* REVOKE UPDATE/DELETE/TRUNCATE broadly (and optionally prove it via tests)

Then add tests mirroring your outbox approach:

* “readonly cannot insert into revoked_tokens” ⇒ expect `42501`
* “auditor cannot insert into ingress_attestations” ⇒ expect `42501`
* “attempt UPDATE/DELETE on revocation tables as db owner (queryNoRole)” ⇒ expect `P0001` (trigger proof)

---

## Concrete “next” work items

1. **Update privileges migration** to include the non-outbox tables (attestations + revocations + policy_versions if needed).
2. **Add DB-level correctness constraints** for revocation expiry monotonicity (`23514`).
3. Decide attestation model:

   * strict append-only (preferred), **or**
   * allow updates but enforce monotonic transitions with `P72xx`.
4. Add **role-boundary tests** for attestations + revocations using `42501`, and **trigger-proof tests** using `P0001`.

If you paste the current definitions of `ingress_attestations` and `policy_versions` from your redesigned repomix, I can propose the exact trigger logic + the specific SQLSTATE codes (P72xx/P73xx) and the matching test assertions.







Some of the earlier uploaded repo/repomix files have expired on my side, so I can’t re-scan the whole schema right now. I *can* confirm the two files you just uploaded are the right kind of “invariant anchor” files (policy gating + ingress attestations), and I can propose **exact trigger logic + SQLSTATE codes + test assertions** for them. If you want me to apply this *across the whole database*, re-upload the full repomix/schema bundle again.

---

## 1) SQLSTATE conventions for this phase (Orchestration Engine)

Use **two buckets** only, consistently:

### A) **Role boundary / privilege failures** (DB permissions)

* **`42501`** = `insufficient_privilege`
* Use when the DB denies an action because the role shouldn’t be able to do it (GRANT/REVOKE driven).

**Test assertion:** `sqlState === '42501'`.

### B) **Invariant enforcement** (triggers / “business rules at the DB boundary”)

* **`P0001`** = `raise_exception` (your deliberate “this must never happen” invariant break)
* Use for: immutability, forbidden transitions, “cannot mark executed without …”, hash-chain continuity, etc.

**Test assertion:** `sqlState === 'P0001'`.

> Why not invent custom codes? You *can* set arbitrary 5-char codes, but you’ll end up with uneven driver behavior and inconsistent error handling. Keep it audit-simple: `42501` for privilege, `P0001` for invariants. Put the invariant ID in the message.

---

## 2) `policy_versions` — proposed triggers + SQLSTATEs

### Invariants to enforce (DB-authoritative)

1. **Only allowed status values** are already enforced by CHECK.
2. **Exactly one ACTIVE** is already enforced by partial unique index.
3. **Status transitions must be monotonic**: `ACTIVE → GRACE → RETIRED` only (no “resurrect”).
4. **RET IRED is immutable** (cannot be changed back).

### Trigger (exact logic)

```sql
CREATE OR REPLACE FUNCTION enforce_policy_versions_transitions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Disallow updates to primary key
  IF TG_OP = 'UPDATE' AND NEW.id IS DISTINCT FROM OLD.id THEN
    RAISE EXCEPTION 'INV-POL-001: policy id is immutable'
      USING ERRCODE = 'P0001';
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Monotonic transitions only
    IF OLD.status = 'RETIRED' AND NEW.status IS DISTINCT FROM OLD.status THEN
      RAISE EXCEPTION 'INV-POL-002: retired policy is immutable'
        USING ERRCODE = 'P0001';
    END IF;

    IF OLD.status = 'GRACE' AND NEW.status = 'ACTIVE' THEN
      RAISE EXCEPTION 'INV-POL-003: cannot promote GRACE back to ACTIVE'
        USING ERRCODE = 'P0001';
    END IF;

    IF OLD.status = 'ACTIVE' AND NEW.status = 'RETIRED' THEN
      RAISE EXCEPTION 'INV-POL-004: must pass through GRACE before RETIRED'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_policy_versions_transitions ON policy_versions;

CREATE TRIGGER trg_policy_versions_transitions
BEFORE UPDATE ON policy_versions
FOR EACH ROW
EXECUTE FUNCTION enforce_policy_versions_transitions();
```

### Matching test assertions

* Trying to update a `RETIRED` record back to `ACTIVE` ⇒ expect **`P0001`**
* Creating a second `ACTIVE` version likely throws **`23505`** (unique violation) unless you wrap it with a *statement-level guard* (optional). If you want it to be `P0001`, add a **BEFORE INSERT/UPDATE** trigger that checks for another ACTIVE and raises `P0001` with `INV-POL-005`.

**My recommendation:** keep the partial unique index as-is; tests can accept `23505` *or* you can promote it to `P0001` for cleaner “proof”.

---

## 3) `ingress_attestations` — proposed triggers + SQLSTATEs

### Invariants you likely want (DB-authoritative)

1. **Append-only**: no UPDATE/DELETE ever.
2. **No “execution_completed” without “execution_started”.**
3. **Terminal status may only be set when `execution_completed = true`.**
4. **Hash-chain continuity**: `prev_hash` must match prior record’s `record_hash` for the same partition stream (if you rely on chaining as evidence).

### Triggers (exact logic)

#### A) Append-only immutability trigger

```sql
CREATE OR REPLACE FUNCTION deny_ingress_attestations_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'INV-ATT-001: ingress_attestations is append-only'
    USING ERRCODE = 'P0001';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_ingress_attestations_update ON ingress_attestations;
DROP TRIGGER IF EXISTS trg_deny_ingress_attestations_delete ON ingress_attestations;

CREATE TRIGGER trg_deny_ingress_attestations_update
BEFORE UPDATE ON ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION deny_ingress_attestations_mutation();

CREATE TRIGGER trg_deny_ingress_attestations_delete
BEFORE DELETE ON ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION deny_ingress_attestations_mutation();
```

#### B) State gating trigger (only on INSERT; or on UPDATE if you permit updates elsewhere)

If your design expects toggling `execution_started/execution_completed` via UPDATE, then you **cannot** make it append-only. Decide one:

* **Option 1 (recommended for evidence):** append-only + separate “execution status” table (or append-only events table).
* **Option 2:** allow UPDATE but strictly gate transitions with triggers (then it’s not append-only evidence).

If you keep it append-only, enforce correctness at **INSERT**:

```sql
CREATE OR REPLACE FUNCTION enforce_attestation_insert_invariants()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.execution_completed = TRUE AND NEW.execution_started = FALSE THEN
    RAISE EXCEPTION 'INV-ATT-002: cannot complete without start'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.terminal_status IS NOT NULL AND NEW.execution_completed = FALSE THEN
    RAISE EXCEPTION 'INV-ATT-003: terminal_status requires execution_completed'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attestation_insert_invariants ON ingress_attestations;

CREATE TRIGGER trg_attestation_insert_invariants
BEFORE INSERT ON ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION enforce_attestation_insert_invariants();
```

#### C) Hash-chain continuity (optional but audit-strong)

This depends on what your “chain” scope is (global stream vs per `caller_identity` vs per day partition). A common, deterministic scope is **global append order**, but in distributed systems you’ll likely want **per identity**:

Example: enforce continuity per `caller_identity`:

```sql
CREATE OR REPLACE FUNCTION enforce_attestation_hash_chain()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  prev TEXT;
BEGIN
  SELECT record_hash
    INTO prev
  FROM ingress_attestations
  WHERE caller_identity = NEW.caller_identity
  ORDER BY attested_at DESC
  LIMIT 1;

  IF prev IS NULL THEN
    -- first record in chain: prev_hash must be '' (or allow anything)
    IF NEW.prev_hash IS DISTINCT FROM '' THEN
      RAISE EXCEPTION 'INV-ATT-004: first record must have empty prev_hash'
        USING ERRCODE = 'P0001';
    END IF;
  ELSE
    IF NEW.prev_hash IS DISTINCT FROM prev THEN
      RAISE EXCEPTION 'INV-ATT-005: prev_hash does not match prior record_hash'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_attestation_hash_chain ON ingress_attestations;

CREATE TRIGGER trg_attestation_hash_chain
BEFORE INSERT ON ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION enforce_attestation_hash_chain();
```

> If you don’t want per-identity chaining, tell me the intended chain scope and I’ll adapt the query accordingly.

---

## 4) Matching node:test assertions (pattern)

Use the same helper everywhere:

```ts
function getSqlState(err: unknown): string | undefined {
  const anyErr = err as { code?: string; sqlState?: string; cause?: { code?: string; sqlState?: string } };
  return anyErr.code ?? anyErr.sqlState ?? anyErr.cause?.code ?? anyErr.cause?.sqlState;
}
```

### Role boundary example

* Expect **`42501`** only:

```ts
await assert.rejects(
  () => db.queryAsRole('symphony_readonly', 'INSERT INTO ...'),
  err => getSqlState(err) === '42501'
);
```

### Invariant trigger example

* Expect **`P0001`** only:

```ts
await assert.rejects(
  () => queryNoRole('UPDATE ingress_attestations SET ...'),
  err => getSqlState(err) === 'P0001'
);
```

---

## 5) Are these the right files?

**Yes** — for defining phase-level SQLSTATE policy and “proof tests”, `policy_versions` and `ingress_attestations` are exactly the right places to start.

To finish “apply SQLSTATEs across the whole database”, I still need the full schema/repomix again (it expired on my side). Once re-uploaded, I’ll produce:

* a table of **every invariant** by table/function,
* which ones should be **42501 vs P0001**,
* and the **exact trigger(s)** + **test(s)** per invariant.








Yes — these are the right files for “apply SQLSTATEs across the whole database” *for the redesigned schema you’re showing*:

* `0003_roles.sql` (role surface)
* `0004_privileges.sql` (role-boundary enforcement → relies on native `42501`)
* `0005_policy_versions.sql` (**missing** explicit invariant SQLSTATEs today)
* `0011_ingress_attestations.sql` (already has immutability trigger → `P0001`)
* `0012_revocation_tables.sql` (already has immutability trigger → `P0001`)
* `0013_outbox_pending_indexes_concurrently.sql` (performance only)

Below is the **exact trigger logic + specific SQLSTATE codes + matching test assertions** to finish “SQLSTATE across the whole database” for this phase.

---

## 1) SQLSTATE taxonomy for the Orchestration Engine (DB layer)

### A. Role boundary (Postgres native)

* **`42501`** = `insufficient_privilege`
  Use this for “role cannot do X” proofs (A–E). Keep it native; don’t wrap it.

### B. Immutability / append-only (your current pattern)

* **`P0001`** = “raise_exception” (custom error via `RAISE EXCEPTION … USING ERRCODE`)
  You already use this for:

  * `ingress_attestations` immutability
  * revocation tables immutability
  * outbox attempts append-only trigger (in your earlier outbox design)

### C. Domain invariants (recommended: keep them `P7xxx`)

Use **project-specific SQLSTATEs** for state machines and correctness invariants so tests can assert precisely.
Suggested ranges:

* **`P71xx`** Policy governance invariants
* **`P72xx`** Revocation invariants
* **`P73xx`** Ingress attestation invariants
* **`P70xx`** Outbox invariants (you already have some `P7002`, `P7003` in repomix)

---

## 2) What’s missing / not adequately defined (invariants)

### Policy Versions (`0005_policy_versions.sql`) — **missing**

Right now you rely on:

* CHECK constraint → typically **`23514`**
* unique active partial index violation → typically **`23505`**

That works, but it’s **not audit-grade deterministic** (tests have to assert generic constraint codes and messages). Missing explicit invariants:

* **Transition rules** (e.g. `RETIRED → ACTIVE` must be impossible)
* **No DELETE** (governance tables should be immutable or strictly controlled)
* Optional: “must always have at least one ACTIVE”

### Ingress Attestations (`0011_ingress_attestations.sql`) — **partially defined**

You have append-only (`P0001`) + a `BEFORE INSERT` defaulting `prev_hash`/`attested_at`. Missing state invariants:

* `execution_completed = true` implies `execution_started = true`
* when completed, `terminal_status` must be non-null
* prevent “un-completing” / “un-starting” once set

### Revocation tables (`0012_revocation_tables.sql`) — **mostly OK**

You already have append-only trigger (`P0001`) + set `revoked_at`. Missing optional invariants (depends on your product intent):

* token hash format validation (length / hex)
* enforce monotonic `revoked_at` is always set and cannot be changed (already covered by immutability)

### Privileges (`0004_privileges.sql`)

This is already your role boundary proof surface. The “SQLSTATE” here is **`42501`**, and that’s correct.

---

## 3) Exact implementation: triggers + SQLSTATE codes

### 3.1 Policy Versions: enforce governance transitions (add to `0005_policy_versions.sql`)

**Goal:** make policy governance deterministic to test.

```sql
-- POLICY SQLSTATE CODES (recommended)
-- P7101: invalid_transition
-- P7102: delete_forbidden
-- P7103: cannot_retire_last_active (optional)
-- P7104: active_conflict (optional; nicer than 23505)

CREATE OR REPLACE FUNCTION public.enforce_policy_version_invariants()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  active_count INT;
BEGIN
  -- No deletes (audit-grade)
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'policy_versions is immutable; delete forbidden'
      USING ERRCODE = 'P7102';
  END IF;

  -- Inserts: allow only ACTIVE/GRACE/RETIRED (already checked), but you may require created_by, etc (UNKNOWN).
  IF TG_OP = 'INSERT' THEN
    RETURN NEW;
  END IF;

  -- Updates: allow forward-only transitions
  IF TG_OP = 'UPDATE' THEN
    -- forbid changing primary identity
    IF NEW.id IS DISTINCT FROM OLD.id THEN
      RAISE EXCEPTION 'policy_versions.id is immutable'
        USING ERRCODE = 'P7101';
    END IF;

    -- Forward-only status transitions
    IF OLD.status = 'RETIRED' AND NEW.status IS DISTINCT FROM 'RETIRED' THEN
      RAISE EXCEPTION 'cannot reactivate retired policy'
        USING ERRCODE = 'P7101';
    END IF;

    IF OLD.status = 'GRACE' AND NEW.status = 'ACTIVE' THEN
      RAISE EXCEPTION 'cannot promote GRACE back to ACTIVE'
        USING ERRCODE = 'P7101';
    END IF;

    -- Optional: prevent retiring the last ACTIVE policy
    IF OLD.status = 'ACTIVE' AND NEW.status <> 'ACTIVE' THEN
      SELECT COUNT(*) INTO active_count
      FROM public.policy_versions
      WHERE status = 'ACTIVE'
        AND id <> OLD.id;

      IF active_count = 0 THEN
        RAISE EXCEPTION 'cannot retire the last ACTIVE policy'
          USING ERRCODE = 'P7103';
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_policy_versions_invariants ON public.policy_versions;

CREATE TRIGGER trg_policy_versions_invariants
BEFORE INSERT OR UPDATE OR DELETE ON public.policy_versions
FOR EACH ROW
EXECUTE FUNCTION public.enforce_policy_version_invariants();
```

**Note:** you *can* keep the unique partial index; tests can now assert:

* transition violations → `P7101`
* delete violations → `P7102`
* “last active” guard → `P7103`
  and reserve `23505` for genuine concurrency edge cases.

---

### 3.2 Ingress Attestations: add state-machine invariants (extend `0011_ingress_attestations.sql`)

Keep your existing append-only trigger (`P0001`) and add a **state integrity trigger** with explicit codes.

```sql
-- INGRESS SQLSTATE CODES
-- P7301: invalid_attestation_state

CREATE OR REPLACE FUNCTION public.enforce_ingress_attestation_state()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- once started, cannot be unset
  IF OLD.execution_started = TRUE AND NEW.execution_started = FALSE THEN
    RAISE EXCEPTION 'execution_started is monotonic'
      USING ERRCODE = 'P7301';
  END IF;

  -- once completed, cannot be unset
  IF OLD.execution_completed = TRUE AND NEW.execution_completed = FALSE THEN
    RAISE EXCEPTION 'execution_completed is monotonic'
      USING ERRCODE = 'P7301';
  END IF;

  -- completed implies started
  IF NEW.execution_completed = TRUE AND NEW.execution_started = FALSE THEN
    RAISE EXCEPTION 'execution_completed requires execution_started'
      USING ERRCODE = 'P7301';
  END IF;

  -- terminal_status required when completed
  IF NEW.execution_completed = TRUE AND (NEW.terminal_status IS NULL OR NEW.terminal_status = '') THEN
    RAISE EXCEPTION 'terminal_status required when execution_completed'
      USING ERRCODE = 'P7301';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ingress_attestation_state ON public.ingress_attestations;

CREATE TRIGGER trg_ingress_attestation_state
BEFORE UPDATE ON public.ingress_attestations
FOR EACH ROW
EXECUTE FUNCTION public.enforce_ingress_attestation_state();
```

This keeps the “append-only semantics” trigger (`P0001`) for disallowed UPDATE/DELETE, while allowing **controlled updates** if you still want `execution_started/execution_completed` toggles. If you truly want *no updates at all*, keep only the immutability trigger and drop this one.

---

### 3.3 Revocation tables: keep append-only (`P0001`) and add format checks (optional)

If you want deterministic “bad token hash” failures:

```sql
-- REVOCATION SQLSTATE CODES
-- P7201: invalid_revocation_input

CREATE OR REPLACE FUNCTION public.validate_revocation_inputs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_TABLE_NAME = 'revoked_tokens' THEN
    -- example: require hex sha256 (64 chars). Adjust to your actual token hash format.
    IF NEW.token_hash !~ '^[0-9a-f]{64}$' THEN
      RAISE EXCEPTION 'token_hash must be lowercase hex sha256'
        USING ERRCODE = 'P7201';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_validate_revoked_tokens ON public.revoked_tokens;

CREATE TRIGGER trg_validate_revoked_tokens
BEFORE INSERT ON public.revoked_tokens
FOR EACH ROW
EXECUTE FUNCTION public.validate_revocation_inputs();
```

If format is UNKNOWN, skip this and track it as a TODO.

---

## 4) Matching test assertions (Node test style)

### 4.1 Policy versions tests

* invalid transition → assert `P7101`
* delete forbidden → assert `P7102`
* retire last active (if enabled) → assert `P7103`

Example predicate:

```ts
function sqlState(err: unknown): string | undefined {
  const e = err as { code?: string; sqlState?: string; cause?: { code?: string; sqlState?: string } };
  return e.code ?? e.sqlState ?? e.cause?.code ?? e.cause?.sqlState;
}

// in test:
await assert.rejects(
  () => queryNoRole("UPDATE policy_versions SET status='ACTIVE' WHERE id=$1", ['some-grace-id']),
  (err) => sqlState(err) === 'P7101'
);
```

### 4.2 Ingress attestation state tests

* If you allow updates:

  * completed without started → `P7301`
  * completed without terminal_status → `P7301`
* If you enforce full immutability:

  * any update/delete → `P0001`

### 4.3 Role boundary tests remain native

Continue to assert **`42501`** for privilege proofs.

---

## 5) “Apply SQLSTATEs across the whole database” — what you do next

1. **Implement Policy SQLSTATE triggers** (`P71xx`) — this is the biggest missing piece right now.
2. Decide ingress semantics:

   * **Strict append-only**: keep `P0001` immutability, no updates ever.
   * **Controlled updates**: add `P7301` state-machine trigger and *relax* immutability accordingly.
3. Optionally add revocation input validation (`P7201`) once the hash format is finalized.
4. Update/extend unit+integration tests to assert the new SQLSTATEs:

   * Governance tests (policy) should assert `P71xx`, not `23514/23505`.
   * Operational/role tests should continue to assert `42501`.
   * Immutability tests should assert `P0001` (or switch to dedicated `P72xx/P73xx` if you want to differentiate).

---

## Open invariant questions (so we don’t encode the wrong rules)

* Should `policy_versions` be **fully immutable** after insert, or do you allow updates to `description/activated_at`?
* Must the system always have **exactly one ACTIVE** policy, or “at least one ACTIVE”?
* For ingress attestations: do you want **strict append-only** (no updates), or controlled updates for execution tracking?

If you answer those, I can tighten the triggers to exactly match your intended audit posture (and remove any optional pieces).
