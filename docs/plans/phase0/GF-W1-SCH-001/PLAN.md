# PLAN: GF-W1-SCH-001 — adapter_registrations (migration 0070)

Status: planned
Phase: 0
Task: GF-W1-SCH-001
Author: <UNASSIGNED>

---

## Objective

Create the `adapter_registrations` table as the structurally stable boundary
object for all green finance methodology adapters. This is migration 0070 —
the first green finance migration. It must be correct because every subsequent
GF migration has an FK dependency path back to it.

---

## Step 1 — Confirm prerequisites

Before writing any SQL:

- [ ] `GF-W1-GOV-005` passed: `verify_migration_sequence.sh` exits 0 with MIGRATION_HEAD=0069
- [ ] `GF-W1-FRZ-005` merged: `GREEN_FINANCE_VOLATILITY_MAP.md` exists
- [ ] `GF-W1-DSN-001` approved: `ADAPTER_CONTRACT_INTERFACE.md` exists
- [ ] `GF-W1-GOV-002` merged: `verify_neutral_schema_ast.py` exists
- [ ] `GF-W1-GOV-003` merged: migration sidecar format defined

---

## Step 2 — Write migration SQL

File: `schema/migrations/0070_gf_adapter_registrations.sql`

```sql
-- symphony:migration
-- id: 0070
-- description: Green finance adapter_registrations — neutral methodology adapter contract table
-- phase: 0
-- volatility_class: CORE_SCHEMA

BEGIN;

CREATE TABLE IF NOT EXISTS public.adapter_registrations (
  adapter_registration_id UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id               UUID        NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  adapter_code            TEXT        NOT NULL,
  methodology_code        TEXT        NOT NULL,
  methodology_authority   TEXT        NOT NULL,
  version_code            TEXT        NOT NULL,
  is_active               BOOLEAN     NOT NULL DEFAULT false,
  payload_schema_refs     JSONB       NOT NULL DEFAULT '[]'::jsonb,
  checklist_refs          JSONB       NOT NULL DEFAULT '[]'::jsonb,
  entrypoint_refs         JSONB       NOT NULL DEFAULT '[]'::jsonb,
  issuance_semantic_mode  TEXT        NOT NULL,
  retirement_semantic_mode TEXT       NOT NULL,
  jurisdiction_compatibility JSONB   NOT NULL DEFAULT '{}'::jsonb,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT adapter_registrations_unique_version
    UNIQUE (tenant_id, adapter_code, methodology_code, version_code)
);

-- Append-only trigger
CREATE OR REPLACE FUNCTION public.gf_adapter_registrations_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'adapter_registrations is append-only: UPDATE not permitted'
      USING ERRCODE = 'P0001';
  END IF;
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'adapter_registrations is append-only: DELETE not permitted'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER gf_adapter_registrations_no_mutate
  BEFORE UPDATE OR DELETE ON public.adapter_registrations
  FOR EACH ROW EXECUTE FUNCTION public.gf_adapter_registrations_append_only();

-- RLS
ALTER TABLE public.adapter_registrations ENABLE ROW LEVEL SECURITY;

CREATE POLICY adapter_registrations_tenant_isolation
  ON public.adapter_registrations
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Revoke-first privilege posture
REVOKE ALL ON public.adapter_registrations FROM PUBLIC;
GRANT SELECT, INSERT ON public.adapter_registrations TO app_runtime;

COMMIT;
```

---

## Step 3 — Write migration sidecar

File: `schema/migrations/0070_gf_adapter_registrations.meta.yml`

```yaml
migration_id: "0070"
description: "adapter_registrations — neutral methodology adapter contract table"
phase: "0"
layer: CORE_SCHEMA
volatility_class: CORE_SCHEMA
touches_core_schema: true
introduces_identifiers:
  - adapter_registrations
  - gf_adapter_registrations_append_only
  - gf_adapter_registrations_no_mutate
  - adapter_registrations_tenant_isolation
second_pilot_justification_required: true
second_pilot_justification: >-
  adapter_registrations is a neutral registry. Solar and forestry adapters
  both register as rows. No sector-specific columns exist.
```

---

## Step 4 — Update MIGRATION_HEAD

```bash
echo "0070" > schema/migrations/MIGRATION_HEAD
```

---

## Step 5 — Run verifiers

```bash
python3 scripts/audit/verify_neutral_schema_ast.py \
  schema/migrations/0070_gf_adapter_registrations.sql

python3 scripts/audit/verify_migration_meta_alignment.py

bash scripts/audit/verify_migration_sequence.sh

bash scripts/db/verify_gf_sch_001.sh
```

All must exit 0 before PR is opened.

---

## Step 6 — Run negative tests

```bash
# N1: append-only
psql -c "INSERT INTO adapter_registrations (...) VALUES (...) RETURNING adapter_registration_id" \
  | xargs -I{} psql -c "UPDATE adapter_registrations SET is_active=true WHERE adapter_registration_id='{}'"
# Must raise P0001

# N2: AST clean
python3 scripts/audit/verify_neutral_schema_ast.py \
  schema/migrations/0070_gf_adapter_registrations.sql
# Must exit 0

# N3: unique constraint
# Insert same (tenant_id, adapter_code, methodology_code, version_code) twice
# Second must fail with unique constraint violation
```

---

## Rollback procedure

If the migration must be reverted before Phase 0 closeout:

```sql
BEGIN;
DROP TRIGGER IF EXISTS gf_adapter_registrations_no_mutate
  ON public.adapter_registrations;
DROP FUNCTION IF EXISTS public.gf_adapter_registrations_append_only();
DROP POLICY IF EXISTS adapter_registrations_tenant_isolation
  ON public.adapter_registrations;
DROP TABLE IF EXISTS public.adapter_registrations;
COMMIT;
```

Update `MIGRATION_HEAD` back to `0069`.

Note: rollback is only permitted before Phase 0 closeout (GF-W1-SCH-009). After closeout, forward-only migration discipline applies per Symphony core rules.

---

## Evidence emission

After all verifiers pass, emit evidence:

```bash
bash scripts/db/verify_gf_sch_001.sh
# Evidence written to evidence/phase0/gf_sch_001.json
```

Confirm evidence file contains all required fields before marking task complete.
