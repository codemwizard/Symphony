# RLS Anti-Drift Wave 2 Task Plan

This plan compares the proposed anti-drift Tasks 6–10 against current Symphony conventions and the saved gap audit, then defines a stricter next-wave task set that is narrower, more canonical, and explicitly hardened against the simulation failure modes.

## Scope of this artifact

This is a planning and task-definition artifact only.
It does not create task packs yet.
It records:
- where the proposed task drafts are strong
- where they diverge from current Symphony conventions or from the anti-drift objective
- the refined draft task definitions that should be created next
- how the simulations at the end change the guardrail design

## Additional review of enforcement authority

I agree with the latest review direction on three non-negotiable additions:
- the immediate anti-drift gates need an explicit enforcement transition model so report-only does not become permanent theater
- the gates need one mandatory shared result contract so the runner stays genuinely composable
- the plan must guard against meta-gate drift so the verifier layer does not quietly fragment over time

I do not disagree with the substance of those additions.
The only implementation nuance is that the enforcement transition model should be encoded both:
- as a shared wave-level rule for Pack B and Pack C gates
- and as a task-level requirement inside `TSK-P1-230` to `TSK-P1-232`

That prevents the promotion model from becoming either vague policy prose or over-fragmented per-gate folklore.

## Comparison against the proposed Tasks 6–10

## What I agree with

- The core diagnosis is correct: the next wave must shift from structural coverage to enforcement depth.
- Global template hardening should be explicit and early.
- YAML-to-human-doc parity must be a standalone verifier, not just guidance.
- Scope control must become mechanical rather than advisory.
- Dependency truth and canonical execution path should become explicit tasks.
- The simulations correctly identify that report-only alone does not stop subtle drift.

## Where I do not fully agree

### 1. The proposed five-task set is not sufficient by itself
The proposed Tasks 6–10 are directionally good, but they omit several simulation-derived controls that should be encoded now at plan level instead of deferred back into conversation:
- objective-work-touches alignment checking
- proof guarantee truthfulness checking
- shadow execution classification as non-authoritative, not only runner centralization
- drift-density escalation across multiple warnings
- cross-task drift accumulation visibility

If these are not named now, the same scheduling loss will happen again.

### 2. `TSK-P1-230` is not rigorous enough in its current form
The proposed dependency validator focuses on duplication and missing dependencies, but the audited gap is stronger than that.
The required behavior is not just heuristic dependency hygiene.
It must validate dependency truth:
- upstream proof exists
- upstream evidence is valid
- any declared dependency outputs exist and are usable

A “duplication detector” alone is too soft for the objective.

### 3. `TSK-P1-231` is too broad if it mixes canonical entrypoint and all enforcement in one step
The current proposal usefully centralizes execution, but the simulations show two separate concerns:
- defining the canonical entrypoint
n- detecting and classifying shadow execution paths

Those can share a dependency chain, but they should not be collapsed if doing so blurs acceptance criteria.

### 4. The proposed tasks under-specify simulation-driven hidden-drift detection
Simulation 2 is the most dangerous case: a task looks narrow in structure but expands conceptually.
A plain scope heuristic validator is not enough.
The plan must require an explicit objective-work-touches alignment check.

### 5. The proposed tasks under-specify proof truthfulness
Simulation 6 shows that `proof_guarantees` can become decorative.
A validator must check that declared guarantees are supported by actual verification/evidence shape.
This needs to be treated as first-order work, not a later nice-to-have.

### 6. Some proposed field shapes are not fully aligned with current Symphony conventions
Compared to current canonical and in-repo Wave 1 task packs:
- `schema_version` should remain aligned with repo conventions already in use for real tasks
- owner role selection must reflect allowed-path reality, not a generic `backend_engineer`
- evidence entries should follow the richer evidence contract style already used in current packs
- verification blocks should include evidence validation and local parity commands in canonical form
- touches must mirror evidence paths and companion docs explicitly
- task packs should preserve the stronger anti-pattern/failure-mode language already present in `TSK-P1-224` to `TSK-P1-226`

### 7. Template hardening and process hardening should stay separate
I agree with the review that template hardening, process-doc hardening, and parity verification should remain separate tasks.
Bundling them would increase scope and blur verification.

### 8. The simulations imply one more immediate task than the proposed set explicitly names
The simulations reveal a need for a report-only but explicit drift-density / alignment escalation layer.
Without it, the system can flag many weak signals without treating the combined pattern as suspicious.

## Design corrections derived from the simulations

### Simulation 1 — obvious oversized task
Keep the scope validator, but make it report a severity tier rather than a flat warning.
This prevents oversized tasks from being treated as routine lint.

