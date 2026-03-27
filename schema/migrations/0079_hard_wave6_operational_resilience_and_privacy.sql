CREATE TABLE public.artifact_signing_batches (
  batch_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  artifact_class text NOT NULL,
  merkle_root text NOT NULL,
  total_artifacts integer NOT NULL CHECK (total_artifacts > 0),
  hsm_key_ref text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.artifact_signing_batch_items (
  item_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.artifact_signing_batches(batch_id) ON DELETE CASCADE,
  artifact_id text NOT NULL,
  leaf_index integer NOT NULL CHECK (leaf_index >= 0),
  leaf_hash text NOT NULL,
  UNIQUE (batch_id, leaf_index)
);

CREATE TABLE public.hsm_fail_closed_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  outage_source text NOT NULL,
  blocked_action text NOT NULL,
  error_code text NOT NULL,
  observed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.signing_throughput_runs (
  run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  target_tps integer NOT NULL CHECK (target_tps > 0),
  achieved_tps integer NOT NULL CHECK (achieved_tps >= 0),
  p95_latency_ms integer NOT NULL CHECK (p95_latency_ms >= 0),
  pass boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.global_rate_limit_policies (
  policy_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  partition_strategy text NOT NULL,
  max_requests integer NOT NULL CHECK (max_requests > 0),
  interval_seconds integer NOT NULL CHECK (interval_seconds > 0),
  activated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.regulatory_retraction_approvals (
  approval_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id text NOT NULL,
  approver_role text NOT NULL,
  approval_stage text NOT NULL,
  approved_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (report_id, approver_role, approval_stage)
);

CREATE TABLE public.redaction_audit_events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id text NOT NULL,
  actor_id text NOT NULL,
  action text NOT NULL,
  redaction_scope text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.boz_operational_scenario_runs (
  run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scenario_name text NOT NULL,
  outcome text NOT NULL CHECK (outcome IN ('PASS','FAIL')),
  evidence_ref text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.regulatory_report_submission_attempts (
  attempt_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id text NOT NULL,
  endpoint text NOT NULL,
  status text NOT NULL,
  response_code integer,
  attempted_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.pii_tokenization_registry (
  token_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_ref text NOT NULL,
  token_value text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  retired_at timestamptz
);

CREATE TABLE public.pii_erasure_journal (
  erasure_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_ref text NOT NULL,
  request_source text NOT NULL,
  approved_at timestamptz,
  completed_at timestamptz,
  status text NOT NULL CHECK (status IN ('REQUESTED','APPROVED','COMPLETED','FAILED'))
);

CREATE TABLE public.pii_erased_subject_placeholders (
  placeholder_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_ref text NOT NULL,
  placeholder_ref text NOT NULL UNIQUE,
  purge_effective_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.penalty_defense_packs (
  pack_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id text NOT NULL,
  contains_raw_pii boolean NOT NULL DEFAULT false,
  submission_attempt_ref uuid REFERENCES public.regulatory_report_submission_attempts(attempt_id),
  generated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.audit_tamper_evident_chains (
  chain_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain text NOT NULL,
  current_hash text NOT NULL,
  previous_hash text,
  generated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.assert_hsm_fail_closed(p_should_block boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_should_block THEN
    RAISE EXCEPTION USING ERRCODE='P8401', MESSAGE='HSM_FAIL_CLOSED_ENFORCED';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_rate_limit_blocked(p_blocked boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_blocked THEN
    RAISE EXCEPTION USING ERRCODE='P8402', MESSAGE='RATE_LIMIT_BREACH_BLOCKED';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_secondary_retraction_approval(p_ok boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT p_ok THEN
    RAISE EXCEPTION USING ERRCODE='P8403', MESSAGE='RETRACTION_SECONDARY_APPROVAL_REQUIRED';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_pii_absent_from_penalty_pack(p_contains_raw_pii boolean)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF p_contains_raw_pii THEN
    RAISE EXCEPTION USING ERRCODE='P8404', MESSAGE='PII_PRESENT_IN_PENALTY_DEFENSE_PACK';
  END IF;
END;
$$;

REVOKE ALL ON TABLE public.artifact_signing_batches FROM PUBLIC;
REVOKE ALL ON TABLE public.artifact_signing_batch_items FROM PUBLIC;
REVOKE ALL ON TABLE public.hsm_fail_closed_events FROM PUBLIC;
REVOKE ALL ON TABLE public.signing_throughput_runs FROM PUBLIC;
REVOKE ALL ON TABLE public.global_rate_limit_policies FROM PUBLIC;
REVOKE ALL ON TABLE public.regulatory_retraction_approvals FROM PUBLIC;
REVOKE ALL ON TABLE public.redaction_audit_events FROM PUBLIC;
REVOKE ALL ON TABLE public.boz_operational_scenario_runs FROM PUBLIC;
REVOKE ALL ON TABLE public.regulatory_report_submission_attempts FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_tokenization_registry FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_erasure_journal FROM PUBLIC;
REVOKE ALL ON TABLE public.pii_erased_subject_placeholders FROM PUBLIC;
REVOKE ALL ON TABLE public.penalty_defense_packs FROM PUBLIC;
REVOKE ALL ON TABLE public.audit_tamper_evident_chains FROM PUBLIC;
