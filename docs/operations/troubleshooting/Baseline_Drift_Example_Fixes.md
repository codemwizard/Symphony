Let me read all five documents carefully.

Viewed baseline_drift_root_cause_analysis.md.resolved:1-133
Viewed WAVE5_TASK_CREATION_LESSONS_LEARNED.md:1-538
Viewed PHASE0_AUDIT_REPORT.md:1-90
Viewed PLANS-addendum_1.md:1-141
Viewed ARCHITECT_PHASE0_PROMPT.md:1-241

Now I have a thorough understanding. Here is exactly how much my plan changes:

---

## My Previous Approach Was Fundamentally Wrong

I was treating the baseline governance failure as a **git staging/commit visibility problem** — trying to make `git diff` see my ADR edit. That was wrong. The real issue is documented clearly in these files:

### What the Documents Tell Me

1. **`baseline_drift_root_cause_analysis.md`** — The baseline was regenerated from the **main DB** (which has divergent constraint names from incremental migrations). The correct fix was **Option A: write a convergence migration** (like `0203_converge_policy_decisions_schema.sql`). This migration was already created. The baseline should then be regenerated **from the fresh DB after applying all migrations including the convergence migration**, not from the main DB.

2. **`PLANS-addendum_1.md`** (Section 3, "Baseline update governance gate") — States explicitly: baseline updates require **both** a migration change in the same PR **and** an explanation artifact (`docs/decisions/ADR-0010-baseline-policy.md` or a plan log entry). The governance script checks for all three files appearing in the same `git diff` range.

3. **`WAVE5_TASK_CREATION_LESSONS_LEARNED.md`** — The governance gate uses `git diff --name-only merge_base...HEAD`, which only sees **committed** changes. My ADR edit is uncommitted, so the script can't see it.

4. **`PHASE0_AUDIT_REPORT.md`** — Confirms that baseline governance is enforced via `verify_baseline_change_governance.sh` and is a resolved Phase-0 gap. This is a canonical gate, not optional.

5. **`ARCHITECT_PHASE0_PROMPT.md`** — Reinforces that evidence discipline, fail-closed gates, and forward-only migrations are non-negotiable. No silent stubs or bypass hacks.

### What Changes

**My previous plan was to just edit the ADR and hope `git diff` would see it. That's wrong on two levels:**

1. The `git diff merge_base...HEAD` only sees committed code. My edit to `ADR-0010` is in the working tree, not in a commit on this branch. The governance script will **never** see it until it's committed.

2. I was treating the lockout as the problem instead of the symptom. The real workflow is:
   - **Commit the ADR change, the baseline, and the migration together** in a single commit on the branch
   - **Then** run `pre_ci.sh`, which will now see all three files in the `git diff` range against `origin/main`
   - If `pre_ci.sh` passes, push

### Revised Plan (3 steps)

1. **Commit all the Wave 8 convergence changes together** — The ADR update, the baseline files, migration 0203, the C# fixes, the projection script fix, and the structural exception. This makes the governance gate see all three required files (`baseline.sql` + `0203*.sql` + `ADR-0010`) in the same diff range.

2. **You run `pre_ci.sh`** — The governance gate will now pass because committed changes are visible to `git diff merge_base...HEAD`.

3. **If `pre_ci.sh` passes, push.** If it fails on something new, we amend the commit and re-run.
