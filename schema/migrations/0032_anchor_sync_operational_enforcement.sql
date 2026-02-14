CREATE TABLE IF NOT EXISTS public.anchor_sync_operations (
  operation_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  pack_id UUID NOT NULL UNIQUE REFERENCES public.evidence_packs(pack_id),
  state TEXT NOT NULL DEFAULT 'PENDING'
    CHECK (state IN ('PENDING', 'ANCHORING', 'ANCHORED', 'COMPLETED', 'FAILED')),
  anchor_provider TEXT NOT NULL DEFAULT 'GENERIC',
  anchor_ref TEXT,
  claimed_by TEXT,
  lease_token UUID,
  lease_expires_at TIMESTAMPTZ,
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT ck_anchor_sync_completed_requires_anchor_ref
    CHECK (state <> 'COMPLETED' OR anchor_ref IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_anchor_sync_operations_state_due
  ON public.anchor_sync_operations(state, lease_expires_at, updated_at);

CREATE OR REPLACE FUNCTION public.touch_anchor_sync_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_touch_anchor_sync_updated_at ON public.anchor_sync_operations;
CREATE TRIGGER trg_touch_anchor_sync_updated_at
BEFORE UPDATE ON public.anchor_sync_operations
FOR EACH ROW
EXECUTE FUNCTION public.touch_anchor_sync_updated_at();

CREATE OR REPLACE FUNCTION public.ensure_anchor_sync_operation(
  p_pack_id UUID,
  p_anchor_provider TEXT DEFAULT 'GENERIC'
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_operation_id UUID;
BEGIN
  IF p_pack_id IS NULL THEN
    RAISE EXCEPTION 'pack_id is required' USING ERRCODE = 'P7210';
  END IF;

  INSERT INTO public.anchor_sync_operations(pack_id, anchor_provider)
  VALUES (p_pack_id, COALESCE(NULLIF(BTRIM(p_anchor_provider), ''), 'GENERIC'))
  ON CONFLICT (pack_id) DO NOTHING
  RETURNING operation_id INTO v_operation_id;

  IF v_operation_id IS NULL THEN
    SELECT operation_id INTO v_operation_id
    FROM public.anchor_sync_operations
    WHERE pack_id = p_pack_id;
  END IF;

  RETURN v_operation_id;
END;
$$;

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
      AND (o.lease_expires_at IS NULL OR o.lease_expires_at <= NOW())
    ORDER BY o.updated_at, o.created_at
    LIMIT 1
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.anchor_sync_operations o
  SET state = CASE WHEN o.state = 'ANCHORED' THEN 'ANCHORED' ELSE 'ANCHORING' END,
      claimed_by = v_worker,
      lease_token = public.uuid_v7_or_random(),
      lease_expires_at = NOW() + make_interval(secs => p_lease_seconds),
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

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= NOW() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  IF v_op.state NOT IN ('ANCHORING', 'ANCHORED') THEN
    RAISE EXCEPTION 'anchor operation cannot be anchored from state %', v_op.state USING ERRCODE = 'P7211';
  END IF;

  IF NULLIF(BTRIM(p_anchor_ref), '') IS NULL THEN
    RAISE EXCEPTION 'anchor reference is required' USING ERRCODE = 'P7211';
  END IF;

  UPDATE public.evidence_packs
  SET anchor_type = COALESCE(NULLIF(BTRIM(p_anchor_type), ''), 'HYBRID_SYNC'),
      anchor_ref = p_anchor_ref,
      anchored_at = COALESCE(anchored_at, NOW())
  WHERE pack_id = v_op.pack_id;

  UPDATE public.anchor_sync_operations
  SET state = 'ANCHORED',
      anchor_ref = p_anchor_ref
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
  v_anchor_ref TEXT;
  v_anchored_at TIMESTAMPTZ;
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

  IF v_op.lease_token IS DISTINCT FROM p_lease_token OR v_op.lease_expires_at IS NULL OR v_op.lease_expires_at <= NOW() THEN
    RAISE EXCEPTION 'anchor operation lease invalid' USING ERRCODE = 'P7212';
  END IF;

  SELECT anchor_ref, anchored_at INTO v_anchor_ref, v_anchored_at
  FROM public.evidence_packs
  WHERE pack_id = v_op.pack_id;

  IF v_op.state <> 'ANCHORED' OR NULLIF(BTRIM(v_op.anchor_ref), '') IS NULL OR NULLIF(BTRIM(v_anchor_ref), '') IS NULL OR v_anchored_at IS NULL THEN
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
    AND lease_expires_at <= NOW();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

REVOKE ALL ON TABLE public.anchor_sync_operations FROM PUBLIC;
