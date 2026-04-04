# Pilot-Demo Deployment Guide

## Overview

This document provides step-by-step instructions for deploying the Symphony Pilot-Demo environment. The pilot-demo profile is a self-contained demonstration environment that showcases Symphony's evidence-backed green finance disbursement capabilities.

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
- **Node.js**: 18.x or later (for frontend assets)
- **Git**: For repository access

### Required Tools

```bash
# Verify .NET installation
dotnet --version
# Expected: 8.0.x or later

# Verify Node.js installation
node --version
# Expected: v18.x or later

# Verify Git installation
git --version
```

---

## Deployment Steps

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd symphony-platform
```

### Step 2: Environment Configuration

Create or verify the `.env` file in the repository root:

```bash
# Runtime profile (REQUIRED)
SYMPHONY_RUNTIME_PROFILE=pilot-demo

# Evidence storage paths (auto-created if missing)
EVIDENCE_LINK_SUBMISSIONS_FILE=./evidence/phase1/evidence_link_submissions.ndjson
DEMO_EXCEPTION_LOG_FILE=./evidence/phase1/demo_exception_log.ndjson

# Signing key for demo evidence links (pilot-demo only)
DEMO_EVIDENCE_LINK_SIGNING_KEY=pilot-demo-hmac-key-phase1

# Optional: Override default ports
# LEDGER_API_PORT=5000
# FRONTEND_PORT=8080
```

**Security Note**: The `DEMO_EVIDENCE_LINK_SIGNING_KEY` is for demonstration purposes only. Production deployments must use secure key management.

### Step 3: Build Backend Services

```bash
# Navigate to .NET project
cd services/ledger-api/dotnet

# Restore dependencies
dotnet restore

# Build the project
dotnet build --configuration Release

# Verify build succeeded
echo $?
# Expected: 0
```

### Step 4: Run Self-Tests (Recommended)

Before starting the demo, verify all components with self-tests:

```bash
# Run all self-tests
dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj \
  -- --self-test

# Run specific component tests
dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj \
  -- --self-test-worker-onboarding

dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj \
  -- --self-test-weighbridge-capture

dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj \
  -- --self-test-pwrm-monitoring-report

# Expected output: All tests PASS, exit code 0
```

**Self-Test Coverage**:
- Evidence link issuance and submission
- Worker onboarding and supplier registry
- Weighbridge capture with structured payloads
- Monitoring report aggregation
- GPS validation and MSISDN matching
- Supervisory read models

### Step 5: Start Backend Service

```bash
# From services/ledger-api/dotnet directory
dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj

# Expected output:
# info: Microsoft.Hosting.Lifetime[14]
#       Now listening on: http://localhost:5000
# info: Microsoft.Hosting.Lifetime[0]
#       Application started. Press Ctrl+C to shut down.
```

**Verify Backend Health**:
```bash
# In a new terminal
curl http://localhost:5000/health
# Expected: {"status":"healthy"}
```

### Step 6: Serve Frontend Assets

```bash
# From repository root
cd src

# Option A: Using Python (simplest)
python3 -m http.server 8080

# Option B: Using Node.js http-server
npx http-server -p 8080

# Option C: Using any static file server
```

**Verify Frontend Access**:
```bash
curl http://localhost:8080/supervisory-dashboard/
# Expected: HTML content
```

---

## Access Points

### Supervisory Dashboard
**URL**: `http://localhost:8080/supervisory-dashboard/`  
**Purpose**: Main demo interface for operators  
**Authentication**: Operator cookie (auto-set in pilot-demo profile)

**Key Features**:
- Programme overview and timeline
- Evidence completeness tracking
- Exception log monitoring
- Drill-down instruction detail
- Export reporting pack
- Generate PWRM0001 monitoring reports

### Onboarding Console
**URL**: `http://localhost:8080/supervisory-dashboard/` → Onboarding tab  
**Purpose**: Tenant and programme provisioning  

**Capabilities**:
- Register new tenants
- Create programmes
- Register suppliers
- Bind policies to programmes
- Activate programmes

### Worker Landing Page (PWRM0001)
**URL**: `http://localhost:8080/recipient-landing/`  
**Purpose**: Waste collector submission interface  

**Workflow**:
1. Worker enters phone number
2. System issues evidence-link token
3. Worker submits weighbridge record with GPS
4. Submission recorded in evidence trail

### API Endpoints

**Base URL**: `http://localhost:5000`

**Pilot-Demo Routes** (require operator cookie):
- `GET /pilot-demo/api/monitoring-report/{programId}` - Generate monitoring report
- `POST /pilot-demo/api/evidence-links/issue` - Issue evidence-link token
- `POST /pilot-demo/api/evidence-links/submit` - Submit artifact
- `GET /pilot-demo/artifacts/{fileName}` - Download artifact files

**Admin Routes**:
- `GET /api/admin/onboarding/status` - Onboarding state
- `POST /api/admin/onboarding/tenants` - Register tenant
- `POST /api/admin/onboarding/programmes` - Create programme

---

## Quick Provision Demo Data

For rapid demo setup, use the Quick Provision feature:

