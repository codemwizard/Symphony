# Implementation Plan: TSK-P1-DEMO-031

## Goal
Bridge functional gaps in the Symphony Pilot Demo UI to achieve parity with the official video script.

## Proposed Changes
- Implement Worker Token issuance UI in the supervisory dashboard.
- Create a slide-out panel for instruction drill-down.
- Add a programme reactivation toggle in the onboarding console.
- Update demo seeding to use Chunga Dumpsite and the `pwrm_001` policy.
- Implement a dynamic timeline refresh loop using the monitoring report API.
- Grant necessary database privileges to the application role.
- Add required proof types (`INVENTORY_RECEIPT`, `WAYBILL_IMAGE`) to the C# backend.

## Verification Plan
### Automated Tests
- Run `bash scripts/audit/verify_tsk_p1_demo_031.sh` to generate the evidence artifact.
- Ensure the pre-CI pipeline passes including the task meta schema checks.

### Manual Verification
- Execute the "Seed Demo Tenant" flow and verify Chunga Dumpsite creation.
- Generate a worker link and verify its functionality.
- Verify the timeline updates dynamically upon submission.
