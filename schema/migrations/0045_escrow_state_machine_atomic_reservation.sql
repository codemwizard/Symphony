-- 0045_escrow_state_machine_atomic_reservation.sql
-- TSK-P1-ESC-001: Escrow state model + atomic transition primitives.

CREATE TABLE IF NOT EXISTS public.escrow_accounts (
  escrow_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  program_id UUID NULL,
  entity_id TEXT NULL,
  state TEXT NOT NULL DEFAULT 'CREATED' CHECK (
    state IN ('CREATED', 'AUTHORIZED', 'RELEASE_REQUESTED', 'RELEASED', 'CANCELED', 'EXPIRED')
  ),
  authorized_amount_minor BIGINT NOT NULL CHECK (authorized_amount_minor >= 0),
  currency_code CHAR(3) NOT NULL,
  authorization_expires_at TIMESTAMPTZ NULL,
  release_due_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  released_at TIMESTAMPTZ NULL,
  canceled_at TIMESTAMPTZ NULL,
  expired_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS idx_escrow_accounts_tenant_state
  ON public.escrow_accounts(tenant_id, state, authorization_expires_at, release_due_at);

CREATE INDEX IF NOT EXISTS idx_escrow_accounts_program
  ON public.escrow_accounts(program_id)
  WHERE program_id IS NOT NULL;

COMMENT ON TABLE public.escrow_accounts IS
  'Phase-1 escrow reservation model. Non-custodial: stores authorization and release state only.';

CREATE TABLE IF NOT EXISTS public.escrow_events (
  event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  escrow_id UUID NOT NULL REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  event_type TEXT NOT NULL CHECK (
    event_type IN ('CREATED', 'AUTHORIZED', 'RELEASE_REQUESTED', 'RELEASED', 'CANCELED', 'EXPIRED')
  ),
  actor_id TEXT NOT NULL DEFAULT current_user,
  reason TEXT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_escrow_events_escrow_created
  ON public.escrow_events(escrow_id, created_at);

DROP TRIGGER IF EXISTS trg_deny_escrow_events_mutation ON public.escrow_events;
CREATE TRIGGER trg_deny_escrow_events_mutation
BEFORE UPDATE OR DELETE ON public.escrow_events
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

CREATE OR REPLACE FUNCTION public.touch_escrow_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_escrow_updated_at ON public.escrow_accounts;
CREATE TRIGGER trg_touch_escrow_updated_at
BEFORE UPDATE ON public.escrow_accounts
FOR EACH ROW
EXECUTE FUNCTION public.touch_escrow_updated_at();

CREATE OR REPLACE FUNCTION public.transition_escrow_state(
  p_escrow_id UUID,
  p_to_state TEXT,
  p_actor_id TEXT DEFAULT 'system',
  p_reason TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb,
  p_now TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE(
  escrow_id UUID,
  previous_state TEXT,
  new_state TEXT,
  event_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_row public.escrow_accounts%ROWTYPE;
  v_to_state TEXT := UPPER(BTRIM(COALESCE(p_to_state, '')));
  v_actor TEXT := COALESCE(NULLIF(BTRIM(p_actor_id), ''), 'system');
  v_event_id UUID;
  v_legal BOOLEAN := FALSE;
BEGIN
  SELECT *
  INTO v_row
  FROM public.escrow_accounts
  WHERE escrow_accounts.escrow_id = p_escrow_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'escrow not found'
      USING ERRCODE = 'P7302';
  END IF;

  IF v_to_state NOT IN ('CREATED', 'AUTHORIZED', 'RELEASE_REQUESTED', 'RELEASED', 'CANCELED', 'EXPIRED') THEN
    RAISE EXCEPTION 'invalid target escrow state %', v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  IF v_row.state IN ('RELEASED', 'CANCELED', 'EXPIRED') THEN
    RAISE EXCEPTION 'escrow terminal state transition forbidden: % -> %', v_row.state, v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  v_legal := (
    (v_row.state = 'CREATED' AND v_to_state IN ('AUTHORIZED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'AUTHORIZED' AND v_to_state IN ('RELEASE_REQUESTED', 'CANCELED', 'EXPIRED'))
    OR (v_row.state = 'RELEASE_REQUESTED' AND v_to_state IN ('RELEASED', 'CANCELED', 'EXPIRED'))
  );

  IF NOT v_legal THEN
    RAISE EXCEPTION 'illegal escrow transition: % -> %', v_row.state, v_to_state
      USING ERRCODE = 'P7303';
  END IF;

  UPDATE public.escrow_accounts
  SET state = v_to_state,
      updated_at = p_now,
      released_at = CASE WHEN v_to_state = 'RELEASED' THEN COALESCE(released_at, p_now) ELSE released_at END,
      canceled_at = CASE WHEN v_to_state = 'CANCELED' THEN COALESCE(canceled_at, p_now) ELSE canceled_at END,
      expired_at = CASE WHEN v_to_state = 'EXPIRED' THEN COALESCE(expired_at, p_now) ELSE expired_at END
  WHERE escrow_accounts.escrow_id = p_escrow_id;

  INSERT INTO public.escrow_events(escrow_id, tenant_id, event_type, actor_id, reason, metadata, created_at)
  VALUES (
    v_row.escrow_id,
    v_row.tenant_id,
    v_to_state,
    v_actor,
    p_reason,
    COALESCE(p_metadata, '{}'::jsonb),
    p_now
  )
  RETURNING escrow_events.event_id INTO v_event_id;

  RETURN QUERY
  SELECT v_row.escrow_id, v_row.state, v_to_state, v_event_id;
END;
$$;

COMMENT ON FUNCTION public.transition_escrow_state(UUID, TEXT, TEXT, TEXT, JSONB, TIMESTAMPTZ) IS
  'Canonical escrow state machine transition gate for Phase-1.';

CREATE OR REPLACE FUNCTION public.release_escrow(
  p_escrow_id UUID,
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
  v_event_id UUID;
BEGIN
  SELECT t.event_id
  INTO v_event_id
  FROM public.transition_escrow_state(
    p_escrow_id => p_escrow_id,
    p_to_state => 'RELEASED',
    p_actor_id => p_actor_id,
    p_reason => p_reason,
    p_metadata => COALESCE(p_metadata, '{}'::jsonb),
    p_now => NOW()
  ) AS t;

  RETURN v_event_id;
END;
$$;

COMMENT ON FUNCTION public.release_escrow(UUID, TEXT, TEXT, JSONB) IS
  'Non-custodial release primitive: emits RELEASED event + state transition; does not move funds.';

CREATE OR REPLACE FUNCTION public.expire_escrows(
  p_now TIMESTAMPTZ DEFAULT NOW(),
  p_actor_id TEXT DEFAULT 'escrow_expiry_worker'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_escrow_id UUID;
  v_count INTEGER := 0;
BEGIN
  FOR v_escrow_id IN
    SELECT e.escrow_id
    FROM public.escrow_accounts e
    WHERE
      (e.state = 'CREATED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      OR (e.state = 'AUTHORIZED' AND e.authorization_expires_at IS NOT NULL AND e.authorization_expires_at <= p_now)
      OR (e.state = 'RELEASE_REQUESTED' AND e.release_due_at IS NOT NULL AND e.release_due_at <= p_now)
  LOOP
    PERFORM public.transition_escrow_state(
      p_escrow_id => v_escrow_id,
      p_to_state => 'EXPIRED',
      p_actor_id => p_actor_id,
      p_reason => 'window_elapsed',
      p_metadata => jsonb_build_object('expired_at', p_now),
      p_now => p_now
    );
    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.expire_escrows(TIMESTAMPTZ, TEXT) IS
  'Expires CREATED/AUTHORIZED/RELEASE_REQUESTED escrows when configured windows elapse.';

REVOKE ALL ON TABLE public.escrow_accounts FROM PUBLIC;
REVOKE ALL ON TABLE public.escrow_events FROM PUBLIC;

