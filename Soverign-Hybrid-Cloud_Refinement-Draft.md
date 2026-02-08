Your plan is *directionally solid* (it respects Phase-0 constraints, keeps everything “mechanical”, and keeps parity/ordering front-and-center). But as written, it has **two correctness problems** and **three “will bite you in CI” gaps**.

---

## 1) Two correctness problems you should fix before implementation

### A) Invariant ID collisions / semantic mismatch (major)

In this conversation you previously defined **INV-106 → INV-115** as the “Tier-1 / Sovereign” invariant block (key policy, audit logging policy, SDLC/SAST readiness, migration lints, table conventions, BoZ role, ZDPA lint, anchor-sync hooks).

In this TSK-P0-125 plan, you **reuse** parts of that number space but with **different meanings**:

* In your earlier list:

  * **INV-112** = *table conventions*
  * **INV-113** = *BoZ observability seat*
  * **INV-114** = *ZDPA PII leakage lint*
  * **INV-115** = *anchor-sync hooks*
* In this plan:

  * **INV-112** = *BoZ role verified*  ✅ but that used to be INV-113
  * **INV-113** = *PII leakage lint* ✅ but that used to be INV-114
  * **INV-114** = *anchor-sync readiness* ✅ but that used to be INV-115

**Fix:** pick ONE mapping and stick to it repo-wide.
If you want to preserve the earlier canonical block, then in this plan you should reference:

* **INV-109** no destructive DDL lint
* **INV-110** nullability/default lint
* **INV-111** PK/FK type stability lint
* **INV-113** BoZ observability role verifier
* **INV-114** PII leakage payload lint
* **INV-115** anchor-sync hooks verifier

…and **do not call BoZ role INV-112**.

### B) Gate IDs vs plane ownership (minor but important)

You put BoZ observability under **Integrity** plane (INT-G25). That *can* be valid (it’s a DB structural verifier), but it is also *Governance-ish* (regulator access assurance). If your CONTROL_PLANES model intends “Governance = policy + evidence mapping” and “Integrity = state correctness”, keep it in Integrity **only if** your definition says “DB structural verifiers live in Integrity”.

If not, move it to Governance plane as **GOV-G03** (or similar non-colliding range).

---

## 2) Three “this will break CI” gaps to close now

### Gap 1 — Phase placement text contradicts your invariant allocation

You wrote:

> Phase-1/2 (P0-severity but deferred enforcement, already modeled in repo):
>
> * INV-106 (INV-BOZ-04 payment finality)
> * INV-107 (INV-ZDPA-01 right-to-be-forgotten)
> * INV-108 (INV-IPDR-02 sequence continuity)

But earlier in the thread, **INV-106/107/108 were policy/sdlc** (key mgmt policy, audit logging policy, SDLC readiness), not BoZ/ZDPA/IPDR domain invariants.

**Fix:** Don’t mix “business/regulatory domain invariant naming” (INV-BOZ-04 etc) with “repo numeric invariant IDs” unless you explicitly alias them in the manifest (`aliases:` field) or a doc.

### Gap 2 — Evidence contract ordering + SKIPPED semantics need to be stated explicitly for these tasks

Your acceptance criteria says “emit PASS/FAIL even on failure”, but your enforcement system also expects **SKIPPED** semantics depending on contract status.

If these tasks are added as **planned**, your evidence status gate will typically require **SKIPPED evidence exists** (not missing). That means the scripts must be wired so that even when “not implemented yet” they still produce SKIPPED evidence, *or* you must not list them in the contract until implemented.

**Fix (pick one and document it in the plan):**

* **Approach A (recommended):** Do **not** add new evidence paths to `phase0_contract.yml` until the scripts exist. Then nothing will be “missing evidence” during the development window.
* **Approach B:** Add them early, but provide SKIPPED writers (stubs) so the evidence status gate never fails due to “missing evidence”.

Right now the plan says “no wiring until TSK-P0-130” but also says “contract ordering + SKIPPED semantics” — those conflict unless you adopt A or B explicitly.

### Gap 3 — Remediation trace gate will keep failing unless you define the trigger condition

