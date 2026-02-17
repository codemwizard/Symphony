-- 0029_pii_decoupling_and_purge_hooks.sql
-- INV-115: PII decoupling + purge survivability (Phase-1)

CREATE TABLE IF NOT EXISTS public.pii_purge_requests (
  purge_request_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  subject_token TEXT NOT NULL,
  requested_by TEXT NOT NULL,
  request_reason TEXT NOT NULL,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pii_purge_requests_subject_requested
  ON public.pii_purge_requests(subject_token, requested_at DESC);

CREATE TABLE IF NOT EXISTS public.pii_vault_records (
  vault_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  subject_token TEXT NOT NULL,
  identity_hash TEXT NOT NULL,
  protected_payload JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  purged_at TIMESTAMPTZ NULL,
  purge_request_id UUID NULL,
  CONSTRAINT ux_pii_vault_records_subject_token UNIQUE (subject_token),
  CONSTRAINT pii_vault_records_purge_shape_chk CHECK (
    (
      purged_at IS NULL
      AND protected_payload IS NOT NULL
      AND purge_request_id IS NULL
    )
    OR
    (
      purged_at IS NOT NULL
      AND protected_payload IS NULL
      AND purge_request_id IS NOT NULL
    )
  )
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'pii_vault_records_purge_request_fk'
      AND conrelid = 'public.pii_vault_records'::regclass
  ) THEN
    ALTER TABLE public.pii_vault_records
      ADD CONSTRAINT pii_vault_records_purge_request_fk
      FOREIGN KEY (purge_request_id)
      REFERENCES public.pii_purge_requests(purge_request_id)
      DEFERRABLE INITIALLY IMMEDIATE;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.pii_purge_events (
  purge_event_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  purge_request_id UUID NOT NULL REFERENCES public.pii_purge_requests(purge_request_id),
  event_type TEXT NOT NULL CHECK (event_type IN ('REQUESTED', 'PURGED')),
  rows_affected INTEGER NOT NULL DEFAULT 0 CHECK (rows_affected >= 0),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB NULL,
  CONSTRAINT ux_pii_purge_events_request_event UNIQUE (purge_request_id, event_type)
);

CREATE OR REPLACE FUNCTION public.deny_pii_vault_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF current_setting('symphony.allow_pii_purge', true) = 'on' THEN
      RETURN NEW;
    END IF;
    RAISE EXCEPTION 'pii_vault_records updates require purge executor'
      USING ERRCODE = 'P7004';
  END IF;

  RAISE EXCEPTION 'pii_vault_records is non-deletable'
    USING ERRCODE = 'P7004';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_pii_vault_mutation ON public.pii_vault_records;

CREATE TRIGGER trg_deny_pii_vault_mutation
BEFORE UPDATE OR DELETE ON public.pii_vault_records
FOR EACH ROW
EXECUTE FUNCTION public.deny_pii_vault_mutation();

CREATE OR REPLACE FUNCTION public.request_pii_purge(
  p_subject_token TEXT,
  p_requested_by TEXT,
  p_request_reason TEXT
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_request_id UUID;
BEGIN
  INSERT INTO public.pii_purge_requests(
    subject_token,
    requested_by,
    request_reason
  ) VALUES (
    p_subject_token,
    p_requested_by,
    p_request_reason
  )
  RETURNING purge_request_id INTO v_request_id;

  INSERT INTO public.pii_purge_events(
    purge_request_id,
    event_type,
    rows_affected,
    metadata
  ) VALUES (
    v_request_id,
    'REQUESTED',
    0,
    jsonb_build_object('subject_token', p_subject_token)
  );

  RETURN v_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.execute_pii_purge(
  p_purge_request_id UUID,
  p_executor TEXT
)
RETURNS TABLE (
  purge_request_id UUID,
  rows_affected INTEGER,
  already_purged BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_subject_token TEXT;
  v_rows INTEGER := 0;
  v_prior INTEGER := 0;
BEGIN
  SELECT r.subject_token
  INTO v_subject_token
  FROM public.pii_purge_requests r
  WHERE r.purge_request_id = p_purge_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'purge request not found: %', p_purge_request_id
      USING ERRCODE = 'P7004';
  END IF;

  SELECT e.rows_affected
  INTO v_prior
  FROM public.pii_purge_events e
  WHERE e.purge_request_id = p_purge_request_id
    AND e.event_type = 'PURGED'
  LIMIT 1;

  IF FOUND THEN
    RETURN QUERY SELECT p_purge_request_id, v_prior, TRUE;
    RETURN;
  END IF;

  PERFORM set_config('symphony.allow_pii_purge', 'on', true);

  UPDATE public.pii_vault_records
     SET protected_payload = NULL,
         purged_at = NOW(),
         purge_request_id = p_purge_request_id
   WHERE subject_token = v_subject_token
     AND purged_at IS NULL;

  GET DIAGNOSTICS v_rows = ROW_COUNT;

  INSERT INTO public.pii_purge_events(
    purge_request_id,
    event_type,
    rows_affected,
    metadata
  ) VALUES (
    p_purge_request_id,
    'PURGED',
    v_rows,
    jsonb_build_object('executor', p_executor)
  )
  ON CONFLICT (purge_request_id, event_type)
  DO NOTHING;

  RETURN QUERY SELECT p_purge_request_id, v_rows, FALSE;
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_pii_purge_requests_mutation ON public.pii_purge_requests;
CREATE TRIGGER trg_deny_pii_purge_requests_mutation
BEFORE UPDATE OR DELETE ON public.pii_purge_requests
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

DROP TRIGGER IF EXISTS trg_deny_pii_purge_events_mutation ON public.pii_purge_events;
CREATE TRIGGER trg_deny_pii_purge_events_mutation
BEFORE UPDATE OR DELETE ON public.pii_purge_events
FOR EACH ROW
EXECUTE FUNCTION public.deny_append_only_mutation();

REVOKE ALL ON TABLE public.pii_vault_records FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_vault_records FROM symphony_executor;
GRANT SELECT ON TABLE public.pii_vault_records TO symphony_readonly;

REVOKE ALL ON TABLE public.pii_purge_requests FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_purge_requests FROM symphony_executor;
GRANT SELECT ON TABLE public.pii_purge_requests TO symphony_readonly;

REVOKE ALL ON TABLE public.pii_purge_events FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_purge_events FROM symphony_executor;
GRANT SELECT ON TABLE public.pii_purge_events TO symphony_readonly;
