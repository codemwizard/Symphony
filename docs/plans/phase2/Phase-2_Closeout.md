


Here is how Gemini classifies the changes by Phase. This means according to Gemini, only one task needs to be done right now. Do you agree?:
Phase 0: Hardened Baseline (Inherited Constraint)
Target: Multi-tenant Isolation (RLS Bypass)
Context: The PHASE_EXECUTION_ENVELOPE.md (§9) mandates that no Phase-2 task may relax prior phase constraints. Phase 0 requires unbypassable tenant isolation.
Unresolved Obligation: The terminal migration state (0096_rls_admin_governance.sql) physically hardcodes an administrative backdoor: OR (current_setting('app.bypass_rls'::text, true) = 'on'::text).
Required Task: Remove the app.bypass_rls toggle condition from all RLS policies to satisfy the "Hardened Baseline" invariant before Phase 2 closeout can be considered.
Phase 5: Adapter Refactor & Methodology Runtime
Target: Hardcoded Methodology Logic (PWRM0001)
Context: Phase 5 (§5.11) objective is to convert Symphony into an adapter-governed runtime where no methodology logic exists in the core.
Unresolved Obligation: The Ledger API binary currently embeds methodology-specific execution logic (e.g., Pwrm0001MonitoringReportHandler.cs, Pwrm0001ArtifactTypes.cs) directly in the core .NET application.
Required Task: Refactor all PWRM0001 domain classes out of the Ledger API codebase. Express the methodology strictly as a governed adapter package within the Adapter Execution Sandbox (Objective 5.5).
Phase 6: UI and Field Reality Layer
Target: Offline Capture Forensic Logic (Dwell Time)
Context: Phase 6 (§6.5) mandates that offline events be "verified for temporal consistency on receipt" and gap periods ("dwell time") greater than a threshold must be flagged.
Unresolved Obligation: While ingress_attestations accepts offline data, the terminal schema lacks the database trigger or validation logic to calculate the delta between device capture and network ingestion.
Required Task: Implement a database trigger on ingress_attestations to mathematically evaluate network_receipt_time - device_capture_time and structurally flag payloads breaching the sync limit (Objective 6.5).
Phase 8A: Sovereign Authorization Layer
Target: Sovereign Authorization Schema (LoA/AER)
Context: Phase 8A (§8A.4 and §8A.6) requires the system to ingest, hash, and bind host-country Letters of Authorization (LoA) to maintain Article 6-eligibility.
Unresolved Obligation: The terminal migration state (0203_converge_policy_decisions_schema.sql) provides foundation records but contains zero schema objects for recording Sovereign LoAs or Corresponding Adjustments.
Required Task: Materialize database migrations to provision the sovereign_authorizations table and create the binding logic to upgrade credits to "Article 6-eligible" status (Objective 8A.6).
Verification of Current Baseline (Pre-Phase 3)
The following items are confirmed as Resolved or Active within the current Phase 2 execution surface and do not require new Phase 3-8 tasks:
Cryptographic Enforcement: Migration 0190 successfully restores mathematical ed25519_verify() enforcement at the DB boundary, satisfying the Phase 2 substrate requirement.
Verifier Script Location: All Wave 4 Pre-Auth verifiers have been relocated from lost_verify/ to canonical validation paths (scripts/db/), satisfying the Phase 1/Phase 2 prerequisite for active validation.
Execution DAG: TSK-P2-W8-GOV-001 is correctly identified as the "In Progress" apex blocker in the PHASE_EXECUTION_ENVELOPE.md. Implementation of the remaining Wave 8 tasks is gated until this task reaches "True-Complete."
Ed25519 Probes: The C# environment fidelity probes are physically present and wired to the active verifier verify_tsk_p2_w8_sec_000.sh.



No. That conclusion is too aggressive, and the “only one task right now” reading is wrong.

Gemini’s phase classification is useful, but the interpretation is off.

It correctly separated obligations by **phase ownership**.
It did **not** prove only one task is executable now.

Those are different claims.

What Gemini actually proved is:

> only one contradiction is an immediate **Phase 2 closeout gate**.

That is not the same as:

> only one task needs to be done right now.

That leap is where the reasoning breaks.

---

# What Gemini actually established

Gemini grouped contradictions by **where they belong architecturally**:

* **Phase 0** → baseline invariant violation
* **Phase 5** → adapter architecture debt
* **Phase 6** → field ingestion enforcement debt
* **Phase 8A** → sovereign authorization capability gap

That classification is good.

But phase ownership is not execution priority.

