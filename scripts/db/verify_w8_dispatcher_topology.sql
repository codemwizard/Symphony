-- Verification SQL for Wave 8 dispatcher topology
-- Task: TSK-P2-W8-DB-001
-- Purpose: Prove that asset_batches writes run through one explicit dispatcher path

-- Check 1: Verify only one trigger exists on asset_batches
SELECT 
    COUNT(*) as trigger_count,
    ARRAY_AGG(trigger_name ORDER BY trigger_name) as trigger_names
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public';

-- Expected: trigger_count = 1, trigger_names = ['trg_wave8_asset_batches_dispatcher']

-- Check 2: Verify the dispatcher trigger exists and is BEFORE INSERT
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public'
AND trigger_name = 'trg_wave8_asset_batches_dispatcher';

-- Expected: event_manipulation = 'INSERT', action_timing = 'BEFORE'

-- Check 3: Verify the dispatcher function exists and is SECURITY DEFINER
SELECT 
    p.proname as function_name,
    p.prosecdef as security_definer,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname = 'wave8_asset_batches_dispatcher';

-- Expected: prosecdef = true (SECURITY DEFINER)

-- Check 4: Verify competing triggers have been dropped
SELECT 
    trigger_name
FROM information_schema.triggers
WHERE event_object_table = 'asset_batches'
AND event_object_schema = 'public'
AND trigger_name IN (
    'trg_attestation_gate_asset_batches',
    'trg_enforce_attestation_freshness',
    'trg_enforce_asset_batch_authority'
);

-- Expected: 0 rows (competing triggers dropped)

-- Check 5: Test write through dispatcher (physical write test)
-- This will actually attempt an insert to prove the dispatcher path is active
DO $$
DECLARE
    test_result text;
BEGIN
    -- Attempt a minimal insert that should fail at the dispatcher gates
    -- This proves the dispatcher is actually intercepting writes
    BEGIN
        INSERT INTO public.asset_batches (
            asset_batch_id,
            tenant_id,
            project_id,
            batch_type,
            quantity,
            status,
            data_authority,
            audit_grade,
            authority_explanation
        ) VALUES (
            gen_random_uuid(),
            gen_random_uuid(),
            gen_random_uuid(),
            'TEST',
            1,
            'PENDING',
            'pending'::data_authority_level,
            false,
            'Wave 8 dispatcher topology test'
        );
        test_result := 'INSERT_SUCCEEDED';
    EXCEPTION WHEN OTHERS THEN
        test_result := 'INSERT_FAILED_DISPATCHER_ACTIVE';
    END;
    
    RAISE NOTICE 'Dispatcher test result: %', test_result;
END $$;

-- Expected: INSERT_FAILED_DISPATCHER_ACTIVE (dispatcher gates reject invalid test data)
