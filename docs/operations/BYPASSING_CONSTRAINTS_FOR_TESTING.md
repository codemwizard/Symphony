# Bypassing PostgreSQL Constraints for Isolation Testing

This document outlines the canonical method for bypassing Foreign Key (FK) constraints and system triggers in PostgreSQL to perform isolated behavioral testing of specific components.

## The Technique: `session_replication_role`

PostgreSQL provides a session-level configuration called `session_replication_role`. Setting this to `replica` suppresses the firing of "normal" triggers and Foreign Key constraint checks.

### Standard Usage (Within a Transaction)

```sql
BEGIN;

-- 1. Explicitly enable the trigger you want to test
-- (Triggers with the default ENABLE status are disabled in replica mode)
ALTER TABLE your_table ENABLE ALWAYS TRIGGER your_specific_trigger;

-- 2. Set the session to replica mode to bypass FKs and other triggers
SET session_replication_role = replica;

-- 3. Perform your test insert/update with dummy FK values
INSERT INTO your_table (id, some_fk_id, ...) VALUES (1, '00000000-0000-0000-0000-000000000000', ...);

-- 4. Revert state if necessary (or just let the transaction rollback/end)
SET session_replication_role = DEFAULT;

ROLLBACK;
```

## Why use this?

1.  **Isolation:** When testing a specific `BEFORE` or `AFTER` trigger (like an attestation gate), you want to prove the logic of *that specific trigger* without needing to mock an entire 10-table dependency tree.
2.  **Mocking:** Allows the use of "Empty UUIDs" or dummy values for FKs when the underlying parent tables (e.g., `tenants`, `projects`) are not seeded in the local environment.
3.  **Performance:** Significantly reduces the overhead of complex schema validation during targeted behavioral unit tests.

## Critical Constraints

> [!WARNING]
> **NOT NULL Constraints Still Apply:** `session_replication_role` does **not** bypass column-level `NOT NULL` constraints. You must provide a value for all non-nullable columns in your `INSERT` statement.

> [!IMPORTANT]
> **Trigger Mode:** Only triggers marked `ENABLE ALWAYS` or `ENABLE REPLICA` will fire when the session is in `replica` mode. If you are testing a standard trigger, you **must** use `ALTER TABLE ... ENABLE ALWAYS TRIGGER` before setting the role.

## Approval Metadata
- **Status**: Canonical Reference
- **Scope**: Internal Engineering / CI Verification
- **Governed By**: DB_FOUNDATION
