-- Migration: 0194_fix_nonce_registry_fk_reference.sql
-- Task: Devin Review remediation
-- Purpose: Ensure wave8_attestation_nonces.batch_id FK references asset_batches(asset_batch_id)
-- Dependencies: 0183_wave8_replay_nonce_registry.sql
-- Type: Forward-only migration
--
-- Bug: Migration 0183 defines batch_id uuid REFERENCES public.asset_batches(id),
-- but the asset_batches primary key is asset_batch_id, not id. Migration 0181
-- creates the table first with the correct FK, so 0183 is a no-op in practice.
-- However, the SQL is incorrect and would fail if applied independently.
--
-- Fix: Drop the incorrect FK constraint if it somehow exists, then ensure the
-- correct constraint referencing asset_batches(asset_batch_id) is present.

-- Drop incorrect FK if it was somehow applied (defensive)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
            AND tc.table_schema = ccu.table_schema
        WHERE tc.table_schema = 'public'
            AND tc.table_name = 'wave8_attestation_nonces'
            AND tc.constraint_type = 'FOREIGN KEY'
            AND ccu.table_name = 'asset_batches'
            AND ccu.column_name = 'id'
    ) THEN
        -- Find and drop the constraint that references the wrong column
        EXECUTE (
            SELECT format('ALTER TABLE public.wave8_attestation_nonces DROP CONSTRAINT %I', tc.constraint_name)
            FROM information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu
                ON tc.constraint_name = ccu.constraint_name
                AND tc.table_schema = ccu.table_schema
            WHERE tc.table_schema = 'public'
                AND tc.table_name = 'wave8_attestation_nonces'
                AND tc.constraint_type = 'FOREIGN KEY'
                AND ccu.table_name = 'asset_batches'
                AND ccu.column_name = 'id'
            LIMIT 1
        );
    END IF;
END;
$$;

-- Ensure the correct FK exists (idempotent — skips if already present from 0181)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
            AND tc.table_schema = ccu.table_schema
        WHERE tc.table_schema = 'public'
            AND tc.table_name = 'wave8_attestation_nonces'
            AND tc.constraint_type = 'FOREIGN KEY'
            AND ccu.table_name = 'asset_batches'
            AND ccu.column_name = 'asset_batch_id'
    ) THEN
        ALTER TABLE public.wave8_attestation_nonces
            ADD CONSTRAINT wave8_attestation_nonces_batch_id_fkey
            FOREIGN KEY (batch_id) REFERENCES public.asset_batches(asset_batch_id);
    END IF;
END;
$$;
