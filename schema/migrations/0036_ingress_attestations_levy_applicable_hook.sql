-- TSK-P0-LEVY-002
-- Phase-0 expand-first hook. Column is nullable and always NULL until Phase-2
-- classification logic is implemented.

ALTER TABLE public.ingress_attestations
    ADD COLUMN IF NOT EXISTS levy_applicable BOOLEAN DEFAULT NULL;

COMMENT ON COLUMN public.ingress_attestations.levy_applicable IS
    'Phase-0 structural hook. NULL until Phase-2 MMO Levy classification logic '
    'sets this field. TRUE = instruction is subject to MMO levy under the applicable '
    'jurisdiction statutory rate. FALSE = exempt. NULL = not yet classified. '
    'DO NOT read or write this column in application runtime until Phase-2.';
