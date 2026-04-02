-- Migration 0103: Green Finance Jurisdiction Rules — remaining regulatory tables
-- Phase 0 schema. Depends on 0102 (regulatory_authorities, current_jurisdiction_code_or_null).

CREATE TABLE public.regulatory_checkpoints (
    regulatory_checkpoint_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    regulatory_authority_id UUID NOT NULL REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT,
    checkpoint_type TEXT NOT NULL,
    checkpoint_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.jurisdiction_profiles (
    jurisdiction_profile_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    profile_type TEXT NOT NULL,
    profile_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.lifecycle_checkpoint_rules (
    lifecycle_checkpoint_rule_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    regulatory_checkpoint_id UUID NOT NULL REFERENCES public.regulatory_checkpoints(regulatory_checkpoint_id) ON DELETE RESTRICT,
    rule_type TEXT NOT NULL,
    rule_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.authority_decisions (
    authority_decision_id UUID PRIMARY KEY DEFAULT public.uuid_v7_or_random(),
    jurisdiction_code TEXT NOT NULL,
    regulatory_authority_id UUID NOT NULL REFERENCES public.regulatory_authorities(regulatory_authority_id) ON DELETE RESTRICT,
    decision_type TEXT NOT NULL,
    decision_payload_json JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for performance
CREATE INDEX idx_regulatory_checkpoints_jurisdiction ON regulatory_checkpoints(jurisdiction_code);
CREATE INDEX idx_jurisdiction_profiles_jurisdiction ON jurisdiction_profiles(jurisdiction_code);
CREATE INDEX idx_lifecycle_checkpoint_rules_jurisdiction ON lifecycle_checkpoint_rules(jurisdiction_code);
CREATE INDEX idx_authority_decisions_jurisdiction ON authority_decisions(jurisdiction_code);

-- RLS for jurisdiction isolation (not tenant isolation)
ALTER TABLE public.regulatory_checkpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regulatory_checkpoints FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_regulatory_checkpoints ON public.regulatory_checkpoints
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

ALTER TABLE public.jurisdiction_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jurisdiction_profiles FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_jurisdiction_profiles ON public.jurisdiction_profiles
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

ALTER TABLE public.lifecycle_checkpoint_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lifecycle_checkpoint_rules FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_lifecycle_checkpoint_rules ON public.lifecycle_checkpoint_rules
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

ALTER TABLE public.authority_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authority_decisions FORCE ROW LEVEL SECURITY;

CREATE POLICY rls_jurisdiction_isolation_authority_decisions ON public.authority_decisions
    FOR ALL TO PUBLIC
    USING (jurisdiction_code = public.current_jurisdiction_code_or_null())
    WITH CHECK (jurisdiction_code = public.current_jurisdiction_code_or_null());

-- Revoke-first privilege posture
REVOKE ALL ON TABLE regulatory_checkpoints FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE regulatory_checkpoints TO symphony_command;
GRANT ALL ON TABLE regulatory_checkpoints TO symphony_control;

REVOKE ALL ON TABLE jurisdiction_profiles FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE jurisdiction_profiles TO symphony_command;
GRANT ALL ON TABLE jurisdiction_profiles TO symphony_control;

REVOKE ALL ON TABLE lifecycle_checkpoint_rules FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE lifecycle_checkpoint_rules TO symphony_command;
GRANT ALL ON TABLE lifecycle_checkpoint_rules TO symphony_control;

REVOKE ALL ON TABLE authority_decisions FROM PUBLIC;
GRANT SELECT, INSERT ON TABLE authority_decisions TO symphony_command;
GRANT ALL ON TABLE authority_decisions TO symphony_control;
