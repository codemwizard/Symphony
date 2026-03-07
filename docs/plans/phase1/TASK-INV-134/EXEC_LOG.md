# EXEC_LOG

- Updated `scripts/security/dotnet_dependency_audit.sh` to emit Phase-1 mirror evidence at `evidence/phase1/dep_audit_gate.json`.
- Added deterministic verifier modes: `--dry-run` (pass evidence emission) and `--test-fail` (fail-closed simulation).
- Added INV-134 declaration in `docs/invariants/INVARIANTS_MANIFEST.yml` and ID registry entry in `docs/invariants/id-management/INVARIANT_ID_MANAGEMENT.md`.
- Verification run:
  - `bash scripts/security/dotnet_dependency_audit.sh --dry-run` -> PASS.
  - `test -f evidence/phase1/dep_audit_gate.json` -> PASS.
