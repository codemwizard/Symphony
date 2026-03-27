# RLS Trust Boundaries — What This System Does Not Protect Against

**Task:** TSK-RLS-ARCH-001  
**Version:** v10.1

---

## What IS Protected

| Layer | Protection | Mechanism |
|-------|-----------|-----------|
| Row Visibility | Tenant A cannot read Tenant B rows | RESTRICTIVE policy with `current_tenant_id_or_null()` |
| Row Mutation | Tenant A cannot write into Tenant B rows | WITH CHECK on same expression |
| NULL GUC | No GUC set → 0 rows (fail-closed) | `current_tenant_id_or_null()` returns NULL → no match |
| FK JOIN | Child rows isolated via parent's tenant | EXISTS subquery in JOIN policy |
| Admin Access | Read-only admin functions | `SECURITY DEFINER` owned by `symphony_reader` (BYPASSRLS) |

## What IS NOT Protected (Observable Risks)

> [!CAUTION]
> These are **known limitations**, not bugs. They require application-layer discipline.

### 1. GUC Spoofing (SET LOCAL by Database Role)

**Risk:** Any role with `SET` privilege can call `SET LOCAL app.current_tenant_id = 'any-uuid'`.

**Mitigation:** Application uses `set_tenant_context()` wrapper. No application code should use `SET LOCAL` directly. CI lint enforces this.

**Why not structurally prevented:** PostgreSQL GUC settings are session-level. There is no mechanism to restrict `SET` to specific functions. This is a PostgreSQL design constraint.

### 2. BYPASSRLS Roles

**Risk:** Roles with `BYPASSRLS` see all rows regardless of policies.

**Mitigation:** Only `symphony_reader` has `BYPASSRLS`. `symphony_reader` is used only by `SECURITY DEFINER` admin functions. CI audit verifies the grant whitelist.

**Why not structurally prevented:** `BYPASSRLS` is a PostgreSQL role attribute. Admin access requires it by design.

### 3. Connection Pool Contamination

**Risk:** If a connection is returned to the pool with a stale GUC, the next request operates under the wrong tenant.

**Mitigation:** Application must `RESET app.current_tenant_id` or call `set_tenant_context()` at request start. Framework middleware is expected to handle this.

**Why not structurally prevented:** Connection pooling is an application-layer concern. PostgreSQL GUC state is per-session, not per-transaction.

### 4. Superuser and Owner Access

**Risk:** Database superuser (`postgres`) and table owners may bypass RLS.

**Mitigation:** Production roles are not superuser. Table ownership is assigned to migration-only roles. `FORCE ROW LEVEL SECURITY` applies RLS even to table owners.

### 5. Bulk Export / pg_dump

**Risk:** `pg_dump` runs as superuser, exporting all rows regardless of RLS.

**Mitigation:** This is expected behavior. Backup operations are infrastructure-level, not application-level. Backup encryption and access controls are separate concerns.

---

## Invariant: GUC Is Not a Structural Guarantee

The dual-policy model provides **fail-closed structural behavior** (NULL GUC → 0 rows). But the *correctness* of the GUC value is an application discipline contract, not a database enforcement.

This is acknowledged, not hidden.
