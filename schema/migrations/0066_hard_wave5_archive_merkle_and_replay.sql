CREATE TABLE public.canonicalization_registry (
  canonicalization_version text PRIMARY KEY,
  spec_json jsonb NOT NULL,
  test_vectors jsonb NOT NULL,
  activated_at timestamptz NOT NULL DEFAULT now(),
  deprecated_at timestamptz,
  immutable boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.canonicalization_archive_snapshots (
  snapshot_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  canonicalization_version text NOT NULL REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT,
  snapshot_path text NOT NULL,
  snapshot_sha256 text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (canonicalization_version, snapshot_sha256)
);

CREATE TABLE public.proof_pack_batches (
  batch_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  merkle_root text NOT NULL,
  leaf_count integer NOT NULL CHECK (leaf_count > 0),
  canonicalization_version text NOT NULL REFERENCES public.canonicalization_registry(canonicalization_version) ON DELETE RESTRICT,
  published_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.proof_pack_batch_leaves (
  leaf_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id uuid NOT NULL REFERENCES public.proof_pack_batches(batch_id) ON DELETE CASCADE,
  artifact_id text NOT NULL,
  leaf_index integer NOT NULL CHECK (leaf_index >= 0),
  leaf_hash text NOT NULL,
  merkle_proof jsonb NOT NULL,
  UNIQUE (batch_id, leaf_index)
);

CREATE TABLE public.anchor_backfill_jobs (
  job_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  replay_day date NOT NULL,
  status text NOT NULL CHECK (status IN ('STARTED','COMPLETED','FAILED')),
  source_stream text NOT NULL,
  target_stream text NOT NULL,
  records_replayed integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE public.archive_verification_runs (
  run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_scope text NOT NULL,
  years_covered integer NOT NULL CHECK (years_covered >= 1),
  archive_only boolean NOT NULL DEFAULT true,
  key_versions_covered text[] NOT NULL,
  canonicalization_versions_covered text[] NOT NULL,
  outcome text NOT NULL CHECK (outcome IN ('PASS','FAIL')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.assert_canonicalization_version_exists(p_version text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.canonicalization_registry WHERE canonicalization_version = p_version) THEN
    RAISE EXCEPTION USING ERRCODE='P8301', MESSAGE='UNVERIFIABLE_MISSING_CANONICALIZER';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.verify_merkle_leaf(
  p_batch_id uuid,
  p_leaf_index integer,
  p_expected_leaf_hash text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_hash text;
BEGIN
  SELECT leaf_hash INTO v_hash
  FROM public.proof_pack_batch_leaves
  WHERE batch_id = p_batch_id AND leaf_index = p_leaf_index;

  IF v_hash IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='P8302', MESSAGE='MERKLE_LEAF_NOT_FOUND';
  END IF;

  IF v_hash <> p_expected_leaf_hash THEN
    RAISE EXCEPTION USING ERRCODE='P8303', MESSAGE='MERKLE_LEAF_HASH_MISMATCH';
  END IF;

  RETURN true;
END;
$$;

INSERT INTO public.canonicalization_registry(canonicalization_version, spec_json, test_vectors)
VALUES ('canon-v1', '{"algorithm":"stable-json-v1"}'::jsonb, '{"vectors":[{"id":"v1-1"}]}'::jsonb)
ON CONFLICT (canonicalization_version) DO NOTHING;

REVOKE ALL ON TABLE public.canonicalization_registry FROM PUBLIC;
REVOKE ALL ON TABLE public.canonicalization_archive_snapshots FROM PUBLIC;
REVOKE ALL ON TABLE public.proof_pack_batches FROM PUBLIC;
REVOKE ALL ON TABLE public.proof_pack_batch_leaves FROM PUBLIC;
REVOKE ALL ON TABLE public.anchor_backfill_jobs FROM PUBLIC;
REVOKE ALL ON TABLE public.archive_verification_runs FROM PUBLIC;