### Simulation 2 — fake narrowness / hidden conceptual expansion
Add objective-work-touches alignment checks that flag:
- work verbs not justified by objective
- touched surfaces not implied by objective
- work language that imports domain or CI semantics without corresponding scope declaration

### Simulation 3 — dependency bypass
Strengthen the dependency validator so it is not just textual duplication detection.
It must verify dependency truth and declared reusable outputs.

### Simulation 4 — parity gaming
Retain the parity verifier, but ensure the later authoring gate can consume parity findings and escalate them into pack non-readiness once the report-only period is proven stable.

### Simulation 5 — execution path bypass
Keep this guardrail early.
This is one of the strongest candidate controls for early blocking promotion because it is crisp and low-ambiguity.

### Simulation 6 — proof illusion
Add a proof-guarantee integrity check so claimed proof guarantees must be traceable to verification and evidence contracts.

### Simulation 7 — cross-task drift accumulation
Do not make full cross-task drift tracking part of the first immediate pack set if it endangers narrowness, but record it now as the first follow-on task after the immediate wave.
This prevents losing it again.

## Shared Pack B gate authority model

The immediate Pack B gates must share one wave-level authority model so they do not degrade into unrelated advisory scripts.

### Shared gate result contract
Every Pack B and Pack C gate must emit one consistent machine-readable result envelope.

Required fields:
- `gate_id`
- `status` with allowed values `PASS | WARN | FAIL | BLOCKED`
- `fail_class` with allowed values `STRUCTURAL | PARITY | SCOPE | PROOF | DEPENDENCY | AUTHORITY`
- `severity` with allowed values `INFO | LOW | MEDIUM | HIGH | CRITICAL`
- `failing_object`
- `reason`
- `evidence_ref`
- `next_action`
- `confidence` with allowed values `LOW | MEDIUM | HIGH`

Wave-level rule:
- a gate that does not emit this shared structure is invalid and cannot be treated as canonical runner output

### Shared enforcement transition model
Pack B gates remain report-only at introduction, but must carry an explicit path to authority.

Required transition fields for each Pack B gate:
- `current_mode: report_only`
- `next_mode: soft_block`
- explicit promotion criteria
- explicit rollback conditions

Minimum promotion criteria shape:
- measured false-positive stability across a meaningful sample of task packs
- no critical false-positive incidents across a consecutive clean run window
- ergonomics/output clarity reviewed before promotion

Minimum rollback shape:
- newly discovered critical false positives
- structured output regression
- gate disagreement with canonical runner contract

### Shared meta-gate consistency rule
Each gate in Pack B and Pack C must explicitly declare:
- its detection scope
- the shared result contract it uses
- the upstream gate results it may consume
- the checks it must not duplicate from other gates

This is the minimum protection against second-order drift inside the verifier layer itself.

## Recommended next-wave structure

## Immediate implementation tasks

These are the next tasks that should be created because they close the highest-risk anti-drift holes while staying narrow.

### `TSK-P1-227` — Harden global task template with anti-drift required fields
Purpose:
- Make anti-drift structure unavoidable for newly created tasks.

Why it stays separate:
- It changes the template contract but does not itself enforce semantic truth.

### `TSK-P1-228` — Harden task creation process with anti-drift authoring rules
Purpose:
- Convert planning-only anti-drift guidance into canonical process requirements.

Why it stays separate:
- This is process authority, not runtime validation logic.

### `TSK-P1-229` — Implement YAML-to-human-doc parity verifier (report-only)
Purpose:
- Detect divergence between `meta.yml`, `PLAN.md`, `EXEC_LOG.md`, and index registration.

Why it stays separate:
- It isolates parity semantics and keeps false-positive tuning contained.

### `TSK-P1-230` — Implement repo-wide task-pack authoring gate (report-only)
Purpose:
- Enforce hardened authoring presence, required sections, declared-doc existence, and no placeholder contract theater.

Why it stays separate:
- It consumes the template/process/parity assumptions but should not be bundled with them.

Additional authority requirement:
- It must establish the first Pack B enforcement-transition and drift-density escalation pattern in a form later gates can reuse.

### `TSK-P1-231` — Implement scope ceiling and objective-work-touches alignment gate (report-only)
Purpose:
- Catch both obvious oversized tasks and fake narrowness.

Why it is broader than the original scope validator:
- Simulation 2 shows that touches-count heuristics alone are insufficient.

Additional authority requirement:
- It must use confidence-bounded scoring so heuristic findings do not overclaim authority while still producing deterministic escalation where confidence is high.