It only tells you **which phase owns the fix**, not **whether the fix blocks Phase 2 closure**.

That distinction matters.

---

# What is actually true right now

You do **not** have one task.

You have **one immediate Phase 2 closure blocker**
plus **three deferred phase-owned obligations**.

That is the real state.

---

# What must be done now (immediate)

## 1. RLS bypass removal — do now

This is the only immediate Phase 2 closeout blocker.

Why:

* it violates inherited baseline invariants
* it is active in terminal schema
* it weakens current production security guarantees
* it invalidates “Phase 2 hardened substrate” claims

This is not future work.
This is unresolved current-phase substrate debt.

Gemini is correct that this must be done now.

This is the only contradiction that blocks truthful Phase 2 closure.

---

# What is real but not immediate Phase 2 closeout work

These are real contradictions.
They are just not immediate Phase 2 closeout blockers.

That does **not** mean “do nothing now.”

It means: do not lie and pretend they are Phase 2 closure gates.

They must be carried forward explicitly.

---

## 2. PWRM0001 adapter extraction — real, but Phase 5-owned

This is real.

Gemini is right that the contradiction exists.

But this is not a Phase 2 substrate blocker.

Why:

* it violates Phase 5 architecture purity
* it does not invalidate current Phase 2 substrate enforcement
* it is architectural debt, not substrate falsification

So this is not “do now before Phase 2 closes.”

It is:

* explicitly carry forward as unresolved Phase 5 implementation debt
* do not mark Phase 5 adapter runtime as complete
* do not claim methodology decoupling is done

Real contradiction. Not immediate Phase 2 closeout blocker.

---

## 3. Dwell-time enforcement — real, but Phase 6-owned

Also real.

Also not immediate Phase 2 closeout blocking.

Why:

* it is a field-ingestion forensic control
* absence weakens future Phase 6 intake assurance
* but it does not invalidate Phase 2 substrate closure unless Phase 2 explicitly claimed 6.5 complete

That last part matters.

If Phase 2 claimed “offline forensic sync enforcement complete,” then this becomes a closure blocker.

If not, it is Phase 6 carry-forward debt.

That one depends on what was formally claimed.

So this is conditional, not automatically immediate.

---

## 4. Sovereign LoA / AER schema — real, but Phase 8A-owned

This is plainly real.

But it is not Phase 2 work.

This is future capability absence, not current substrate contradiction.

It does not block Phase 2 closure unless someone falsely claimed Article 6 sovereign authorization is already implemented.

If no such claim was made, this is not a blocker.
It is simply unbuilt Phase 8A scope.

So this is not remediation-now.
It is explicit future-phase obligation.

---

# Correct interpretation

Gemini proved:

* **1 immediate closeout blocker**
* **3 real deferred obligations**

It did **not** prove:

* only one task exists
* only one task matters
* everything else can be ignored

That would be false.

---

# Correct operational conclusion

## Do now

* Remove `app.bypass_rls`
* rerun RLS runtime proof
* re-baseline
* re-close Phase 2 substrate truthfully

## Carry forward explicitly (not optional)

* PWRM0001 adapter extraction → Phase 5 unresolved
* Dwell-time forensic enforcement → Phase 6 unresolved
* Sovereign LoA / AER schema → Phase 8A unresolved

These are not “later maybe.”

They are real obligations, just not immediate Phase 2 closure gates.

---

# Bottom line

No, I do not agree that only one task needs to be done right now.

I agree that only **one task is an immediate Phase 2 closure blocker**.

That is the correct reading.

Everything else is still real.
It just belongs in explicit carry-forward, not false immediate closure.



Review:
Created Program.cs
Created WAVE8-Wave_8_Closure_and_Remediation_Implementation.md
Created WAVE8-Wave_8_Closure_and_Remediation_Task.md
Created exception_change-rule_migration_file_added_or_deleted_2026-05-05.md
Created Wave8_CI_Convergence_Issues.md
Created PLAN.md
Created PLAN.md
Created PLAN.md
Created PLAN.md
Created DRD.md

Here is the task breakdown based on the corrected interpretation you provided:

---

## Immediate Phase 2 Closeout Blocker

### Task 1: Remove `app.bypass_rls` from All RLS Policies

| Field | Value |
|---|---|
| **Phase** | Phase 0 (inherited constraint enforced at Phase 2 closeout) |
| **Priority** | **Blocking** — must complete before Phase 2 can truthfully close |
| **Target** | Migration `0096_rls_admin_governance.sql` and terminal schema state |
| **Obligation** | All RLS policies currently contain `OR (current_setting('app.bypass_rls'::text, true) = 'on'::text)` — this is a hardcoded administrative backdoor that violates the Phase 0 "unbypassable tenant isolation" invariant |

