# Phase-1 Security And Git Containment Remediation

## Purpose

Convert the 2026-03-09 parity-fixture containment incident and Tier-1 security audit into executable task packs.

## Canonical Sources

- `docs/operations/AI_AGENT_OPERATION_MANUAL.md`
- `docs/security/TIER_1_FINANCIAL_SECURITY_AUDIT_2026-03-09.md`
- `docs/audits/FORENSIC_REPORT_DIFF_PARITY_FIXTURE_2026-03-09.md`

## Ordered Task Chain

### Git Containment Program

1. `TSK-P1-061`
   Codify repo-wide Git containment rule and inventory mutable Git fixtures.

2. `TSK-P1-062`
   Clean up retained contaminated worktrees and fail closed on stale/prunable worktree state.

3. `TSK-P1-063`
   Audit and harden other mutable Git scripts against inherited Git plumbing.

4. `TSK-P1-064`
   Wire hostile-environment Git containment regression tests into local and CI guardrails.

### Tier-1 Security Audit Remediation

5. `TSK-P1-065`
   Remove hardcoded self-test secrets from production-path code surfaces.

6. `TSK-P1-066`
   Enforce bounded amount validation on ingress commands.

7. `TSK-P1-067`
   Sanitize database persistence failures before client exposure.

8. `TSK-P1-068`
   Add endpoint-specific rate limiting for sensitive/admin surfaces.

## Execution Notes

- `TSK-P1-061..064` are containment and governance work. They should run before additional hook-heavy or Git-mutating automation changes.
- `TSK-P1-065..068` are application-security remediations derived directly from the Tier-1 audit.
- None of these tasks authorize new runtime DDL in production paths.

5. `TSK-P1-073`
   Fail closed when guarded execution surface fixes land without remediation or task artifact freshness.
