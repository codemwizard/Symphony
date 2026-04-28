# PLAN: GF-W1-SCH-008 — verifier_registry (migration 0085)

Status: planned
Phase: 0
Task: GF-W1-SCH-008
Author: <UNASSIGNED>

---

## Objective

Create `verifier_registry` and `verifier_project_assignments` tables, and
`check_reg26_separation()` DB function. This is the compliance infrastructure
for both Symphony revenue models — Model A (project developers) and Model B
(verifiers). The Regulation 26 constraint must be enforced at the DB layer.

---

## Step 1 — Confirm prerequisites

- [ ] GF-W1-SCH-007 evidence exists and passes (regulatory plane deployed)
- [ ] Migration 0084 applied (FNC-005 functions exist — verifier_registry
      references projects table which exists by this point)
- [ ] MIGRATION_HEAD = 0084

---

## Step 2 — Write migration SQL

File: `schema/migrations/0085_gf_verifier_registry.sql`

```sql
-- symphony:migration
-- id: 0085
-- description: verifier_registry and verifier_project_assignments — SI Regulation 23 + Regulation 26
-- phase: 0
-- volatility_class: POLICY_TABLE

BEGIN;

-- Table 1: verifier_registry
CREATE TABLE IF NOT EXISTS public.verifier_registry (
  verifier_id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id                 UUID        NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  jurisdiction_code         TEXT        NOT NULL,
  verifier_name             TEXT        NOT NULL,
  role_type                 TEXT        NOT NULL CHECK (role_type IN ('VALIDATOR','VERIFIER','VALIDATOR_VERIFIER')),
  accreditation_reference   TEXT        NOT NULL,
  accreditation_authority   TEXT        NOT NULL,
  accreditation_expiry      DATE        NOT NULL,
  methodology_scope         JSONB       NOT NULL DEFAULT '[]'::jsonb,
  jurisdiction_scope        JSONB       NOT NULL DEFAULT '[]'::jsonb,
  is_active                 BOOLEAN     NOT NULL DEFAULT false,
  deactivated_at            TIMESTAMPTZ NULL,
  deactivation_reason       TEXT        NULL,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by                TEXT        NOT NULL DEFAULT CURRENT_USER,
  CONSTRAINT verifier_deactivation_consistency CHECK (
    (is_active = true  AND deactivated_at IS NULL  AND deactivation_reason IS NULL) OR
    (is_active = false AND deactivated_at IS NOT NULL AND deactivation_reason IS NOT NULL)
  )
);

-- Table 2: verifier_project_assignments
-- Authoritative record of who is assigned in what role for which project.
-- check_reg26_separation queries THIS table, not token history.
CREATE TABLE IF NOT EXISTS public.verifier_project_assignments (
  assignment_id   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  verifier_id     UUID        NOT NULL REFERENCES public.verifier_registry(verifier_id) ON DELETE RESTRICT,
  project_id      UUID        NOT NULL REFERENCES public.projects(project_id) ON DELETE RESTRICT,
  assigned_role   TEXT        NOT NULL CHECK (assigned_role IN ('VALIDATOR','VERIFIER')),
  assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  assigned_by     TEXT        NOT NULL DEFAULT CURRENT_USER,
  CONSTRAINT verifier_project_role_unique UNIQUE (verifier_id, project_id, assigned_role)
);

-- Append-only triggers on both tables
CREATE OR REPLACE FUNCTION public.gf_verifier_tables_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP IN ('UPDATE','DELETE') THEN
    RAISE EXCEPTION 'Table % is append-only', TG_TABLE_NAME
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER verifier_registry_no_mutate
  BEFORE UPDATE OR DELETE ON public.verifier_registry
  FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();

CREATE TRIGGER verifier_project_assignments_no_mutate
  BEFORE UPDATE OR DELETE ON public.verifier_project_assignments
  FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tables_append_only();

-- Regulation 26 enforcement function
-- Called by issue_verifier_read_token before any token is issued.
-- Raises GF001 if validator attempts verifier role on same project.
CREATE OR REPLACE FUNCTION public.check_reg26_separation(
  p_verifier_id   UUID,
  p_project_id    UUID,
  p_requested_role TEXT
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_requested_role = 'VERIFIER' THEN
    IF EXISTS (
      SELECT 1 FROM public.verifier_project_assignments
      WHERE verifier_id   = p_verifier_id
        AND project_id    = p_project_id
        AND assigned_role = 'VALIDATOR'
    ) THEN
      RAISE EXCEPTION
        'Regulation 26 violation: validator cannot verify the same project (verifier_id=%, project_id=%)',
        p_verifier_id, p_project_id
        USING ERRCODE = 'GF001';
    END IF;
  END IF;
END;
$$;

-- RLS
ALTER TABLE public.verifier_registry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verifier_project_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY verifier_registry_tenant_isolation
  ON public.verifier_registry USING (
    tenant_id = current_setting('app.current_tenant_id', true)::uuid
  );

CREATE POLICY verifier_assignments_project_scope
  ON public.verifier_project_assignments USING (
    verifier_id IN (
      SELECT verifier_id FROM public.verifier_registry
      WHERE tenant_id = current_setting('app.current_tenant_id', true)::uuid
    )
  );

REVOKE ALL ON public.verifier_registry FROM PUBLIC;
REVOKE ALL ON public.verifier_project_assignments FROM PUBLIC;
GRANT SELECT, INSERT ON public.verifier_registry TO app_runtime;
GRANT SELECT, INSERT ON public.verifier_project_assignments TO app_runtime;
GRANT EXECUTE ON FUNCTION public.check_reg26_separation(UUID, UUID, TEXT) TO app_runtime;

COMMIT;
```

