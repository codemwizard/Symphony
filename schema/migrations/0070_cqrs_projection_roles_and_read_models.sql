-- 0070_cqrs_projection_roles_and_read_models.sql
-- Sprint-2 CQRS/projection split: additive query-side roles and projection tables.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_command') THEN
    CREATE ROLE symphony_command NOLOGIN;
  END IF;
  ALTER ROLE symphony_command NOLOGIN;

  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'symphony_query') THEN
    CREATE ROLE symphony_query NOLOGIN;
  END IF;
  ALTER ROLE symphony_query NOLOGIN;
END $$;

GRANT USAGE ON SCHEMA public TO symphony_command, symphony_query;

CREATE TABLE IF NOT EXISTS public.instruction_status_projection (
  instruction_id TEXT PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  participant_id TEXT NOT NULL,
  rail_type TEXT NOT NULL,
  status TEXT NOT NULL,
  attestation_id UUID NOT NULL REFERENCES public.ingress_attestations(attestation_id) ON DELETE RESTRICT,
  outbox_id UUID NOT NULL,
  payload_hash TEXT NOT NULL,
  amount_minor BIGINT NOT NULL DEFAULT 0,
  currency_code CHAR(3) NOT NULL DEFAULT 'ZMW',
  correlation_id UUID NULL,
  as_of_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  projection_version TEXT NOT NULL DEFAULT 'phase1-cqrs-v1'
);

CREATE TABLE IF NOT EXISTS public.evidence_bundle_projection (
  instruction_id TEXT PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  projection_payload JSONB NOT NULL,
  as_of_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  projection_version TEXT NOT NULL DEFAULT 'phase1-cqrs-v1'
);

CREATE TABLE IF NOT EXISTS public.escrow_summary_projection (
  escrow_id UUID PRIMARY KEY REFERENCES public.escrow_accounts(escrow_id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  program_id UUID NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  state TEXT NOT NULL,
  authorized_amount_minor BIGINT NOT NULL DEFAULT 0,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  as_of_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  projection_version TEXT NOT NULL DEFAULT 'phase1-cqrs-v1'
);

CREATE TABLE IF NOT EXISTS public.incident_case_projection (
  incident_id UUID PRIMARY KEY REFERENCES public.regulatory_incidents(incident_id) ON DELETE RESTRICT,
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  status TEXT NOT NULL,
  projection_payload JSONB NOT NULL,
  as_of_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  projection_version TEXT NOT NULL DEFAULT 'phase1-cqrs-v1'
);

CREATE TABLE IF NOT EXISTS public.program_member_summary_projection (
  tenant_id UUID NOT NULL REFERENCES public.tenants(tenant_id) ON DELETE RESTRICT,
  program_id UUID NOT NULL REFERENCES public.programs(program_id) ON DELETE RESTRICT,
  active_member_count BIGINT NOT NULL DEFAULT 0,
  verified_member_count BIGINT NOT NULL DEFAULT 0,
  as_of_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  projection_version TEXT NOT NULL DEFAULT 'phase1-cqrs-v1',
  PRIMARY KEY (tenant_id, program_id)
);

REVOKE ALL ON TABLE public.instruction_status_projection FROM PUBLIC;
REVOKE ALL ON TABLE public.evidence_bundle_projection FROM PUBLIC;
REVOKE ALL ON TABLE public.escrow_summary_projection FROM PUBLIC;
REVOKE ALL ON TABLE public.incident_case_projection FROM PUBLIC;
REVOKE ALL ON TABLE public.program_member_summary_projection FROM PUBLIC;

REVOKE ALL ON TABLE public.instruction_status_projection FROM symphony_query, symphony_command, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.evidence_bundle_projection FROM symphony_query, symphony_command, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.escrow_summary_projection FROM symphony_query, symphony_command, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.incident_case_projection FROM symphony_query, symphony_command, symphony_control, symphony_readonly, symphony_auditor, test_user;
REVOKE ALL ON TABLE public.program_member_summary_projection FROM symphony_query, symphony_command, symphony_control, symphony_readonly, symphony_auditor, test_user;

GRANT SELECT, INSERT, UPDATE ON TABLE public.instruction_status_projection TO symphony_command, symphony_control, test_user;
GRANT SELECT, INSERT, UPDATE ON TABLE public.evidence_bundle_projection TO symphony_command, symphony_control, test_user;
GRANT SELECT, INSERT, UPDATE ON TABLE public.escrow_summary_projection TO symphony_command, symphony_control, test_user;
GRANT SELECT, INSERT, UPDATE ON TABLE public.incident_case_projection TO symphony_command, symphony_control, test_user;
GRANT SELECT, INSERT, UPDATE ON TABLE public.program_member_summary_projection TO symphony_command, symphony_control, test_user;

GRANT SELECT ON TABLE public.instruction_status_projection TO symphony_query, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.evidence_bundle_projection TO symphony_query, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.escrow_summary_projection TO symphony_query, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.incident_case_projection TO symphony_query, symphony_readonly, symphony_auditor;
GRANT SELECT ON TABLE public.program_member_summary_projection TO symphony_query, symphony_readonly, symphony_auditor;
