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
- **.NET SDK**: 8.0 or later
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

Create or verify the `.env` file in the repository root:

```bash
# Runtime profile (REQUIRED)
SYMPHONY_RUNTIME_PROFILE=pilot-demo

# Database connection (REQUIRED)
DATABASE_URL=postgresql://symphony_admin:symphony_pass@localhost:5432/symphony

# Evidence storage paths
EVIDENCE_LINK_SUBMISSIONS_FILE=./evidence/phase1/evidence_link_submissions.ndjson
DEMO_EXCEPTION_LOG_FILE=./evidence/phase1/demo_exception_log.ndjson
```

*Note on WSL:* If you have a local PostgreSQL running on port 5432 on your Windows host, it will conflict with Docker. You can remap the Docker port by exporting before running docker-compose: `export HOST_POSTGRES_PORT=5433` and updating your `DATABASE_URL` to match. 

### Step 2: Start Infrastructure Containers

The pilot demo relies on PostgreSQL (storage) and OpenBao (secrets/key vault).

```bash
# Start PostgreSQL database (from repo root)
docker compose -f infra/docker/docker-compose.yml up -d

# Start OpenBao vault
docker compose -f infra/openbao/docker-compose.yml up -d

# Verify they are running
docker ps
```

### Step 3: Bootstrap Secrets & Database Schema

The system is strictly secure-by-default. You must seed the vault and apply migrations.

```bash
# 1. Bootstrap OpenBao with keys and AppRole credentials
bash scripts/security/openbao_bootstrap.sh

# 2. Source environment variables to connect to DB
set -a && source .env && set +a

# 3. Apply 111+ schema migrations
bash scripts/db/migrate.sh
```

### Step 4: Validate Component Health

```bash
# Verify Postgres is accepting connections
pg_isready -h 127.0.0.1 -p 5432 -U symphony_admin -d symphony

# Verify OpenBao is unsealed
curl -s http://127.0.0.1:8200/v1/sys/health | grep -q '"sealed":false' && echo "Vault Ready"
```

### Step 5: Start the Backend Service

Symphony uses Kestrel to serve both the Ledger API and the frontend assets directly. You do NOT need a separate frontend server.

```bash
# Load OpenBao dynamically injected credentials
source /tmp/symphony_openbao/secrets.env

# Run the API server directly
dotnet run --project services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj
```

**Verify Service Health**:
```bash
# In a new terminal
curl http://localhost:8080/health
```
Expected output should include `"database_ready":true` and `"openbao_available":true`.

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

---

## Troubleshooting

### `DATABASE_URL is required` Error
You did not source the `.env` file before running the backend or the `migrate.sh` script.

### Auth Missing / Vault Unathorised
Ensure you ran `source /tmp/symphony_openbao/secrets.env` in the exact terminal session you used to launch `dotnet run`. The OpenBao AppRole credentials expire in memory if not loaded properly.

### Port Already in Use (WSL users)
If `5432` is taken by a host Postgres, map it to `5433`:
```bash
export HOST_POSTGRES_PORT=5433
docker compose -f infra/docker/docker-compose.yml up -d
```
Then remember to update your `DATABASE_URL` in `.env` to match port `5433`.

---

**Document Version**: 1.1 (Canonical Truth Update)  
**Maintained By**: Symphony Architecture Team