### `TSK-P1-232` — Implement verification-and-evidence integrity gate (report-only)
Purpose:
- Combine verification reality checking, evidence-to-acceptance binding, and proof-guarantee truthfulness into one narrow proof-integrity task.

Why I combine these three here:
- They all answer the same anti-hallucination question: does the declared proof actually prove the declared contract?
- Keeping them together avoids splitting one proof chain across multiple thin but overlapping validators.

Additional authority requirement:
- It must remain strictly contract-level and explicitly refuse semantic/runtime proof claims beyond declared verifier/evidence alignment.

## Early follow-on tasks

These should be created immediately after the above pack is stable enough to tune.

### `TSK-P1-233` — Implement dependency truth validator (report-only)
Purpose:
- Validate that downstream tasks do not proceed on socially assumed dependencies.

### `TSK-P1-234` — Define canonical `verify-task` entrypoint
Purpose:
- Expose one sanctioned task verification entrypoint for humans and CI wrappers.

### `TSK-P1-235` — Detect and classify shadow execution paths
Purpose:
- Mark direct gate invocation and bypass flows as non-authoritative.

### `TSK-P1-236` — Enforce mandatory artifact emission for verification runs
Purpose:
- Eliminate in-memory-only verification state.

### `TSK-P1-237` — Enforce completion completeness before status closure
Purpose:
- Prevent partial completion from being treated as done.

## Deferred but explicitly retained

These stay planned, but not in the immediate next pack:
- promotion readiness validator
- local non-authoritative mirror path
- full fail-class ergonomics completion
- CI downgrade protection / B7
- evidence freshness / provenance / lineage
- cross-task drift tracker
- derived-status truth
- verifier/runtime/toolchain closure
- DB consistency / TOCTOU hardening

## Draft task definitions

The draft definitions below are intentionally aligned with the current Wave 1 style rather than the looser initial proposals.

## Draft `TSK-P1-227`

### Title
Harden the canonical task template so all future task packs must declare anti-drift boundaries and proof limits

### Owner role
`SUPERVISOR`

### Rationale
This task changes the canonical task-authoring contract and companion planning guidance, so it should be authored from a governance/orchestration standpoint rather than as generic backend work.

### Depends on
- `TSK-P1-222`

### Touches
- `tasks/_template/meta.yml`
- `tasks/TSK-P1-227/meta.yml`
- `docs/plans/phase1/TSK-P1-227/PLAN.md`
- `docs/plans/phase1/TSK-P1-227/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_227_template_hardening.json`

### Required additions to the template
- explicit anti-drift boundary fields or clearly equivalent canonical fields for:
  - objective / intent truthfulness
  - out-of-scope / non-goals
  - stop conditions
  - proof guarantees
  - proof limitations
- stronger author guidance against:
  - parity drift
  - fake narrowness
  - placeholder verification
  - scope theater
  - completion claims beyond proof

### Acceptance focus
- newly authored tasks cannot omit the hardened anti-drift contract shape
- template guidance is explicit enough to prevent silent loss of anti-drift sections

### Negative test
- a test fixture task missing anti-drift sections fails the strict schema/readiness flow used by this task’s verifier

### Notes
This task should not promise semantic correctness enforcement.
It only hardens the required structural contract.

## Draft `TSK-P1-228`

### Title
Harden the task creation process so anti-drift authoring rules become canonical repo policy

### Owner role
`SUPERVISOR`

### Depends on
- `TSK-P1-227`

### Touches
- `docs/operations/TASK_CREATION_PROCESS.md`
- `tasks/TSK-P1-228/meta.yml`
- `docs/plans/phase1/TSK-P1-228/PLAN.md`
- `docs/plans/phase1/TSK-P1-228/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_228_process_hardening.json`

### Must codify
- one-primary-objective rule
- explicit out-of-scope/non-goals/stop-conditions discipline
- no placeholder or aspirational verifier declarations
- parity expectations between YAML and companion docs
- requirement to state proof guarantees and proof limitations honestly
- requirement to identify what anti-drift cheating modes remain open for foundational tasks

### Acceptance focus
- task creation process becomes authoritative on anti-drift authoring discipline instead of leaving it in plan prose

## Draft `TSK-P1-229`

