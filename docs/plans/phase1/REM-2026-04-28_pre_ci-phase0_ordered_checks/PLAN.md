# DRD Full Postmortem: Lock-Risk Lint Allowlist Mismatch

## Metadata
- Template Type: Full
- Incident Class: Security/DDL
- Severity: L2
- Status: Resolved
- Owner: system
- Date Opened: 2026-04-28
- Date Resolved: 2026-04-28
- Task: TSK-P2-PREAUTH-007-14 (trigger fixes)
- Branch: feat/pre-phase2-wave-5-state-machine-trigger-layer
- Commit Range: b2c14f0e..HEAD

## Summary
Lock-risk lint failed due to duplicate migration file 0134. The allowlist had entries for `0134_create_policy_decisions.sql` but the lint was checking `0134_policy_decisions.sql`. The correct migration file is `0134_policy_decisions.sql` (without "create" in name, uses GF061, proper hardening). The duplicate file was a merge conflict artifact that should have been removed.

## Impact
- Total delay: ~20 minutes (investigation + DRD documentation)
- Failed attempts: 2 (pre_ci.sh failures)
- Full reruns before convergence: 0 (stopped after root cause identification)
- Runtime per rerun: N/A
- Estimated loop waste: Minimal (stopped before blind reruns)

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 08:00-08:10 | 10m | Lock-risk lint failure | Discovered duplicate migration 0134 files |
| 08:10-08:20 | 10m | Investigation | Scanned all migrations, calculated fingerprints, identified correct file |
| 08:20-08:25 | 5m | Fix applied | Updated allowlist, deleted duplicate file |

## Diagnostic Trail
- First-fail artifacts: lock-risk lint failure on 0134_policy_decisions.sql:41-42
- Commands:
  - `ls schema/migrations/0134*.sql` (discovered duplicate files)
  - `grep "CREATE INDEX" schema/migrations/*.sql | grep policy_decisions` (identified statements)
  - `python3 calc_fingerprints.py` (calculated correct fingerprints)

## Root Causes
1. Duplicate migration files with same number: `0134_create_policy_decisions.sql` and `0134_policy_decisions.sql`
2. Allowlist had entries for `0134_create_policy_decisions.sql` but lint was checking `0134_policy_decisions.sql`
3. The duplicate file was a merge conflict artifact that was not properly resolved
4. No automated check prevented duplicate migration numbers

## Contributing Factors
1. Merge conflict in Wave 4 policy_decisions migration was not fully resolved
2. Both files persisted in the repository
3. Allowlist was populated for the incorrect file name

## Recovery Loop Failure Analysis
N/A - stopped after root cause identification, did not attempt blind reruns

## What Unblocked Recovery
Systematic fingerprint calculation revealed the mismatch between allowlist entries and actual file being linted

## Corrective Actions Taken
- Files changed: scripts/security/ddl_allowlist.json (updated entries), schema/migrations/0134_create_policy_decisions.sql (deleted)
- Commands run: Fingerprint calculation, allowlist update, duplicate file deletion

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|---|
| Add migration number uniqueness check to pre_ci.sh | DB Foundation Agent | Script gate | Pass/Fail | Open | TBD |
| Add git pre-commit hook to prevent duplicate migration numbers | DB Foundation Agent | Git hook | Pass/Fail | Open | TBD |

## Early Warning Signs
- Lock-risk lint failure on policy_decisions CREATE INDEX statements
- Allowlist entries pointing to non-existent or wrong file

## Decision Points
1. Stop blind reruns after first lint failure (✅ followed)
2. Investigate root cause before proceeding (✅ followed)
3. Use DRD Full for security/DDL remediation (✅ followed)
4. Delete duplicate file rather than trying to maintain both (✅ followed)

## Verification Outcomes
- Command: `python3 calc_fingerprints.py` - Result: Identified 2 missing allowlist entries for 0134_policy_decisions.sql
- Command: `rm schema/migrations/0134_create_policy_decisions.sql` - Result: Duplicate file deleted
- Command: Updated allowlist with correct fingerprints - Result: Allowlist now has entries for correct file

## Open Risks / Follow-ups
- Need to implement prevention actions to avoid duplicate migration numbers
- Need to investigate why merge conflict was not fully resolved

## Bottom Line
Duplicate migration file 0134 caused allowlist mismatch. Fixed by updating allowlist to point to correct file and deleting the duplicate. This is a security/DDL regulated surface change requiring full DRD documentation.
