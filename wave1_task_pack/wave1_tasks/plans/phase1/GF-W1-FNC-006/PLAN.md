# PLAN: GF-W1-FNC-006 — issue_verifier_read_token (migration 0086)

Status: planned
Phase: 1
Task: GF-W1-FNC-006
Author: <UNASSIGNED>

---

## Objective

DB-level token issuance primitive only. Creates time-bounded project-scoped
read token for a registered verifier. Enforces Regulation 26 before issuing.
Stores token hash, not plaintext. Supports non-destructive revocation.
The API surface that consumes this token is Phase 2.

---

## Step 1 — Confirm prerequisites

- [ ] GF-W1-SCH-008 evidence passes (verifier_registry + check_reg26_separation exist)
- [ ] GF-W1-FNC-005 evidence passes
- [ ] MIGRATION_HEAD = 0085

---

## Step 2 — Write migration SQL

File: `schema/migrations/0086_gf_fn_verifier_read_token.sql`

```sql
-- symphony:migration id: 0086
-- phase: 1, volatility_class: CORE_SCHEMA

BEGIN;

-- Token table
CREATE TABLE IF NOT EXISTS public.gf_verifier_read_tokens (
  token_id      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  verifier_id   UUID        NOT NULL REFERENCES public.verifier_registry(verifier_id),
  project_id    UUID        NOT NULL REFERENCES public.projects(project_id),
  tenant_id     UUID        NOT NULL REFERENCES public.tenants(tenant_id),
  token_hash    TEXT        NOT NULL UNIQUE,
  scoped_tables JSONB       NOT NULL,
  issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at    TIMESTAMPTZ NOT NULL,
  revoked_at    TIMESTAMPTZ NULL,
  issued_by     TEXT        NOT NULL DEFAULT CURRENT_USER
);

CREATE OR REPLACE FUNCTION public.gf_verifier_tokens_append_only()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'gf_verifier_read_tokens: DELETE not permitted — use revoke'
      USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER gf_verifier_tokens_no_delete
  BEFORE DELETE ON public.gf_verifier_read_tokens
  FOR EACH ROW EXECUTE FUNCTION public.gf_verifier_tokens_append_only();

ALTER TABLE public.gf_verifier_read_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY gf_verifier_tokens_tenant
  ON public.gf_verifier_read_tokens
  USING (tenant_id = current_setting('app.current_tenant_id', true)::uuid);

-- Issuance function
CREATE OR REPLACE FUNCTION public.issue_verifier_read_token(
  p_verifier_id UUID,
  p_project_id  UUID,
  p_ttl_hours   INTEGER DEFAULT 72
)
RETURNS TEXT  -- returns raw token secret (once only)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_tenant_id   UUID;
  v_secret      TEXT;
  v_hash        TEXT;
BEGIN
  -- 1. Verify verifier is active
  SELECT tenant_id INTO v_tenant_id
  FROM public.verifier_registry
  WHERE verifier_id = p_verifier_id AND is_active = true;

  IF v_tenant_id IS NULL THEN
    RAISE EXCEPTION 'Verifier % not found or not active', p_verifier_id
      USING ERRCODE = 'P0001';
  END IF;

  -- 2. Regulation 26 check (raises GF001 if violated)
  PERFORM public.check_reg26_separation(p_verifier_id, p_project_id, 'VERIFIER');

  -- 3. Generate token secret and hash
  v_secret := encode(gen_random_bytes(32), 'hex');
  v_hash   := encode(digest(v_secret, 'sha256'), 'hex');

  -- 4. Store token record with hash only
  INSERT INTO public.gf_verifier_read_tokens (
    verifier_id, project_id, tenant_id,
    token_hash, scoped_tables, expires_at
  )
  VALUES (
    p_verifier_id, p_project_id, v_tenant_id,
    v_hash,
    '["evidence_nodes","monitoring_records","asset_batches","verification_cases"]'::jsonb,
    now() + (p_ttl_hours || ' hours')::interval
  );

  -- 5. Return raw secret once — never stored, never recoverable
  RETURN v_secret;
END;
$$;

-- Revocation function (non-destructive)
CREATE OR REPLACE FUNCTION public.revoke_verifier_read_token(
  p_token_hash TEXT
)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  UPDATE public.gf_verifier_read_tokens
  SET revoked_at = now()
  WHERE token_hash = p_token_hash
    AND revoked_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Token not found or already revoked'
      USING ERRCODE = 'P0001';
  END IF;
END;
$$;

REVOKE ALL ON public.gf_verifier_read_tokens FROM PUBLIC;
GRANT SELECT, INSERT ON public.gf_verifier_read_tokens TO app_runtime;
GRANT EXECUTE ON FUNCTION public.issue_verifier_read_token(UUID, UUID, INTEGER) TO app_runtime;
GRANT EXECUTE ON FUNCTION public.revoke_verifier_read_token(TEXT) TO app_runtime;

COMMIT;
```

---

## Step 3 — Rollback procedure

```sql
BEGIN;
DROP FUNCTION IF EXISTS public.revoke_verifier_read_token(TEXT);
DROP FUNCTION IF EXISTS public.issue_verifier_read_token(UUID, UUID, INTEGER);
DROP TRIGGER IF EXISTS gf_verifier_tokens_no_delete ON public.gf_verifier_read_tokens;
DROP FUNCTION IF EXISTS public.gf_verifier_tokens_append_only();
DROP TABLE IF EXISTS public.gf_verifier_read_tokens;
COMMIT;
```

---

## Step 4 — Critical negative tests

```sql
-- N1: Regulation 26 fires BEFORE token creation
INSERT INTO verifier_project_assignments (verifier_id, project_id, assigned_role)
VALUES ('<v>', '<p>', 'VALIDATOR');

SELECT issue_verifier_read_token('<v>', '<p>');
-- Must raise GF001. Check gf_verifier_read_tokens is empty — no partial state.

-- N2: Inactive verifier
UPDATE verifier_registry SET is_active=false ... -- won't work (append-only)
-- Insert new inactive row instead, then:
SELECT issue_verifier_read_token('<inactive_v>', '<p>');
-- Must raise P0001 before Reg 26 check

-- N3: No DELETE on token
SELECT issue_verifier_read_token('<v>', '<p2>') as token \gset
DELETE FROM gf_verifier_read_tokens WHERE token_hash = ...;
-- Must raise P0001

-- N4: Revocation preserves row
SELECT revoke_verifier_read_token('<hash>');
SELECT revoked_at FROM gf_verifier_read_tokens WHERE token_hash = '<hash>';
-- Must be NOT NULL. Row still exists.
```
