-- 0053_hier_008_sim_swap_alerts.sql
-- TSK-P1-HIER-008: SIM swap alerts derived + formula traceability.

CREATE TABLE IF NOT EXISTS public.sim_swap_alerts (
  alert_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  member_id UUID NOT NULL REFERENCES public.members(member_id) ON DELETE RESTRICT,
  source_event_id UUID NOT NULL UNIQUE REFERENCES public.member_device_events(event_id) ON DELETE RESTRICT,
  prior_iccid_hash TEXT NOT NULL,
  new_iccid_hash TEXT NOT NULL,
  formula_version_id UUID NOT NULL REFERENCES public.risk_formula_versions(formula_version_id) ON DELETE RESTRICT,
  alert_type TEXT NOT NULL DEFAULT 'SIM_SWAP_DETECTED' CHECK (alert_type = 'SIM_SWAP_DETECTED'),
  derived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT sim_swap_alerts_iccid_diff_chk CHECK (prior_iccid_hash <> new_iccid_hash)
);

CREATE INDEX IF NOT EXISTS idx_sim_swap_alerts_tenant_member_derived
  ON public.sim_swap_alerts(tenant_id, member_id, derived_at DESC);

CREATE OR REPLACE FUNCTION public.deny_sim_swap_alerts_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'sim_swap_alerts is append-only'
    USING ERRCODE = 'P0001';
END;
$$;

DROP TRIGGER IF EXISTS trg_deny_sim_swap_alerts_mutation ON public.sim_swap_alerts;
CREATE TRIGGER trg_deny_sim_swap_alerts_mutation
BEFORE UPDATE OR DELETE ON public.sim_swap_alerts
FOR EACH ROW
EXECUTE FUNCTION public.deny_sim_swap_alerts_mutation();

CREATE OR REPLACE FUNCTION public.derive_sim_swap_alert(p_event_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_event public.member_device_events%ROWTYPE;
  v_prior_iccid_hash TEXT;
  v_formula_version_id UUID;
  v_alert_id UUID;
BEGIN
  SELECT e.*
  INTO v_event
  FROM public.member_device_events e
  WHERE e.event_id = p_event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'member_device_event % not found', p_event_id
      USING ERRCODE = 'P7400';
  END IF;

  IF v_event.event_type <> 'SIM_SWAP_DETECTED' OR v_event.iccid_hash IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT md.iccid_hash
  INTO v_prior_iccid_hash
  FROM public.member_devices md
  WHERE md.tenant_id = v_event.tenant_id
    AND md.member_id = v_event.member_id
    AND md.status = 'ACTIVE'
    AND md.iccid_hash IS NOT NULL
    AND md.iccid_hash <> v_event.iccid_hash
  ORDER BY md.created_at DESC, md.member_device_id DESC
  LIMIT 1;

  IF v_prior_iccid_hash IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT rf.formula_version_id
  INTO v_formula_version_id
  FROM public.risk_formula_versions rf
  WHERE rf.formula_key = 'TIER1_DETERMINISTIC_DEFAULT'
    AND rf.is_active = TRUE
  ORDER BY rf.created_at DESC
  LIMIT 1;

  IF v_formula_version_id IS NULL THEN
    RAISE EXCEPTION 'active formula key % not found', 'TIER1_DETERMINISTIC_DEFAULT'
      USING ERRCODE = 'P7401';
  END IF;

  INSERT INTO public.sim_swap_alerts(
    tenant_id,
    member_id,
    source_event_id,
    prior_iccid_hash,
    new_iccid_hash,
    formula_version_id,
    alert_type,
    derived_at
  )
  VALUES (
    v_event.tenant_id,
    v_event.member_id,
    v_event.event_id,
    v_prior_iccid_hash,
    v_event.iccid_hash,
    v_formula_version_id,
    'SIM_SWAP_DETECTED',
    COALESCE(v_event.observed_at, NOW())
  )
  ON CONFLICT (source_event_id) DO NOTHING
  RETURNING alert_id INTO v_alert_id;

  IF v_alert_id IS NULL THEN
    SELECT s.alert_id
    INTO v_alert_id
    FROM public.sim_swap_alerts s
    WHERE s.source_event_id = v_event.event_id;
  END IF;

  RETURN v_alert_id;
END;
$$;

COMMENT ON TABLE public.sim_swap_alerts IS
  'Phase-1 append-only SIM swap alerts derived from member_device_events with formula-version traceability.';

REVOKE ALL ON TABLE public.sim_swap_alerts FROM PUBLIC;
