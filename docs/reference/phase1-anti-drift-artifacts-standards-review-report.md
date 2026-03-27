# Phase 1 Anti-Drift Artifacts Standards Review Report

This report reviews the planned and created `TSK-P1-222` through `TSK-P1-235` artifacts for canonical quality, dependency integrity, and future-agent pickup safety.

## Overall verdict

The artifact set is **structurally strong but not yet fully up to standard for execution handoff**.

### What is already good
- All task packs `TSK-P1-222` through `TSK-P1-235` pass `verify_task_pack_readiness.sh`.
- Each reviewed task has complete metadata, a plan, and an append-only execution log.
- The Wave 2 tasks preserve the intended contract-bounded anti-drift design in their `intent`, `work`, `acceptance_criteria`, and `failure_modes`.
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md` registers the Wave 1 and Wave 2 tasks coherently.
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md` materially improves handoff clarity compared with leaving the order only in chat.

## Mechanical validation performed

Command run:

```bash
for task in TSK-P1-222 TSK-P1-223 TSK-P1-224 TSK-P1-225 TSK-P1-226 TSK-P1-227 TSK-P1-228 TSK-P1-229 TSK-P1-230 TSK-P1-231 TSK-P1-232 TSK-P1-233 TSK-P1-234 TSK-P1-235; do
  bash scripts/audit/verify_task_pack_readiness.sh --task "$task"
done
```

Result:
- all fourteen task packs passed readiness

## Findings

### Critical 1 — The canonical execution order is not fully encoded in task metadata

The repository now contains a canonical linear order, but the actual task metadata does not fully enforce that order through `depends_on`.
Because `RESUME-TASK` mode uses `depends_on` completion as the gating rule, another agent can still legally start some later tasks earlier than intended.

#### Evidence
- `tasks/TSK-P1-227/meta.yml:19-23`
  - `TSK-P1-227` depends only on `TSK-P1-222`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:42-64`
  - the canonical chain places `TSK-P1-227` after `TSK-P1-226`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:78`
  - the pickup queue compensates with the non-mechanical phrase `Wave 1 spine is stable enough`
- `tasks/TSK-P1-234/meta.yml:19-22`
  - `TSK-P1-234` depends only on `TSK-P1-224`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:62-64`
  - the canonical chain places `TSK-P1-234` after `TSK-P1-233`
- `tasks/TSK-P1-235/meta.yml:19-21`
  - `TSK-P1-235` depends only on `TSK-P1-234`, even though the documented linear chain treats Pack C as `233 -> 234 -> 235`

#### Why this matters
Under the repo’s own router rules, an agent checks `depends_on`, not narrative sequencing.
That means:
- `TSK-P1-227` is resume-eligible before the rest of Wave 1 is complete
- `TSK-P1-234` is resume-eligible well before `TSK-P1-233`
- the documented linear chain can still be bypassed by a standards-compliant agent

#### Standard impact
This is a **critical pickup-safety defect** because the repository contains two authorities:
- narrative order in the execution-order doc
- executable order in task metadata

Those authorities do not currently fully agree.

#### Recommended remediation
Choose one of these and apply it consistently:
1. **Encode the linear order mechanically** by tightening `depends_on` in the affected tasks.
2. **Explicitly declare branch parallelism** in the execution-order artifact if `TSK-P1-233` and `TSK-P1-234` are intentionally parallel after `TSK-P1-232`.

Minimum tasks to revisit first:
- `TSK-P1-227`
- `TSK-P1-234`
- possibly `TSK-P1-235`

### Major 2 — The pickup guide still contains non-mechanical and duplicate sequencing language

The handoff artifact is valuable, but parts of it are still too ambiguous for a future agent operating from repository state alone.

#### Evidence
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:78`
  - `Wave 1 spine is stable enough to harden future authoring`
  - this is not machine-checkable and not equivalent to `depends_on`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:142-150`
  - the downstream backlog includes `Local non-authoritative mirror path`, `CI downgrade protection / B7`, and `DB consistency / TOCTOU hardening`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:162-174`
  - the same or near-identical items appear again as `Local non-authoritative mirror path for operators`, `Promote B7 to blocking`, and `DB consistency and TOCTOU hardening`
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md:213-235`
  - the staged backlog repeats the same concepts again in later stages

#### Why this matters
A future agent may not know whether these are:
- the same backlog item with multiple phrasings
- separate tasks that still need distinct packs
- one implementation task plus one later promotion task

That weakens the repo handoff function the document was created to serve.

#### Recommended remediation
Normalize the downstream backlog into one of these shapes:
- exact future task IDs only, if those tasks will be created soon
- or one deduplicated backlog table with fields: `backlog_item`, `status`, `task_id_if_assigned`, `stage`, `depends_on`, `notes`

### Major 3 — The primary Phase 1 task index does not point readers to the execution-order artifact

The execution-order guide exists, but it is not referenced from the main Phase 1 task index section that registers `TSK-P1-222` through `TSK-P1-235`.

#### Evidence
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md:187-344`
  - the Wave 1 and Wave 2 tasks are registered
  - there is no pointer to `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md`

