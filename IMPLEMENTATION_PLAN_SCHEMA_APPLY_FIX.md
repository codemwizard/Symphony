# Implementation Plan: Fix Schema Apply Failure (RETURN NEXT OUT params)

## Objective
Resolve the schema apply failure in `schema/v1/011_payment_outbox.sql` so the migration can run to completion and update the DB functions reliably.

## Scope
- Fix the invalid `RETURN NEXT (..)` usage in `repair_expired_leases`.
- Reapply the schema file successfully.
- Verify the corrected function bodies are installed in the database.

## Non-goals
- Redesigning the outbox schema or changing business logic beyond the required fix.
- Modifying unrelated migrations or CI workflows.

---

## 1) Fix the invalid RETURN NEXT usage

### File
- `schema/v1/011_payment_outbox.sql`

### Issue Addressed
- `RETURN NEXT (v_record.outbox_id, v_next_attempt_no);` is invalid when a function has OUT parameters.

### Task 1.1 — Update RETURN NEXT syntax
- Replace:
  - `RETURN NEXT (v_record.outbox_id, v_next_attempt_no);`
- With:
  - `outbox_id := v_record.outbox_id;`
  - `attempt_no := v_next_attempt_no;`
  - `RETURN NEXT;`

### Definition of Done
- `rg -n "RETURN NEXT" schema/v1/011_payment_outbox.sql` no longer shows tuple-form usage.

---

## 2) Reapply the schema file cleanly

### Command
```bash
PGPASSWORD=dockTLK520 psql -h localhost -p 5432 -U symphony_admin -d symphony \
  -v ON_ERROR_STOP=1 -f schema/v1/011_payment_outbox.sql
```

### Definition of Done
- `psql` output ends with `COMMIT` and no ERROR.

---

## 3) Verify updated function bodies in DB

### Checks
```bash
PGPASSWORD=dockTLK520 psql -h localhost -p 5432 -U symphony_admin -d symphony -c \
"SELECT pg_get_functiondef('enqueue_payment_outbox(text,text,text,text,jsonb)'::regprocedure);"
```

```bash
PGPASSWORD=dockTLK520 psql -h localhost -p 5432 -U symphony_admin -d symphony -c \
"SELECT pg_get_functiondef('repair_expired_leases(int,text)'::regprocedure);"
```

### Definition of Done
- `enqueue_payment_outbox` shows the single‑arg `pg_advisory_xact_lock(...)` form.
- `repair_expired_leases` shows `outbox_id := ...; attempt_no := ...; RETURN NEXT;`.

---

## Open Questions / Decisions Needed
- Confirm whether to reapply only `011_payment_outbox.sql` or re-run the full schema sequence.
