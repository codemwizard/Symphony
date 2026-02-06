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