### Title
Implement a report-only parity verifier so task YAML and companion docs cannot silently diverge

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-227`
- `TSK-P1-228`
- `TSK-P1-224`

### Touches
- `scripts/audit/task_parity_gate.py`
- `scripts/audit/verify_tsk_p1_229.sh`
- `tasks/TSK-P1-229/meta.yml`
- `docs/plans/phase1/TSK-P1-229/PLAN.md`
- `docs/plans/phase1/TSK-P1-229/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_229_task_parity.json`

### Must compare
- core task objective / intent representation
- verification command declarations
- evidence declarations
- declared plan/log paths
- human task index registration for the same task

### Simulation-hardening requirement
- parity output must be structured and consumable later by the authoring gate for escalation

### Shared contract requirement
- The parity verifier must emit the Pack B shared gate result contract even before it is part of Pack B proper, so later gates consume one consistent envelope.

## Draft `TSK-P1-230`

### Title
Implement a report-only task-pack authoring gate so hollow or incomplete task contracts fail readiness truthfully

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-227`
- `TSK-P1-228`
- `TSK-P1-229`
- `TSK-P1-224`

### Touches
- `scripts/audit/task_authoring_gate.py`
- `scripts/audit/verify_tsk_p1_230.sh`
- `tasks/TSK-P1-230/meta.yml`
- `docs/plans/phase1/TSK-P1-230/PLAN.md`
- `docs/plans/phase1/TSK-P1-230/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_230_authoring_gate.json`

### Must enforce in report-only mode
- hardened required sections exist
- declared docs resolve
- no placeholder / filler verification prose remains
- evidence declarations are structurally complete
- parity findings are surfaced in one consistent result envelope

### Simulation-hardening requirement
- repeated weak signals should raise severity rather than appear as isolated lint

### Shared gate contract requirement
- must emit the shared gate result contract fields exactly:
  - `gate_id`
  - `status`
  - `fail_class`
  - `severity`
  - `failing_object`
  - `reason`
  - `evidence_ref`
  - `next_action`
  - `confidence`

### Enforcement transition requirement
- declare `current_mode: report_only`
- declare `next_mode: soft_block`
- include explicit promotion criteria based on measured false-positive stability and reviewed output clarity
- include explicit rollback conditions for critical false positives, output-shape regressions, and runner-contract disagreement

### Drift-density escalation requirement
- escalate repeated weak signals instead of emitting isolated advisory noise
- at minimum, the draft task pack must define how multiple warnings in one task pack are promoted to a stronger result class

### Meta-gate consistency requirement
- declare its detection scope explicitly
- declare that it uses the shared gate result contract
- declare the checks it must not duplicate from parity or scope gates

## Draft `TSK-P1-231`

### Title
Implement a report-only scope ceiling and objective-work-touches alignment gate so fake narrowness is surfaced before implementation begins

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-227`
- `TSK-P1-224`

### Touches
- `scripts/audit/task_scope_gate.py`
- `scripts/audit/verify_tsk_p1_231.sh`
- `tasks/TSK-P1-231/meta.yml`
- `docs/plans/phase1/TSK-P1-231/PLAN.md`
- `docs/plans/phase1/TSK-P1-231/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_231_scope_alignment.json`

### Must detect
- touches-count threshold breaches
- multi-family verifier breadth
- mixed platform/domain surface classes
- work items that import concerns not justified by the stated objective
- touched files that imply hidden scope expansion

### Simulation-hardening requirement
- include fixtures for both:
  - obvious oversized task
  - structurally narrow but conceptually expanded task

### Confidence and scoring requirement
- emit `alignment_score` on a bounded numeric scale
- emit `confidence` in the shared gate result contract
- low-confidence findings must not escalate beyond warning-level authority
- high-confidence hidden-drift findings may escalate to fail-level severity when the declared thresholds are met

### Severity model requirement
- define deterministic severity mapping for obvious oversized tasks, mixed-surface violations, and high-confidence fake-narrowness cases

### Gate interaction requirement
- consume authoring/parity findings where relevant
- explicitly avoid re-implementing structural checks already owned by the authoring gate

### Enforcement transition requirement
- declare the same report-only to soft-block transition model used by `TSK-P1-230`
- include rollback conditions for heuristic overreach and false-positive spikes

## Draft `TSK-P1-232`

### Title
Implement a report-only proof-integrity gate so declared verification, acceptance criteria, evidence, and proof guarantees must align

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-224`
- `TSK-P1-225`
- `TSK-P1-227`

### Touches
- `scripts/audit/task_proof_integrity_gate.py`
- `scripts/audit/verify_tsk_p1_232.sh`
- `tasks/TSK-P1-232/meta.yml`
- `docs/plans/phase1/TSK-P1-232/PLAN.md`
- `docs/plans/phase1/TSK-P1-232/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_232_proof_integrity.json`

### Must detect
- no-op or obviously non-proving verifier declarations
- acceptance criteria with no verifier linkage
- acceptance criteria with no evidence linkage
- orphan evidence with no mapped criterion
- proof guarantees not supported by declared verification/evidence shape

