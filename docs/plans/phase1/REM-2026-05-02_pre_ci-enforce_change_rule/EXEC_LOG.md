# EXEC LOG

- **Action:** Ran `preflight_structural_staged.sh` to determine the exact failure (`PRECI.STRUCTURAL.CHANGE_RULE`).
- **Root Cause:** Migrations `0095`, `0199`, `0201`, `0202` modified DDL structurally without appending to `THREAT_MODEL.md` or `COMPLIANCE_MAP.md`.
- **Fix Applied:** Appended 2026-05-02 timestamped notes to `THREAT_MODEL.md` and `COMPLIANCE_MAP.md` covering the `execution_records` constraints and `rls_dual_policy` restoration.
- **Verification:** Ran `scripts/dev/pre_ci.sh` to confirm structural rule parity.
