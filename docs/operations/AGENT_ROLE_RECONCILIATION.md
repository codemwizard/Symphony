# Agent Role Reconciliation

This document enumerates the **current agent set with their rules** (per `AGENTS.md`) and maps them to the **new agents defined in `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`**, but it explicitly defers to `docs/operations/AI_AGENT_OPERATION_MANUAL.md` as the ultimate source of truth for any conflict or interpretation question.

## 1. Current Agents and Rules

| Agent | Rules / Constraints |
|---|---|
| **Supervisor/Orchestrator** | Decides specialist agent per detector output, files changed, and phase; enforces hard constraints (no runtime DDL, forward-only migrations, SECURITY DEFINER hardening, revoke-first, append-only outbox, no direct pushes to `main`). |
| **DB Foundation Agent** | Paths: `schema/migrations/**`, `scripts/db/**`; must run `scripts/db/verify_invariants.sh`, `scripts/db/tests/test_db_functions.sh`; may never weaken fencing, grants, or append-only semantics. |
| **Invariants Curator Agent** | Paths: `docs/invariants/**`, `docs/PHASE0/**`, `docs/tasks/**`, `scripts/audit/**`, `scripts/db/**`, `schema/**`, `.github/codex/prompts/invariants_review.md`; must run `scripts/audit/run_invariants_fast_checks.sh`; never mark invariants implemented without enforcement evidence. |
| **Security Guardian Agent** | Paths: `scripts/security/**`, `scripts/audit/**`, `docs/security/**`, `.github/workflows/**`, `infra/**`, `src/**`, `packages/**`, `Dockerfile`; must run `scripts/audit/run_security_fast_checks.sh`; never broaden privileges, weaken SECURITY DEFINER hardening, or add runtime DDL. |
| **Compliance Mapper Agent** | Paths: `docs/security/**`, `docs/architecture/**`, `evidence/**` (read-only); produces control-matrix updates/gaps; no code changes. |
| **Research Scout** | Paths: `docs/research/**`, `docs/overview/**`; scheduled work only. |

These roles are referenced (and replicated with slight variations) in `.codex/agents/` and `.cursor/agents/` prompts, but they all defer to the hard constraints listed above plus the mechanical gates and verification scripts (`scripts/dev/pre_ci.sh`, CI workflows, evidence harness, remediation trace).

## 2. New Agent Roles (from v2) and Mapping

| New Role | Key Responsibilities | Current Agent Equivalent / Mapping |
|---|---|---|
| **DB/Schema Agent** | Owns migrations, constraints, triggers; enforces expand/contract discipline; cannot adjust evidence semantics. | **DB Foundation Agent** ( identical scope + constraints). |
| **Runtime/Orchestration Agent** | Implements state machines and workers; adheres to DB-level enforcement; chooses implementation details within constraints. | **Supervisor** (orchestrator for runtime paths) coordinated with **DB Foundation** when touching schema; v2 runtime agent explicitly covers what Supervisor previously inferred. |
| **Security Guardian Agent** | Owns PII boundaries, authz, secrets; reviews sensitive code. | **Security Guardian Agent** already defined; v2 adds formal forbidding of invariant renaming and evidence tampering but aligns with existing rules. |
| **Compliance / Invariant Mapper Agent** | Maps requirements → invariants → verifiers → evidence; updates manifests/contracts after code + evidence exist. | **Invariants Curator Agent** + **Compliance Mapper** combined; v2 merges these roles by emphasizing mapping and evidence-first updates while keeping enforcement-first requirement. |
| **Evidence & Audit Agent** | Guarantees deterministic evidence emission; validates hashing/proof. | Not formally named today; functions performed by `scripts/audit/*` and `verify_evidence_harness_integrity.sh`; v2 makes it an explicit agent, ensuring oversight. |
| **Human Approver** | Mandatory for schema/invariant/policy changes; approval recorded as evidence. | Implicit today via reviewers + plan/emergency trace files; v2 formalizes record keeping of approvals. |

## 3. Gap Analysis

1. **Evidence Ownership**: The current system enforces evidence through scripts but has no named “Evidence & Audit Agent.” V2 adds visibility; we can satisfy it by documenting that the evidence harness role is performed by existing audit cells (`scripts/audit/`), and by requiring plan/log references to that role.  
2. **Explicit Human Approver**: Today approval is implicit in code review. V2’s explicit Human Approver role can be implemented by mandating addendum notation in remediation logs (e.g., `approval_id`, `approver_signoff`).  
3. **Runtime Agent**: Existing Supervisor orchestration can be documented to include the Runtime/Orchestration responsibilities V2 describes; add to AGENTS file a mention of runtime enforcement when state-machine files change.  
4. **Compliance Mapper scope**: V2 insists on mapping requirements to evidence before manifest changes. We already do this via the Invariants Curator’s checks; highlight that mapping in `docs/operations/AGENT_ROLE_RECONCILIATION.md`.  
5. **Stop/Escalation rules**: V2 explicitly lists stop conditions (phase boundary risk, missing evidence). We already escalate via plan/gate failures; codify these stop rules in the supervisor prompt/rules so no knowledge is lost.

## 4. Recommended Fix Approach

1. Elevate the master rule text into one canonical document (e.g., `docs/operations/AGENT_CONTRACT.md`) referenced by all agent prompts (.codex, .cursor, .agent).  
2. Annotate each agent prompt/rules file with the current mapping table (Section 2) so auditors see how legacy roles map to v2 roles.  
3. Add a verification step (script in `scripts/audit/verify_agent_conformance.sh`) that checks agent files reference the canonical contract and include the resolved role mapping.  
4. When adopting Phase-1, expand `AGENTS.md` to include v2 roles (Evidence Agent, Human Approver, Runtime Agent) while keeping the mechanical gate references intact.

The reconciliation document is saved as `docs/operations/AGENT_ROLE_RECONCILIATION.md`. It ensures we retain all existing constraints while tracking the new roles’ coverage.
