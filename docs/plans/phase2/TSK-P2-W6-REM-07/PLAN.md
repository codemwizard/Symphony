# TSK-P2-W6-REM-07: Verifier Connection Hardening

## Objective
Remediate Wave 6 implementation gap (GAP-W6-009) where verification scripts use an anti-pattern.

## Implementation Steps
- [ ] Update all `verify_*.sh` scripts for Wave 6 to replace bare `psql -c` calls with `psql "$DATABASE_URL" -c`.

## Verification
- [ ] Run `scripts/dev/pre_ci.sh` to ensure all tests still pass and can connect correctly.

> [!IMPORTANT]
> **Sequencing Directive:** This task MUST be executed *before* or *in parallel with* `TSK-P2-W6-REM-06` (API/DB Parity Verifier). This ensures that any new verification scripts written in REM-06 do not inherit the `psql -c` anti-pattern and are hardened by default.
