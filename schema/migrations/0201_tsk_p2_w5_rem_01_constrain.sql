-- Migration 0176: Enforce NOT NULL on entity_type and entity_id in execution_records
-- Task: TSK-P2-W5-REM-01
-- Constrain step of the 4-step sequence

ALTER TABLE public.execution_records
ALTER COLUMN entity_type SET NOT NULL,
ALTER COLUMN entity_id SET NOT NULL;
