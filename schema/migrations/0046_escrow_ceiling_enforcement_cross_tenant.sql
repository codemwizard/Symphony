-- 0046_escrow_ceiling_enforcement_cross_tenant.sql
-- TSK-P1-ESC-002: Escrow invariants + cross-tenant protections (ceiling enforcement).

-- Programs now bind to a canonical budget envelope escrow_id.
CREATE TABLE IF NOT EXISTS public.programs (
  program_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  program_key TEXT NOT NULL,
  program_name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','SUSPENDED','CLOSED')),
  program_escrow_id UUID NOT NULL REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tenant_id, program_key),
  UNIQUE (tenant_id, program_escrow_id)
);

CREATE INDEX IF NOT EXISTS idx_programs_tenant_status
  ON public.programs(tenant_id, status);

COMMENT ON TABLE public.programs IS
  'Phase-1 program registry. Binds each program to a single budget envelope escrow_id (program_escrow_id).';

-- Each budget envelope has a single balance row that is locked during reservations.
CREATE TABLE IF NOT EXISTS public.escrow_envelopes (
  escrow_id UUID PRIMARY KEY REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  currency_code CHAR(3) NOT NULL,
  ceiling_amount_minor BIGINT NOT NULL CHECK (ceiling_amount_minor >= 0),
  reserved_amount_minor BIGINT NOT NULL DEFAULT 0 CHECK (reserved_amount_minor >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_escrow_envelopes_tenant
  ON public.escrow_envelopes(tenant_id);

COMMENT ON TABLE public.escrow_envelopes IS
  'Phase-1 budget envelope balance row. Locked FOR UPDATE by authorize_escrow_reservation() to prevent oversubscription.';

-- Reservation ledger: each successful reservation is recorded with envelope binding.
CREATE TABLE IF NOT EXISTS public.escrow_reservations (
  reservation_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  program_escrow_id UUID NOT NULL REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  reservation_escrow_id UUID NOT NULL REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  amount_minor BIGINT NOT NULL CHECK (amount_minor > 0),
  actor_id TEXT NOT NULL DEFAULT current_user,
  reason TEXT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (program_escrow_id, reservation_escrow_id)
);

CREATE INDEX IF NOT EXISTS idx_escrow_reservations_tenant_program
  ON public.escrow_reservations(tenant_id, program_escrow_id, created_at);

COMMENT ON TABLE public.escrow_reservations IS
  'Phase-1 reservation ledger: append-only record of successful ceiling-checked reservations.';

-- Touch helpers.
CREATE OR REPLACE FUNCTION public.touch_programs_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_programs_updated_at ON public.programs;
CREATE TRIGGER trg_touch_programs_updated_at
BEFORE UPDATE ON public.programs
FOR EACH ROW
EXECUTE FUNCTION public.touch_programs_updated_at();

CREATE OR REPLACE FUNCTION public.touch_escrow_envelopes_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_escrow_envelopes_updated_at ON public.escrow_envelopes;
CREATE TRIGGER trg_touch_escrow_envelopes_updated_at
BEFORE UPDATE ON public.escrow_envelopes
FOR EACH ROW
EXECUTE FUNCTION public.touch_escrow_envelopes_updated_at();

-- Ceiling-enforced reservation primitive.
CREATE OR REPLACE FUNCTION public.authorize_escrow_reservation(
  p_program_escrow_id UUID,
  p_amount_minor BIGINT,
  p_actor_id TEXT DEFAULT 'system',
  p_reason TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_env public.escrow_envelopes%ROWTYPE;
  v_amount BIGINT := COALESCE(p_amount_minor, 0);
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_reservation_escrow_id UUID;
BEGIN
  IF v_amount <= 0 THEN
    RAISE EXCEPTION 'invalid reservation amount %', v_amount
      USING ERRCODE = 'P7304';
  END IF;

  -- Critical lock: deterministic prevention of oversubscription.
  SELECT *
  INTO v_env
  FROM public.escrow_envelopes
  WHERE escrow_envelopes.escrow_id = p_program_escrow_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'escrow envelope not found'
      USING ERRCODE = 'P7302';
  END IF;

  IF v_env.reserved_amount_minor + v_amount > v_env.ceiling_amount_minor THEN
    RAISE EXCEPTION 'escrow ceiling exceeded'
      USING ERRCODE = 'P7304';
  END IF;

  UPDATE public.escrow_envelopes
  SET reserved_amount_minor = reserved_amount_minor + v_amount,
      updated_at = NOW()
  WHERE escrow_envelopes.escrow_id = v_env.escrow_id;

  INSERT INTO public.escrow_accounts(
    tenant_id, program_id, entity_id, state, authorized_amount_minor, currency_code, authorization_expires_at, release_due_at
  ) VALUES (
    v_env.tenant_id, NULL, NULL, 'CREATED', v_amount, v_env.currency_code, NOW() + interval '30 minutes', NOW() + interval '60 minutes'
  )
  RETURNING escrow_accounts.escrow_id INTO v_reservation_escrow_id;

  -- Record state as AUTHORIZED and write append-only event.
  PERFORM 1
  FROM public.transition_escrow_state(
    p_escrow_id => v_reservation_escrow_id,
    p_to_state => 'AUTHORIZED',
    p_actor_id => v_actor,
    p_reason => COALESCE(p_reason, 'reservation_authorized'),
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_now => NOW()
  );

  INSERT INTO public.escrow_reservations(
    tenant_id, program_escrow_id, reservation_escrow_id, amount_minor, actor_id, reason, metadata, created_at
  ) VALUES (
    v_env.tenant_id, v_env.escrow_id, v_reservation_escrow_id, v_amount, v_actor, p_reason, COALESCE(p_metadata, '{}'::jsonb), NOW()
  );

  RETURN v_reservation_escrow_id;
END;
$$;

COMMENT ON FUNCTION public.authorize_escrow_reservation(UUID, BIGINT, TEXT, TEXT, JSONB) IS
  'Phase-1 reservation primitive: locks escrow_envelopes row FOR UPDATE and fails closed if reservation would exceed ceiling.';

REVOKE ALL ON TABLE public.programs FROM PUBLIC;
REVOKE ALL ON TABLE public.escrow_envelopes FROM PUBLIC;
REVOKE ALL ON TABLE public.escrow_reservations FROM PUBLIC;

