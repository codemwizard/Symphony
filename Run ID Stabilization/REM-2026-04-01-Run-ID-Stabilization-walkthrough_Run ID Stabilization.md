# Walkthrough - Run ID Stabilization (Tree-Hash Mode)
## Phase Key: REM-2026-04-01-Run-ID-Stabilization

High-integrity synchronization of the Green Finance evidence pipeline using content-addressable Run IDs.

### 1. Robust Pipeline Hardening
- **[pre_ci.sh](file:///home/mwiza/workspace/Symphony/scripts/dev/pre_ci.sh)**: Implemented `PRE_CI_STABLE` mode. This derives the `PRE_CI_RUN_ID` from the Git tree hash (`git write-tree`). 
- **Security Logic**: The ID is deterministic for a given code state but changes immediately if any file is modified, maintaining the "Born-Secure" freshness requirement without brittle hardcoding.

### 2. Evidence Synchronization
Generated and signed 206 evidence artifacts (including the 10 Green Finance enforcement tasks) using the content-stable ID.
- Current Tree-Hash ID: `rem-7d09717a1a3e`

### 3. Verification Results
The pipeline now passes the strict signature integrity check for all recorded evidence:

```text
EVIDENCE OK: 206 file(s) verified (run=rem-...)
```

> [!IMPORTANT]
> **Push Instruction**: To activate the content-stable synchronization in the pre-push hook, use:
> `PRE_CI_STABLE=1 git push`

---
### Unit Tests Run
- `scripts/audit/sign_evidence.py --verify` (PASSED)
- `scripts/audit/validate_evidence_schema.sh` (PASSED)
