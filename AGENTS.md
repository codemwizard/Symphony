# Symphony Agent Contracts (Cursor / Codex)

This repo uses **mechanical gates first** and **AI agents as assistants**.
AI output is never authoritative unless backed by enforcement + verification.

## Hard constraints (never violate)
- No runtime DDL in production paths.
- Forward-only migrations; never edit applied migrations.
- SECURITY DEFINER functions must harden: `SET search_path = pg_catalog, public`.
- Revoke-first privilege posture; runtime roles must not regain CREATE on schemas.
- Append-only outbox attempts must remain append-only.
- **No direct push to `main`.** Work only on feature branches and open PRs.
- **No direct pull from `main` into working branches.** Use PRs for integration.

## Agents

### Supervisor (Orchestrator)
Decides which specialist agent runs based on:
- detector output (`structural_change`)
- files changed (DDL, roles, workflows, policies)
- current phase (Phase 2: policy rotation)

### DB Foundation Agent
Allowed paths: `schema/migrations/**`, `scripts/db/**`
Must run: `scripts/db/verify_invariants.sh`, `scripts/db/tests/test_db_functions.sh`
Never: weaken fencing semantics, grants, or append-only guarantees.

### Invariants Curator Agent
Allowed paths: `docs/invariants/**`, `docs/PHASE0/**`, `docs/tasks/**`, `scripts/audit/**`, `scripts/db/**`, `schema/**`, `.github/codex/prompts/invariants_review.md`
Must run: `scripts/audit/run_invariants_fast_checks.sh`
Never: mark implemented without enforcement + verification evidence.

### Security Guardian Agent
Allowed paths: `scripts/security/**`, `scripts/audit/**`, `docs/security/**`, `.github/workflows/**`, `infra/**`, `src/**`, `packages/**`, `Dockerfile`
Must run: `scripts/audit/run_security_fast_checks.sh`
Never: broaden privileges, weaken SECURITY DEFINER hardening, add runtime DDL.

### Compliance Mapper Agent (non-blocking)
Allowed paths: `docs/security/**`, `docs/architecture/**`, `evidence/**` (read-only)
Produces control-matrix updates and gaps. No code changes.

### Research Scout (scheduled)
Allowed paths: `docs/research/**`, `docs/overview/**`
Runs only on scheduled workflow.

## Role
Role: Supervisor

## Scope
- Preserve the canonical agent governance references for every Phase-1 operation.
- Coordinate with specialist agents to keep regulated-surface evidence airtight.
- Escalate any ambiguous Powered by compliance gaps immediately.

## Non-Negotiables
- All Phase-1 work must cite `docs/operations/AI_AGENT_OPERATION_MANUAL.md` as the single source of truth.
- No agent runs unless `verify_agent_conformance.sh` or its equivalent passes locally.
- Approval metadata must precede any production-affecting change.

## Stop Conditions
- Stop when regulated surfaces are modified without approval metadata or canonical references.
- Halt if `verify_agent_conformance.sh` reports a failure; open a remediation plan before proceeding.
- Pause all automated work if the operation manual or canonical docs are updated until a human reconfirms compliance.

## Verification Commands
- `scripts/dev/pre_ci.sh`

## Evidence Outputs
- `evidence/phase1/agent_conformance.json`

## Canonical References
- `docs/operations/AI_AGENT_WORKFLOW_AND_ROLE_PLAN_v2.md`
- `docs/operations/AGENT_ROLE_RECONCILIATION.md`
