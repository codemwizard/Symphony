-- Migration: 0188_wave8_signer_resolution_add_superseded_columns.sql
-- Task: TSK-P2-W8-DB-005 (remediation)
-- Purpose: Add missing superseded_by and superseded_at columns to wave8_signer_resolution table
-- Dependencies: 0176_wave8_signer_resolution_surface.sql
-- Type: Forward-only migration
--
-- Bug: Migration 0176 defined resolve_authoritative_signer() returning superseded_by and
-- superseded_at columns, but the table definition omitted them. This causes undefined-column
-- errors when the function executes its SELECT against the table.

ALTER TABLE public.wave8_signer_resolution
    ADD COLUMN IF NOT EXISTS superseded_by uuid,
    ADD COLUMN IF NOT EXISTS superseded_at timestamp with time zone;

COMMENT ON COLUMN public.wave8_signer_resolution.superseded_by IS
    'UUID of the signer that supersedes this signer (for key rotation). NULL if not superseded.';

COMMENT ON COLUMN public.wave8_signer_resolution.superseded_at IS
    'Timestamp when this signer was superseded. NULL if not superseded.';
