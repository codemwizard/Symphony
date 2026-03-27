# Final RLS Remediation & Verification Hardening Plan

This plan closes `TSK-RLS-ARCH-001` through a CI-only, canonical verification path, promotes execution ergonomics into the mandatory governance baseline, stages new platform controls through report-only activation before they become blocking, and decomposes the work into multiple short, distinct, highly instructive tasks.

## What is added to the finalized plan

The new mandatory addition is an **execution ergonomics baseline**. This is now treated as a closure requirement, not a follow-on improvement.

Added as mandatory requirements:
- Surgical failure output at point-of-failure
- Failure classification emitted by gates at source
- A safe local non-authoritative mirror path
- A single deterministic next-action mapping per failure class
- Clear operator-facing recovery guidance that feeds DRD/remediation rather than depending on it

This complements DRD/remediation rather than replacing it:
- DRD/remediation remains the post-failure traceability and escalation layer
- execution ergonomics becomes the in-the-moment survivability layer

The plan now also adopts a **staged rollout model** for new platform controls:
- controls must be built before closure
- controls may begin in report-only mode while outputs are validated and stabilized
- controls become blocking in an explicit activation sequence
- task-local remediation obligations remain explicit throughout

This avoids deadlock and over-coupled rollout while preserving the target end-state.

## Companion implementation plans

This master plan is paired with two execution plans that must be kept distinct:
- `rls-remediation-first-five-tasks-b8c1dc.md` — the immediate first-wave implementation plan
- `rls-remediation-remainder-plan-b8c1dc.md` — the remaining work after the first five tasks are removed

Execution order:
- first use the first-five-tasks plan
- then resume the remainder plan
- keep this master plan as the governing end-state and sequencing reference

The plan also now prefers **multiple short task packs over large omnibus tasks**.
That is a deliberate anti-drift mechanism:
- smaller scope reduces context contraction risk
- narrower tasks reduce hidden assumptions
- short task packs make stop conditions easier to enforce
- distinct acceptance criteria make honesty easier than improvisation

## Task decomposition strategy

This remediation should not be executed as one large task.
It should be executed as a **chain of short, distinct tasks** with hard dependencies.

Each task should be:
- narrow in touched files
- explicit about one primary outcome
- explicit about what is out of scope
- mechanically verifiable
- small enough that an agent cannot hide ambiguity inside it

Preferred shape of a task:
- one primary objective
- one surface area or one tightly related surface pair
- one verifier family
- one evidence/output expectation
- one clear stop condition

Avoid tasks that combine too many of these at once:
- task-pack repair
- runner/platform primitives
- DB migration semantics
- trust-model reconciliation
- test hardening
- CI wiring
- docs truthfulness

Those should be separate tasks with dependencies, not one large implementation blob.

## Rules for highly instructive tasks

To keep agents honest and reduce context contraction, each task pack should include all of the following:

### 1. One primary objective
The task title and objective must describe one dominant result, not a bundle.

Bad:
- "Fix RLS remediation and CI"

Good:
- "Create report-only task contract validator for RLS remediation tasks"

### 2. Tight scope boundary
The task must explicitly say:
- in-scope files
- out-of-scope files
- dependent tasks that must not be absorbed into this task

### 3. Concrete acceptance criteria
Acceptance criteria must describe observable outcomes, not intentions.

Bad:
- "Improve ergonomics"

Good:
- "Every gate failure emits `FAIL_CLASS`, one primary next action, and a repro command"

### 4. Named verifier path
Each task must declare exactly how it will be checked:
- one command or one small verifier set
- report-only or blocking mode clearly stated

### 5. Honest stop condition
Each task must say when the agent must stop instead of guessing.

Examples:
- DB-backed verification unavailable
- required file outside `touches`
- activation criteria not yet met

### 6. No hidden follow-on work
If completing the task would require building another subsystem, that subsystem must become a separate task.

### 7. Output artifact or proof marker
Even small tasks should leave a durable proof of what changed:
- report output
- evidence snippet
- updated remediation log
- verifier output sample

## Recommended first-wave task breakdown

The following first-wave task structure is recommended instead of one large remediation task.

### Task 1 — Repair task contract for `TSK-RLS-ARCH-001`
Primary objective:
- make `meta.yml` truthful and scoped before any further implementation

In scope:
- `tasks/TSK-RLS-ARCH-001/meta.yml`
- required remediation references