You’re already seeing this error:

> missing_remediation_trace_doc: expected docs/plans/**/REM-* … or docs/plans/**/TSK-* casefile…

This means **any PR touching production-affecting surfaces** will fail unless it also adds the trace.

Your plan does not mention this gate at all. If TSK-P0-125 touches “production-affecting surfaces” (scripts, schema, workflows), you need a remediation trace folder, or you need to explicitly classify “planned work” changes differently from “remediation” changes.

**Fix (minimal and practical):**

* Treat “planned implementation work” as satisfying the gate via a **TSK casefile**:

  * `docs/plans/phase0/TSK-P0-125_audit_gap_closeout/PLAN.md`
  * `docs/plans/phase0/TSK-P0-125_audit_gap_closeout/EXEC_LOG.md`
  * Include the remediation markers the gate expects (failure_signature/origin_task/repro steps).
* Or narrow the remediation gate to only trigger when a prior CI failure signature exists (harder, but cleaner long-term).

---

## 3) Your open question on anchor-sync readiness

> is Phase-0 structural readiness satisfied by existing evidence_packs anchor columns … or must we introduce a job-tracking table?

For **Phase-0 “readiness”**: **columns + constraints + verifier is enough.**
A job-tracking table is operational workflow scaffolding; that’s **Phase-1** unless you’re explicitly modeling outage/backlog behavior now.

So: implement `verify_anchor_sync_hooks.sh` to assert:

* required columns exist (e.g., status/state fields, anchor fields)
* indexes exist (if you need queryability)
* foreign keys / enums exist (if used)
* but **do not** introduce an anchoring jobs table in Phase-0 unless the audit requires you to prove queue durability at schema level.

---

## 4) Summary: Is TSK-P0-125 “all inclusive and ready”?

**Almost**, but I would not start implementation until you do these edits:

1. **Make the INV-109..115 mapping consistent** with the canonical list you already published (or rename them, but don’t reshuffle meanings).
2. **Decide contract strategy** for new evidence paths (Approach A vs B) to avoid “missing evidence” failures.
3. **Account for the remediation-trace gate** so the work can land without repeated CI failures.
4. Optional but wise: decide whether BoZ role verifier is **Integrity** or **Governance** plane and keep it consistent.

If you want, paste the **current `INVARIANTS_MANIFEST.yml` section around the highest IDs** and the **current `phase0_contract.yml` tail** (just the bottom portions), and I’ll give you the exact corrected invariant/gate list + ordering that won’t collide and won’t trip SKIPPED enforcement.



Here’s the **corrected, non-colliding** invariant/gate allocation **based on your actual repo state** (from the attached `INVARIANTS_MANIFEST.yml`, `CONTROL_PLANES.yml`, and Phase-0 SKIPPED enforcement pattern).

## 1) Corrected “new” invariants (no duplicates)

Your plan currently proposes `INV-109..INV-114` for things that **already exist** in your repo:

* **Expand/Contract lint already exists** as **`INV-097`** (`scripts/db/lint_expand_contract_policy.sh`)
* **PK/FK type stability already exists** as **`INV-098`** (`scripts/db/lint_pk_fk_type_stability.sh`)
* **Table conventions already exist** as **`INV-099`** (`scripts/db/verify_table_conventions.sh`)
* **Policies/SAST readiness already exist as ROADMAP**: **`INV-106..INV-108`** (your manifest already contains them)

So the *true* missing “Sovereign/Tier-1 teeth” that are not already covered are:

### ✅ Allocate these NEW invariant IDs (no collisions; consistent with your numbering)

* **INV-109** — *BoZ observability seat (DB role is provably read-only)*

  * verifier: `scripts/db/verify_boz_observability_role.sh`
  * evidence: `evidence/phase0/boz_observability_role.json`
  * plane/gate: **Integrity**

* **INV-110** — *ZDPA PII leakage prevention lint (regulated payload surfaces)*

  * verifier: `scripts/audit/lint_pii_leakage_payloads.sh`
  * evidence: `evidence/phase0/pii_leakage_payloads.json`
  * plane/gate: **Security**