#### Why this matters
Another agent is likely to start from `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`.
If the index does not mention the separate ordering authority, the agent may rely only on `depends_on`, which is already not fully aligned with the intended chain.

#### Recommended remediation
Add one short note or subsection in the Wave 1 / Wave 2 area pointing to:
- `docs/tasks/RLS_ANTI_HALLUCINATION_EXECUTION_ORDER.md`

That would make the pickup guide discoverable from the primary governance index.

### Minor 4 — The plans and logs are canonical, but the review/approval preconditions are declarative only

The plan files consistently include preconditions such as `This PLAN.md has been reviewed and approved`, but the created task-pack set does not establish a linked approval mechanism for those preconditions.

#### Evidence
- `docs/plans/phase1/TSK-P1-222/PLAN.md:25-31`
- `docs/plans/phase1/TSK-P1-227/PLAN.md:25-30`
- `docs/plans/phase1/TSK-P1-232/PLAN.md:25-30`
- `docs/plans/phase1/TSK-P1-235/PLAN.md:25-29`

#### Why this matters
This is not currently a blocker for task-pack quality, but it leaves the phrase `reviewed and approved` as a manual convention rather than a verifiable handoff condition.

#### Recommended remediation
Either:
- keep this as a human convention and accept it as-is, or
- define a standard Phase 1 task-pack review marker if the repo wants this to become mechanically meaningful later

## Standards judgment by category

### Canonical task-pack completeness
- **Pass**
- The packs are complete, readable, and structured consistently.

### Dependency and ordering integrity
- **Needs remediation**
- The intended execution order is not yet fully reflected in `depends_on`.

### Scope and anti-drift quality
- **Pass**
- The task definitions stay narrow and preserve the contract-level anti-drift boundaries well.

### Governance and handoff quality
- **Needs remediation**
- The order artifact helps, but pickup safety is still weakened by metadata/order divergence and index discoverability gaps.

## Remediation order

Apply fixes in this order:

1. **Repair execution-order encoding in task metadata**
   - revisit `TSK-P1-227`, `TSK-P1-234`, and if needed `TSK-P1-235`
2. **Normalize the downstream backlog in the execution-order artifact**
   - remove duplicates and ambiguous aliases
3. **Register the execution-order artifact from the Phase 1 task index**
   - add a short pointer in `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
4. **Optionally standardize plan-review markers**
   - only if you want that convention enforced mechanically

## Final conclusion

The recent code-mode work is **good quality and materially improves the repo**, but it is **not yet fully handoff-safe** because the task metadata does not completely enforce the same order that the repository now documents.

The biggest gap is not task-pack structure.
The biggest gap is **execution-order authority drift between metadata and handoff documentation**.