Out of scope:
- DB logic
- runner/platform code
- test logic changes

Acceptance criteria:
- `touches`, `verification`, `evidence`, and closure conditions are accurate
- canonical verifier path is declared
- undeclared drift is removed or explicitly brought into scope

Verifier:
- task-pack/schema/readiness validation commands

Stop condition:
- if additional undeclared surfaces are discovered, amend the task pack before continuing

### Task 2 — Build task loader primitive
Primary objective:
- load task metadata safely for later report-only gates

In scope:
- task loader code only

Out of scope:
- CI wiring
- DB checks
- evidence generation

Acceptance criteria:
- loader parses target task metadata
- basic required top-level fields are surfaced consistently

Verifier:
- report-only local runner invocation against known task metadata

### Task 3 — Build standard gate result shape and runner skeleton
Primary objective:
- provide a common result contract and non-blocking execution shell

In scope:
- result schema
- runner skeleton
- structured output format

Out of scope:
- deep gate logic
- CI blocking behavior

Acceptance criteria:
- runner executes at least stub/report-only gates
- output contains `status`, `fail_class`, `next_action`, and `repro_command`

Verifier:
- runner dry-run against a sample task

### Task 4 — Implement report-only contract gate (B1-lite)
Primary objective:
- catch basic task-pack invalidity early

In scope:
- contract gate logic for presence/shape checks

Out of scope:
- full undeclared-file diff enforcement
- CI blocking

Acceptance criteria:
- missing/invalid contract emits structured failure output
- gate integrates with runner

Verifier:
- sample valid/invalid task metadata runs

### Task 5 — Implement report-only test-validity gate (B4-lite)
Primary objective:
- detect obviously weak counted tests before deep enforcement

In scope:
- presence/assertion-shape checks only

Out of scope:
- full semantic correctness of every test

Acceptance criteria:
- weak counted test shape produces `FAIL_CLASS=TEST_VALIDITY_WEAK`

Verifier:
- gate run against known weak test patterns

### Task 6 — Implement report-only Phase 0 input/config gate (B5-lite)
Primary objective:
- establish deterministic config identity before DB comparison

In scope:
- YAML/config parse and deterministic hashing

Out of scope:
- full DB policy comparison
- normalization engine

Acceptance criteria:
- canonical Phase 0 config hash is emitted
- invalid config produces structured failure output

Verifier:
- gate run against valid/invalid config cases

### Task 7 — Implement execution ergonomics standard (B8-lite)
Primary objective:
- enforce useful failure output before any gate becomes blocking

In scope:
- failure output format
- `FAIL_CLASS`
- primary next-action enforcement
- local mirror messaging

Out of scope:
- full CI authority
- final closure proof

Acceptance criteria:
- runner rejects gates that do not emit required ergonomic fields
- local mirror path is documented and non-authoritative

Verifier:
- simulated gate failures with missing/complete ergonomic fields

### Task 8 — Restore honest DB-backed verification path
Primary objective:
- remove environment blockers such as the `0081` migration issue so DB-backed proof becomes possible

In scope:
- only the blocker necessary to restore verification environment integrity

Out of scope:
- full RLS semantics remediation

Acceptance criteria:
- ephemeral DB path or equivalent honest verification path works again

Verifier:
- DB bootstrap / pre-CI path reaches the point required for downstream RLS verification

Stop condition:
- if unrelated infrastructure failures appear, open separate remediation instead of absorbing them

### Task 9 — Remediate task-local RLS semantics and docs
Primary objective:
- fix A-items for the actual RLS task once the proof path exists

In scope:
- canonical verifier unification
- trust/doc/test/evidence corrections

Out of scope:
- new platform primitives beyond the minimum baseline

Acceptance criteria:
- task-local verifiers are truthful
- tests are assertive
- docs match implementation
- exact evidence path is honored

Verifier:
- task-local declared verifier set

### Task 10 — Promote baseline controls to blocking in order
Primary objective:
- activate validated report-only controls without deadlock

In scope:
- promotion state
- CI wiring state
- activation criteria checks

Out of scope:
- creation of entirely new gate families

Acceptance criteria:
- controls move from report-only to blocking only when promotion criteria are met

Verifier:
- repeated stable runs and CI enforcement checks

## Task writing template guidance

When authoring each short task, include these sections explicitly:
- objective
- in_scope
- out_of_scope
- dependencies
- acceptance_criteria
- verifier_commands
- evidence_or_output
- stop_conditions
- non_goals

