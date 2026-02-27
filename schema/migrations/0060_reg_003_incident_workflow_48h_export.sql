CREATE TABLE IF NOT EXISTS public.regulatory_incidents (
  incident_id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  incident_type TEXT NOT NULL,
  detected_at TIMESTAMPTZ NOT NULL,
  description TEXT NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  status TEXT NOT NULL CHECK (status IN ('OPEN','UNDER_INVESTIGATION','REPORTED','CLOSED')),
  reported_to_boz_at TIMESTAMPTZ NULL,
  boz_reference TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.incident_events (
  incident_event_id UUID PRIMARY KEY,
  incident_id UUID NOT NULL REFERENCES public.regulatory_incidents(incident_id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  event_payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_regulatory_incidents_tenant_detected
  ON public.regulatory_incidents (tenant_id, detected_at DESC);

CREATE INDEX IF NOT EXISTS ix_incident_events_incident_created
  ON public.incident_events (incident_id, created_at ASC);
