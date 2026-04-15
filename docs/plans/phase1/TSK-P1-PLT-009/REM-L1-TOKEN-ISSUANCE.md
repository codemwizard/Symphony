# REM-L1-PLT-TOKEN-ISSUANCE (DRD Lite)

## 1. Incident Overview
- **Incident ID**: REM-L1-PLT-TOKEN-ISSUANCE
- **Severity**: L1 (Minor Functional Regression)
- **Status**: OPEN
- **Affected Surface**: Symphony Pilot - Token Issuance
- **Root Cause**: Premature closure of TSK-P1-PLT-006; functional gap in dynamic worker/programme state alignment.

## 2. Triage & Discovery
- **Observation**: Newly registered workers (from the Onboarding tab) do not appear in the Token Issuance dropdown.
- **Investigation**: The `token-issuance.html` file contains hardcoded `worker-chunga-001` placeholders instead of fetching from the database-backed lookup API.
- **Impact**: Demo operators cannot issue tokens to real-world pilot participants without manual database intervention.

## 3. Remediation Plan (Targeted)
- **A) Dependency Injection**: Replace static HTML options with a dynamic fetch to `/pilot-demo/api/workers/lookup`.
- **B) Cascading Alignment**: Update the backend issuance handler to return `sequence_number` to ensure UI/Ledger parity.
- **C) Verification**: Run E2E smoke tests to confirm a registered worker can receive a simulate issuance with an authoritative sequence ID.

## 4. Prevention
- **Constraint**: Future pilot UI tasks must be verified against current database state (seeding) to prevent "disconnected" mockups.

## 5. Metadata
- **Owner**: ARCHITECT
- **Reference**: TSK-P1-PLT-009
