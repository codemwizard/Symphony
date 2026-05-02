-- Migration 0174: Expand execution_records with entity_type and entity_id
-- Task: TSK-P2-W5-REM-01
-- symphony:no_tx

ALTER TABLE public.execution_records 
ADD COLUMN IF NOT EXISTS entity_type TEXT, 
ADD COLUMN IF NOT EXISTS entity_id UUID;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_execution_records_entity_coherence 
ON public.execution_records (entity_type, entity_id);
