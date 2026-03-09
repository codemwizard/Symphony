# Sprint 1 Rollback And Exception Policy

## Code rollback
- Revert by new commit on the feature branch.
- Do not rewrite or drop applied migrations.

## Schema rollback
- Fix forward only through new migrations.
- If a migration assumption fails, stop and record a remediation trace casefile.

## CI/gate rollback
- Any gate relaxation requires documented exception metadata, expiry, owner, and compensating control.
- Security and invariant gates remain fail-closed by default.