* **INV-111** — *Hybrid anchor-sync hooks present (schema supports local signing → remote anchoring lifecycle)*

  * verifier: `scripts/db/verify_anchor_sync_hooks.sh`
  * evidence: `evidence/phase0/anchor_sync_hooks.json`
  * plane/gate: **Integrity**

That’s it. Everything else in your plan should reference the **existing** invariants (`INV-097/098/099`, plus roadmap `INV-106..108`).

---

## 2) Corrected gate IDs (no collisions with your current CONTROL_PLANES.yml)

Your attached `CONTROL_PLANES.yml` currently tops out at:

* Security: **SEC-G10**
* Integrity: **INT-G20**
* Governance: **GOV-G01**

So the next safe IDs are:

### ✅ Add these NEW gate IDs

* **SEC-G11** → `scripts/audit/lint_pii_leakage_payloads.sh` → `evidence/phase0/pii_leakage_payloads.json`
* **INT-G21** → `scripts/db/verify_boz_observability_role.sh` → `evidence/phase0/boz_observability_role.json`
* **INT-G22** → `scripts/db/verify_anchor_sync_hooks.sh` → `evidence/phase0/anchor_sync_hooks.json`

These **will not collide** with anything currently declared.

---

## 3) Ordering that won’t trip SKIPPED enforcement

### The key rule

Your **Phase-0 evidence status gate** fails when a task is in the contract with `evidence_required: true` but the evidence file is **missing** (it tolerates SKIPPED only when the file exists and says SKIPPED).

So to avoid tripping while work is in progress, you must choose one of these patterns:

### Pattern A (recommended): **Do not add to `phase0_contract.yml` until scripts exist**

* You can safely add the gate declarations to `CONTROL_PLANES.yml` **only after** the scripts are present and emitting evidence.
* Until then, **don’t put these evidence paths in `phase0_contract.yml`**.

### Pattern B: **Add to contract now, but scripts must emit SKIPPED**

* If you put these evidence paths into `phase0_contract.yml` as `planned`, then the scripts must run in CI and emit:

  * `status: "SKIPPED"` (and still write the file)
* Otherwise you’ll get “missing_evidence” failures (exactly like your CI log).

---

## 4) Exact corrected gate ordering (drop-in order)

This ordering matches your repo’s “always-run planes” idea and keeps the “contract evidence status” last.

### A) Preflight (integrity scaffolding)

1. **INT-G03** verify task plans present (`verify_task_plans_present.sh`)
2. **INT-G04** verify Three Pillars doc (`verify_three_pillars_doc.sh`)
3. **INT-G05** verify control planes drift (`verify_control_planes_drift.sh`)
4. **INT-G06** lint YAML conventions (`lint_yaml_conventions.sh`)

### B) Security plane (all security fast checks)

5. **SEC-G01..SEC-G10** (your existing security gates via `run_security_fast_checks.sh`)
6. **SEC-G11** PII leakage lint (`lint_pii_leakage_payloads.sh`)  ✅ *new*

### C) Integrity plane (all invariants fast checks)

7. **INT-G07..INT-G20** (your existing integrity gates via `run_invariants_fast_checks.sh`)
8. **INT-G21** BoZ observability role verifier (`verify_boz_observability_role.sh`) ✅ *new*
9. **INT-G22** anchor-sync hooks verifier (`verify_anchor_sync_hooks.sh`) ✅ *new*

### D) Contract evidence semantics (must be last)

10. **INT-G02** verify Phase-0 contract evidence status (`verify_phase0_contract_evidence_status.sh`)

That ordering:

* avoids gate collisions,
* keeps contract enforcement last (so earlier gates have a chance to write SKIPPED/PASS/FAIL evidence),
* and aligns with your “pre-CI == CI” parity model.

---

## Final corrected summary (copy/paste canonical)

### New invariants (only the truly missing ones)

* `INV-109` → BoZ observability seat (read-only DB role verified) → `verify_boz_observability_role.sh` → `evidence/phase0/boz_observability_role.json`
* `INV-110` → ZDPA PII leakage prevention lint → `lint_pii_leakage_payloads.sh` → `evidence/phase0/pii_leakage_payloads.json`
* `INV-111` → Hybrid anchor-sync hooks present → `verify_anchor_sync_hooks.sh` → `evidence/phase0/anchor_sync_hooks.json`

