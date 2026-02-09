# Implementation Plan (TSK-P0-128)

failure_signature: P0.REG.BOZ_OBSERVABILITY_ROLE.MISSING_OR_NOT_READONLY
origin_task_id: TSK-P0-128
repro_command: source infra/docker/.env && export DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@localhost:5432/${POSTGRES_DB}" && scripts/db/verify_boz_observability_role.sh

## Goal
Provide a provably read-only BoZ observability seat, implemented as a database role (`boz_auditor`) with mechanical verification.

## Scope
In scope:
- Forward-only migration creating/locking down `boz_auditor` (NOLOGIN, revoke-first posture)
- Verifier `scripts/db/verify_boz_observability_role.sh` (catalog-based privilege proof)
- Evidence JSON at `evidence/phase0/boz_observability_role.json`

Out of scope:
- Runtime app-level observability dashboards (Phase-1 runtime)
- External regulator network access policy (infra-level, later)

## Acceptance
- `boz_auditor` exists and is NOLOGIN.
- `boz_auditor` has no CREATE on schemas and no DML privileges on public tables.
- Verifier emits evidence on PASS and FAIL.

## Toolchain prerequisites (checklist)
- [ ] `psql` available (catalog verification).
- [ ] `python3` available (evidence emission).

verification_commands_run:
- "PENDING: source infra/docker/.env && export DATABASE_URL=... && scripts/db/migrate.sh"
- "PENDING: source infra/docker/.env && export DATABASE_URL=... && scripts/db/verify_boz_observability_role.sh"

final_status: OPEN
