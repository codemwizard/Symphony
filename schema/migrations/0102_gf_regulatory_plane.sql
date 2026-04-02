-- Migration 0102: Green Finance Regulatory Plane — jurisdiction function and first tables
-- Phase 0 schema for GF jurisdiction isolation. Depends on 0097 (projects).

CREATE OR REPLACE FUNCTION public.current_jurisdiction_code_or_null()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
  SELECT current_setting('app.jurisdiction_code', true);
$$;

REVOKE ALL ON FUNCTION public.current_jurisdiction_code_or_null() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.current_jurisdiction_code_or_null() TO symphony_command;
GRANT EXECUTE ON FUNCTION public.current_jurisdiction_code_or_null() TO symphony_control;

CREATE TABLE public.interpretation_packs (
    interpretation_pack_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    pack_type TEXT NOT NULL,
    pack_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.regulatory_authorities (
    regulatory_authority_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    authority_name TEXT NOT NULL,
    authority_type TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_interpretation_packs_jurisdiction ON interpretation_packs(jurisdiction_code);
CREATE INDEX idx_regulatory_authorities_jurisdiction ON regulatory_authorities(jurisdiction_code);

-- RLS for jurisdiction isolation (not tenant isolation)
ALTER TABLE public.interpretation_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interpretation_packs FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_interpretation_packs ON public.interpretation_packs
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

ALTER TABLE public.regulatory_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_authorities FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_regulatory_authorities ON public.regulatory_authorities
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- Revoke-first privilege posture
REVOKE ALL ON TABLE interpretation_packs FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE interpretation_packs TO symphony_command;
GRANT ALL ON TABLE interpretation_packs TO symphony_control;

REVOKE ALL ON TABLE regulatory_authorities FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE regulatory_authorities TO symphony_command;
GRANT ALL ON TABLE regulatory_authorities TO symphony_control;
