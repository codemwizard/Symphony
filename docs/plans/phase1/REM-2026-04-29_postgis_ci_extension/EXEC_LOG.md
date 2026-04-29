# Execution Log: REM-2026-04-29_postgis_ci_extension

## 2026-04-29T08:30:00Z - Investigation Started
- CI failure observed at migration 0125_postgis_extension.sql
- Error: extension "postgis" is not available
- HINT: The extension must first be installed on the system where PostgreSQL is running

## 2026-04-29T08:32:00Z - Root Cause Identified
- Compared local Docker environment with CI environment
- Local: postgis/postgis:18-3.6 image (includes PostGIS)
- CI: postgresql-18 apt package (no PostGIS)
- Environment mismatch confirmed

## 2026-04-29T08:35:00Z - Fix Implemented
- Modified .github/workflows/invariants.yml line 492
- Changed: `sudo apt-get install -y postgresql-18 postgresql-client-18`
- To: `sudo apt-get install -y postgresql-18 postgresql-client-18 postgresql-18-postgis-3`

## 2026-04-29T08:40:00Z - Remediation Casefile Created
- Created docs/plans/phase1/REM-2026-04-29_postgis_ci_extension/PLAN.md
- Created docs/plans/phase1/REM-2026-04-29_postgis_ci_extension/EXEC_LOG.md
- Documented root cause, fix, and prevention actions

## 2026-04-29T08:45:00Z - Verification
- Local preflight checks pass
- Changes staged for commit
- Ready to push to trigger CI re-run
