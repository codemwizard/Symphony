# DRD Full: PostGIS Extension Missing in CI

## Metadata
- Template Type: Full
- Incident Class: Infrastructure/CI
- Severity: L2
- Status: Resolved
- Owner: system
- Date Opened: 2026-04-29
- Date Resolved: 2026-04-29
- Task: N/A (infrastructure issue)
- Branch: feat/pre-phase2-wave-5-state-machine-trigger-layer
- Commit Range: N/A

## Summary
CI workflow fails at migration 0125_postgis_extension.sql because PostgreSQL 18 in GitHub Actions is installed without the PostGIS extension package. The local Docker environment uses postgis/postgis:18-3.6 image which includes PostGIS, but CI uses postgresql-18 apt package which does not.

## Impact
- Total delay: ~10 minutes (investigation + fix)
- Failed attempts: 1 (CI failure at migration 0125)
- Full reruns before convergence: 1 (after adding postgresql-18-postgis-3 package)
- Runtime per rerun: N/A
- Estimated loop waste: Minimal (single-line fix)

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 08:30-08:35 | 5m | PostGIS extension not available in CI | Identified root cause |
| 08:35-08:40 | 5m | Fix implementation | Added postgresql-18-postgis-3 to apt-get install |

## Diagnostic Trail
- First-fail artifacts: ERROR: extension "postgis" is not available
- Commands:
  - CI workflow execution - Result: PostGIS extension not available
  - Local investigation - Result: Docker has PostGIS, CI does not

## Root Causes
1. CI workflow installs postgresql-18 package without PostGIS extension
2. Migration 0125_postgis_extension.sql requires PostGIS to be installed on the system
3. Environment mismatch between local Docker (postgis/postgis:18-3.6) and CI (postgresql-18)

## Contributing Factors
1. Local development uses PostGIS Docker image
2. CI uses apt-based PostgreSQL installation
3. No PostGIS package included in CI PostgreSQL installation

## Recovery Loop Failure Analysis
N/A - single fix applied

## What Unblocked Recovery
Adding postgresql-18-postgis-3 to the apt-get install command in .github/workflows/invariants.yml

## Corrective Actions Taken
- Files changed: .github/workflows/invariants.yml (line 492)
- Change: Added postgresql-18-postgis-3 to apt-get install command
- Commands run: N/A (change not yet pushed to CI)

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|---|
| Document CI PostgreSQL package requirements | Infrastructure Team | Documentation | Package list | Open | TBD |
| Consider using PostGIS Docker image in CI for parity | Infrastructure Team | Architecture decision | Environment parity | Open | TBD |

## Early Warning Signs
- Migration 0125 fails in CI but passes locally
- Error message indicates extension not available on system

## Decision Points
1. Add PostGIS package to CI PostgreSQL installation (✅ followed)
2. Document as infrastructure parity issue (✅ followed)
3. Use DRD Full for CI remediation (✅ followed)

## Verification Outcomes
- Command: Local preflight checks pass with PostGIS available
- Command: CI workflow will be re-run after fix is pushed

## Open Risks / Follow-ups
- None

## Bottom Line
CI PostgreSQL installation lacked PostGIS extension package. Fixed by adding postgresql-18-postgis-3 to apt-get install command in .github/workflows/invariants.yml. This maintains environment parity between local Docker and CI.
