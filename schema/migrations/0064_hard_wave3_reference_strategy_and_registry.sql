CREATE TYPE public.reference_strategy_type_enum AS ENUM (
  'SUFFIX',
  'DETERMINISTIC_ALIAS',
  'RE_ENCODED_HASH_TOKEN',
  'RAIL_NATIVE_ALT_FIELD'
);

CREATE TABLE public.reference_strategy_policy_versions (
  policy_version_id text PRIMARY KEY,
  version_status text NOT NULL DEFAULT 'ACTIVE' CHECK (version_status IN ('ACTIVE','INACTIVE')),
  policy_json jsonb NOT NULL,
  signed_at timestamptz,
  signed_key_id text,
  unsigned_reason text,
  evidence_path text,
  activated_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_reference_strategy_policy_active
  ON public.reference_strategy_policy_versions((version_status))
  WHERE version_status = 'ACTIVE';

CREATE TABLE public.dispatch_reference_registry (
  registry_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id uuid NOT NULL,
  adjustment_id uuid REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT,
  rail_id text NOT NULL,
  allocated_reference text NOT NULL,
  canonicalized_reference text NOT NULL,
  strategy_used public.reference_strategy_type_enum NOT NULL,
  policy_version_id text NOT NULL REFERENCES public.reference_strategy_policy_versions(policy_version_id) ON DELETE RESTRICT,
  collision_retry_count integer NOT NULL DEFAULT 0 CHECK (collision_retry_count >= 0),
  allocation_timestamp timestamptz NOT NULL DEFAULT now(),
  dispatch_attempted_at timestamptz,
  CONSTRAINT dispatch_reference_registry_ref_unique UNIQUE (rail_id, allocated_reference),
  CONSTRAINT dispatch_reference_registry_canon_unique UNIQUE (rail_id, canonicalized_reference)
);

CREATE INDEX idx_dispatch_reference_registry_instruction ON public.dispatch_reference_registry(instruction_id, allocation_timestamp DESC);
CREATE INDEX idx_dispatch_reference_registry_adjustment ON public.dispatch_reference_registry(adjustment_id, allocation_timestamp DESC);

CREATE TABLE public.dispatch_reference_collision_events (
  collision_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  instruction_id uuid NOT NULL,
  adjustment_id uuid REFERENCES public.adjustment_instructions(adjustment_id) ON DELETE RESTRICT,
  rail_id text NOT NULL,
  reference_attempted text NOT NULL,
  strategy_used public.reference_strategy_type_enum NOT NULL,
  collision_count integer NOT NULL CHECK (collision_count >= 1),
  outcome text NOT NULL CHECK (outcome IN ('RESOLVED','EXHAUSTED','TRUNCATION_COLLISION_BLOCKED','UNREGISTERED_BLOCKED','REJECTED')),
  policy_version_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_dispatch_reference_collision_events_instruction ON public.dispatch_reference_collision_events(instruction_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.block_active_reference_policy_updates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF OLD.version_status = 'ACTIVE' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P7803',
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_block_active_reference_policy_updates ON public.reference_strategy_policy_versions;
CREATE TRIGGER trg_block_active_reference_policy_updates
BEFORE UPDATE ON public.reference_strategy_policy_versions
FOR EACH ROW
EXECUTE FUNCTION public.block_active_reference_policy_updates();

CREATE OR REPLACE FUNCTION public.resolve_reference_strategy(
  p_rail_id text
)
RETURNS TABLE(
  strategy_type public.reference_strategy_type_enum,
  rail_id text,
  max_length integer,
  nonce_retry_limit integer,
  collision_action text,
  policy_version_id text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_policy record;
BEGIN
  SELECT policy_version_id, policy_json INTO v_policy
  FROM public.reference_strategy_policy_versions
  WHERE version_status = 'ACTIVE'
  ORDER BY activated_at DESC
  LIMIT 1;

  IF v_policy.policy_version_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
  END IF;

  RETURN QUERY
  SELECT
    (s->>'strategy_type')::public.reference_strategy_type_enum,
    s->>'rail_id',
    (s->>'max_length')::integer,
    (s->>'nonce_retry_limit')::integer,
    s->>'collision_action',
    v_policy.policy_version_id
  FROM jsonb_array_elements(v_policy.policy_json->'strategies') AS s
  WHERE s->>'rail_id' IN (p_rail_id, '*')
  ORDER BY CASE WHEN s->>'rail_id' = p_rail_id THEN 0 ELSE 1 END
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='P7802', MESSAGE='REFERENCE_STRATEGY_POLICY_NOT_FOUND';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.canonicalize_reference_for_rail(
  p_allocated_reference text,
  p_rail_id text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_strategy record;
  v_truncated text;
BEGIN
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);
  v_truncated := left(p_allocated_reference, v_strategy.max_length);
  IF length(v_truncated) > v_strategy.max_length THEN
    RAISE EXCEPTION USING ERRCODE='P7901', MESSAGE='REFERENCE_LENGTH_EXCEEDED';
  END IF;
  RETURN v_truncated;
END;
$$;

CREATE OR REPLACE FUNCTION public.allocate_dispatch_reference(
  p_instruction_id uuid,
  p_adjustment_id uuid,
  p_parent_reference text,
  p_rail_id text
)
RETURNS TABLE(
  registry_id uuid,
  allocated_reference text,
  canonicalized_reference text,
  strategy_used public.reference_strategy_type_enum,
  policy_version_id text,
  collision_retry_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_strategy record;
  v_attempt integer := 0;
  v_candidate text;
  v_canon text;
  v_collision boolean;
BEGIN
  SELECT * INTO v_strategy FROM public.resolve_reference_strategy(p_rail_id);

  LOOP
    IF v_strategy.strategy_type = 'SUFFIX' THEN
      v_candidate := p_parent_reference || '-' || lpad(v_attempt::text, 2, '0');
    ELSIF v_strategy.strategy_type = 'DETERMINISTIC_ALIAS' THEN
      v_candidate := substr(md5(p_parent_reference || ':' || coalesce(p_adjustment_id::text,'none') || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
    ELSIF v_strategy.strategy_type = 'RE_ENCODED_HASH_TOKEN' THEN
      v_candidate := substr(md5('reh:' || p_parent_reference || ':' || p_rail_id || ':' || v_attempt::text), 1, greatest(8, v_strategy.max_length));
    ELSE
      v_candidate := p_parent_reference;
    END IF;

    v_canon := public.canonicalize_reference_for_rail(v_candidate, p_rail_id);

    SELECT EXISTS(
      SELECT 1 FROM public.dispatch_reference_registry r
      WHERE r.rail_id = p_rail_id
        AND (r.allocated_reference = v_candidate OR r.canonicalized_reference = v_canon)
    ) INTO v_collision;

    IF NOT v_collision THEN
      INSERT INTO public.dispatch_reference_registry(
        instruction_id, adjustment_id, rail_id, allocated_reference,
        canonicalized_reference, strategy_used, policy_version_id, collision_retry_count
      ) VALUES (
        p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
        v_canon, v_strategy.strategy_type, v_strategy.policy_version_id, v_attempt
      )
      RETURNING
        dispatch_reference_registry.registry_id,
        dispatch_reference_registry.allocated_reference,
        dispatch_reference_registry.canonicalized_reference,
        dispatch_reference_registry.strategy_used,
        dispatch_reference_registry.policy_version_id,
        dispatch_reference_registry.collision_retry_count
      INTO registry_id, allocated_reference, canonicalized_reference, strategy_used, policy_version_id, collision_retry_count;

      IF v_attempt > 0 THEN
        INSERT INTO public.dispatch_reference_collision_events(
          instruction_id, adjustment_id, rail_id, reference_attempted,
          strategy_used, collision_count, outcome, policy_version_id
        ) VALUES (
          p_instruction_id, p_adjustment_id, p_rail_id, v_candidate,
          v_strategy.strategy_type, v_attempt, 'RESOLVED', v_strategy.policy_version_id
        );
      END IF;

      RETURN NEXT;
      RETURN;
    END IF;

    v_attempt := v_attempt + 1;
    IF v_attempt > v_strategy.nonce_retry_limit THEN
      INSERT INTO public.dispatch_reference_collision_events(
        instruction_id, adjustment_id, rail_id, reference_attempted,
        strategy_used, collision_count, outcome, policy_version_id
      ) VALUES (
        p_instruction_id, p_adjustment_id, p_rail_id, p_parent_reference,
        v_strategy.strategy_type, v_attempt, 'EXHAUSTED', v_strategy.policy_version_id
      );
      RAISE EXCEPTION USING ERRCODE='P7801', MESSAGE='REFERENCE_ALLOCATION_RETRY_EXHAUSTED';
    END IF;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION public.assert_reference_registered(
  p_rail_id text,
  p_reference text,
  p_instruction_id uuid,
  p_adjustment_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.dispatch_reference_registry r
    WHERE r.rail_id = p_rail_id
      AND (r.allocated_reference = p_reference OR r.canonicalized_reference = p_reference)
      AND r.instruction_id = p_instruction_id
      AND (p_adjustment_id IS NULL OR r.adjustment_id = p_adjustment_id)
  ) INTO v_exists;

  IF NOT v_exists THEN
    INSERT INTO public.dispatch_reference_collision_events(
      instruction_id, adjustment_id, rail_id, reference_attempted,
      strategy_used, collision_count, outcome, policy_version_id
    ) VALUES (
      p_instruction_id, p_adjustment_id, p_rail_id, p_reference,
      'SUFFIX', 1, 'UNREGISTERED_BLOCKED', NULL
    );
    RAISE EXCEPTION USING ERRCODE='P8001', MESSAGE='REFERENCE_NOT_REGISTERED';
  END IF;
END;
$$;

INSERT INTO public.reference_strategy_policy_versions(
  policy_version_id,
  version_status,
  policy_json,
  unsigned_reason,
  evidence_path
)
VALUES (
  'refdsl-v1',
  'ACTIVE',
  jsonb_build_object(
    'schema_version', '1.0.0',
    'strategies', jsonb_build_array(
      jsonb_build_object('strategy_type','SUFFIX','rail_id','*','max_length',35,'nonce_retry_limit',3,'collision_action','RETRY_WITH_NONCE'),
      jsonb_build_object('strategy_type','DETERMINISTIC_ALIAS','rail_id','zipss','max_length',32,'nonce_retry_limit',4,'collision_action','RETRY_WITH_NONCE'),
      jsonb_build_object('strategy_type','RE_ENCODED_HASH_TOKEN','rail_id','mmo','max_length',28,'nonce_retry_limit',4,'collision_action','RETRY_WITH_NONCE'),
      jsonb_build_object('strategy_type','RAIL_NATIVE_ALT_FIELD','rail_id','zechl','max_length',48,'nonce_retry_limit',1,'collision_action','BLOCK')
    )
  ),
  'DEPENDENCY_NOT_READY',
  'evidence/phase1/hardening/tsk_hard_030.json'
)
ON CONFLICT (policy_version_id) DO NOTHING;

REVOKE ALL ON TABLE public.reference_strategy_policy_versions FROM PUBLIC;
REVOKE ALL ON TABLE public.dispatch_reference_registry FROM PUBLIC;
REVOKE ALL ON TABLE public.dispatch_reference_collision_events FROM PUBLIC;
