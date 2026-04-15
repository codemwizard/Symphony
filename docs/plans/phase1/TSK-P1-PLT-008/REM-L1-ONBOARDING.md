# DRD Lite

## Metadata
- Template Type: Lite
- Incident Class: UI-API Data Contract Mismatch
- Severity: L1
- Status: Open
- Owner: ARCHITECT
- Date: 2026-04-12
- Task: TSK-P1-PLT-008
- Branch: N/A

## Summary
The Pilot UI's onboarding components fail to successfully execute `fetch(...)` sequence APIs because the interface attempts to map properties using mock CamelCase keys instead of the `.NET Minimal API` strictly typed snake_case dictionary output. Furthermore, missing `.tenant_id` fields block the Programme and Worker API payloads.

## First Failing Signal
- Artifact/log path: `/api/admin/onboarding/programmes`
- Error signature: `HTTP 400 Bad Request`

## Impact
- What was blocked: The ability to onboard testing Tenants, Programmes, and Workers directly from the Pilot UI.
- Delay: Several iterations post verification parity blocks.
- Attempts before record: 1

## Diagnostic Trail
- Command(s): `scripts/audit/verify_pilot_integration.sh`
- Result(s): The 401s passed because the session cookies were injected. However, actual payload submittals return 400 Bad Request since they lack the correct required parameters.

## Root Cause
- Confirmed or suspected: `onboarding.html` was extracting parameter IDs with literal references to `.key` or `.id` instead of `.tenant_id` and `.programme_id`.

## Fix Applied
- Files changed: `src/symphony-pilot/onboarding.html`
- Why it should work: Re-synchronizing the DOM element values with the verified backend API requirement guarantees deterministic data transmission.

## Verification Outcomes
- Command(s): `bash scripts/audit/verify_tsk_p1_plt_008.sh`
- PASS/FAIL: TBD

## Escalation Trigger
- Escalate to Full if: The payloads require complex `.NET API` modifications beyond frontend remapping.
