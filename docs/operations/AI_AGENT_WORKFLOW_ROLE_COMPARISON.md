# AI Agent Workflow & Role Plan v2 vs. Symphony Current System

This document records:

- A step-by-step walkthrough of the current Symphony Phase-0 workflow for AI-assisted coding, tasks, and remediation.
- A comparison to `ai_agent_workflow_and_role_plan_v_2.md`, highlighting gaps the new process tries to close.
- An opinionated recommendation about adopting the new plan (worth it or not) and how to migrate if chosen.

## Current System — Detailed Execution Steps

1. **Discover requirements and agents.**
   - Identify the invariant(s), phase, and control planes impacted by the work (`AGENTS.md`, `docs/invariants/INVARIANTS_MANIFEST.yml`).
   - Decide whether the change touches production-affecting surfaces (`schema/**`, `scripts/**`, `.github/workflows/**`, `src/**`, `packages/**`, `infra/**`, `docs/PHASE0/**`, `docs/invariants/**`, `docs/control_planes/**`, `docs/security/**` when policy changes).
2. **Create the task artifacts.**
   - Human-facing plan: `docs/tasks/PHASE0_TASKS.md` (score card: title, owner, touches, invariants, acceptance, verification commands, evidence, failure modes).
   - Machine metadata: `tasks/<TASK_ID>/meta.yml` (phase, owner role, touches, invariants, work steps, acceptance, verification/evidence, status, agent assignment).
   - Evidence roadmap: plan must name the gate script(s) and evidence JSON path(s), and the task meta must list the actual verification commands that will populate them.
3. **Create authoritative plan/log casefiles.**
   - Place `docs/plans/phase0/<task>/PLAN.md` describing mission, scope, verification steps, and expected evidence.
   - Place `docs/plans/phase0/<task>/EXEC_LOG.md` tracking every command, failure, fix, and evidence update.
   - Task meta references these files (new fields `implementation_plan`, `implementation_log` keep the link explicit), and `scripts/audit/verify_task_plans_present.sh` enforces their presence before marking completion.
4. **Implement within agent scope.**
   - Agent role determines allowed paths (`AGENTS.md`). DB Foundation touches migrations/scripts/db; Security Guardian handles security/audit scripts; Invariants Curator touches docs/invariants; Supervisor orchestrates cross-plane work.
   - Strict constraints apply: no runtime DDL, forward-only migrations, SECURITY DEFINER hardening, revoke-first, append-only outbox, CI/pre-CI parity.
5. **Run parity and evidence gates.**
   - Primary local command: `scripts/dev/pre_ci.sh` (fresh DB by default, ordered checks, verification scripts, remediation trace).
   - Verification scripts must emit evidence JSON (`evidence/phase0/*.json`); `scripts/ci/check_evidence_required.sh` ensures each declared artifact exists.
   - The newly hardened `verify_remediation_trace.sh` ensures each production-affecting change carries a remediation plan/log with required markers.
6. **Complete remediation/work tracing (if needed).**
   - When an error arises, create a remediation trace casefile `docs/plans/phase0/REM-*/{PLAN.md,EXEC_LOG.md}` with markers `failure_signature`, `origin_task_id`/`origin_gate_id`, `repro_command`, `verification_commands_run`, `final_status`.
   - Derive tasks from the remediation plan, implement them, and log every diagnostic/fix step. Once the fix passes, update the plan with final status and evidence.
   - Keep a “debug process” log mirroring the original task creation—failure signature, repro command, scope, tasks, verification, and lessons captured.
7. **Finalization.**
   - Update manifest/contracts (`docs/control_planes/CONTROL_PLANES.yml`, `docs/invariants/INVARIANTS_MANIFEST.yml`, `docs/PHASE0/phase0_contract.yml`) after code, evidence, tests are green.
   - Ensure the plan/log have been updated, evidence artifacts uploaded, and gates pass (indexed by `evidence/phase0`).

## Comparison with `ai_agent_workflow_and_role_plan_v_2.md`

| Aspect | Current System | v2 Plan |
|---|---|---|
|Governance emphasis| Mechanical, evidence-first; tasks tied to invariants and signage; proper plan/log files required | Same emphasis; additional explicit agent roles, stop conditions, and phase authority table |
|Task granularity| Highly prescriptive tasks/plans with explicit file edits and gate scripts | Intent-based missions with adaptive agent autonomy; emphasizes motion without renaming invariants |
|Remediation discipline| Remediation trace required for fixes, enforced by gate | Same rule, but v2 frames it as first-class lifecycle with linkage to failures and approvals |
|AI agent role definitions| Agent scopes declared in `AGENTS.md`, enforced via allowed paths and verification commands | V2 splits roles into DB/Runtime/Security/Compliance/Evidence/Human Approver with detailed do/don’t lists |
|Phase boundary enforcement| Procedural, enforced via plan gating and manifest updates | V2 codifies “phase authority model”, explicit keep-out rules, and escalation triggers |
|Evidence harness controls| Evidence harness integrity gate prohibits bypass patterns; remediation trace gate enforces required markers | V2 reasserts proof-first (prompt hash, model id) and says AI output is always proposed, not authoritative |

## Gaps the New Process Bridges

1. **Role clarity.** V2 spells out six agent roles (including Evidence/Audit and human approver). Current system uses similar roles but without the rich role-to-task mapping and explicit “stop and escalate” rules; V2 strengthens that map and hard stops.
2. **Phase authority narrative.** Current system already enforces phases via plan structure, but V2 codifies a phase-authority table and forbids reinterpretation, reducing ambiguity for runtime work happening across Phase-1/2.
3. **Mission-focused tasks.** V2 pushes mission/constraints/success-criteria wording; our current tasks are mechanical and may over-specify implementation. Bridging that gap would let AI choose safer implementations while still delivering the required evidence artifacts.
4. **Governance hand-off documentation.** V2 formalizes “evidence and audit agent” plus AI-assisted governance data (prompt hash, model id), which the current system implicitly collects but does not record in a single persona-driven artifact yet.
5. **Escalation/stop conditions.** V2 lists explicit stop triggers (unclear invariant, phase risk, missing evidence). While our tasks would catch these through gates, V2 makes them explicit for agents’ decision-making logic, reducing “silent errors” when evidence can’t be emitted.

## Recommendation

Adopting V2 is worth it if you need to scale AI assistance beyond structural Phase-0 tasks into Phase-1 runtime work:

1. **Start by expanding role definitions.** Formalize the new roles (Evidence & Audit, Human Approver) in `AGENTS.md` and `docs/operations/PHASE1_AI_AGENT_ORCHESTRATION_STRATEGY_COMPARISON.md`.
2. **Treat V2 missions as plans.** Translate each mission block into `docs/plans/phase1/<task>/PLAN.md` + `EXEC_LOG.md`, linking them to `tasks/<TASK_ID>/meta.yml` with added mission info and success criteria.
3. **Layer on the new stop/escalation rules.** Implement a lightweight enforcer (a script or process note) that checks for the V2 stop conditions before allowing merges (e.g., verify that invariants are clear, evidence can be emitted, approvals are present).

If you’re staying on Phase-0 tasks only, you can keep the existing mechanical system and selectively borrow V2 wording when you document Phase-1 readiness (no migration needed yet). However, if Phase-1 execution is imminent, adopt V2’s roles and phase authority alongside the mechanical plan/evidence framework to retain auditability while letting AI autonomy expand.
