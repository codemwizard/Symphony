# Symphony Task Verification & Compliance Process

This document is the **Authoritative Guide for Task Verification and Implementation Compliance**. It dictates the mandatory process any agent or developer must follow to prove that a task is implementation-ready and structurally/behaviorally sound.

> [!WARNING]
> **No "Verification Theatre" Permitted.** Passing a verifier script does not automatically guarantee compliance. Verifiers must prove *observable business logic execution* using realistic database states, not just string matching or schema side-effects.

---

## 1. Prerequisites: Governance & Metadata Validation

Before any code is modified or a database verifier is written, the task's administrative state must be locked.

1. **Task Metadata Definition:** A `meta.yml` (and associated `PLAN.md`) must exist, adhering strictly to the `TASK_AUTHORING_STANDARD_v2.md`.
2. **Preflight Checks:** The following verifiers must pass, proving the task is registered in the governance ledger:
   * `scripts/audit/verify_task_plans_present.sh`
   * `scripts/audit/verify_task_meta_schema.sh`

---

## 2. Dependency Discovery & The Canonical Seed

You cannot test an isolated component without mapping its surrounding data reality.

### 2.1 Map the "Full Chain of Dependencies"
Before writing a verifier, map the full relational tree for the component being tested. 
*Example for Policy Decisions:* `billable_clients` → `tenants` → `projects` → `interpretation_packs` → `execution_records` → `policy_decisions`.

### 2.2 Use the Master Canonical Seed
All behavioral verification MUST rely on the **Master Canonical Seed Script**:
* **Location:** `scripts/dev/seed_canonical_test_data.sql`
* **Purpose:** This script satisfies all `NOT NULL`, `CHECK`, and `FOREIGN KEY` constraints across the dependency chain. 
* **Rule:** If you discover a new schema constraint during implementation, **do not bypass it or swallow the error in your verifier**. You must take a step back and expand the Canonical Seed Script to naturally satisfy the new constraint.

---

## 3. Writing the Behavioral Verifier (Test-Driven Compliance)

Verifiers are the ultimate source of truth. They must be written and executed *before* marking a task as implemented.

### 3.1 Strict Behavioral Constraints
A valid verification script MUST:
* **Import the Production Implementation:** Do not simulate the logic; invoke the actual class method, database function, or `pre_ci.sh` routine.
* **Assert Observable Outcomes:** The test must prove a DB call sequence, a thrown custom exception (e.g., `SQLERRM LIKE '%GF061: K13 violation%'`), a status transition, or an emitted event.
* **Reject Generic Errors:** Do not allow verifiers to pass on generic database errors (like `not-null violation` or `foreign_key_violation`) if the objective is to prove a specific business-logic trigger.

### 3.2 Required Test Coverage
Every verifier script must include:
1. **Structural Checks:** Asserting that required columns, triggers, and functions exist in the schema.
2. **Negative Behavioral Tests (Failure Path):** Proving that the system actively rejects invalid state using the Canonical Seed Data.
3. **Positive Behavioral Tests (Success Path):** Proving that the system accepts a fully compliant, correctly chained payload.

---

## 4. Execution Confinement & Evidence Generation

All testing and evidence generation must occur within a constrained environment to prevent drift and ensure reproducibility.

1. **Run in ORIGIN / FRESH_DB Mode:** Tests must be executed against a parity-matched database environment (e.g., `FRESH_DB=1` in `pre_ci.sh`).
2. **Evidence Artifacts:** Upon successful execution, the verifier must generate a strict JSON payload documenting the observed hashes and results.
3. **Location:** Evidence must be saved to the appropriate phase directory (e.g., `evidence/phase2/tsk_p2_preauth_007_xx.json`).

---

## 5. Final Certification: The Pre-CI Gate

A task is never complete until it survives the continuous integration simulation.

* **Execute `scripts/dev/pre_ci.sh`:** This script acts as the final arbiter.
* **Zero Exceptions:** It enforces DRD lockouts, cryptographic provenance (`PRECI_STEP`), execution confinement, and structural parity.
* **Certification:** If `pre_ci.sh` exits with code `0`, the task is officially verified and compliant. If it fails, the task returns to Phase 2 (Dependency Discovery & Canonical Seed updating).
