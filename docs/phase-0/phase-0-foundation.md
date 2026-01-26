# Phase 0: Foundation and Project Reset

## Goal
Create a clean-slate repo that can be safely extended bottom-up without inheriting legacy drift:
- Authoritative documentation structure
- Mechanical verification of invariants
- Deterministic DB bootstrap workflow
- Strict posture defaults (no runtime DDL)

## Non-goals
- Implementing payment orchestration business logic
- Implementing policy rotation/grace
- Implementing full ledger posting

## Deliverables

### 1. Repo Structure
Create the following directory structure:
- `services/` - Application services
- `packages/` - Shared Node.js and .NET packages
- `schema/` - Database migrations and seeds
- `scripts/` - DB and dev tooling
- `docs/` - Documentation (design, invariants, decisions, operations)
- `infra/` - Docker and infrastructure configs
- `archive/` - Legacy codebase (frozen, read-only)

### 2. Invariants Contract
- `docs/invariants/INVARIANTS_QUICK.md` - One-line per invariant
- `docs/invariants/INVARIANTS_IMPLEMENTED.md` - Mechanically enforced invariants
- `docs/invariants/INVARIANTS_ROADMAP.md` - Planned/reserved invariants

### 3. Agent Instructions
- `AGENT.md` - Short, strict agent guidance

### 4. DB Verification Entrypoint
- `scripts/db/verify_invariants.sh` - Runs CI gate locally

### 5. CI Invariant Gate
- `scripts/db/ci_invariant_gate.sql` - Hard-fail SQL gate for CI

### 6. Local Dev Environment
- `infra/docker/docker-compose.yml` - Postgres 18 for local dev

### 7. Reset Script Posture
- `scripts/db/reset_and_migrate.sh` - Must NOT grant CREATE on public to PUBLIC

## Acceptance Criteria
1. Fresh DB + migrations + gate passes locally:
   ```bash
   DATABASE_URL=... scripts/db/verify_invariants.sh
   ```
2. CI runs the same script and fails on violations
3. No documentation references legacy paths as authoritative

## Risks
| Risk | Mitigation |
|------|------------|
| "Docs-only invariants" drift | CI gate is mandatory |
| Convenience regressions (devs re-add PUBLIC CREATE) | Gate + explicit ADR |

## ADRs Required
- ADR-0001: Repo structure and archive boundary
- ADR-0002: Invariant enforcement approach (SQL gate + scripts)
