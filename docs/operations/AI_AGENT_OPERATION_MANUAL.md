# AI Agent Operations Manual

## Purpose

This manual is the **single source of truth** for AI agent behavior and processes in Symphony. All other agent rule artifacts (e.g., `AGENTS.md`, `docs/operations/AGENT_ROLE_RECONCILIATION.md`, `.codex/agents/**`, `.cursor/agents/**`) are **derived from it**, and any reference to a “canonical” document must point first to this manual. When a task needs the more focused mapping in `AGENT_ROLE_RECONCILIATION.md`, it must explicitly state “see `AI_AGENT_OPERATION_MANUAL.md` for the authoritative rule set and `AGENT_ROLE_RECONCILIATION.md` for the role mapping snapshot.”

This manual defines:

1. The lifecycle of tasks, plans, evidence, remediation, and approvals that every agent must follow.
2. How Phase-1 roles (DB/Schema, Runtime, Security, Compliance, Evidence & Audit, Human Approver) map back to the current agent set.
3. The propagation rules: changes originate here and are copied down into the satellite documents that agents reference for quick context.

Follow this manual whenever an agent is invoked manually or via automation. AI output is never authoritative unless proven by verification scripts/evidence.

## Core Hard Constraints

All agents must obey these guards, as recorded in `AGENTS.md`:

- No runtime DDL on production paths; schema changes only in `schema/migrations/**`.
- Forward-only migrations with `symphony:no_tx` when needed; never edit applied migrations.
- SECURITY DEFINER functions must explicitly set `search_path = pg_catalog, public`.
- Roles follow revoke-first: runtime roles do not regain CREATE.
- Outbox attempts remain append-only.
- No direct pushes or pulls to/from `main`; work only on feature branches/PRs.

Violations stop the agent; escalate to a human supervisor.

## Task Lifecycle (Plan → Implementation → Evidence)

1. **Requirements capture**
   - Identify the invariant(s), gates, and phases touched.
   - Determine whether the work is production-affecting.
2. **Task creation**
   - Register in `docs/tasks/PHASE0_TASKS.md` and `tasks/<TASK_ID>/meta.yml` (fields: phase, owner, touches, invariants, verification, evidence, status, implementation_plan/log).
   - Assign to the appropriate agent based on allowed paths.
3. **Plan + Execution log**
   - Create `docs/plans/phase0/<task>/PLAN.md` (mission, constraints, verification, approvals).
   - Create `docs/plans/phase0/<task>/EXEC_LOG.md` (append-only record of work, errors, fixes, evidence).
4. **Implementation**
   - Modify only the files permitted for the assigned agent.
   - Emit evidence via the declared verification commands (scripts under `scripts/audit/`, `scripts/db/`, `scripts/security/`).
5. **Local parity**
   - Run `scripts/dev/pre_ci.sh` (fresh DB, ordered checks, remediation trace).
   - Evidence scripts must produce `evidence/phase0/*.json`; missing files fail `scripts/ci/check_evidence_required.sh`.
6. **Completion**
   - Mark task `status: "completed"` after evidence exists and gates pass.
   - Attach approvals and signature metadata in evidence artifacts when required.

## Remediation & Debugging

1. When a failure touches production-affecting surfaces, open a remediation casefile under `docs/plans/phase0/REM-*/`.
2. Ensure the plan/log include markers: `failure_signature`, `origin_task_id` (or gate), `repro_command`, `verification_commands_run`, `final_status`.
3. Derive dependent tasks, log every command/fix in `EXEC_LOG.md`, and emit evidence for each verification step.
4. Finalize by updating the plan with root cause, final solution, and approvals (if required). Curate long-term learnings into `docs/operations/troubleshooting/**`.
5. The Evidence & Audit agent must validate that approvals are recorded before evidence artifacts are accepted.

## Agent Roles (Mapping to v2)

Use `docs/operations/AGENT_ROLE_RECONCILIATION.md` to map current agents to Phase-1 roles.  
Evidence & Audit is the gatekeeper of prompt/model hashes and approval evidence.  
Human approvals are recorded as evidence artifacts (JSON with approver, timestamp, artifact path).

## Verification & Compliance

- `scripts/audit/verify_task_plans_present.sh` ensures each task has a plan/log linking to its mission.
- `scripts/audit/verify_remediation_trace.sh` enforces remediation traces when production files change.
- `scripts/audit/verify_evidence_harness_integrity.sh` blocks scripts that try to bypass gates.
-- `scripts/audit/verify_agent_conformance.sh` validates canonical references, stop conditions, regulated-surface approval metadata, and emits role-scoped conformance evidence (`evidence/phase1/agent_conformance_architect.json`, `evidence/phase1/agent_conformance_implementer.json`, `evidence/phase1/agent_conformance_policy_guardian.json`) per the `docs/operations/VERIFY_AGENT_CONFORMANCE_SPEC.md`. It also depends on `docs/operations/approval_metadata.schema.json` and `docs/operations/approval_sidecar.schema.json` to validate approval artifacts.

Agents must never work without these scripts passing locally and in CI. Changes to the specification must follow the same approval + evidence discipline as any regulated surface change.

## Operating the Manual

Read this file before starting any Phase-0/Phase-1 work. Reference the canonical rule files (`AGENTS.md`, `docs/operations/AGENT_ROLE_RECONCILIATION.md`, `docs/operations/AGENT_ROLE_RECONCILIATION.md`, `docs/operations/PHASE1_AI_AGENT_ORCHESTRATION_STRATEGY_COMPARISON.md`). Document deviations as remediation trace entries.

## Definitions (Phase-1 Regulated Surfaces)
These surfaces are critical to the Phase-1 governance contract. Every change touching them must carry AI trace metadata and human approval evidence.
- `schema/migrations/**`
- `scripts/audit/**`
- `scripts/db/**`
- `docs/invariants/**`
- `INVARIANTS_MANIFEST.yml`
- `INVARIANTS_IMPLEMENTED.md`
- `INVARIANTS_ROADMAP.md`
- `CONTROL_PLANES.yml`
- `docs/operations/**`
- `evidence/**`

## Required Metadata for Regulated Surfaces

When a regulated surface changes, the resulting evidence or remediation trace MUST include:

- `ai_prompt_hash` (non-empty string)
- `model_id` (non-empty string)
- `approver_id` (non-empty string)
- `approval_artifact_ref` (path pointing to the approval artifact document)
- `change_reason` (short human-readable explanation)

These metadata values must never include raw PII (emails, national IDs, phone numbers). Use `docs/operations/approval_metadata.schema.json` to validate structure when possible.

## Approval Artifact Format

Approval artifacts must follow this structure:

- Markdown record: `approvals/YYYY-MM-DD/PR-<number>.md` with the required H2 headers (Summary, Scope, Invariants & Phase Discipline, AI Disclosure, Verification & Evidence, Risk Assessment, Approval, Cross-References).
- Approval sidecar JSON: `approvals/YYYY-MM-DD/PR-<number>.approval.json` that mirrors the metadata in `approval_metadata.json` and passes `docs/operations/approval_sidecar.schema.json`.
- Evidence metadata: `evidence/phase1/approval_metadata.json` linking AI + human approvals and regulated-surface scope.

The Markdown file must include a cross-reference block (H2 `## 8. Cross-References (Machine-Readable)`) containing an exact line `Approval Sidecar JSON: approvals/YYYY-MM-DD/PR-<number>.approval.json`. The verifier relies on this to ensure traceability.