---

## Step 3 — Write sidecar

File: `schema/migrations/0085_gf_verifier_registry.meta.yml`

```yaml
migration_id: "0085"
phase: "0"
layer: POLICY_TABLE
volatility_class: POLICY_TABLE
touches_core_schema: true
introduces_identifiers:
  - verifier_registry
  - verifier_project_assignments
  - check_reg26_separation
  - gf_verifier_tables_append_only
second_pilot_justification_required: true
```

---

## Step 4 — Update MIGRATION_HEAD

```bash
echo "0085" > schema/migrations/MIGRATION_HEAD
```

---

## Step 5 — Run negative tests

```bash
# N1: Reg 26 enforcement
psql << 'SQL'
  INSERT INTO verifier_project_assignments (verifier_id, project_id, assigned_role)
  VALUES ('<test_verifier_id>', '<test_project_id>', 'VALIDATOR');

  SELECT check_reg26_separation('<test_verifier_id>', '<test_project_id>', 'VERIFIER');
  -- Must raise GF001
SQL

# N2: Invalid role type
psql -c "INSERT INTO verifier_registry (role_type, ...) VALUES ('CONSULTANT', ...)"
# Must fail with CHECK constraint

# N3: Append-only
psql -c "UPDATE verifier_registry SET is_active=true WHERE ..."
# Must raise P0001

# N4: AST clean
python3 scripts/audit/verify_neutral_schema_ast.py \
  schema/migrations/0085_gf_verifier_registry.sql
```

---

## Rollback procedure

```sql
BEGIN;
DROP FUNCTION IF EXISTS public.check_reg26_separation(UUID, UUID, TEXT);
DROP TRIGGER IF EXISTS verifier_project_assignments_no_mutate
  ON public.verifier_project_assignments;
DROP TRIGGER IF EXISTS verifier_registry_no_mutate
  ON public.verifier_registry;
DROP FUNCTION IF EXISTS public.gf_verifier_tables_append_only();
DROP TABLE IF EXISTS public.verifier_project_assignments;
DROP TABLE IF EXISTS public.verifier_registry;
COMMIT;
```

Rollback only permitted before Phase 0 closeout (GF-W1-SCH-009).
