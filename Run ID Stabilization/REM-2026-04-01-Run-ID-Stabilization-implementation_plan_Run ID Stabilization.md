# Goal Description

The previous hardcoded `rem-cleanup-v1` ID was an effective but brittle hotfix. To resolve the Run ID mismatch loop in a more robust and architecturally sound manner, we will implement a "Content-Stable" ID mode for remediation.

This uses the current state of the code (the Git tree hash) to derive a deterministic `PRE_CI_RUN_ID`. This ID is stable as long as the source files are unchanged, allowing multiple executions (e.g., manual regeneration and the pre-push hook) to synchronize perfectly.

## User Review Required

> [!IMPORTANT]
> **Security Guardrail**: This content-stable mode is ONLY active when the environment variable `PRE_CI_STABLE=1` is provided. The production default remains random and high-entropy to prevent evidence reuse across different code versions.

## Proposed Changes

### Pipeline Stabilization

#### [MODIFY] [pre_ci.sh](file:///home/mwiza/workspace/Symphony/scripts/dev/pre_ci.sh)
- Replace the hardcoded `fix/bom-cleanup` check with a generic content-stable derivation:
  ```bash
  if [[ "${PRE_CI_STABLE:-0}" == "1" ]]; then
    # Content-addressable ID (stable during remediation sync/push loop)
    PRE_CI_RUN_ID="rem-$(git write-tree | cut -c1-12)"
  else
    PRE_CI_RUN_ID="${PRE_CI_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)_$$}"
  fi
  ```

## Verification Plan

### Automated Tests
1. **Stability Check**: Run `PRE_CI_STABLE=1 scripts/dev/pre_ci.sh` twice and confirm the `PRE_CI_RUN_ID` is identical.
2. **Schema Verification**: Ensure evidence signed with this hash-based ID passes audit gates.

### Manual Verification
- **Push**: Run `PRE_CI_STABLE=1 git push`.
