-- Migration 0175: Backfill entity_type and entity_id in execution_records from policy_decisions
-- Task: TSK-P2-W5-REM-01
-- Backfill step of the 4-step sequence

-- Populate from policy_decisions (assuming 1:1 or N:1 relationship where entity is consistent)
UPDATE public.execution_records er
SET entity_type = pd.entity_type,
    entity_id = pd.entity_id
FROM public.policy_decisions pd
WHERE er.execution_id = pd.execution_id;

-- For any remaining orphans (where no policy_decision exists yet), 
-- we leave them NULL for now; the next migration (Constrain) will 
-- fail if orphans exist, which is a valid safety gate for this remediation.