**Sub-tasks:**

1. **Audit**: Enumerate every RLS policy in the terminal schema that references `app.bypass_rls`. Determine the full list of affected tables.
2. **Migration**: Write a forward-only migration that `DROP POLICY` + `CREATE POLICY` for each affected table, removing the bypass condition entirely.
3. **Application Code Audit**: Search `Program.cs` and all `.cs` files for `set_config('app.bypass_rls'` calls. The current `Program.cs` you just created contains at least one instance (in `SeedDemoTenant` around line 2750). These must be removed or refactored.
4. **Seed Logic Refactoring**: The pilot-demo tenant seeding currently relies on `app.bypass_rls = 'on'` to insert across tenants. This must be replaced with a different mechanism (e.g., superuser connection, or explicit `SET ROLE` to a seeding role that has legitimate access).
5. **Re-baseline**: Regenerate `schema/baseline.sql` and baseline snapshots.
6. **RLS Runtime Proof**: Re-run the RLS runtime verification scripts to prove tenant isolation holds without the bypass toggle.
7. **Evidence**: Produce verifier evidence that the bypass is gone from all policies and the runtime enforcement is intact.

> **This is the only task that gates Phase 2 closure.**

---

## Deferred Phase-Owned Obligations (Carry-Forward, Not Immediate)

These are **real contradictions** that must be explicitly documented as unresolved carry-forward debt. They are **not** Phase 2 closeout blockers, but they **cannot be silently ignored**.

### Task 2: PWRM0001 Adapter Extraction (Phase 5)

| Field | Value |
|---|---|
| **Phase** | Phase 5 (Adapter Refactor & Methodology Runtime) |
| **Priority** | Carry-forward — document as unresolved Phase 5 debt |
| **Target** | `Pwrm0001MonitoringReportHandler.cs`, `Pwrm0001ArtifactTypes.cs`, and all PWRM0001 domain classes in the Ledger API |
| **Obligation** | Phase 5 requires no methodology logic in the core runtime. Currently, methodology-specific classes are compiled directly into the API binary |

**Required now:** Create a carry-forward record documenting that Phase 5 adapter decoupling is incomplete. Do NOT claim Phase 5 methodology runtime is done.

**Required later (Phase 5 execution):** Extract all PWRM0001 classes into a governed adapter package within the Adapter Execution Sandbox (Objective 5.5).

---

### Task 3: Dwell-Time Forensic Enforcement (Phase 6)

| Field | Value |
|---|---|
| **Phase** | Phase 6 (UI and Field Reality Layer) |
| **Priority** | **Conditional** — becomes a blocker only if Phase 2 formally claimed Objective 6.5 as complete |
| **Target** | `ingress_attestations` table |
| **Obligation** | Phase 6 §6.5 requires offline events to be verified for temporal consistency. The schema currently lacks a trigger to calculate `network_receipt_time - device_capture_time` and flag payloads breaching the sync limit |

**Required now:** 
1. Check `PHASE_EXECUTION_ENVELOPE.md` to determine whether Phase 2 claimed Objective 6.5 as complete.
2. If claimed → this becomes an immediate blocker alongside Task 1.
3. If not claimed → create a carry-forward record for Phase 6.

---

### Task 4: Sovereign LoA / AER Schema (Phase 8A)

| Field | Value |
|---|---|
| **Phase** | Phase 8A (Sovereign Authorization Layer) |
| **Priority** | Carry-forward — future capability, not current substrate contradiction |
| **Target** | Terminal schema (post-migration 0203) |
| **Obligation** | Phase 8A §8A.4 and §8A.6 require schema objects for sovereign Letters of Authorization and Corresponding Adjustments. These do not exist |

**Required now:** Create a carry-forward record documenting that Phase 8A sovereign authorization schema is unbuilt. Do NOT claim Article 6-eligibility is implemented.

**Required later (Phase 8A execution):** Materialize the `sovereign_authorizations` table and binding logic.

---

## Summary

| # | Task | Phase Owner | Execution Timing | Blocks Phase 2? |
|---|---|---|---|---|
| 1 | Remove `app.bypass_rls` | Phase 0 (enforced at P2) | **Now** | **Yes** |
| 2 | PWRM0001 adapter extraction | Phase 5 | Carry-forward | No |
| 3 | Dwell-time enforcement | Phase 6 | Conditional (check claim) | **Maybe** |
| 4 | Sovereign LoA schema | Phase 8A | Carry-forward | No |

