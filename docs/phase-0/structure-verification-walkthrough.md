# Phase-0 Structure Verification Walkthrough

**Verification Date**: 2026-01-24  
**Status**: ⚠️ Partial Match (Core Foundation Present, Several Gaps Identified)

---

## Overview

This document compares the current Symphony project structure against the expected Phase-0 layout.

---

## Verification Results

### Root Level

| Expected | Status | Notes |
|----------|--------|-------|
| `README.md` | ✅ Present | |
| `AGENT.md` | ✅ Present | |
| `archive/` | ✅ Present | Contains legacy codebase |

---

### `docs/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `docs/overview/vision.md` | ❌ Missing | Directory does not exist |
| `docs/overview/architecture.md` | ❌ Missing | |
| `docs/overview/glossary.md` | ❌ Missing | |
| `docs/design/phase-0-foundation.md` | ✅ Present | |
| `docs/design/phase-1-db-foundation.md` | ✅ Present | |
| `docs/invariants/INVARIANTS_QUICK.md` | ✅ Present | |
| `docs/invariants/INVARIANTS_IMPLEMENTED.md` | ✅ Present | |
| `docs/invariants/INVARIANTS_ROADMAP.md` | ✅ Present | |
| `docs/decisions/ADR-0001-repo-structure.md` | ✅ Present | |
| `docs/decisions/ADR-0002-db-mig-ledger.md` | ✅ Present | |
| `docs/decisions/ADR-0003-outbox-lease-fencing.md` | ✅ Present | |
| `docs/decisions/ADR-0004-policy-seeding.md` | ✅ Present | |
| `docs/operations/local-dev.md` | ✅ Present | |
| `docs/operations/ci.md` | ❌ Missing | |
| `docs/operations/runbooks.md` | ❌ Missing | |

---

### `schema/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `schema/baseline.sql` | ✅ Present | |
| `schema/migrations/0001_init.sql` | ✅ Present | |
| `schema/migrations/0002_outbox_functions.sql` | ✅ Present | |
| `schema/migrations/0003_roles.sql` | ✅ Present | |
| `schema/migrations/0004_privileges.sql` | ✅ Present | |
| `schema/migrations/0005_policy_versions.sql` | ✅ Present | |
| `schema/seeds/dev/seed_policy_from_file.sh` | ❌ Missing | Directory does not exist |
| `schema/seeds/ci/seed_policy_from_env.sh` | ❌ Missing | (exists in `scripts/db/`) |

---

### `scripts/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `scripts/db/migrate.sh` | ✅ Present | |
| `scripts/db/reset_and_migrate.sh` | ✅ Present | |
| `scripts/db/apply_baseline.sh` | ✅ Present | |
| `scripts/db/ci_invariant_gate.sql` | ✅ Present | |
| `scripts/db/verify_invariants.sh` | ✅ Present | |
| `scripts/db/lint_migrations.sh` | ✅ Present | |
| `scripts/dev/up.sh` | ❌ Missing | Directory does not exist |
| `scripts/dev/down.sh` | ❌ Missing | |

---

### `packages/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `packages/node/db/` | ❌ Missing | Entire `packages/` directory does not exist |
| `packages/node/bootstrap/` | ❌ Missing | |
| `packages/node/common/` | ❌ Missing | |
| `packages/dotnet/LedgerCore/` | ❌ Missing | |

---

### `services/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `services/outbox-relayer/node/` | ❌ Missing | Entire `services/` directory does not exist |
| `services/api/node/` | ❌ Missing | |
| `services/ledger-api/dotnet/` | ❌ Missing | |

---

### `infra/` Directory

| Expected | Status | Notes |
|----------|--------|-------|
| `infra/docker/docker-compose.yml` | ✅ Present | |
| `infra/docker/postgres/init/00-create-db.sql` | ❌ Missing | `postgres/` subdirectory does not exist |

---

## Summary

### ✅ Present (Core Foundation)
- Root files: `README.md`, `AGENT.md`
- Archive directory for legacy code
- All 5 schema migrations
- All scripts in `scripts/db/`
- Docker Compose configuration
- Invariants documentation (all 3 files)
- ADR documents (all 4 files)
- Design documents (both phase files)

### ❌ Missing (Gaps to Address)
1. **`docs/overview/`** - Vision, architecture, glossary documents
2. **`docs/operations/`** - CI and runbooks documentation
3. **`schema/seeds/`** - Policy seeding scripts (partially in `scripts/db/`)
4. **`scripts/dev/`** - Local development scripts (`up.sh`, `down.sh`)
5. **`packages/`** - Node.js and .NET shared packages
6. **`services/`** - Application services (outbox-relayer, api, ledger-api)
7. **`infra/docker/postgres/`** - Database initialization scripts

---

## Recommendation

The project has strong foundational elements (migrations, scripts, invariants, ADRs) but lacks the application layer (`packages/`, `services/`) and some operational tooling. These should be scaffolded in subsequent phases.