This keeps the task self-instructive and reduces the chance that an agent fills gaps with improvisation.

## Why short tasks help

Short, distinct tasks help because they:
- lower context load
- make failure localized
- make proof cheaper to inspect
- make it obvious when a task is blocked vs. incomplete
- reduce the temptation to silently absorb extra scope
- let report-only controls mature before they become critical path blockers

This is the preferred way to combine the guardrails with practical agent execution.

## Non-overridable global invariants

These sit above `meta.yml` and may not be weakened by any task pack.

- Exactly one canonical completion runner
- Canonical completion runner is authoritative only from CI
- Canonical completion runner must emit evidence
- Evidence must bind `meta.yml` hash
- Evidence must bind canonical verifier hash
- Evidence must bind execution environment
- Evidence must bind commit SHA
- Evidence must bind CI identity
- RLS tasks must include formal test-validity enforcement
- RLS tasks must include deterministic Phase 0/Phase 1 proof
- RLS tasks must use lossless normalized policy comparison
- Task completion truth must be derived from latest valid proof
- Required governance controls must be active and CI-enforced
- CI enforcement baseline must be protected from downgrade
- Mandatory runtime ergonomics must be present for authoritative completion paths

Fail if any task pack omits or weakens a required invariant class.

## Rollout model

This plan distinguishes between:
- **implementation strictness**: the control exists, runs, and emits stable structured output
- **enforcement strictness**: the control is blocking in CI and required for closure

Rule:
- New platform-level controls are introduced in **report-only mode first**.
- A control may become blocking only after its outputs are validated as correct, stable, and trustworthy.

Platform-level controls eligible for staged activation:
- B1 task contract validator
- B2 unified task verification runner
- B4 formal test-validity gate
- B5 deterministic Phase 0 gate
- B7 CI enforcement completeness validator
- B8 execution ergonomics and local mirror standard

End-state rule:
- `TSK-RLS-ARCH-001` still cannot close until the required baseline controls are active and blocking.
- The difference is that rollout to that state is staged rather than all-at-once.

## Minimum viable implementation slice

Build these primitives first before deep enforcement:

1. **Task loader**
   - load `tasks/<TASK_ID>/meta.yml`
   - validate basic structure only

2. **Standard gate result shape**
   - every gate emits a common result object / structure
   - required fields include `status`, `fail_class`, `message`, `details`, `next_action`, `repro_command`

3. **Unified runner skeleton**
   - accepts `TASK_ID`
   - runs gates in order
   - prints structured output
   - non-blocking at first

4. **Initial report-only gates**
   - contract gate (B1-lite)
   - Phase 0 hash/config gate (B5-lite)
   - test validity presence/assertion gate (B4-lite)
   - ergonomics output enforcement (B8-lite)

5. **Delayed deep controls**
   - full normalization
   - DB equality comparison
   - CI attestation hard blocking
   - verifier/runtime closure hard blocking
   - TOCTOU/full provenance hard blocking

The immediate objective is not full hardness on day one.
The immediate objective is a system that explains failure correctly and consistently, so later blocking enforcement is trusted.

## Plan A — Canonical closure of `TSK-RLS-ARCH-001`

### A0. Hard stop rule
If any required implementation file, verifier, evidence artifact, or task-local doc is outside `meta.yml`:
- stop immediately
- amend `meta.yml` first
- validate task pack
- only then continue

No implementation-time interpretation is allowed.

### A1. Remediation artifact
Deliverables:
- remediation artifact exists
- severity recorded
- failure classes recorded, including:
  - scope drift
  - verifier ambiguity
  - weak tests
  - evidence mismatch
  - trust-model mismatch
  - environment drift
  - verifier integrity drift
  - normalization abuse risk
  - CI downgrade risk
  - mutable status risk
  - TOCTOU risk
  - DB concurrency/state drift risk
  - execution ergonomics failure risk

### A2. Task-pack amendment first
`tasks/TSK-RLS-ARCH-001/meta.yml` must truthfully declare:
- touched files
- canonical completion runner / verifier path
- evidence path
- required gating classes
- task-local docs
- completion conditions
- CI-only closure rule
- ergonomics requirements for authoritative path

Hard rule:
- no undeclared file/verifier/artifact influences completion

### A3. Single canonical completion authority
Required outcome:
- exactly one authoritative completion path exists