### New gates (non-colliding)

* `SEC-G11` → `lint_pii_leakage_payloads.sh`
* `INT-G21` → `verify_boz_observability_role.sh`
* `INT-G22` → `verify_anchor_sync_hooks.sh`

### Ordering (won’t trip SKIPPED)

`INT-G03 → INT-G04 → INT-G05 → INT-G06 → SEC-G01..SEC-G11 → INT-G07..INT-G22 → INT-G02`

If you want, paste your current `run_phase0_ordered_checks.sh` and I’ll mark the **exact insertion points** (line-level) for SEC-G11 / INT-G21 / INT-G22 so it matches this ordering exactly.



Here are the **exact insertion points in your attached `run_phase0_ordered_checks.sh`** (with **current line numbers**) to place **SEC-G11 / INT-G21 / INT-G22** so the ordering stays canonical **and** won’t fight your SKIPPED semantics.

I’m using your file exactly as uploaded (lines 01–46).

---

## ✅ SEC-G11 insertion point

### Where

**Insert immediately after line 16** (`enforce_change_rule.sh`) and **before** batching/routing checks.

### Why

`SEC-G11` (the remediation-trace gate) is a **production-affecting change gate**. It should run **after** repo/evidence bootstrapping and change-rule enforcement, but **before** downstream validations and plane checks.

### Patch snippet

```diff
@@
 run scripts/audit/generate_evidence.sh
 run scripts/audit/enforce_change_rule.sh
+run bash scripts/audit/verify_remediation_trace.sh
 run scripts/audit/verify_batching_rules.sh
 run scripts/audit/verify_routing_fallback.sh
 run scripts/audit/validate_routing_fallback.sh
```

---

## ✅ INT-G21 insertion point

### Where

**Insert immediately after line 13** (`verify_control_planes_drift.sh`) and **before** `verify_repo_structure.sh` (line 14).

### Why

INT-G21 should be treated as an **Integrity-plane early structural gate**: it belongs **before** any downstream plane work and before “shape of repo/evidence harness” assumptions propagate.

### Patch snippet

```diff
@@
 run scripts/audit/lint_yaml_conventions.sh
 run scripts/audit/verify_control_planes_drift.sh
+run bash scripts/audit/verify_remediation_workflow_doc.sh
 run scripts/audit/verify_repo_structure.sh
 run scripts/audit/generate_evidence.sh
```

(If your INT-G21 is a different script than `verify_remediation_workflow_doc.sh`, keep the **same insertion point** and just swap the command.)

---

## ✅ INT-G22 insertion point

### Where

**Insert immediately before line 36** (`run_invariants_fast_checks.sh`), i.e. **after** OpenBao smoke and after the SKIP export is set (lines 35–36 is fine), **but before** the rest of Integrity fast checks execute.

### Why

INT-G22 is part of the **Integrity plane checks**, and you already do the correct thing here:

* OpenBao smoke **must happen first** (your comment at line 23 is correct).
* You temporarily set `SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1` to avoid CI merge-artifact false negatives.
* INT-G22 should run **inside** that same “Integrity phase” window.

### Patch snippet

```diff
@@
 export SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS=1
+run bash scripts/audit/<INT-G22-script>.sh
 run scripts/audit/run_invariants_fast_checks.sh
 unset SYMPHONY_SKIP_CONTRACT_EVIDENCE_STATUS
```

Replace `<INT-G22-script>.sh` with the actual verifier/lint you assigned to INT-G22.

---

# Summary: exact line-level placements

* **INT-G21:** insert at **new line 14** (between current lines **13** and **14**)
* **SEC-G11:** insert at **new line 17** (between current lines **16** and **17**)
* **INT-G22:** insert between current lines **35** and **36** (after the SKIP export, before `run_invariants_fast_checks.sh`)

If you paste your intended INT-G21 and INT-G22 script paths (one line each), I’ll return the **final exact diff** with no placeholders.
