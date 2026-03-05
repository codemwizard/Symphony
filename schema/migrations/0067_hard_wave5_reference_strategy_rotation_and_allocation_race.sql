BEGIN;

-- Allow policy rotation by permitting ACTIVE -> INACTIVE transitions,
-- while still blocking mutation of rows that remain ACTIVE.
CREATE OR REPLACE FUNCTION public.block_active_reference_policy_updates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF OLD.version_status = 'ACTIVE' AND NEW.version_status = 'ACTIVE' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P7803',
      MESSAGE = 'ACTIVE_REFERENCE_POLICY_IMMUTABLE';
  END IF;

  RETURN NEW;
END;
$$;

-- Validate raw reference length before truncation so P7901 is reachable.
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

  IF length(p_allocated_reference) > v_strategy.max_length THEN
    RAISE EXCEPTION USING ERRCODE='P7901', MESSAGE='REFERENCE_LENGTH_EXCEEDED';
  END IF;

  v_truncated := left(p_allocated_reference, v_strategy.max_length);
  RETURN v_truncated;
END;
$$;

-- Resolve allocation collisions atomically under concurrent inserts by treating
-- unique violations as collisions and retrying under nonce limits.
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
    v_collision := false;

    BEGIN
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
    EXCEPTION
      WHEN unique_violation THEN
        v_collision := true;
    END;

    IF NOT v_collision THEN
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

INSERT INTO public.schema_migrations(version) VALUES ('0067_hard_wave5_reference_strategy_rotation_and_allocation_race.sql');

COMMIT;