Requirements:
- canonical completion runner declared
- overlapping verifiers removed or explicitly non-authoritative
- only canonical path may produce authoritative evidence/proof for closure

### A4. CI-only authority for closure
Only CI-originated canonical runs are authoritative for task closure.

Evidence/proof must include CI attestation:
- CI provider identity
- CI workflow/job name
- CI run ID
- CI attempt number if relevant
- trusted execution marker
- commit SHA
- branch/ref context

Fail if local or replayed artifacts are used for closure.

### A5. Single orchestrated completion path
All completion flows must go through one orchestrated command path, e.g. `make verify-task TASK=TSK-RLS-ARCH-001` or its CI wrapper.

Manual assembly of verifier runs, evidence files, proof records, or status updates does not count.

### A6. Derived status truth
Authoritative status is derived from the latest valid canonical proof, not from a mutable field.

If stored status remains, it is cache only.

Fail if stored status says `completed` without a current valid proof.

### A7. Status mutation control
If stored status remains, only the canonical CI runner or an automation wrapper around it may transition status to `completed`.

Required proof record:
- task ID
- commit SHA
- canonical runner identity
- canonical verifier identity
- verifier hash
- environment binding
- CI attestation
- evidence hash
- `meta.yml` hash
- pass/fail result
- timestamp

### A8. Environment binding
Canonical run must bind:
- commit SHA
- DB schema version / migration head
- Phase 0 input hash
- config/YAML hash
- whitelisted environment variable hashes
- dependency lock hash if applicable
- CI identity
- runtime image/container identity if used

### A9. Verifier execution closure
Verifier integrity includes:
- canonical verifier file content
- helper scripts affecting verdict
- interpreter/runtime identity
- critical binary/toolchain identity

Preferred implementation:
- pinned container image

Minimum fallback:
- hash/version bind `bash`, `python`, `psql`, `jq`, and other critical tools

### A10. Trust model and SQL reconciliation
Must align:
- function ownership
- `SECURITY DEFINER`
- hardened `search_path`
- `BYPASSRLS`
- inheritance
- grant posture

Fail if DB trust model differs from canonical trust contract.

### A11. Formal test-validity hardening
A counted test must assert a measurable state transition or measurable denial.

Valid counted assertions include:
- row count comparison
- exact value comparison
- explicit error expectation
- permission-denial confirmation
- before/after invariant
- existence/non-existence verification

Specific fixes:
- `T09` must assert no unauthorized delete effect
- `T11` must become deterministic or be excluded from counted security totals

### A12. Documentation truthfulness
Correct:
- contradictory `pre_ci` claims
- false lock semantics claims
- false drift-acknowledgment claims
- false `force_override` claims

### A13. Evidence only from canonical CI run
Target artifact:
- `evidence/phase1/rls_arch/tsk_rls_arch_001.json`

Evidence must include:
- task ID
- commit SHA
- timestamp
- CI attestation
- canonical runner identity
- canonical verifier identity
- verifier hash
- helper/runtime/toolchain closure record
- verifier output hash
- `meta.yml` hash
- environment binding
- Phase 0 input hash
- evidence schema version
- pass/fail summary

### A14. `meta.yml` hash binding with lineage
Evidence must record:
- current `meta.yml` hash
- previous evidence reference if one exists

Only the latest evidence whose `meta.yml` hash matches the current task contract is authoritative.

### A15. Deterministic Phase 0 → Phase 1 proof
Phase 1 must be a pure function of Phase 0 output.

Phase 0 must prove:
- full YAML coverage
- structural validity
- deterministic expected policy derivation
- exact required policy cardinality
- rejection of ambiguous/partial config

### A16. Bidirectional determinism with lossless normalization
Required comparison:
- `normalize(actual_policy_state) == normalize(derived_expected_policy_state)`

Normalization must be lossless with respect to security semantics.

Canonical normalization specification must define:
- canonical schema
- normalized field set
- deterministic serialization
- deterministic ordering
- explicit handling of defaults
- explicit handling of normalized expressions
- rejection of unknown fields
- rejection of lossy transforms

Evidence must include:
- normalized expected form
- normalized actual form
- raw extracted actual policy form
- raw derived expected form or derivation source reference

### A17. DB state consistency / concurrency protection
Record at minimum:
- DB schema/migration head at start
- DB schema/migration head at end
- policy-state hash at start where relevant
- policy-state hash at end where relevant