### Simulation-hardening requirement
- include fixtures for:
  - decorative verification command
  - evidence file exists but proves nothing mapped
  - proof guarantee exceeds what the verifier/evidence chain can justify

### Hard scope constraint
- validate declared contract alignment only
- prohibit semantic execution analysis
- prohibit runtime truth claims beyond the verifier/evidence contract described by the task pack

### Proof-chain mapping requirement
- each acceptance criterion must map to at least one verifier declaration
- each acceptance criterion must map to at least one evidence declaration
- each evidence artifact must map back to at least one acceptance criterion

### Severity and confidence requirement
- structural proof-chain mismatches should produce high-confidence results
- semantic guesses must stay low-confidence and may not escalate into strong authority claims
- acceptance criteria without verifier support must be treated as critical-severity findings in the draft design

### Gate dependency and consistency requirement
- consume outputs from the authoring and scope/alignment gates rather than duplicating their logic
- declare the shared gate result contract explicitly
- include the same enforcement transition structure as the other Pack B gates

## Draft `TSK-P1-233`

### Title
Implement a report-only dependency truth validator so downstream tasks cannot proceed on socially assumed upstream completion

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-232`

### Touches
- `scripts/audit/task_dependency_truth_gate.py`
- `scripts/audit/verify_tsk_p1_233.sh`
- `tasks/TSK-P1-233/meta.yml`
- `docs/plans/phase1/TSK-P1-233/PLAN.md`
- `docs/plans/phase1/TSK-P1-233/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_233_dependency_truth.json`

### Must detect
- dependency marked complete without valid proof artifacts
- missing required dependency outputs
- downstream work that reimplements dependency responsibilities instead of consuming them

## Draft `TSK-P1-234`

### Title
Define the canonical `verify-task` entrypoint so task verification has one sanctioned execution shell

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-224`

### Touches
- `scripts/audit/verify_task.sh`
- `scripts/audit/verify_tsk_p1_234.sh`
- `tasks/TSK-P1-234/meta.yml`
- `docs/plans/phase1/TSK-P1-234/PLAN.md`
- `docs/plans/phase1/TSK-P1-234/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_234_verify_task_entrypoint.json`

### Notes
Keep this task focused on entrypoint definition and sanctioned invocation contract.
Do not overload it with all bypass detection.

## Draft `TSK-P1-235`

### Title
Detect and classify non-canonical verification execution so bypass outputs are treated as non-authoritative

### Owner role
`SECURITY_GUARDIAN`

### Depends on
- `TSK-P1-234`

### Touches
- `scripts/audit/task_execution_authority_gate.py`
- `scripts/audit/verify_tsk_p1_235.sh`
- `tasks/TSK-P1-235/meta.yml`
- `docs/plans/phase1/TSK-P1-235/PLAN.md`
- `docs/plans/phase1/TSK-P1-235/EXEC_LOG.md`
- `docs/tasks/PHASE1_GOVERNANCE_TASKS.md`
- `evidence/phase1/tsk_p1_235_execution_authority.json`

### Must detect
- direct gate invocation
- partial runner bypass
- outputs lacking canonical authority markers

## Guardrail simulations to preserve in the task plans

Each immediate-wave task should embed at least one simulation-derived negative test fixture and explicitly name which cheat mode it is closing.

### Required simulation fixtures for the immediate wave
- oversized multi-surface task fixture
- fake-narrowness task fixture
- decorative verifier fixture
- orphan evidence fixture
- parity mismatch fixture
- dependency-complete-but-unproven fixture
- direct gate invocation fixture

## Creation order recommendation

### Pack A — authoring contract
- `TSK-P1-227`
- `TSK-P1-228`
- `TSK-P1-229`

### Pack B — report-only anti-drift gates
- `TSK-P1-230`
- `TSK-P1-231`
- `TSK-P1-232`

### Pack C — execution/dependency authority
- `TSK-P1-233`
- `TSK-P1-234`
- `TSK-P1-235`

## Explicit non-goals for this wave

- do not promote broad blocking behavior yet except where later explicitly approved
- do not pull CI downgrade protection forward into this wave
- do not claim cross-task drift tracking is solved in this pack
- do not claim proof truthfulness is fully solved beyond declared-contract alignment
- do not claim runtime/DB proof integrity is solved by authoring-side validators

## Approval questions for the next step

- Do you want me to create only Pack A first, or create all three packs now as draft task packs?
- Do you want `TSK-P1-232` kept combined as one proof-integrity task, or split into separate verification-integrity and evidence-binding tasks?
- Do you want the cross-task drift tracker promoted into Pack C now, or preserved as the first task after `TSK-P1-235`?
