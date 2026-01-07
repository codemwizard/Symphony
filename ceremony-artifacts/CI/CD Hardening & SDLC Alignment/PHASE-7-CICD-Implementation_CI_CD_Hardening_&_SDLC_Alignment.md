# CI/CD Hardening & SDLC Alignment (PHASE-7-CICD)

This plan addresses identified gaps in the Symphony CI/CD pipeline to ensure compliance with the `secure-sdlc-procedure.md` and readiness for the Phase-7 unlock.

## User Review Required

> [!IMPORTANT]
> **Snyk Integration**: This plan adds a Snyk scan step. It assumes a `SNYK_TOKEN` will be provided in GitHub Secrets. If not present, this step will be configured to fail-safe (warn but not block) until configured.
>
> **CodeQL**: Enabling CodeQL will increase CI run time by ~3-5 minutes.

## Proposed Changes

### CI/CD Pipeline
Summary: Hardening the security gates and expanding the GitHub Actions workflow to include mandated SDLC tools.

---

#### [MODIFY] [security-gates.ts](file:///wsl.localhost/Ubuntu/home/mwiza/workspaces/Symphony/scripts/ci/security-gates.ts)
- Exclude the definition file `dev-key-manager.ts` from the `DevelopmentKeyManager` usage check to prevent false positives.

#### [MODIFY] [ci-security.yml](file:///wsl.localhost/Ubuntu/home/mwiza/workspaces/Symphony/.github/workflows/ci-security.yml)
- Add CodeQL Analysis workflow step.
- Add Snyk Security Scan step.
- Integrate existing verification scripts (`verify_mtls.js`, `verify_audit_integrity.js`, etc.) into a "Compliance Verification" job.

#### [MODIFY] [package.json](file:///wsl.localhost/Ubuntu/home/mwiza/workspaces/Symphony/package.json)
- Update `ci:full` or add a new script to run the expanded set of verification tools.

## Verification Plan

### Automated Tests
- `npm run security-check`: Verify it now passes without false positives.
- `npm run ci:full`: Verify all 12+ verification scripts execute correctly.

### Manual Verification
- Review the updated `.github/workflows/ci-security.yml` structure for logic errors.
- Validate that the `PHASE` environment variable is correctly respected in the new CI steps.