Fail if DB state changes unexpectedly during the verification chain.

### A18. TOCTOU-safe completion chain
Verification, evidence emission, proof generation, and status derivation/update must be one atomic logical chain against:
- fixed commit SHA
- fixed `meta.yml` hash
- fixed verifier hash
- fixed CI identity
- consistency-checked DB state

### A19. Mandatory execution ergonomics baseline
Authoritative completion paths must include operator-facing runtime ergonomics.

Required capabilities:
- Surgical failure output at the point of failure
- Structured failure classification emitted by the gate itself
- Exactly one primary next action per failure class
- A safe local non-authoritative mirror path
- Clear handoff from runtime failure into DRD/remediation artifacts

Every gate failure must emit:
- `FAIL_CLASS=<machine_readable_class>`
- a concise title
- exact failing object/component
- why it failed
- why it matters
- exactly one primary next action
- canonical repro command
- local mirror command if available

Example classes:
- `PHASE0_DETERMINISM_MISMATCH`
- `EVIDENCE_HASH_MISMATCH`
- `CI_ATTESTATION_INVALID`
- `META_CONTRACT_DRIFT`
- `VERIFIER_HASH_MISMATCH`

The local mirror path must:
- use the same logic where possible
- be explicitly labeled non-authoritative
- never produce closure-authoritative proof

Activation note:
- ergonomics enforcement should begin in report-only mode
- once all gates emit stable `FAIL_CLASS`, `next_action`, and repro output, ergonomics may become blocking

### A20. Strict completion flow
Completion is allowed only through this ordered chain:
- validate task contract
- validate non-overridable global invariants
- validate CI baseline completeness
- run formal test-validity gate
- run deterministic Phase 0 gate
- run canonical CI verifier
- emit evidence
- validate evidence schema/provenance
- validate `meta.yml` hash
- validate verifier/runtime closure
- validate environment binding
- validate normalization results
- validate DB consistency
- generate status proof
- derive/update status

### A21. Closure rule
`TSK-RLS-ARCH-001` may be considered complete only if:
- Plan A fully passes
- and Plan B baseline controls are implemented, active, and CI-enforced

## Plan B — Mandatory active governance baseline

These are minimum required controls for closure.

Mandatory active controls:
- **B1** Task contract validator
- **B2** Unified task verification runner
- **B4** Formal test-validity gate
- **B5** Deterministic Phase 0 gate with lossless normalization
- **B7** CI enforcement completeness validator
- **B8** Execution ergonomics and local mirror gate standard

Without all six active, the task cannot close.

Rollout note:
- these controls are built in report-only mode first
- they become active for closure only after promotion to blocking status in the activation order below

### B1. Task contract validator
Must enforce:
- changed files in `touches`
- declared files exist
- exactly one canonical verifier/runner declared
- evidence declaration valid
- no undeclared verifier/artifact participation
- task pack satisfies global invariants

### B2. Unified task verification runner
Must:
- accept `TASK_ID`
- load real task metadata
- execute only canonical path
- emit evidence
- emit status proof
- reject non-canonical participation
- support CI-only authoritative mode

### B4. Formal test-validity gate
Must reject:
- mutation without assertion
- counted observational passes
- counted tests lacking machine-checkable conditions

### B5. Deterministic Phase 0 gate
Must prove:
- full coverage
- structural validity
- deterministic derivation
- exact cardinality
- bidirectional equality with lossless normalization
- DB consistency across verification window

### B7. CI enforcement completeness validator
Must enforce:
- required governance jobs exist
- required jobs are blocking
- required jobs are not downgraded to advisory
- task completion path is CI-wired
- CI baseline has not drifted from approved governance baseline

### B8. Execution ergonomics and local mirror standard
Must enforce that each authoritative gate exposes:
- machine-readable `FAIL_CLASS`
- concise human-readable failure title
- exact failing object/component
- why-it-matters text
- exactly one primary next action
- canonical repro command
- local non-authoritative mirror command when applicable

Must also enforce the existence of a sanctioned local mirror path, e.g.:
- `make verify-task TASK=<TASK_ID> LOCAL=1`

The local mirror path must:
- share validation logic where feasible
- be visibly marked non-authoritative
- never emit authoritative closure proof

## Activation order

Promote controls from report-only to blocking in this order:

