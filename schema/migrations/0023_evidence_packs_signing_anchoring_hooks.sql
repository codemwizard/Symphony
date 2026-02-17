-- 0023_evidence_packs_signing_anchoring_hooks.sql
-- Evidence pack signing + anchoring schema hooks (Phase-0: schema-only; forward-only)

ALTER TABLE public.evidence_packs
  ADD COLUMN IF NOT EXISTS signer_participant_id TEXT NULL,
  ADD COLUMN IF NOT EXISTS signature_alg TEXT NULL,
  ADD COLUMN IF NOT EXISTS signature TEXT NULL,
  ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS anchor_type TEXT NULL,
  ADD COLUMN IF NOT EXISTS anchor_ref TEXT NULL,
  ADD COLUMN IF NOT EXISTS anchored_at TIMESTAMPTZ NULL;

CREATE INDEX IF NOT EXISTS idx_evidence_packs_anchor_ref
  ON public.evidence_packs(anchor_ref)
  WHERE anchor_ref IS NOT NULL;

