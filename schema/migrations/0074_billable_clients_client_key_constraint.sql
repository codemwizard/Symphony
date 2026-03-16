-- Migration 0074: Replace billable_clients unique index with full constraint
-- This migration repairs the conflict target defect for NpgsqlTenantOnboardingStore.

DROP INDEX IF EXISTS public.ux_billable_clients_client_key;

DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_constraint 
        WHERE conname = 'ux_billable_clients_client_key' 
          AND conrelid = 'public.billable_clients'::regclass
    ) THEN 
        ALTER TABLE public.billable_clients 
        ADD CONSTRAINT ux_billable_clients_client_key UNIQUE (client_key); 
    END IF; 
END $$;
