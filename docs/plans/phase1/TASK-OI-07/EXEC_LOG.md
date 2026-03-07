# EXEC_LOG

- Wired SEC-G08 gate into CI workflow:
  - Added required step in `.github/workflows/invariants.yml`: `Run SEC-G08 dependency audit gate (required)`.
- Added deterministic failure simulation in dependency audit script for mechanical fail-closed verification.
- Verification run:
  - `rg -n "dotnet_dependency_audit|dep-audit" .github/workflows/*.yml` -> PASS.
  - `! bash scripts/security/dotnet_dependency_audit.sh --test-fail` -> PASS (script exits non-zero as expected).
