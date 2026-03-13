# GreenTech4CE Tenant and Programme Provisioning Runbook

Status: Implemented (TSK-P1-DEMO-017)
Scope: Phase-1 partner onboarding procedure (operator-run, no self-service UI)

## 1. Purpose
Provide a repeatable, auditable onboarding procedure for tenant and programme provisioning so manual partner configuration is deterministic, reviewable, and verifiable before go-live.

## 2. Preconditions
1. `TSK-P1-DEMO-006` and `TSK-P1-DEMO-011` are completed.
2. Required regulated-surface approval metadata is present for the active change batch.
3. The operator has the tenant identifier, programme identifier, policy binding, and supplier seed data required for onboarding.
4. The environment is in a known-good state and `scripts/dev/pre_ci.sh` passes before provisioning starts.
5. The deployment runtime contract in `docs/operations/SYMPHONY_DEMO_DEPLOYMENT_GUIDE.md` is satisfied, including tenant allowlist and read/admin key configuration.

## 3. Provisioning Steps
1. Run baseline verification before any onboarding action:
   - `scripts/dev/pre_ci.sh`
2. Record required onboarding identifiers:
   - tenant identifier
   - programme identifier
   - target policy version reference
   - operator access mode
   - evidence/report routing target
3. Confirm supplier seed prerequisites before enabling the programme:
   - supplier identity
   - payout target
   - programme allowlist inclusion
   - any required location or routing attributes
4. Apply tenant and programme configuration in this order:
   - tenant context
   - programme context
   - policy binding
   - supplier allowlist data
   - evidence/report routing data
5. Run pre-go-live isolation verification before declaring the programme ready.

## 4. Required Configuration Fields
1. Tenant ID
2. Programme ID
3. Policy/version binding fields
4. Supplier allowlist data per programme
5. Payout target and routing fields for seeded suppliers
6. Evidence routing fields for reporting and export
7. Operator access mode or supervisory access flag where required

## 5. Isolation Verification Before Go-Live
1. Confirm cross-tenant access rejection.
2. Confirm cross-programme supplier denial when allowlists differ.
3. Confirm reveal and reporting surfaces remain scoped by tenant and programme.
4. Confirm exception outputs are tenant and programme bound.
5. Confirm evidence outputs are tenant and programme bound.
6. Confirm the onboarding checklist is complete before partner activation.

## 6. Rollback/Abort
1. Abort onboarding immediately if any isolation or seed prerequisite check fails.
2. Capture failure evidence and open a remediation casefile before retry.
3. Remove or disable incomplete programme configuration before reattempting onboarding.
4. Re-run full verification before any retry or go-live decision.

## 7. Completion Checklist
- [ ] Baseline verification passed before provisioning
- [ ] Provisioning commands executed in required order
- [ ] Mandatory configuration fields populated
- [ ] Supplier seed prerequisites validated
- [ ] Isolation checks passed
- [ ] Evidence artifacts generated and archived
- [ ] Rollback notes reviewed and retained with onboarding record
