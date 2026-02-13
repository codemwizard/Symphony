-- 0030_fix_pii_purge_executor_conflict_target.sql
-- Follow-up fix: avoid plpgsql ambiguity in ON CONFLICT target for execute_pii_purge.

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
  ON CONFLICT ON CONSTRAINT ux_pii_purge_events_request_event
  DO NOTHING;

  RETURN QUERY SELECT p_purge_request_id, v_rows, FALSE;
END;
$$;
