# Hard Constraints (must not break)

- Forward-only migrations; never edit applied migrations.
- No runtime DDL.
- SECURITY DEFINER functions must harden: `SET search_path = pg_catalog, public`.
- Runtime roles are NOLOGIN templates; app uses SET ROLE.
- Outbox attempts remain append-only; do not weaken lease fencing.
- If uncertain: fail closed and use an exception file (timeboxed) rather than inventing enforcement.
