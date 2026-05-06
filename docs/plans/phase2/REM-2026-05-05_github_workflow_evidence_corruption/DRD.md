# DRD: GitHub Workflow Evidence File Corruption

## Metadata
- Template Type: Full
- Incident Class: Evidence Integrity Failure
- Severity: L2
- Status: Open
- Owner: QA_VERIFIER_AGENT
- Date Opened: 2026-05-05
- Date Resolved: TBD
- Task: TSK-P2-W8-QA-001-REM-01
- Branch: fix/github-workflow-evidence-corruption
- Commit Range: TBD

## Summary
GitHub workflow redirects verify_phase2_contract.sh stdout into evidence/phase2/phase2_contract_status.json, but the script itself also opens and writes that same JSON file. Writing to same path from shell redirection and from Python writer in script can interleave/overwrite content, producing a corrupted evidence artifact even when verification succeeds.

## Impact
- Total delay: TBD minutes
- Failed attempts: 0 (proactive identification)
- Full reruns before convergence: N/A
- Runtime per rerun: N/A
- Estimated loop waste: N/A

## Timeline
| Window | Duration | First blocker | Notes |
|---|---:|---|---|
| 2026-05-05T09:18Z | TBD | Code review finding | Workflow evidence corruption identified |

## Diagnostic Trail
- First-fail artifacts: Code review of GitHub workflow evidence redirection
- Commands: 
  - `grep -n -A 3 -B 3 "verify_phase2_contract.sh.*>" .github/workflows/*.yml`
  - `grep -n "phase2_contract_status.json" scripts/audit/verify_phase2_contract.sh`

## Root Causes
1. Workflow uses shell redirection (`> evidence/phase2/phase2_contract_status.json`)
2. Script internally writes to same file (`evidence/phase2/phase2_contract_status.json`)
3. Concurrent writes cause interleaving or overwriting of JSON content
4. No coordination between shell redirection and script file writing

## Contributing Factors
1. Lack of evidence file coordination in workflow design
2. Script writes evidence file while workflow also redirects to same file
3. No atomic file writing mechanism for evidence artifacts
4. Missing verification that evidence files are not corrupted by concurrent writes

## Recovery Loop Failure Analysis
N/A - Proactive identification before deployment prevents recovery loop

## What Unblocked Recovery
Proactive code review identified evidence corruption before deployment

## Corrective Actions Taken
- Files changed: TBD (GitHub workflow and verification script to be corrected)
- Commands run: TBD (workflow execution and evidence integrity tests to be run)

## Prevention Actions
| Action | Owner | Enforcement | Metric | Status | Target Date |
|---|---|---|---|---|
| Evidence coordination review | QA_VERIFIER_AGENT | Mandatory pre-merge | Open | 2026-05-05 |
| Atomic evidence writing | QA_VERIFIER_AGENT | Automated test | Open | 2026-05-05 |
| Workflow evidence audit | QA_VERIFIER_AGENT | CI gate | Open | 2026-05-05 |

## Early Warning Signs
- Shell redirection to files that scripts also write
- Evidence files written by multiple processes simultaneously
- Missing atomic file operations for critical evidence

## Decision Points
- Whether to remove shell redirection and let script handle file writing
- Whether to implement evidence file locking mechanism
- Whether to separate temporary and final evidence files

## Verification Outcomes
- Command: TBD (workflow verification script with evidence integrity tests)
- Result: TBD

## Open Risks / Follow-ups
- Risk of corrupted evidence artifacts masking verification failures
- Need to audit all other workflows for similar issues
- Potential impact on Phase 2 contract verification reliability

## Bottom Line
Critical evidence integrity failure that could produce corrupted verification artifacts, potentially masking real verification failures or producing false positives. Must be fixed to maintain evidence artifact integrity.
