# Pilot-Demo Deployment Guide

## Overview

This document provides step-by-step instructions for deploying the Symphony Pilot-Demo environment on a local machine (including WSL). The pilot-demo profile is a self-contained demonstration environment that showcases Symphony's evidence-backed green finance disbursement capabilities.

**Runtime Profile**: `pilot-demo`  
**Target Audience**: Demo operators, integration partners, pilot stakeholders  
**Deployment Time**: ~15 minutes (excluding dependency installation)

---

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **RAM**: Minimum 4GB available
- **Disk Space**: 2GB free space
- **.NET SDK**: 8.0 or later (Ledger API targets `net10.0`; SDK 10.x recommended)
- **Docker & Docker Compose**: Required for PostgreSQL and OpenBao containers
- **psql**: PostgreSQL client tools (required for schema migrations)

### Required Tools Verification

```bash
# Verify .NET installation
dotnet --version

# Verify Docker installation
docker compose version

# Verify psql installation
psql --version
```

---

## Deployment Sequence

### Step 1: Environment Configuration

Create or verify the `.env` file in the repository root. The `DATABASE_URL` host port **must match** `HOST_POSTGRES_PORT` in `infra/docker/.env` (default `55432`, not `5432`).

```bash
# Runtime profile (REQUIRED)
SYMPHONY_RUNTIME_PROFILE=pilot-demo

# Database connection (REQUIRED) — port must match infra/docker/.env HOST_POSTGRES_PORT
DATABASE_URL=postgresql://symphony_admin:symphony_pass@localhost:55432/symphony

# Evidence storage paths
EVIDENCE_LINK_SUBMISSIONS_FILE=./evidence/phase1/evidence_link_submissions.ndjson
DEMO_EXCEPTION_LOG_FILE=./evidence/phase1/demo_exception_log.ndjson
```

*Note on WSL:* If port `5432` on the host is already taken by a local PostgreSQL instance, the repo defaults avoid that conflict by mapping Docker Postgres to **`55432`** via `infra/docker/.env`. Do not point `DATABASE_URL` at host `5432` unless that instance is the Symphony Docker database with matching credentials.

To use a different host port, set `HOST_POSTGRES_PORT` in `infra/docker/.env` and update `DATABASE_URL` to the same port.

### Step 2: Start Infrastructure Containers

The pilot demo relies on PostgreSQL (storage) and OpenBao (secrets/key vault).

```bash
# Start PostgreSQL database (from repo root; uses infra/docker/.env for port mapping)
docker compose -f infra/docker/docker-compose.yml --env-file infra/docker/.env up -d

# Start OpenBao vault
docker compose -f infra/openbao/docker-compose.yml up -d

# Verify they are running
docker ps
```

Expected Postgres mapping: `0.0.0.0:55432->5432/tcp` (or your custom `HOST_POSTGRES_PORT`).

### Step 3: Bootstrap Secrets & Database Schema

The system is strictly secure-by-default. You must seed the vault and apply migrations.

```bash
# 1. Bootstrap OpenBao with keys and AppRole credentials
bash scripts/security/openbao_bootstrap.sh

# 2. Source environment variables to connect to DB
set -a && source .env && set +a

# 3. Apply schema migrations
bash scripts/db/migrate.sh
```

### Step 4: Validate Component Health

Use the same Postgres port as in `DATABASE_URL` (default `55432`):

```bash
# Verify Postgres is accepting connections
pg_isready -h 127.0.0.1 -p 55432 -U symphony_admin -d symphony

# Verify OpenBao is unsealed
curl -s http://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false' && echo "Vault Ready"
```

### Step 5: Start the Backend Service

Symphony uses Kestrel to serve both the Ledger API and the frontend assets directly. You do NOT need a separate frontend server.

```bash
# Load root .env and OpenBao-injected credentials (same shell session)
set -a && source .env && source /tmp/symphony_openbao/secrets.env && set +a

# Run the API server directly
dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj
```

**Verify Service Health**:

```bash
# Liveness (lightweight)
curl http://localhost:8080/health

# Readiness (DB + OpenBao probes)
curl http://localhost:8080/readyz
```

Expected `/readyz` output should include `"database_ready":true` and `"openbao_ready":true`.  
`/health` reports `"openbao_available":true` and `"status":"ok"` but does not include `database_ready` (use `/readyz` for DB readiness).

---

## Access Points

### Supervisory Dashboard
**URL**: `http://localhost:8080/pilot-demo/supervisory`  
**Purpose**: Main demo interface for operators  
**Authentication**: Operator cookie (auto-set in pilot-demo profile)

### Worker Landing Page (PWRM0001)
**URL**: `http://localhost:8080/pilot-demo/evidence-link`  
**Purpose**: Waste collector submission interface  

---

## Quick Provision Demo Data

For rapid demo setup, use the Quick Provision feature:

1. Navigate to Supervisory Dashboard → Onboarding tab
2. Click "Seed Demo Tenant" button
3. System automatically creates a demo tenant and programme.

On first startup with an empty database, the API may also auto-seed a default pilot-demo tenant and programme when `SYMPHONY_RUNTIME_PROFILE=pilot-demo`.

---

## Troubleshooting

### `DATABASE_URL is required` Error
You did not source the `.env` file before running the backend or the `migrate.sh` script.

### Auth Missing / Vault Unauthorised
Ensure you ran `source /tmp/symphony_openbao/secrets.env` in the exact terminal session you used to launch `dotnet run`. The OpenBao AppRole credentials expire in memory if not loaded properly.

### Connection Refused or Wrong Database
Confirm `DATABASE_URL` uses the **Docker-mapped** host port from `infra/docker/.env` (`HOST_POSTGRES_PORT`, default `55432`), not host `5432`, unless you intentionally run Postgres on `5432` with the same credentials.

```bash
# Check mapped port
docker ps --filter name=symphony-postgres --format '{{.Ports}}'

# Test connectivity
pg_isready -h 127.0.0.1 -p 55432 -U symphony_admin -d symphony
```

### Port Already in Use (WSL users)
Change `HOST_POSTGRES_PORT` in `infra/docker/.env`, then recreate the container and update root `.env` `DATABASE_URL` to match:

```bash
# Example: use 5433 on the host
# In infra/docker/.env: HOST_POSTGRES_PORT=5433
docker compose -f infra/docker/docker-compose.yml --env-file infra/docker/.env up -d
# In root .env: DATABASE_URL=...@localhost:5433/symphony
```

### Migration Errors on Fresh Database
If `scripts/db/migrate.sh` fails partway through, inspect the reported migration file under `schema/migrations/` and resolve before starting the API. An already-migrated database may skip most files and only fail on new migrations.

---

**Document Version**: 1.2 (Port alignment, health endpoints, compose env-file)  
**Maintained By**: Symphony Architecture Team
