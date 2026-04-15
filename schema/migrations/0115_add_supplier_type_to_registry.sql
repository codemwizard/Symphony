-- 0115_add_supplier_type_to_registry.sql

-- Add supplier_type column to public.supplier_registry
-- Baseline synced 2026-04-15 to include this column
ALTER TABLE public.supplier_registry 
ADD COLUMN IF NOT EXISTS supplier_type TEXT;

-- Update existing records to 'WORKER' as a default for simulation safety
UPDATE public.supplier_registry 
SET supplier_type = 'WORKER' 
WHERE supplier_type IS NULL;

-- Ensure the role has access (idempotent)
GRANT SELECT, INSERT, UPDATE ON TABLE public.supplier_registry TO symphony_command;
GRANT ALL ON TABLE public.supplier_registry TO symphony_control;