**Bottom line:** Task 1 is mandatory before Phase 2 closeout. Task 3 requires a claim-check against the envelope. Tasks 2 and 4 are explicit carry-forward records that must be created now but executed later.

Shall I proceed with creating the implementation plan for Task 1 (RLS bypass removal)?


The breakdown is mostly right, but there are two places where it can still mislead implementation if you follow it literally.

## What is correct

The structure is correct:

* **Task 1** is the only unconditional Phase 2 closeout blocker.
* **Task 2** is real but Phase 5-owned.
* **Task 4** is real but Phase 8A-owned.
* **Task 3** is conditional and must be claim-checked.

That part is sound.

The dangerous part is not the classification.
It is the implementation assumptions inside Task 1.

That is where this can still go wrong.

---

# What is still wrong in the Task 1 plan

## 1. “Remove `app.bypass_rls` from all RLS policies” is correct

## “remove all code paths that set it” is incomplete

That is too shallow.

The real task is not:

> remove the string

The real task is:

> remove the operational dependency on bypass semantics.

Those are not the same thing.

If you only strip the condition from policies and delete `set_config(...)`, you can break:

* bootstrap
* seeding
* tenant provisioning
* admin governance flows
* backfills
* repair scripts
* test fixtures
* operational tooling

That turns a security fix into an availability regression.

The real audit target is not just policy text.
It is the **entire execution surface that assumes bypass exists**.

So Task 1 needs one more explicit sub-task before migration:

### **Task 1.0 — Dependency Surface Audit (mandatory)**

Before touching policies, enumerate every operational path that assumes bypass semantics:

* application bootstrap
* seeding
* admin repair flows
* migration helpers
* test harnesses
* CI setup
* one-off operational scripts
* support tooling
* local dev bootstraps

Do not start with policy surgery.
Start with dependency discovery.

Otherwise you will remove the escape hatch before identifying what still breathes through it.

That is how you create a false “security fix” that detonates the platform.

---

## 2. “Replace with superuser or SET ROLE” is dangerously under-specified

This is the most dangerous line in the whole plan.

> “replace with superuser connection, or explicit SET ROLE”

That is not a plan. That is a liability.

A superuser replacement can easily recreate the same bypass in a less visible form.

That would be worse, not better.

If the answer becomes:

* “don’t use `app.bypass_rls`, use superuser instead”

then you did not remove the bypass.
You just moved it somewhere harder to audit.

That fails the objective.

The replacement mechanism must be:

* explicit
* scoped
* auditable
* non-default
* non-runtime ambient
* impossible to invoke accidentally in production request paths

That means:

* no ambient superuser application connections
* no hidden privileged fallback in runtime request handlers
* no “admin mode” connection string hacks
* no silent privilege escalation path in normal execution

If privileged seeding is required, it must be isolated into a **non-runtime administrative execution boundary**.

That means:

* separate administrative execution path
* separate role
* separate invocation surface
* explicit operator intent
* not available in request-serving runtime

If you do not enforce that boundary, you are just rebuilding the same backdoor under a different name.

---

## 3. Task 1 is not just schema + app

It is **schema + runtime + operational model**.

The plan currently frames Task 1 like this:

1. change policy
2. change code
3. rerun tests

That is incomplete.

It must be:

1. discover all bypass dependencies
2. classify them (runtime / admin / seed / test)
3. remove runtime dependency first
4. isolate privileged operational paths
5. then rewrite policies
6. then rerun runtime proof
7. then rerun operational proof
8. then rebaseline

That is the correct order.

Anything else is how you create fake closure.

---

# What must be added before proceeding

Task 1 needs one explicit precondition inserted before implementation:

## **Task 1.0 — Bypass Dependency Inventory (required before remediation)**

Produce a full dependency inventory of every place `app.bypass_rls` is assumed, including:

* SQL migrations
* policy definitions
* `Program.cs`
* seeding paths
* service startup
* repair jobs
* scripts
* tests
* fixtures
* CI bootstrap
* operational admin paths

For each dependency classify:

* **RUNTIME** → must be removed
* **ADMIN** → must be isolated
* **SEED** → must be refactored
* **TEST** → must be rewritten
* **MIGRATION** → must be made explicit and one-time only

Only after that do you touch the policies.

Without this, Task 1 is under-scoped and dangerous.

---

# Final verdict

The phase classification is correct.

The implementation framing is still incomplete.

Do **not** proceed directly to “implementation plan for Task 1.”

Proceed to:

> **Task 1.0 — Bypass Dependency Inventory**

first.

That is the real first task.