1. Navigate to Supervisory Dashboard → Onboarding tab
2. Click "Seed Demo Tenant" button
3. System automatically creates:
   - Demo tenant: `Zambia Green MFI`
   - Demo programme: `PGM-ZAMBIA-GRN-001` (PWRM0001)
   - Policy binding: `green_eq_v1`
   - Programme activation

**Manual Provisioning** (alternative):

```bash
# Register tenant
curl -X POST http://localhost:5000/api/admin/onboarding/tenants \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_key": "ten-zambiagrn",
    "display_name": "Zambia Green MFI"
  }'

# Create programme (use tenant_id from response)
curl -X POST http://localhost:5000/api/admin/onboarding/programmes \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "<tenant-id>",
    "programme_key": "PGM-ZAMBIA-GRN-001",
    "display_name": "Chunga Dumpsite — PWRM0001 Plastic Collection"
  }'

# Bind policy (use programme_id from response)
curl -X POST http://localhost:5000/api/admin/onboarding/programmes/<programme-id>/policy-binding \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "<tenant-id>",
    "policy_code": "green_eq_v1"
  }'

# Activate programme
curl -X PUT http://localhost:5000/api/admin/onboarding/programmes/<programme-id>/activate \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "<tenant-id>"
  }'
```

---

## Verification Checklist

After deployment, verify the following:

- [ ] Backend service running on port 5000
- [ ] Frontend accessible on port 8080
- [ ] Supervisory dashboard loads without errors
- [ ] Onboarding console shows "0 tenants" initially
- [ ] Quick provision creates demo tenant successfully
- [ ] Programme appears in dashboard after activation
- [ ] Worker landing page loads and accepts phone numbers
- [ ] Self-tests pass (all 8 test suites)

---

## Troubleshooting

### Backend Won't Start

**Symptom**: `dotnet run` fails with compilation errors

**Solution**:
```bash
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build --configuration Release
```

### Port Already in Use

**Symptom**: `Address already in use` error

**Solution**:
```bash
# Find process using port 5000
lsof -i :5000  # macOS/Linux
netstat -ano | findstr :5000  # Windows

# Kill process or use different port
export LEDGER_API_PORT=5001
```

### Frontend 404 Errors

**Symptom**: Dashboard shows "Not Found"

**Solution**:
```bash
# Verify you're serving from src/ directory
cd src
python3 -m http.server 8080

# Access with trailing slash
http://localhost:8080/supervisory-dashboard/
```

### Self-Tests Fail

**Symptom**: Self-test runner exits with code 1

**Solution**:
```bash
# Check runtime profile
echo $SYMPHONY_RUNTIME_PROFILE
# Must be: pilot-demo

# Verify evidence directory exists
mkdir -p evidence/phase1

# Re-run specific failing test with verbose output
dotnet run --no-launch-profile \
  --project src/LedgerApi.DemoHost/LedgerApi.DemoHost.csproj \
  -- --self-test-<test-name>
```

### Database Connection Issues

**Note**: Pilot-demo uses in-memory storage. No database required.

If you see database errors, verify `SYMPHONY_RUNTIME_PROFILE=pilot-demo` is set.

---

## Production Deployment Notes

**CRITICAL**: The pilot-demo profile is NOT suitable for production use.

**Production Requirements**:
- Change runtime profile to `production`
- Configure PostgreSQL database
- Implement secure key management (Azure Key Vault, AWS Secrets Manager)
- Enable TLS/HTTPS
- Configure authentication/authorization
- Set up monitoring and logging
- Implement backup and disaster recovery
- Review and harden security policies

**Profile Differences**:

| Feature | pilot-demo | production |
|---------|-----------|------------|
| Storage | In-memory | PostgreSQL |
| Auth | Cookie-based | OAuth2/OIDC |
| Signing | Demo HMAC key | HSM/KMS |
| Evidence | Local files | S3/Blob Storage |
| Monitoring | Console logs | Structured logging |

---

## Support and Resources

**Documentation**:
- Architecture: `docs/architecture/`
- Operations: `docs/operations/`
- Invariants: `docs/invariants/`

**Self-Test Evidence**:
- Location: `evidence/phase1/`
- Format: NDJSON and JSON
- Retention: Survives data purge

**Contact**:
- Technical issues: See repository issues
- Security concerns: See SECURITY.md
- Demo requests: Contact project maintainers

---

## Appendix: Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SYMPHONY_RUNTIME_PROFILE` | Yes | - | Must be `pilot-demo` |
| `EVIDENCE_LINK_SUBMISSIONS_FILE` | No | `./evidence/phase1/evidence_link_submissions.ndjson` | Submission log path |
| `DEMO_EXCEPTION_LOG_FILE` | No | `./evidence/phase1/demo_exception_log.ndjson` | Exception log path |
| `DEMO_EVIDENCE_LINK_SIGNING_KEY` | No | `pilot-demo-hmac-key-phase1` | HMAC signing key |
| `LEDGER_API_PORT` | No | `5000` | Backend API port |
| `FRONTEND_PORT` | No | `8080` | Frontend server port |

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-03  
**Maintained By**: Symphony Platform Team
