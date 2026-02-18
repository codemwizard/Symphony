# Phase-1 Agent System Rollout (PATCHED v2)

failure_signature: PHASE1.AGENT_SYSTEM.ROLL_OUT
origin_task_id: TSK-P1-001
first_observed_utc: 2026-02-10T00:00:00Z

## Mission
Document, formalize, and enforce the Phase-1 agent operating model so every automated or human-plus-AI change follows the new roles, approval, and evidence contracts defined in:

- `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md` (canonical rules)
- `docs/operations/AGENT_ROLE_RECONCILIATION.md` (role mapping + prompt requirements)

without losing Phase-0 mechanical gates, ordering parity, and remediation-trace discipline.

## Scope
In scope:
- Align `AGENTS.md`, `.codex/agents/*`, and `.cursor/agents/*` to reference:
  * `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
  * `docs/operations/AGENT_ROLE_RECONCILIATION.md`
- Introduce explicit Evidence & Audit and Human Approver artifacts (prompt hash, model id, approval record) into the verification/evidence pipeline.
- Add Phase-1 verification tooling so every agent file and remediation trace references the same rule set and includes stop/escalation conditions.

Out of scope:
- Writing the Phase-1 runtime services themselves (these are separate tasks); this is purely governance/verification infrastructure.

## Definitions (Phase-1 Regulated Surfaces)

These are “Phase-1 surfaces” for the purpose of approval metadata and conformance checks.

- `schema/migrations/**`
- `scripts/audit/**`
- `scripts/db/**`
- `docs/invariants/**`
- `INVARIANTS_MANIFEST.md`
- `INVARIANTS_IMPLEMENTED.md`
- `INVARIANTS_ROADMAP.md`
- `docs/control_planes/CONTROL_PLANES.yml`
- `docs/operations/**` (agent governance / controls)
- `evidence/**` (evidence harness schema)

Required metadata when regulated surfaces are changed:

- `ai_prompt_hash` (non-empty string)
- `model_id` (non-empty string)
- `approver_id` (non-empty string for regulated surfaces)
- `approval_artifact_ref` (path/identifier to approval record)
- `change_reason` (non-empty overview of the change)

Metadata must avoid raw PII.

## Proposed Tasks
1. `TSK-P1-001`: Canonize agent rule sourcing and role mapping (update docs and prompts, ensure stop conditions are recorded).
2. `TSK-P1-002`: Extend evidence and remediation scripts to record prompt/model hashes plus approval metadata when regulated surfaces are touched.
3. `TSK-P1-003`: Introduce a verification pass that ensures every agent file references the canonical doc, includes stop/escalation conditions, and regulated-surface changes carry the required metadata.
4. `TSK-P1-004`: Define the `verify_agent_conformance.sh` specification, integrate it with the manual, and ensure its requirements (including approval metadata + sidecar usage) are well-documented before implementation.

## Acceptance (Global)
- `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md` is the canonical contract referenced everywhere.
- `docs/operations/AGENT_ROLE_RECONCILIATION.md`, `AGENTS.md`, and all `.codex/.cursor` agent prompts:
  * reference the canonical contract(s)
  * include explicit Stop Conditions / Escalation sections.
- Evidence JSON files include the required prompt/model/approval metadata whenever regulated surfaces are touched.
- Automated check (`scripts/audit/verify_agent_conformance.sh`) validates canonical references, stop sections, and approval metadata before merges, emitting Phase-1 evidence.
