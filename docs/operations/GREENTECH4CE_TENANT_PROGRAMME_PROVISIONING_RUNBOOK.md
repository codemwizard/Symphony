# GreenTech4CE Tenant and Programme Provisioning Runbook

Status: reconciled with host-based E2E operator flow
Scope: Phase-1 partner onboarding procedure inside the host-based demo execution path

## 1. Purpose
Provide a repeatable, auditable onboarding procedure for tenant and programme provisioning so manual partner configuration is deterministic, reviewable, and verifiable before go-live.

This runbook is no longer framed as an independent `pre_ci.sh`-gated workflow. It is now a provisioning component inside:
- `docs/operations/SYMPHONY_DEMO_E2E_RUNBOOK.md`

## 2. Provisioning Entry Point Contract
### Repo-backed executable entrypoint
- `POST /v1/admin/tenants`

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

Verification reference:
- `bash scripts/audit/verify_ten_003_tenant_onboarding_admin.sh`
- evidence: `evidence/phase1/ten_003_tenant_onboarding_admin.json`

### Non-repo-backed external prerequisites on this branch
The following must still be explicitly confirmed by the operator because this branch does not provide a single repo-backed command that applies them end-to-end:
- programme context
- policy binding
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

## 4. Provisioning Procedure
### Step 1 — Confirm operator inputs
Pass condition:
- all required inputs are recorded

Fail condition:
- any required field is missing

Operator action:
- stop provisioning; do not infer missing values

Evidence emitted:
- operator notes or run-summary provisioning section

### Step 2 — Execute tenant onboarding entrypoint
Use the repo-backed admin endpoint:
- `POST /v1/admin/tenants`

Pass condition:
- endpoint returns `200`
- response contains `tenant_id` and `created_at`

Fail condition:
- endpoint rejects request or returns malformed response

Operator action:
- stop; inspect tenant onboarding response and server logs

Evidence emitted:
- onboarding response captured in the run bundle
- `evidence/phase1/ten_003_tenant_onboarding_admin.json` as contract proof

### Step 3 — Confirm external provisioning prerequisites
Confirm, in this order:
1. programme context
2. policy binding
3. supplier allowlist data
4. evidence/report routing data

Pass condition:
- all four are explicitly confirmed for the demo run

Fail condition:
- any item is missing, unknown, or assumed implicitly

Operator action:
- stop signoff runs; rehearsal-only runs must remain labeled non-signoff if these prerequisites are incomplete

Evidence emitted:
- provisioning status recorded in `run_summary.json`

### Step 4 — Run isolation verification before go-live
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
- incomplete external programme/policy/supplier/routing state must not be silently reused as if complete

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
- [ ] Programme context confirmed
- [ ] Policy binding confirmed
- [ ] Supplier allowlist confirmed
- [ ] Evidence/report routing confirmed
- [ ] Isolation verification passed
- [ ] Failure/rollback notes captured when needed
