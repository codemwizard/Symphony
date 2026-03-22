# GreenTech4CE Tenant and Programme Provisioning Runbook

Status: reconciled with hardened onboarding control-plane architecture
Scope: Phase-1 partner onboarding procedure using server-side onboarding APIs and persisted control-plane state

## 1. Purpose
Provide a repeatable, auditable onboarding procedure for tenant and programme provisioning so manual partner configuration is deterministic, reviewable, and verifiable before go-live.

This runbook is a provisioning component inside:
- `docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md`

All provisioning now uses the server-side onboarding APIs backed by persisted control-plane state (TSK-P1-217/218). Environment-variable-based provisioning is no longer the supported path.

## 2. Provisioning Entry Point Contract
### Tenant onboarding
- `POST /api/admin/onboarding/tenants`

Authorization:
- header: `x-admin-api-key`

Request contract:
- `tenant_id`
- `display_name`
- `jurisdiction_code`
- `plan`

Idempotency posture:
- deterministic create-or-return behavior keyed as `tenant_onboarding:<tenant_id>`

Expected response:
- `200 OK`
- body contains:
  - `tenant_id`
  - `created_at`

### Programme onboarding
- `POST /api/admin/onboarding/programmes`

Authorization:
- header: `x-admin-api-key`

Request contract:
- `programme_id`
- `tenant_id`
- `display_name`
- `policy_version` (optional at creation; bind separately)

Expected response:
- `200 OK` or `201 Created`
- body contains:
  - `programme_id`
  - `tenant_id`
  - `status`

### Programme activation
- `PUT /api/admin/onboarding/programmes/{id}/activate`

### Policy binding
- `POST /api/admin/onboarding/programmes/{id}/policy-binding`

### Onboarding status readback
- `GET /api/admin/onboarding/status`

Returns the full persisted onboarding state for verification.

Verification reference:
- `bash scripts/audit/verify_ten_003_tenant_onboarding_admin.sh`
- evidence: `evidence/phase1/ten_003_tenant_onboarding_admin.json`

### Non-repo-backed external prerequisites
The following must still be explicitly confirmed by the operator because this branch does not provide a single repo-backed command that applies them end-to-end:
- supplier allowlist data
- evidence/report routing data

For signoff posture, these must be satisfied and recorded before the run is declared ready.

## 3. Required Inputs
1. Tenant ID
2. Tenant display name
3. Jurisdiction code
4. Plan
5. Programme ID
6. Policy/version binding reference
7. Supplier allowlist data per programme
8. Payout target and routing fields for seeded suppliers
9. Evidence/report routing target
10. Operator access mode or supervisory access flag where required

## 4. Provisioning Procedure (UI Guided Workflow)

The onboarding flow is strictly sequenced in the Operator Onboarding Console:

### Step 1 — Register Tenant
- **Form:** "Register New Tenant"
- **Action:** Enter Tenant UUID (or leave blank to auto-generate), Tenant Key, and Display Name.
- **Pass condition:** Submitting returns success; Tenant populates in the registry table and dropdowns.

### Step 2 — Create Programme
- **Form:** "Create Programme"
- **Prerequisite:** A Tenant **must** be selected from the `Select Tenant...` dropdown to enable the "Create Programme" button.
- **Action:** Select Tenant, enter Programme Key and Display Name.
- **Pass condition:** Submitting returns success; Programme appears in the registry table and unlocks the Policy dropdowns.

### Step 3 — Register Supplier
- **Form:** "Register Supplier"
- **Prerequisite:** A Tenant **must** be selected to enable the "Register Supplier" button.
- **Action:** Enter Supplier ID (optional), Supplier Name, and Payout Target (e.g., MSISDN).

### Step 4 — Bind Policy and Activate
- **Form:** "Bind Policy to Programme"
- **Prerequisite:** A Programme **must** be selected to enable "Bind Policy" and "Activate" buttons.
- **Action 1:** Select Programme, enter Policy Code (e.g. `green_eq_v1`), click "Bind Policy".
- **Action 2:** Once bound, click "Activate" (the UI automatically routes the correct `tenant_id` payload).

### Step 5 — Confirm external provisioning prerequisites
Confirm, in this order:
1. supplier allowlist data
2. evidence/report routing data

Pass condition:
- all items are explicitly confirmed for the demo run

Fail condition:
- any item is missing, unknown, or assumed implicitly

Operator action:
- stop signoff runs; rehearsal-only runs must remain labeled non-signoff if these prerequisites are incomplete

Evidence emitted:
- provisioning status recorded in `run_summary.json`

### Step 6 — Verify onboarding state
- `GET /api/admin/onboarding/status`

Pass condition:
- readback shows tenant, programme, policy binding, and activation state as expected

### Step 7 — Run isolation verification before go-live
Checks:
1. confirm cross-tenant access rejection
2. confirm cross-programme supplier denial when allowlists differ
3. confirm reveal and reporting surfaces remain tenant/programme scoped
4. confirm exception outputs remain tenant/programme bound
5. confirm evidence outputs remain tenant/programme bound

Pass condition:
- all required isolation checks pass

Fail condition:
- any isolation check fails or is skipped without explicit waiver

Operator action:
- abort provisioning and open remediation before retry

Evidence emitted:
- isolation verification outcome in run-summary provisioning section

## 5. Retry and Failure Rules
- tenant onboarding is idempotent by `tenant_id`
- failed onboarding must not be retried blindly without reviewing the prior response/logs
- incomplete external supplier/routing state must not be silently reused as if complete

## 6. Rollback / Abort
1. Abort onboarding immediately if any isolation or seed prerequisite check fails.
2. Capture failure evidence and open a remediation casefile before retry.
3. Remove or disable incomplete programme configuration before reattempting onboarding.
4. Re-run verification before any retry or signoff decision.

## 7. Teardown / Retention
Retain:
- onboarding response captured in the run bundle
- pilot onboarding readiness evidence
- remediation notes for any failed provisioning attempt

Do not retain in the run bundle:
- raw admin secret values

Reuse vs recreate:
- intentional tenant reuse is allowed only when the operator explicitly chooses it
- accidental reuse of stale partial programme state is not allowed

## 8. Completion Checklist
- [ ] Required inputs recorded
- [ ] Tenant onboarding endpoint executed successfully or idempotently confirmed
- [ ] Programme onboarding endpoint executed successfully
- [ ] Policy binding applied
- [ ] Programme activated
- [ ] Onboarding status readback verified
- [ ] Supplier allowlist confirmed
- [ ] Evidence/report routing confirmed
- [ ] Isolation verification passed
- [ ] Failure/rollback notes captured when needed
