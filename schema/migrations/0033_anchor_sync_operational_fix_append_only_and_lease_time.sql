ALTER TABLE public.anchor_sync_operations
  ADD COLUMN IF NOT EXISTS anchor_type TEXT;

CREATE OR REPLACE FUNCTION public.claim_anchor_sync_operation(
  p_worker_id TEXT,
  p_lease_seconds INTEGER DEFAULT 30
)
RETURNS TABLE(
  operation_id UUID,
  pack_id UUID,
  lease_token UUID,
  state TEXT,
  attempt_count INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_worker TEXT := NULLIF(BTRIM(p_worker_id), '');
BEGIN
  IF v_worker IS NULL THEN
    RAISE EXCEPTION 'worker_id is required' USING ERRCODE = 'P7210';
  END IF;

  IF p_lease_seconds IS NULL OR p_lease_seconds <= 0 THEN
    RAISE EXCEPTION 'lease seconds must be > 0' USING ERRCODE = 'P7210';
  END IF;

  RETURN QUERY
  WITH candidate AS (
    SELECT o.operation_id
    FROM public.anchor_sync_operations o
    WHERE o.state IN ('PENDING', 'ANCHORED')
      AND (o.lease_expires_at IS NULL OR o.lease_expires_at <= clock_timestamp())
    ORDER BY o.updated_at, o.created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.anchor_sync_operations o
  SET state = CASE WHEN o.state = 'ANCHORED' THEN 'ANCHORED' ELSE 'ANCHORING' END,
      claimed_by = v_worker,
      lease_token = public.uuid_v7_or_random(),
      lease_expires_at = clock_timestamp() + make_interval(secs => p_lease_seconds),
      attempt_count = o.attempt_count + 1,
      last_error = NULL
  FROM candidate c
  WHERE o.operation_id = c.operation_id
  RETURNING o.operation_id, o.pack_id, o.lease_token, o.state, o.attempt_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_anchor_sync_anchored(
  p_operation_id UUID,
  p_lease_token UUID,
  p_worker_id TEXT,
  p_anchor_ref TEXT,
  p_anchor_type TEXT DEFAULT 'HYBRID_SYNC'
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_op public.anchor_sync_operations%ROWTYPE;
BEGIN
  SELECT * INTO v_op
  FROM public.anchor_sync_operations
  WHERE operation_id = p_operation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
  END IF;

  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.state NOT IN ('ANCHORING', 'ANCHORED') THEN
    RAISE EXCEPTION 'anchor operation cannot be anchored from state %', v_op.state USING ERRCODE = 'P7211';
  END IF;

  IF NULLIF(BTRIM(p_anchor_ref), '') IS NULL THEN
    RAISE EXCEPTION 'anchor reference is required' USING ERRCODE = 'P7211';
  END IF;

  UPDATE public.anchor_sync_operations
  SET state = 'ANCHORED',
      anchor_ref = p_anchor_ref,
      anchor_type = COALESCE(NULLIF(BTRIM(p_anchor_type), ''), 'HYBRID_SYNC')
  WHERE operation_id = v_op.operation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.complete_anchor_sync_operation(
  p_operation_id UUID,
  p_lease_token UUID,
  p_worker_id TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
  v_op public.anchor_sync_operations%ROWTYPE;
BEGIN
  SELECT * INTO v_op
  FROM public.anchor_sync_operations
  WHERE operation_id = p_operation_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'anchor operation not found' USING ERRCODE = 'P7210';
  END IF;

  IF v_op.claimed_by IS DISTINCT FROM p_worker_id THEN
    RAISE EXCEPTION 'anchor operation worker mismatch' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= clock_timestamp() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.state <> 'ANCHORED' OR NULLIF(BTRIM(v_op.anchor_ref), '') IS NULL THEN
    RAISE EXCEPTION 'anchor completion requires anchored state' USING ERRCODE = 'P7211';
  END IF;

  UPDATE public.anchor_sync_operations
  SET state = 'COMPLETED',
      lease_token = NULL,
      lease_expires_at = NULL
  WHERE operation_id = v_op.operation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.repair_expired_anchor_sync_leases(
  p_worker_id TEXT DEFAULT 'anchor_repair'
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  UPDATE public.anchor_sync_operations
  SET state = CASE WHEN state = 'ANCHORED' THEN 'ANCHORED' ELSE 'PENDING' END,
      claimed_by = NULL,
      lease_token = NULL,
      lease_expires_at = NULL,
      last_error = COALESCE(last_error, 'LEASE_EXPIRED_REPAIRED')
  WHERE state IN ('ANCHORING', 'ANCHORED')
    AND lease_expires_at IS NOT NULL
    AND lease_expires_at <= clock_timestamp();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
