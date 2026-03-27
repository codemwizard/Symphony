# RLS Remediation First Five Tasks

This plan defines the first five implementation tasks as narrow, dependency-linked Symphony task packs that establish the verification spine without opening deep security-hardening scope too early.

## Purpose

This is the immediate execution plan.
It exists to keep the first wave small enough for AI implementation without drift while still building a real, reusable verification spine.

This plan is subordinate to:
- `rls-remediation-final-plan-b8c1dc.md`

The remainder after these five tasks moves to:
- `rls-remediation-remainder-plan-b8c1dc.md`

## Canonical Wave 1 task IDs

The first implementation wave is assigned to these Symphony task IDs:
- `TSK-P1-222` — repair `TSK-RLS-ARCH-001` task contract before implementation
- `TSK-P1-223` — build task metadata loader primitive on governed audit surfaces
- `TSK-P1-224` — build report-only runner skeleton and gate result contract
- `TSK-P1-225` — implement report-only task contract gate
- `TSK-P1-226` — implement proof-blocker detection and hard stop

Implementation surfaces for this wave are intentionally limited to:
- `tasks/**`
- `docs/plans/phase1/**`
- `scripts/audit/**`
- `evidence/phase1/**`

## Decision

Run these five tasks first:
1. `TSK-P1-222` — task contract repair for `TSK-RLS-ARCH-001`
2. `TSK-P1-223` — task loader primitive
3. `TSK-P1-224` — runner skeleton + gate result contract
4. `TSK-P1-225` — report-only contract gate
5. `TSK-P1-226` — proof-blocker hard stop

## Why this specific five

These five are the smallest viable sequence that:
- forces truthful scope before implementation
- creates a single runner-centric architecture early
- gives failures a common shape
- prevents fake forward progress when proof is blocked
- avoids jumping into DB semantics, normalization, CI attestation, or evidence lineage too early

## Assessment of the proposed five tasks

The proposed first five are directionally correct, but need adjustment before implementation.

### What is good
- narrow dependency chain
- runner-centric direction
- proof-blocker concept is early enough
- avoids deep hardening too early

### What must be corrected
- tasks must follow Symphony CREATE-TASK process, not ad-hoc YAML shape
- task meta must use the canonical template fields already present in `tasks/_template/meta.yml`
- `owner_role` must use an actual repo role from `AGENTS.md`, not `platform`
- `touches` must include the task pack itself and any declared plan/log/evidence paths
- `implementation_plan` and `implementation_log` must be declared and created
- verification commands must be realistic and phase-appropriate
- evidence contracts must be concrete, not placeholder-only
- task 3 should combine runner skeleton and gate result contract because they form one primitive pair and should not be split too early
- task 5 should be proof-blocker hard stop, not test-validity gate, because stop enforcement is more foundational than semantic test analysis

## Corrected first five tasks

### Task 1 — Repair task contract for `TSK-RLS-ARCH-001`

Primary objective:
- make the existing RLS task pack truthful and narrow before any further implementation

Why first:
- Symphony requires truthful scope and readiness before implementation
- this task prevents silent expansion into undeclared files

In scope:
- `tasks/TSK-RLS-ARCH-001/meta.yml`
- plan/log references and remediation references required to make the task pack truthful

Out of scope:
- runner code
- DB logic
- test rewrites

Verifier family:
- `verify_task_meta_schema.sh`
- `verify_task_pack_readiness.sh`

Stop condition:
- if additional undeclared files are discovered, amend the task pack before proceeding

### Task 2 — Build task loader primitive

Primary objective:
- load task metadata safely for later report-only verification flow

In scope:
- loader module only

Out of scope:
- gate execution
- DB checks
- CI integration

Verifier family:
- local loader invocation against known task metadata

Stop condition:
- if canonical task metadata shape is ambiguous, stop and reconcile against the template first

### Task 3 — Build runner skeleton and gate result contract

Primary objective:
- provide one orchestrated entry point and one shared output shape for later gates

Why combined:
- the runner and gate output contract are one primitive pair
- separating them further adds handoff risk without real anti-drift benefit

In scope:
- runner entry point
- sequential gate execution shell
- structured gate result schema
- report-only output path

Out of scope:
- CI wiring
- DB-backed checks
- deep gate logic

Verifier family:
- runner dry-run against sample and invalid task inputs

Stop condition:
- if loader output is unstable, do not add more gates

### Task 4 — Implement report-only contract gate

Primary objective:
- catch basic task-pack invalidity through the runner

In scope:
- field presence/shape checks
- touches existence checks that are safe for report-only mode
- structured failure output

Out of scope:
- full undeclared-file enforcement
- blocking CI behavior

Verifier family:
- runner invocation against valid and invalid task packs

Stop condition:
- if the runner/gate contract is unstable, stop and fix the primitive layer first

### Task 5 — Implement proof-blocker hard stop

Primary objective:
- detect when verification cannot honestly continue and halt the chain

Why this is task 5 instead of test-validity gate:
- proof honesty is more foundational than richer domain analysis
- this directly reduces drift by preventing optimistic continuation

In scope:
- blocked-state detection for missing required runtime dependencies and unavailable proof path
- `FAIL_CLASS=PROOF_BLOCKED`
- runner stop behavior for downstream gates

Out of scope:
- fixing the blocker
- DB semantics verification
- CI attestation

Verifier family:
- simulated blocked/unblocked conditions through the runner

Stop condition:
- if blocker semantics are ambiguous, stop and define the allowed blocker classes before implementation

## Why these five are small enough

Each of the five tasks has:
- one primary objective
- one surface area or tightly related surface pair
- one verifier family
- one clear stop condition
- no deep DB or CI authority semantics

That makes them small enough for AI implementation with materially reduced drift risk.

## Why they are still not trivial

These tasks are small, but they are not throwaway.
They establish:
- truthful task scope
- one orchestrated path
- one output contract
- one stop mechanism

That is enough structure to constrain future work without dragging in advanced hardening too early.

## Explicit non-goals for the first five

Do not add in this wave:
- normalization engine
- trust-model verifier
- CI attestation
- evidence lineage
- full test-validity semantics
- local mirror path beyond noting future need
- status derivation model

## Required task-authoring rules for the five

When these five Symphony tasks are created, each task pack must include:
- one primary objective
- exact `touches`
- explicit `out_of_scope`
- explicit `stop_conditions`
- explicit `non_goals`
- realistic verification commands
- concrete evidence contract
- `implementation_plan` and `implementation_log`
- valid `owner_role`

## Sequencing rule

Do not start task N+1 until task N is:
- schema-valid
- readiness-valid
- implemented
- locally verified at its declared scope
- logged in its execution log with the first-wave output artifact

## Exit criteria for this first-wave plan

This plan is complete only when:
- all five tasks are created as valid Symphony task packs
- all five tasks are implemented in order
- runner-centric report-only verification exists
- proof-blocker hard stop works
- no deep hardening controls were pulled in prematurely

## Hand-off to remainder plan

Once these five are complete, switch to:
- `rls-remediation-remainder-plan-b8c1dc.md`

That plan covers the next wave and the deferred advanced controls.