1. **B1** task contract validator
2. **B2** unified task verification runner
3. **B4** formal test-validity gate
4. **B5** deterministic Phase 0 gate
5. **B8** execution ergonomics standard
6. **B7** CI enforcement completeness validator

Promotion criteria for each control:
- output is stable across repeated runs
- false positives are understood and corrected
- remediation path is clear from gate output
- local non-authoritative mirror behavior matches CI logic where intended
- the control can be trusted not to deadlock rollout unnecessarily

## Plan C — Extended hardening

### C1. Trust model verifier
Implement DB-state trust verification against canonical trust contract.

### C2. Canonical `verify-task` entry point
Provide one sanctioned entry point for humans and CI wrappers.

### C3. Evidence freshness/provenance validator
Validate freshness, provenance completeness, lineage, and supersession.

### C4. Policy normalization/diff library
Reusable normalized comparison tooling for future RLS tasks.

### C5. Derived-status model
Move fully to derived status as authoritative truth; stored status remains cache only if retained.

### C6. CI baseline protection spec
Maintain approved CI baseline/template/hash and explicit governance workflow for changing it.

### C7. Independent evidence verification
Add a validator independent of the canonical evidence producer to re-check critical claims:
- evidence schema
- proof hash consistency
- verifier identity/hash
- `meta.yml` hash consistency
- critical invariant summaries

## Final hard rules

### Scope
- No implementation-time scope interpretation
- Amend task pack first or stop

### Authority
- Only CI-originated canonical runs can authorize closure
- Local runs are non-authoritative

### Orchestration
- One orchestrated completion path only
- Manual assembly of valid-looking state does not count

### Verifier integrity
- Canonical verifier hash required
- Helper/runtime/toolchain closure required
- Prefer pinned container execution

### Evidence
- Evidence only from canonical CI run
- Evidence must include provenance, environment, verifier closure, `meta.yml` hash, lineage

### Determinism
- Phase 1 must be a pure function of Phase 0
- Comparison must be lossless-normalized
- Raw and normalized forms must both be auditable

### DB consistency
- Start/end DB state must be consistency-checked
- Unexpected drift invalidates proof

### Status
- Authoritative status is derived from latest valid proof
- Stored status, if present, is cache only
- Manual status mutation without proof is invalid

### Runtime ergonomics
- DRD/remediation is post-failure traceability, not runtime survivability
- Authoritative gates must provide immediate failure clarity
- Every gate failure must provide one clear next action
- A safe non-authoritative local mirror path is mandatory

### CI baseline
- Baseline controls must be active in CI
- CI config drift must be detected and rejected
- Partial adoption does not count as enforcement

## Final execution order

### Phase I — Build mandatory baseline first
1. B1 task contract validator
2. B2 unified task verification runner
3. B4 formal test-validity gate
4. B5 deterministic Phase 0 gate with lossless normalization and DB consistency checks
5. B7 CI enforcement completeness validator with CI baseline protection
6. B8 execution ergonomics and local mirror standard

During Phase I:
- controls may run in report-only mode
- outputs must be reviewed for stability and correctness
- no control is promoted to blocking until promotion criteria are satisfied

### Phase II — Repair and close `TSK-RLS-ARCH-001`
7. remediation artifact
8. task-pack amendment
9. canonical verifier/runner unification
10. CI-only closure authority
11. single orchestrated completion path
12. derived-status / status mutation control
13. environment binding
14. verifier/runtime/toolchain closure
15. trust-model reconciliation
16. formal test hardening
17. documentation correction
18. canonical CI evidence emission
19. `meta.yml` hash binding + evidence lineage
20. runtime ergonomics output implementation
21. TOCTOU-safe strict completion run
22. closure only through canonical proof chain

During Phase II:
- blocking activation follows the activation order above
- closure is allowed only after all required baseline controls are active and blocking

### Phase III — Extend recurrence prevention
23. trust-model verifier
24. canonical `verify-task` entry point
25. evidence freshness/provenance validator
26. reusable policy normalization/diff tooling
27. full derived-status model
28. CI baseline protection workflow
29. independent evidence verification

## Bottom line

This plan treats execution ergonomics as part of the security boundary, not a convenience feature.

It also treats rollout discipline as part of system safety:
- build first
- observe in report-only mode
- promote to blocking in sequence
- close the task only after the baseline is active and trusted

The system must be:
- hard to game
- hard to drift
- and easy enough to recover within that engineers do not route around it under pressure
