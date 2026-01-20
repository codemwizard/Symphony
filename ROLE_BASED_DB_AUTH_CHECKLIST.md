# Role-Based DB Auth Checklist

## Purpose
Practical checklist for role-scoped database access with pooled connections, aligned with least privilege and no-leakage principles.

## Design Rules
- Use explicit `DbRole` on every DB call (no implicit/global role).
- `queryAsRole()` is single-statement only.
- Any 2+ query workflow uses `transactionAsRole()`.
- RoleBoundClient exposes only `query(text, params?)` (no `release()`, `setRole()`, or raw client access).
- `SET ROLE`/`RESET ROLE` must happen in `try/finally`.
- `SET LOCAL ROLE` must be used inside transactions.

## Pool Safety (Taint Prevention)
- Always `RESET ROLE` before releasing the client, even on error.
- Reset must run even if `SET ROLE` fails or query throws.
- Never keep per-request state on the client beyond the scoped call.

## Call-Site Rules
- Raw role strings only at service boundary; map/validate once via `assertDbRole`.
- Anonymous/unauthenticated paths must map to `symphony_readonly`.
- No direct `db.query`, `db.setRole`, `db.executeTransaction`, or `currentRole` usage.

## Guardrails
- CI grep (Phase A): forbid `setRole(`, `currentRole`, `executeTransaction(`.
- CI grep (Phase B): forbid `db.query(` after migration completes.
- Evidence scan output:
  ```bash
  mkdir -p reports
  rg "db\\.query\\(|db\\.setRole\\(|setRole\\(|currentRole|executeTransaction\\(" -n . > reports/role-usage-scan.txt
  ```

## Tests
- Role isolation test: concurrent `queryAsRole` with different roles must not leak.
- Residue test (success): reused pooled client starts clean.
- Residue test (failure): failing query still resets role before release.

## Evidence Artifacts
- `reports/role-usage-scan.txt`
- CI logs (lint/build/test)
- Test output for role isolation/residue
- Diff of `libs/db/index.ts` API surface

## References
- Least privilege: ISO 27001 A.9, PCI DSS Req 7/8, SOC 2 CC6.1/CC6.3.
- Change monitoring: SOC 2 CC7.2, ISO 27001 A.12.
- Access control testing: OWASP ASVS V4.
